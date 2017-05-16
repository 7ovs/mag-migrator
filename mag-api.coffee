require('colors')
_ = require('lodash')
require('uasync')(_)
fs = require 'fs'
path = require 'path'

filters = JSON.parse(fs.readFileSync(path.resolve(__dirname, "cfg/filters.json"), "utf-8"))

MagRequestFactory = require("./mag-request-factory")

isAttributeExistsFactory = (access, enableCache = true) ->

  enableCache = enableCache

  cache = false

  options = 
    qs:
      searchCriteria:
        currentPage: 1
        page_size: 300

  magRequest = MagRequestFactory('GET', '/V1/products/attributes', access)
    
  return (targetName) ->
    return new Promise (resolve, reject) ->

      complete = (items) ->
        result = _.find items, (obj) -> 
          obj.attribute_code.toLowerCase() == targetName.toLowerCase()
        resolve(result)

      if enableCache and cache 
        complete(cache)
      else
        magRequest options, (error, response, body) ->
          if error
            reject(error)
          else if body
            cache = body.items if enableCache
            complete(body.items)

getAttributesFactory = (access, enableCache = true) ->

  enableCache = enableCache

  cache = false

  options = 
    qs:
      searchCriteria:
        currentPage: 1
        page_size: 300

  magRequest = MagRequestFactory('GET', '/V1/products/attributes', access)
    
  return (targetName) ->
    return new Promise (resolve, reject) ->

      complete = (items) ->
        

      if enableCache and cache 
        resolve(cache)
      else
        magRequest options, (error, response, body) ->
          if error
            reject(error)
          else if body
            cache = body.items if enableCache
            resolve(body.items)

getAttributeSetsFactory = (access, enableCache = true)->

  cache = false

  options = 
    qs:
      searchCriteria:
        currentPage: 1
        page_size: 300

  magRequest = MagRequestFactory('GET', 'V1/products/attribute-sets/sets/list', access)
  
  return (targetName) ->
    return new Promise (resolve, reject) ->

      if enableCache and cache 
        resolve(cache)
      else
        magRequest options, (error, response, body) ->
          if error
            reject(error)
          else if body
            cache = body.items if enableCache
            resolve(body.items)

getProductsFactory = (access)->

  magRequest = MagRequestFactory('GET', 'V1/products', access)
  
  return (page, count) ->

    options = 
      qs:
        searchCriteria:
          currentPage: page
          page_size: count

    return new Promise (resolve, reject) ->

      magRequest options, (error, response, body) ->
        if error
          reject(error)
        else if body
          resolve(body.items)

getProductFactory = (access)->
  
  return (sku) ->

    sku = encodeURIComponent(sku)

    magRequest = MagRequestFactory('GET', "V1/products/#{sku}", access)

    return new Promise (resolve, reject) ->

      magRequest {}, (error, response, body) ->
        if error
          reject(error)
        else if body
          resolve(body)

isAttributeSetExistsFactory = (access, enableCache = true)->

  cache = false

  options = 
    qs:
      searchCriteria:
        currentPage: 1
        page_size: 300

  magRequest = MagRequestFactory('GET', 'V1/products/attribute-sets/sets/list', access)
  
  return (targetName) ->
    return new Promise (resolve, reject) ->

      complete = (items) ->
        result = _.find items, (obj) -> 
          obj.attribute_set_name.toLowerCase() == targetName.toLowerCase()
        resolve(result)

      if enableCache and cache 
        complete(cache)
      else
        magRequest options, (error, response, body) ->
          if error
            reject(error)
          else if body
            cache = body.items if enableCache
            complete(body.items)

normalizeAttribute = (attribute) ->
  filter = filters.attribute
  result = {}
  filter.forEach (f) -> if attribute[f] then result[f] = attribute[f]
  result.options = result.options.map (opt) -> label: opt.label
  result.options = _.filter result.options, (opt) -> opt.label.trim() != ''
  return result

normalizeAttributeSet = (attributeSet) ->
  filter = filters.attributeSet
  result = {}
  filter.forEach (f) -> if attributeSet[f] then result[f] = attributeSet[f]
  return result

normalizeProduct = (prod) ->
  filter = filters.product
  result = _.cloneDeep(prod)
  delete result[f] for f in filter
  if _.isArray(result.media_gallery_entries)
    delete entry.id for entry in result.media_gallery_entries
    
  return result

createAttributeFactory = (access) -> 

  magRequest = MagRequestFactory('POST', '/V1/products/attributes', access)
  
  return (attribute) ->
    return new Promise (resolve, reject) -> 

      options = body: {attribute: normalizeAttribute(attribute)}

      magRequest options, (error, response, body) ->
        if not error and body
          if response.statusCode == 200
            resolve(body)
          else
            reject(body.message)  
        else
          reject(error)   

createProductFactory = (access) -> 

  magRequest = MagRequestFactory('POST', '/V1/products', access)
  
  return (product) ->
    return new Promise (resolve, reject) -> 

      options = body: {product: product}

      magRequest options, (error, response, body) ->
        if not error and body
          if response.statusCode == 200
            resolve(body)
          else
            console.log body
            reject(body.message)  
        else
          reject(error)  

