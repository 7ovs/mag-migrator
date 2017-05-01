require('colors')
_ = require('lodash')
require('uasync')(_)
fs = require 'fs'
path = require 'path'

filters = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/filters.json"), "utf-8"))

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

deleteAttributeFactory = (access) -> 
  
  return (attributeId) ->

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

MagApiFactory = (access, enableCache = true) ->
  return {
    getAttributes: getAttributesFactory(access, enableCache)
    getAttributeSets: getAttributeSetsFactory(access, enableCache)
    isAttributeExists: isAttributeExistsFactory(access, enableCache)
    isAttributeSetExists: isAttributeSetExistsFactory(access, enableCache)
    createAttribute: createAttributeFactory(access)
    createAttributeSet: createAttributeSetFactory(access)
    deleteAttribute: deleteAttributeFactory(access)
    deleteAttributeSet: deleteAttributeSetFactory(access)
    normalizeAttribute: normalizeAttribute
    normalizeAttributeSet: normalizeAttributeSet
  }

module.exports = MagApiFactory