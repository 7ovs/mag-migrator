require "colors"
path = require "path"
fs = require "fs"
_ = require "lodash"

Promise = require("bluebird")

access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access.json"), "utf-8"))

# data = fs.readFileSync("default-attribute-sets.json", "utf-8")
# data = JSON.parse(data)
# items = data.items
# list = items.map (item) -> item.attribute_set_name
# fs.writeFileSync("default-attribute-set-list.json", JSON.stringify(list, null, "  "), "utf-8")

list = JSON.parse(fs.readFileSync("default-attribute-set-list.json", "utf-8"))

{getAttributeSets, deleteAttributeSet} = require("./mag-api")(access.new)

getAttributeSets().then (attrSets) ->

  items = _(attrSets)
    .map (attrSet) -> {name: attrSet.attribute_set_name, id: attrSet.attribute_set_id}
    .filter (attrSet) -> not (attrSet.name in list)

  #console.log JSON.stringify(items, null, '  ')

  Promise.mapSeries items, (item) ->
    console.log "delete".red, item.name, " [#{item.id}] ..."
    deleteAttributeSet(item.id)
.catch (e) ->
  console.log e

