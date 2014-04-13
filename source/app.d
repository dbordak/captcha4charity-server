import vibe.d;
import std.file;
import std.datetime;
import std.container;

MongoClient mongo;

shared static this() {
	//Connect to MongoLab
	auto userpass = splitLines(chomp(readText("secretmongo")));
	mongo = connectMongoDB("mongodb://" ~ userpass[0] ~ ":" ~ userpass[1] ~
						   "@ds039737.mongolab.com:39737/captcha4charity");

	//Set up URL Routing
	auto router = new URLRouter;
	router.get("/", &index);
	router.post("/captcha", &newCaptcha);
	router.get("/workers", &numWorkers);
	router.post("/solve", &solveCaptcha);
	router.post("/state", &setState);
	router.get("*", serveStaticFiles("public/"));

	//Start server
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, router);

	//Echo server
	// listenTCP(8081, conn => conn.write(conn), "127.0.0.1");

	//Create Data Structures

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

/**
 * Renders a bootstrap thing.
 * Might just remove this later?
 */
void index(HTTPServerRequest req, HTTPServerResponse res) {
	res.render!("index.dt",req);
}

/**
 * Adds a new captcha to the queue.
 *
 * Customer provides URL to the captcha, CC info, and optionally the number of
 * workers it wants to complete the task and how long they have to complete it.
 */
void newCaptcha(HTTPServerRequest req, HTTPServerResponse res) {
	enforceHTTP("img_url" in req.form, HTTPStatus.badRequest,
				"Missing image URL.");
	enforceHTTP("payment" in req.form, HTTPStatus.badRequest,
				"Missing payment information.");
	// enforceHTTP("tim" in req.post, HTTPStatus.badRequest, "Missing timeout.");
	// enforceHTTP("num" in req.post, HTTPStatus.badRequest, "Missing num Workers.");

	int tim = 300;
	int num = 1;
	string img = req.form["img_url"];
	//do something with payment

	auto Date = Clock.currTime() + tim.seconds();
	auto jobs = mongo.getCollection("jobs");


	// Add captcha to Mongo

	// Assign rID number? Return Mongo ID?
}

/**
 * Slams the worker who completed the last captcha for a given customer.
 * Customer provides CC info to identify self.
 */
void slamWorker(HTTPServerRequest req, HTTPServerResponse res) {
	enforceHTTP("rid" in req.form, HTTPStatus.badRequest,
				"Missing request id.");

	//Remove completed job.

	//Next time worker logs, tell them they've been slammed.
}

/**
 * Returns the number of workers currently active.
 */
void numWorkers(HTTPServerRequest req, HTTPServerResponse res) {

}

/**
 * Called on POST after worker has solved a captcha.
 */
void solveCaptcha(HTTPServerRequest req, HTTPServerResponse res) {

	//Report back the result of the captcha

	//Wait a few minutes for blame before adding points and deducting monies.
}

/**
 * Sets a worker to idle or ready state.
 */
void setState(HTTPServerRequest req, HTTPServerResponse res) {
	enforceHTTP("state" in req.form, HTTPStatus.badRequest, "Missing state.");
	//Receive state, move worker to appropriate queue.
}
