package com.isigroup.steelsales

import android.util.Base64
import android.util.Log
import java.io.BufferedReader
import java.net.URL
import java.security.MessageDigest
import java.security.cert.X509Certificate
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.X509TrustManager

/**
 * Certificate-pinned HTTP over Android's platform TLS stack (Conscrypt).
 *
 * ## Why this exists at all
 *
 * The SAP facade asks the client to renegotiate the TLS session mid-connection
 * (TLS 1.2 only, almost certainly optional client-certificate negotiation on the
 * binding). Dart's BoringSSL aborts this unconditionally — `NO_RENEGOTIATION`,
 * boringssl `ssl_lib.cc:1635` — with no option to permit it, so no Dart-side
 * transport (default HttpClient, Dio's IOHttpClientAdapter, or Cronet, which is
 * also BoringSSL) can reach this host. Conscrypt tolerates the renegotiation,
 * and `HttpsURLConnection` is part of the OS, so it adds no dependency and
 * cannot hit the `org.chromium.net` namespace collision that made cronet_http
 * unbuildable under AGP 9.
 *
 * ## Security posture — this is NOT a trust-all bypass
 *
 * The server certificate is accepted only when its SHA-256 fingerprint equals
 * the pin passed from Dart ([Env.sapCertSha256]) — the same value and the same
 * base64-SHA-256-of-DER comparison as `DioFactory._applyTls`, and the same
 * fail-closed behaviour. Any other certificate is rejected. Hostname
 * verification is bypassed only because the certificate is a valid CA-issued
 * wildcard for `*.isigroup.com.kh` while the app dials a raw IP that is
 * legitimately absent from the SAN list; the pin, not the hostname, authenticates
 * the server here.
 */
object SapNativeHttpClient {

    private const val TAG = "SapNativeHttp"

    data class Result(
        val statusCode: Int?,
        val body: String?,
        val headers: Map<String, String>,
        val error: String?,
    )

    fun send(
        method: String,
        urlString: String,
        headers: Map<String, String>,
        body: String?,
        pinBase64Sha256: String,
        timeoutMs: Int,
    ): Result {
        var connection: HttpsURLConnection? = null
        return try {
            val url = URL(urlString)
            // This client exists to carry TLS + certificate pinning. A non-https
            // URL means the pin is meaningless and `openConnection()` returns a
            // plain HttpURLConnection that cannot be cast below — so reject it
            // with a legible message instead of a ClassCastException. A cleartext
            // URL reaching here indicates a stale generated env or a misconfig.
            if (!url.protocol.equals("https", ignoreCase = true)) {
                return Result(
                    null, null, emptyMap(),
                    "SapNativeHttpClient requires https; got '${url.protocol}'. " +
                        "The SAP transport is TLS-pinned — a cleartext URL is a misconfiguration."
                )
            }

            val sslContext = SSLContext.getInstance("TLS").apply {
                init(null, arrayOf(PinnedTrustManager(pinBase64Sha256)), null)
            }

            connection = (url.openConnection() as HttpsURLConnection).apply {
                sslSocketFactory = sslContext.socketFactory
                // Authenticated by pin, not by name — see the class doc.
                setHostnameVerifier { _, _ -> true }
                requestMethod = method
                connectTimeout = timeoutMs
                readTimeout = timeoutMs
                for ((key, value) in headers) setRequestProperty(key, value)
                // Content-Length is managed by the connection; passing the
                // caller's copy through can conflict with chunked encoding.
                if (!body.isNullOrEmpty() && method != "GET" && method != "HEAD") {
                    doOutput = true
                }
            }

            if (connection.doOutput && !body.isNullOrEmpty()) {
                connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            }

            val status = connection.responseCode
            // Non-2xx bodies (SAP puts "no rows" vs "bad conId" in the body)
            // arrive on the error stream, not the input stream.
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val text = stream?.bufferedReader()?.use(BufferedReader::readText)

            val responseHeaders = HashMap<String, String>()
            connection.headerFields.forEach { (key, values) ->
                if (key != null && values.isNotEmpty()) {
                    responseHeaders[key] = values.joinToString(",")
                }
            }

            Log.i(TAG, "$method $urlString -> $status")
            Result(status, text, responseHeaders, null)
        } catch (t: Throwable) {
            // The class name is the diagnosis: SSLHandshakeException naming
            // renegotiation would mean even Conscrypt refuses it; a
            // CertificateException means the pin did not match.
            Log.w(TAG, "$method $urlString failed: ${t.javaClass.simpleName}: ${t.message}")
            Result(null, null, emptyMap(), "${t.javaClass.name}: ${t.message}")
        } finally {
            connection?.disconnect()
        }
    }

    /**
     * Accepts exactly the certificate whose SHA-256 fingerprint equals the pin.
     * Everything else is rejected — this is the fail-closed policy the Dart
     * client uses, not a "trust all" shim.
     */
    private class PinnedTrustManager(private val pinBase64: String) : X509TrustManager {

        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            throw UnsupportedOperationException("client authentication is not used")
        }

        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            val leaf = chain?.firstOrNull()
                ?: throw java.security.cert.CertificateException("no certificate presented")

            val digest = MessageDigest.getInstance("SHA-256").digest(leaf.encoded)
            val presented = Base64.encodeToString(digest, Base64.NO_WRAP)

            if (presented != pinBase64) {
                throw java.security.cert.CertificateException(
                    "certificate pin mismatch; presented=$presented"
                )
            }
        }

        override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
    }
}
