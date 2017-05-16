require "colors"
fs = require "fs"
_ = require "lodash"
path = require "path"

Promise = require("bluebird")

access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access.json"), "utf-8"))
access2 = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access2.json"), "utf-8"))

access2 = _.mapValues access2, (cfg, key) -> 
  cfg.ssh.privateKey = fs.readFileSync(cfg.ssh.privateKey)
  return cfg

oldMag = require("./mag-api")(access.old)
newMag = require("./mag-api")(access.new)

{
  getGroupsForAttributeSet
  getGroupsAndSetsForAttribute
  getGroupsAndSetsForAttributesList
  getGroupsForAttributeSetsList
} = require "./tunnel-mysql"

Promise.all [oldMag.getAttribute(), newMag.getAttribute()]
.then (result) ->
  Promise.mapSeries result[0], (oldAttr) ->
    getGroupsAndSetsForAttribute(oldAttr.attribute_set_id, access2.old).then (items) ->
      items.forEach (item) ->
        getGroupsForAttributeSet(item.attribute_set_id)













