require("coffee-script/register")
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

defaultAttrList = JSON.parse(fs.readFileSync("default-attribute-list.json", "utf-8"))

{
  getGroupsForAttributeSet
  getGroupsAndSetsForAttribute
  getGroupsAndSetsForAttributesList
  getGroupsForAttributeSetsList
  getProductsCount
} = require "./tunnel-mysql"

IMAGE_DIR = '/Volumes/BufferHD/magento2/pub/media/catalog/product'

EXT_TO_MIME = 
  gif: "image/gif"
  jpeg: "image/jpeg"
  jpg: "image/jpeg"
  png: "image/png"
  tiff: "image/tiff"
  tif: "image/tiff"


getPages = (count, pageSize) ->
  pages = []
  while count
    if count > pageSize
      count = count - pageSize
      pages.push(pageSize)
    else
      pages.push(count)
      count = 0
  return pages

main = () ->
  attrOptO2N = JSON.parse(fs.readFileSync('attribute-option-old-to-new.json', 'utf-8'))

  nAttrs = await newMag.getAttributes()
  oAttrs = await oldMag.getAttributes()

  nAttrSets = await newMag.getAttributeSets()
  oAttrSets = await oldMag.getAttributeSets()

  nAttrsByCode = new Map()
  oAttrsByCode = new Map()

  nAttrsById = new Map()
  oAttrsById = new Map()

  nAttrSetByName = new Map()
  oAttrSetByName = new Map()


  nAttrs.forEach (attr) -> nAttrsByCode.set(attr.attribute_code, attr)
  oAttrs.forEach (attr) -> oAttrsByCode.set(attr.attribute_code, attr)

  nAttrs.forEach (attr) -> nAttrsByCode.set(attr.attribute_code, attr)
  oAttrs.forEach (attr) -> oAttrsByCode.set(attr.attribute_code, attr)

  nAttrSets.forEach (attrSet) -> nAttrSetByName.set(attrSet.attribute_set_name, attrSet)
  oAttrSets.forEach (attrSet) -> oAttrSetByName.set(attrSet.attribute_set_name, attrSet)

  attrIdO2N = {}
  nAttrIdByCode = {}
  oAttrIdByCode = {}

  for oAttr in oAttrs
    nAttr = nAttrsByCode.get(oAttr.attribute_code)
    assert(nAttr)
    attrIdO2N[oAttr.attribute_id] = nAttr.attribute_id
    nAttrIdByCode[oAttr.attribute_code] = nAttr.attribute_id
    nAttrIdByCode[oAttr.attribute_code] = oAttr.attribute_id

  attrSetIdO2N = {}
  for oAttrSet in oAttrSets
    nAttrSet = nAttrSetByName.get(oAttrSet.attribute_set_name)
    assert(nAttrSet)
    attrSetIdO2N[oAttrSet.attribute_set_id] = nAttrSet.attribute_set_id

  #console.log JSON.stringify(attrSetIdO2N, null, '  ').yellow

  try 
    total = 300 #await getProductsCount()
    pageSize = 100
    pages = getPages(total, pageSize)

    for count, page in pages
      products = await oldMag.getProducts(page+1, count)

      console.log "getProducts".blue,  products.length
      for product in products
        console.log product.sku.cyan
        product = await oldMag.getProduct(product.sku)

        newProduct = await newMag.getProduct(product.sku)
        if newProduct.sku
          console.log "PRODUCT #{newProduct.sku} already exists. Skiped"
          continue

        newProduct = newMag.normalizeProduct(product)

        newProduct.attribute_set_id = attrSetIdO2N[newProduct.attribute_set_id]
        newProduct.product_links = []

        if _.isArray(newProduct.media_gallery_entries)
          for entry in newProduct.media_gallery_entries
            #console.log entry
            imagePath = IMAGE_DIR + entry.file
            #console.log "imagePath", imagePath

            base64 = new Buffer(fs.readFileSync(imagePath)).toString('base64')
            #console.log 'base64.length', base64.length
            mediaType = EXT_TO_MIME[path.extname(imagePath).slice(1)]
            #console.log "mediaType", mediaType
            assert(mediaType)

            delete entry.id   if entry.id
            delete entry.file if entry.file
            
            entry.content = 
              base64_encoded_data: base64
              type: mediaType
              name: path.basename(imagePath)

        console.log "change attr_set #{product.name.magenta}[#{product.sku.magenta}] #{product.attribute_set_id} => #{newProduct.attribute_set_id}".green

        #console.log JSON.stringify(newProduct, null, '  ').grey

        for cust in newProduct.custom_attributes
          if attrOptO2N[cust.attribute_code]
            prev = cust.value
            next = attrOptO2N[cust.attribute_code][cust.value]

            #console.log cust.attribute_code.yellow
            nAttr = nAttrsByCode.get(cust.attribute_code)

            assert(nAttr)
            
            if next
              if nAttr.frontend_input == "multiselect"
                cust.value = [next]
                console.log "  change multiselect option #{cust.attribute_code} #{prev} => [#{next}]".magenta
              else
                cust.value = next
                console.log "  change option #{cust.attribute_code} #{prev} => #{next}".cyan
              
            else
              console.log "  ⚠️  skip change option #{cust.attribute_code} = #{prev}".cyan

        #console.log JSON.stringify(newProduct, null, '  ').grey
        createdProduct = await newMag.createProduct(newProduct)
        console.log createdProduct.sku.green, "- OK".green
        #console.log JSON.stringify(createdProduct, null, '  ').green



  catch e
    console.error ":> EXCEPTION:".red, e






















