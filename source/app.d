import vibe.d;
import std.file;
import std.datetime;
import std.container;
import std.conv;

struct PayInfo { int stuff; }; //Placehodler
MongoClient mongo;
PayInfo[string] ridMapping; //Maps request id to Payment information

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
	router.get("/numjobs", &numJobs);
	router.get("/job", &getJob);
	router.post("/solve", &solveCaptcha);
	router.post("/state", &setState);
	router.get("/result/:rid", &getResult);
	router.get("*", serveStaticFiles("public/"));

	//Start server
	auto settings = new HTTPServerSettings;
	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

/**
 * Renders a bootstrap thing.
 * Might just remove this later?
 */
void index(HTTPServerRequest req, HTTPServerResponse res) {
	res.redirect("https://github.com/revan/captcha4charity",300);
	// res.render!("index.dt",req);
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
	string Date = BsonDate.fromStdTime(Clock.currStdTime() + tim*10000000).toString();

	MongoCollection jobs = mongo.getDatabase("captcha4charity")["jobs"];
	jobs.insert(Bson(["img":Bson(img), "date":Bson(Date)]));
	auto cursor = jobs.find(Bson(["img":Bson(img), "date":Bson(Date)])).front;
	res.writeBody(cursor["_id"].toString.chompPrefix("\"").chop());
}

/**
 * Slams the worker who completed the last captcha for a given customer.
 * Customer provides CC info to identify self.
 */
void slamWorker(HTTPServerRequest req, HTTPServerResponse res) {
	enforceHTTP("rid" in req.form, HTTPStatus.badRequest,
				"Missing request id.");
	enforceHTTP("success" in req.form, HTTPStatus.badRequest,
				"Missing sucess status.");

	if(req.form["success"] == "1") {
		donateMonies(req.form["rid"]);
		//Give worker points
	} else {
		//Once we implement a scoring system, this section will punish the worker.
	}
	//Remove completed job.

	//Next time worker logs, tell them they've been slammed.
}

/**
 * Returns the number of workers currently active.
 */
void numWorkers(HTTPServerRequest req, HTTPServerResponse res) {

}

/**
 * Returns the number of jobs not yet accepted.
 */
void numJobs(HTTPServerRequest req, HTTPServerResponse res) {
	res.writeBody(to!string(mongo.getDatabase("captcha4charity")["jobs"].count(Bson())));
}

/**
 * Get a job.
 */
void getJob(HTTPServerRequest req, HTTPServerResponse res) {
	// res.writeBody(to!string(
	mongo.getDatabase("captcha4charity")["jobs"].findOne(Bson()).toJson().toString();
}

/**
 * Called on POST after worker has solved a captcha.
 */
void solveCaptcha(HTTPServerRequest req, HTTPServerResponse res) {
	enforceHTTP("rid" in req.form, HTTPStatus.badRequest,
				"Missing request id.");
	enforceHTTP("soln" in req.form, HTTPStatus.badRequest,
				"Missing solution.");

	MongoCollection jobs = mongo.getDatabase("captcha4charity")["completed"];
	jobs.insert(Bson(["_id":Bson(req.form["rid"]), "soln":Bson(req.form["soln"])]));
}

void getResult(HTTPServerRequest req, HTTPServerResponse res) {
	auto rid = req.params["rid"];

	MongoCollection jobs = mongo.getDatabase("captcha4charity")["completed"];
	auto cursor = jobs.find(Bson(["_id":Bson(rid)])).front;
	res.writeBody(cursor["soln"].toString.chompPrefix("\"").chop());

}

/**
 * Sets a worker to idle or ready state.
 */
void setState(HTTPServerRequest req, HTTPServerResponse res) {
	enforceHTTP("state" in req.form, HTTPStatus.badRequest, "Missing state.");
	//Receive state, move worker to appropriate queue.
}

void donateMonies(string rid) {
	//TODO: FirstGiving API, once we get the key.
	//Also fetch payment info by relation to rid.

}
