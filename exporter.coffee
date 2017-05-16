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
Promise.all [oldMag.getAttributeSets(), newMag.getAttributeSets()]
.then (result) ->

  defaultAttrOld = _(result[0]).remove(attribute_set_name: "Default").head()
  defaultAttrNew = _(result[1]).remove(attribute_set_name: "Default").head()

  console.log defaultAttrOld
  console.log defaultAttrNew

  getGroupsForAttributeSet(defaultAttrOld.attribute_set_id, access2.old).then (defaultOldGroupInfo) ->
    getGroupsForAttributeSet(defaultAttrNew.attribute_set_id, access2.new).then (defaultNewGroupInfo) ->

      console.log JSON.stringify(defaultOldGroupInfo, null, "  ").grey    
      console.log JSON.stringify(defaultNewGroupInfo, null, "  ").magenta

      Promise.mapSeries result[0], (oldAttr) -> 
        console.log "getGroupsForAttributeSet".green, oldAttr.attribute_set_name, "[#{oldAttr.attribute_set_id}]"
        newAttr = _.find(result[1], attribute_set_name: oldAttr.attribute_set_name)
        return new Promise (resolve) ->
          getGroupsForAttributeSet(oldAttr.attribute_set_id, access2.old).then (oldGroupInfo) ->
            getGroupsForAttributeSet(newAttr.attribute_set_id, access2.new).then (newGroupInfo) ->
              console.log "\n=====================================".cyan
              console.log oldAttr.attribute_set_name.toUpperCase().red, oldAttr.attribute_set_id, newAttr.attribute_set_id
              console.log JSON.stringify(_.differenceBy(oldGroupInfo, defaultOldGroupInfo, 'attribute_group_code'), null, "  ").grey    
              console.log JSON.stringify(_.differenceBy(newGroupInfo, defaultNewGroupInfo, 'attribute_group_code'), null, "  ").magenta
              
              
              resolve(oldGroupInfo)
  .then (allResults) ->
    console.log JSON.stringify(allResults, null, "  ")
  .catch (e) ->
    console.log e 





# .then (result) ->
#   list = result[1].map (attrSet) -> attrSet.attribute_set_name
#   migrAttrSets = _.filter result[0], (attrSet) -> not (attrSet.attribute_set_name in list)
#   # LL = migrAttrSets.map (attrSet) -> attrSet.attribute_set_name
#   # console.log JSON.stringify(LL, null, '  ')
#   N = migrAttrSets.length
#   counter = 0
#   T1 = moment()
#   Promise.mapSeries migrAttrSets, (oldAttrSet) ->
#     console.log "\n---------------------------------".cyan
#     console.log JSON.stringify(newMag.normalizeAttributeSet(oldAttrSet), null, '  ').grey
#     console.log "\n [#{++counter} of #{N}].", "CREATE ATTRIBUTE SET".green, "#{oldAttrSet.attribute_set_name}...\n"
#     t1 = moment()
#     return newMag.createAttributeSet(oldAttrSet).then (newAttrSet) ->

#       Promise.all([
#           getGroupsForAttributeSet(oldAttrSet.attribute_set_id, access2.old)
#           getGroupsForAttributeSet(newAttrSet.attribute_set_id, access2.new)
#         ])
#       .then (results) ->


#       t2 = moment()
#       t = moment.duration(t2.diff(t1)).get('milliseconds')
#       console.log JSON.stringify(result, null, '  ')
#       console.log " - ", "OK".green, " [#{t}ms]"
#       return result
#   .then (result) ->
#     console.log "\n\n\n\n================================\n\n "
#     console.log JSON.stringify(result, null, '  ').grey
#     T2 = moment()
#     T = moment.duration(T2.diff(T1)).get('seconds')
#     console.log " +++ OK +++".green, "(create #{counter} elements during #{T} seconds)\n"
#   .catch (e) ->
#     console.log "\n\n\n\n$#%$#%$#%$#%$#%$#%$#%$#%$#%$\n\n"
#     console.log e
