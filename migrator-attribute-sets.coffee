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
    oldMag.getAttributeSets()
    newMag.getAttributeSets()
  ])
.then (result) ->
  list = result[1].map (attrSet) -> attrSet.attribute_set_name
  migrAttrSets = _.filter result[0], (attrSet) -> not (attrSet.attribute_set_name in list)
  # LL = migrAttrSets.map (attrSet) -> attrSet.attribute_set_name
  # console.log JSON.stringify(LL, null, '  ')
  N = migrAttrSets.length
  counter = 0
  T1 = moment()
  Promise.mapSeries migrAttrSets, (attrSet) -> 
    console.log "\n---------------------------------".cyan
    console.log JSON.stringify(newMag.normalizeAttributeSet(attrSet), null, '  ').grey
    console.log "\n [#{++counter} of #{N}].", "CREATE ATTRIBUTE SET".green, "#{attrSet.attribute_set_name}...\n"
    t1 = moment()
    return newMag.createAttributeSet(attrSet).then (result) ->
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
