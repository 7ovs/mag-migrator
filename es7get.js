require("coffee-script/register");
require("colors");

var fs = require("fs");
var _ = require("lodash");
var path = require("path");
var Promise = require("bluebird");

var access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access.json"), "utf-8"));
var access2 = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access2.json"), "utf-8"));

var access2 = _.mapValues(access2, (cfg, key) => {
  cfg.ssh.privateKey = fs.readFileSync(cfg.ssh.privateKey);
  return cfg;
});

var oldMag = require("./mag-api")(access.old);
var newMag = require("./mag-api")(access.new);

var GroupAPI = require("./tunnel-mysql");

var readFile = Promise.promisify(fs.readFile);

async function asyncFunction() {
  let data = JSON.parse(await readFile(path.resolve(__dirname, "etc/access.json"), "utf-8"));
  console.log(data)
}

asyncFunction().then( (result) => {console.log("Finsh", result)});