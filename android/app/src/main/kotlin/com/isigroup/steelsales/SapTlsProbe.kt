package com.isigroup.steelsales

import android.util.Log
import java.io.BufferedReader
import java.net.URL
import java.security.MessageDigest
import java.security.cert.X509Certificate
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.X509TrustManager
import android.util.Base64

/**
 * DIAGNOSTIC — determines whether Android's platform TLS stack (Conscrypt)
 * tolerates the server-initiated TLS renegotiation that Dart's BoringSSL
 * refuses with `NO_RENEGOTIATION`.
 *
 * Uses `HttpsURLConnection` deliberately: it is part of the OS, so unlike
 * Cronet it adds no dependency and cannot collide with AGP 9's unique-namespace
 * rule (`org.chromium.net` is declared by two Cronet artifacts, which fails the
 * manifest merge outright).
 *
 * Certificate handling mirrors `DioFactory._applyTls` exactly: the server's
 * certificate is accepted only when its SHA-256 fingerprint matches the pin
 * passed in from Dart. Hostname verification is bypassed **only** because the
 * certificate is a valid CA-issued wildcard for `*.isigroup.com.kh` while the
 * app connects by raw IP — the pin, not the hostname, is what authenticates the
 * server here.
 *
 * Sends whatever body Dart supplies. The probe path sends `{}`, never
 * credentials.
 */
object SapTlsProbe {

    private const val TAG = "SapTlsProbe"

    data class Result(val statusCode: Int?, val body: String?, val error: String?)

    fun post(
        urlString: String,
        body: String,
        pinBase64Sha256: String,
        timeoutMs: Int = 20_000,
    ): Result {
        var connection: HttpsURLConnection? = null
        return try {
            val trustManager = PinnedTrustManager(pinBase64Sha256)
            val sslContext = SSLContext.getInstance("TLS").apply {
                init(null, arrayOf(trustManager), null)
            }

            connection = (URL(urlString).openConnection() as HttpsURLConnection).apply {
                sslSocketFactory = sslContext.socketFactory
                // The certificate is authenticated by pin, not by name; the app
                // dials an IP that is legitimately absent from the SAN list.
                setHostnameVerifier { _, _ -> true }
                requestMethod = "POST"
                connectTimeout = timeoutMs
                readTimeout = timeoutMs
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "*/*")
            }

            connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }

            val status = connection.responseCode
            // A 4xx/5xx body arrives on the error stream, not the input stream.
            val stream = if (status in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }
            val text = stream?.bufferedReader()?.use(BufferedReader::readText)

            Log.i(TAG, "platform TLS succeeded: HTTP $status")
            Result(statusCode = status, body = text, error = null)
        } catch (t: Throwable) {
            // The exception class is the diagnosis: an SSLHandshakeException
            // mentioning renegotiation means Conscrypt refuses it too, and no
            // client-side transport on Android can reach this server.
            Log.w(TAG, "platform TLS failed: ${t.javaClass.simpleName}: ${t.message}")
            Result(
                statusCode = null,
                body = null,
                error = "${t.javaClass.name}: ${t.message}",
            )
        } finally {
            connection?.disconnect()
        }
    }

    /**
     * Accepts exactly one certificate: the one whose SHA-256 fingerprint equals
     * the configured pin. Everything else is rejected, so this is not a
     * "trust all" shim — it is the same fail-closed policy the Dart client uses.
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
