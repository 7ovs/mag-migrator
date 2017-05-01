require "colors"
fs = require "fs"
_ = require "lodash"
path = require "path"
moment = require "moment"
access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access.json"), "utf-8"))

oldMag = require("./mag-api")(access.old)
newMag = require("./mag-api")(access.new)

Promise = require("bluebird")

Promise.all([
    oldMag.getAttributes()
    newMag.getAttributes()
  ])
.then (result) ->
  list = result[1].map (attr) -> attr.attribute_code
  migrAttrs = _.filter result[0], (attr) -> not (attr.attribute_code in list)
  #console.log migrAttrs.map (a) -> a.attribute_code
  N = migrAttrs.length
  counter = 0
  T1 = moment()
  Promise.mapSeries migrAttrs, (attr) -> 
    console.log "\n---------------------------------".cyan
    console.log JSON.stringify(newMag.normalizeAttribute(attr), null, '  ').grey
    console.log "\n [#{++counter} of #{N}].", "CREATE ATTRIBUTE".green, "#{attr.attribute_code} [#{attr.options.length} options]...\n"
    t1 = moment()
    return newMag.createAttribute(attr).then (result) ->
      t2 = moment()
      t = moment.duration(t2.diff(t1)).get('milliseconds')
      console.log JSON.stringify(result, null, '  ')
      console.log " - ", "OK".green, " [#{t}ms]"
      return result
  .then (result) ->
    console.log "\n\n\n\n================================\n\n "
    console.log JSON.stringify(result, null, '  ').grey
    T2 = moment()
    T = moment.duration(T2.diff(T1)).get('seconds')
    console.log " +++ OK +++".green, "(create #{counter} elements during #{T} seconds)\n"
  .catch (e) ->
    console.log "\n\n\n\n$#%$#%$#%$#%$#%$#%$#%$#%$#%$\n\n"
    console.log e