test = ->
  prods = await oldMag.getProducts(1, 10)
  prods = _.map prods, (prod) -> newMag.normalizeProduct(prod)
  console.log JSON.stringify(prods, null, '  ')

test2 = ->
  attrs = await newMag.getAttributes()
  frontend_input = {}
  attrs.forEach (attr) -> 
    if frontend_input[attr.frontend_input] == undefined
      frontend_input[attr.frontend_input] = 1
    else
      frontend_input[attr.frontend_input]++

  selAttrs = _.filter attrs, (attr) -> attr.frontend_input == 'select' or attr.frontend_input == 'multiselect'

  for attr in selAttrs
    attr.options

  console.log JSON.stringify(selAttrs, null, '  ')
  console.log JSON.stringify(frontend_input, null, '  ')

test3 = ->
  nAttrs = await newMag.getAttributes()
  oAttrs = await oldMag.getAttributes()

  nAttrsByCode = new Map()
  oAttrsByCode = new Map()

  nAttrsById = new Map()
  oAttrsById = new Map()


  nAttrs.forEach (attr) -> nAttrsByCode.set(attr.attribute_code, attr)
  oAttrs.forEach (attr) -> oAttrsByCode.set(attr.attribute_code, attr)

  nAttrs.forEach (attr) -> nAttrsById.set(attr.attribute_id, attr)
  oAttrs.forEach (attr) -> oAttrsById.set(attr.attribute_id, attr)

  attrIdO2N = {}
  nAttrIdByCode = {}
  oAttrIdByCode = {}
  for oAttr in oAttrs
    nAttr = nAttrsByCode.get(oAttr.attribute_code)
    assert(nAttr)
    attrIdO2N[oAttr.attribute_id] = nAttr.attribute_id
    nAttrIdByCode[oAttr.attribute_code] = nAttr.attribute_id
    nAttrIdByCode[oAttr.attribute_code] = oAttr.attribute_id

  # console.log JSON.stringify(attrIdO2N, null, '  ').grey
  # console.log JSON.stringify(nAttrIdByCode, null, '  ').yellow
  # console.log JSON.stringify(nAttrIdByCode, null, '  ').blue

  selAttrs = _.filter oAttrs, (oAttr) -> 
    oAttr.options.length > 0
    #oAttr.frontend_input == 'select' or oAttr.frontend_input == 'multiselect'


  #console.log JSON.stringify(selAttrs, null, '  ').grey

  attrOptO2N = {}
  for oAttr in selAttrs
    if oAttr in defaultAttrList
      continue
    nAttr = nAttrsByCode.get(oAttr.attribute_code)
    if oAttr.options.length > nAttr.options.length

    # console.log oAttr.attribute_code, nAttr.attribute_code
    # console.log oAttr.attribute_id, nAttr.attribute_id
      console.log "Attribute options mismatch".red, oAttr.attribute_code.cyan, oAttr.options.length, nAttr.options.length
      continue
    # console.log nAttr
    # console.log oAttr
    else 
      console.log "Attribute options match".green, oAttr.attribute_code.cyan, oAttr.options.length, nAttr.options.length


    optValO2N = {}
    nOptByLabel = new Map()
    for opt in nAttr.options
      nOptByLabel.set(opt.label, opt) 
    # console.log nOptByLabel
    # console.log oAttr.options.length
    
    for oOpt in oAttr.options
      continue if oOpt.label.trim() == ''
      try
        nOpt = nOptByLabel.get(oOpt.label)
        assert(nOpt)
        optValO2N[oOpt.value] = nOpt.value
        #console.log "  ", oAttr.attribute_code.cyan, oOpt.label.yellow, "#{oOpt.value} => #{nOpt.value}"
      catch e
        console.log e
        console.log oOpt
        console.log nOptByLabel.get(oOpt.label)
    attrOptO2N[oAttr.attribute_code] = optValO2N


  console.log JSON.stringify(attrOptO2N, null, '  ').green
  fs.writeFileSync('attribute-option-old-to-new.json',JSON.stringify(attrOptO2N, null, '  '), "utf-8")
    


checkAndCompleteAttributeOptions = () ->
  nAttrs = await newMag.getAttributes()
  oAttrs = await oldMag.getAttributes()

  nAttrsByCode = new Map()
  oAttrsByCode = new Map()

  nAttrs.forEach (attr) -> nAttrsByCode.set(attr.attribute_code, attr)
  oAttrs.forEach (attr) -> oAttrsByCode.set(attr.attribute_code, attr)

  for oAttr in oAttrs
    nAttr = nAttrsByCode.get(oAttr.attribute_code)
    assert(nAttr)
    if oAttr.options.length > nAttr.options.length
      console.log "Attribute options mismatch".red, oAttr.attribute_code.cyan, oAttr.options.length, nAttr.options.length

      for oOpt in oAttr.options
        continue if oOpt.label.trim == ''
        unless _.find(nAttr.options, label: oOpt.label)
          status = await newMag.createAttributeOption(nAttr.attribute_code, oOpt)
          assert(status)
          console.log "create in".green, nAttr.attribute_code.yellow, oOpt.label



#checkAndCompleteAttributeOptions().then ->
main()