const http = require("http");
const https = require("https");

const TARGET_HOST = "192.168.100.112";
const TARGET_PORT = 4451;
const LISTEN_PORT = 8080;

const agent = new https.Agent({ rejectUnauthorized: false, keepAlive: false });

http.createServer((req, res) => {
  const started = Date.now();
  const headers = { ...req.headers };
  headers.host = TARGET_HOST + ":" + TARGET_PORT;

  const proxyReq = https.request(
    { host: TARGET_HOST, port: TARGET_PORT, path: req.url, method: req.method, headers, agent },
    (proxyRes) => {
      console.log("  " + proxyRes.statusCode + " " + req.method + " " + req.url + " " + (Date.now() - started) + "ms");
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res);
    }
  );

  proxyReq.on("error", (err) => {
    console.error("  ERR " + req.method + " " + req.url + " - " + err.message);
    res.writeHead(502, { "content-type": "application/json" });
    res.end(JSON.stringify({ proxyError: err.message }));
  });

  req.pipe(proxyReq);
}).listen(LISTEN_PORT, "0.0.0.0", () => {
  console.log("SAP dev proxy on http://0.0.0.0:" + LISTEN_PORT);
  console.log("  -> https://" + TARGET_HOST + ":" + TARGET_PORT);
  console.log("  emulator uses: http://10.0.2.2:" + LISTEN_PORT);
});
