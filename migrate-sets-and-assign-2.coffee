require "colors"
fs = require "fs"
_ = require "lodash"
path = require "path"
assert = require "assert"

Promise = require("bluebird")

access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access.json"), "utf-8"))
access2 = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access2.json"), "utf-8"))

access2 = _.mapValues access2, (cfg, key) -> 
  cfg.ssh.privateKey = fs.readFileSync(cfg.ssh.privateKey)
  return cfg

oldMag = require("./mag-api")(access.old)
newMag = require("./mag-api")(access.new, false)

{
  getGroupsForAttributeSet
  getGroupsAndSetsForAttribute
  getGroupsAndSetsForAttributesList
  getGroupsForAttributeSetsList
} = require "./tunnel-mysql"

__getNewAttrIdByOldId = {}
__getNewAttrSetIdByOldId = {}

__AttrSetNameTransformation = {}
__AttrSetGroupNameTransformation = {}

main = () ->
  try 
    oldAttrs = await oldMag.getAttributes()
    console.log "getAttributes old - OK".green, oldAttrs.length, "items"
    
    newAttrs = await newMag.getAttributes()
    console.log "getAttributes new - OK".green, newAttrs.length, "items"

    oldAttrSets = await oldMag.getAttributeSets()
    console.log "getAttributeSets old - OK".green, oldAttrSets.length, "items"
    
    newAttrSets = await newMag.getAttributeSets()
    console.log "getAttributeSets new - OK".green, newAttrSets.length, "items"

    console.log newAttrSets
    defaultAttributeSet = _.find newAttrSets, attribute_set_name: "Default"
    defaultAttributes = await newMag.getAttributesForSet(defaultAttributeSet.attribute_set_id)
    defaultAttributes = defaultAttributes.map (attr) -> attr.attribute_code

    console.log "default attribute list:".grey
    console.log JSON.stringify(defaultAttributes).grey

    for newAttr in newAttrs
      if newAttr.attribute_code in defaultAttributes
        console.log oldAttr.attribute_code.cyan, "is default attribute, lets skip it..."
        continue
      oldAttr = _.find(oldAttrs, attribute_code: newAttr.attribute_code)

      assert(oldAttr)

      __getNewAttrIdByOldId[oldAttr.attribute_id] = newAttr.attribute_id


      console.log "find", oldAttr.attribute_code.yellow, "#{oldAttr.attribute_id} => #{newAttr.attribute_id}"

      setList = await getGroupsAndSetsForAttribute(oldAttr.attribute_id, access2.old)

      console.log "getGroupsAndSetsForAttribute[#{oldAttr.attribute_id}]", setList.length, "items"

      for setInfo in setList
        oldAttrSet = _.find oldAttrSets, attribute_set_id: setInfo.attribute_set_id
        assert(oldAttrSet)
        newAttrSet = _.find newAttrSets, attribute_set_name: oldAttrSet.attribute_set_name
        unless newAttrSet
          console.log "attribute set #{oldAttrSet.attribute_set_name.cyan} not found, creating new...".yellow
          newAttrSet = _.clone(oldAttrSet)
          # if /^Migration_(.*)$/.test(newAttrSet.attribute_set_name)
          #   console.log 
          #   newAttrSet.attribute_set_name = RegExp.$1
          #   __AttrSetGroupNameTransformation[oldAttrSet.attribute_set_name] = newAttrSet.attribute_set_name
          newAttrSet = await newMag.createAttributeSet(newAttrSet)
          newAttrSets.push(newAttrSet)
          console.log "create new attribute set:".green
          console.log JSON.stringify(newAttrSet, null, "  ").grey
        else
          console.log "found #{oldAttrSet.attribute_set_name.yellow} [#{oldAttrSet.attribute_set_id}] => [#{newAttrSet.attribute_set_id}]"
        assert(newAttrSet)

        __getNewAttrSetIdByOldId[oldAttrSet.attribute_set_id] = newAttrSet.attribute_set_id

        attrsForSetNew = await newMag.getAttributesForSet(newAttrSet.attribute_set_id)
        attrExists = _.find attrsForSetNew, attribute_code: newAttr.attribute_code
        if attrExists == undefined
          groups = await getGroupsForAttributeSet(newAttrSet.attribute_set_id, access2.new)
          console.log "  get groups for attribute set #{newAttrSet.attribute_set_id} in new mag,", groups.length, "items"
          group = _.find(groups, attribute_group_name: setInfo.attribute_group_name)
          unless group
            console.log "target group #{setInfo.attribute_group_name} didn't find, let's create it...".yellow

            # name = setInfo.attribute_group_name
            # if /^Migration_(.*)$/.test(setInfo.attribute_group_name)
            #   name = RegExp.$1
            #   __AttrSetGroupNameTransformation[setInfo.attribute_group_name] = name

            group = await newMag.createAttributeSetGroup(setInfo.attribute_group_name, newAttrSet.attribute_set_id)
            console.log "create new group:".green
            console.log JSON.stringify(group, null, "  ").grey
          else
            console.log "found group", setInfo.attribute_group_name.yellow
          status = await newMag.assignAttributeToAttributeSet(newAttrSet.attribute_set_id, group.attribute_group_id, newAttr.attribute_code, setInfo.sort_order)
          console.log "assign attribute #{oldAttr.attribute_code.cyan} to #{newAttrSet.attribute_set_name.cyan} in group #{setInfo.attribute_group_code.cyan} with status #{status.cyan} - OK".green
        else
          console.log "attribute #{newAttr.attribute_code.cyan} alreay exists in set #{newAttrSet.attribute_set_name.cyan}".yellow
        console.log "\n--------------------------\n".magenta
    fs.writeFileSync("getNewAttrIdByOldId.json", JSON.stringify(__getNewAttrIdByOldId, null, '  '), "utf-8")
    fs.writeFileSync("getNewAttrSetIdByOldId.json", JSON.stringify(__getNewAttrSetIdByOldId, null, '  '), "utf-8")
  catch e
    console.error ":> EXCEPTION:".red, e


main()