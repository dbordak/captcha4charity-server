import vibe.d;

shared static this() {
	auto router = new URLRouter;
	router.get("/", &index);
	router.post("/captcha", &newCaptcha);
	router.get("*", serveStaticFiles("public/"));
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, router);
	listenTCP(8081, conn => conn.write(conn), "127.0.0.1");

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

void index(HTTPServerRequest req, HTTPServerResponse res) {
	res.render!("index.dt",req);
}

void newCaptcha(HTTPServerRequest req, HTTPServerResponse res) {
	enforceHTTP("img_url" in req.post, HTTPStatus.badRequest, "Missing image URL.");
	enforceHTTP("payment" in req.post, HTTPStatus.badRequest, "Missing payment information.");
	// enforceHTTP("tim" in req.post, HTTPStatus.badRequest, "Missing timeout.");
	// enforceHTTP("num" in req.post, HTTPStatus.badRequest, "Missing num Workers.");


}