createAttributeSetFactory = (access) -> 

  magRequest = MagRequestFactory('POST', 'V1/products/attribute-sets', access)
  
  return (attributeSet) ->
    return new Promise (resolve, reject) ->  

      options = body: {
        attributeSet: normalizeAttributeSet(attributeSet), 
        skeletonId: attributeSet.entity_type_id
      }

      magRequest options, (error, response, body) ->
        if not error and body
          if response.statusCode == 200
            resolve(body)
          else
            reject(body.message)  
        else
          reject(error)

createAttributeSetGroupFactory = (access) -> 

  magRequest = MagRequestFactory('POST', '/V1/products/attribute-sets/groups', access)
  
  return (groupName, attrSetId, sortOrder = 100) ->
    return new Promise (resolve, reject) ->  

      options = body: 
        "group": 
          "attribute_group_name": groupName
          "attribute_set_id": attrSetId
          "extension_attributes": 
            "attribute_group_code": _.kebabCase(groupName).toLowerCase()
            "sort_order": sortOrder

      magRequest options, (error, response, body) ->
        if not error and body
          if response.statusCode == 200
            resolve(body)
          else
            reject(body.message)  
        else
          reject(error)

assignAttributeToAttributeSetFactory = (access) -> 

  magRequest = MagRequestFactory('POST', '/V1/products/attribute-sets/attributes', access)
  
  return (attrSetId, attrGroupId, attrCode, sortOrder = 1) ->
    return new Promise (resolve, reject) ->  

      options = body: {
        "attributeSetId":   attrSetId,
        "attributeGroupId": attrGroupId,
        "attributeCode":    attrCode,
        "sortOrder":        sortOrder
      }

      magRequest options, (error, response, body) ->
        if not error and body
          if response.statusCode == 200
            resolve(body)
          else
            reject(body.message)  
        else
          reject(error)

deleteAttributeFactory = (access) -> 
  
  return (attributeId) ->

    attributeId = encodeURIComponent(attributeSetId)

    magRequest = MagRequestFactory('DELETE', "V1/products/attributes/#{attributeId}", access)
    
    return new Promise (resolve, reject) ->  

      magRequest {}, (error, response, body) ->
        if not error
          if response.statusCode == 200
            resolve(null)
          else
            reject(body.message)  
        else
          reject(error)    

deleteAttributeSetFactory = (access) -> 
  
  return (attributeSetId) ->

    attributeSetId = encodeURIComponent(attributeSetId)

    magRequest = MagRequestFactory('DELETE', "V1/products/attribute-sets/#{attributeSetId}", access)

    return new Promise (resolve, reject) ->  

      magRequest {}, (error, response, body) ->
        if not error
          if response.statusCode == 200
            resolve(null)
          else
            reject(body.message)  
        else
          reject(error)


getAttributesForSetFactory = (access, enableCache = true) -> 

  cache = {}
  
  return (attributeSetId) ->

    attributeSetId = encodeURIComponent(attributeSetId)

    magRequest = MagRequestFactory('GET', "/V1/products/attribute-sets/#{attributeSetId}/attributes", access)

    return new Promise (resolve, reject) ->  

      if enableCache and cache[attributeSetId]
        resolve(cache[attributeSetId])
      magRequest {}, (error, response, body) ->
        if error
          reject(error)
        else 
          if response.statusCode == 200
            cache[attributeSetId] = body if enableCache
            resolve(body)
          else 
            reject(body.message)

normalizeAttributeOption = (option) ->
  result = _.clone(option)
  delete result['value']
  return result

createAttributeOptionFactory = (access) -> 
  
  return (attributeCode, option) ->

    attributeCode = encodeURIComponent(attributeCode)
     
    magRequest = MagRequestFactory('POST', "/V1/products/attributes/#{attributeCode}/options", access)

    return new Promise (resolve, reject) -> 

      options = body: {option: normalizeAttributeOption(option)} 

      magRequest options, (error, response, body) ->
        if error
          reject(error)
        else 
          if response.statusCode == 200
            resolve(body)
          else 
            reject(body.message)


MagApiFactory = (access, enableCache = true) ->
  return {
    getAttributes: getAttributesFactory(access, enableCache)
    getAttributeSets: getAttributeSetsFactory(access, enableCache)
    isAttributeExists: isAttributeExistsFactory(access, enableCache)
    isAttributeSetExists: isAttributeSetExistsFactory(access, enableCache)
    getAttributesForSet: getAttributesForSetFactory(access, enableCache)
    createAttribute: createAttributeFactory(access)
    createAttributeSet: createAttributeSetFactory(access)
    deleteAttribute: deleteAttributeFactory(access)
    deleteAttributeSet: deleteAttributeSetFactory(access)
    normalizeAttribute: normalizeAttribute
    normalizeAttributeSet: normalizeAttributeSet
    createAttributeSetGroup: createAttributeSetGroupFactory(access)
    assignAttributeToAttributeSet: assignAttributeToAttributeSetFactory(access)
    getProducts: getProductsFactory(access)
    normalizeProduct: normalizeProduct
    normalizeAttributeOption: normalizeAttributeOption
    createAttributeOption: createAttributeOptionFactory(access)
    createProduct: createProductFactory(access)
    getProduct: getProductFactory(access)
  }

module.exports = MagApiFactory