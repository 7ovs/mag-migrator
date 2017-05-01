require "colors"
path = require "path"
fs = require "fs"
_ = require "lodash"

Promise = require("bluebird")

access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access.json"), "utf-8"))

# data = fs.readFileSync("default-attributes.json", "utf-8")
# data = JSON.parse(data)
# items = data.items
# list = items.map (item) -> item.attribute_code
# fs.writeFileSync("default-attribute-list.json", JSON.stringify(list, null, "  "), "utf-8")

list = JSON.parse(fs.readFileSync("default-attribute-list.json", "utf-8"))

{getAttributes, deleteAttribute} = require("./mag-api")(access.new)

getAttributes().then (attrs) ->

  items = _(attrs)
    .map (attr) -> {code: attr.attribute_code, id: attr.attribute_id}
    .filter (attr) -> not (attr.code in list)

  #console.log JSON.stringify(items, null, '  ')

  Promise.mapSeries items, (item) ->
    console.log "delete".red, item.code, " [#{item.id}] ..."
    deleteAttribute(item.id)
.catch (e) ->
  console.log e

