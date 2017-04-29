require('colors')
_ = require('lodash')
require('uasync')(_)
fs = require 'fs'
path = require 'path'

access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access.json"), "utf-8"))
filters = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/filters.json"), "utf-8"))

ENABLE_CACHE = yes

MagRequestFactory = require("./mag-request-factory")

isAttributeExists = ( () ->

  cache = false

  options = 
    qs:
      searchCriteria:
        currentPage: 1
        page_size: 300

  magRequest = MagRequestFactory('GET', '/V1/products/attributes', access.old)
    
  return (targetName) ->
    return new Promise (resolve, reject) ->

      complete = (items) ->
        result = _.find items, (obj) -> 
          obj.attribute_code.toLowerCase() == targetName.toLowerCase()
        resolve(result)

      if ENABLE_CACHE and cache 
        complete(cache)
      else
        magRequest options, (error, response, body) ->
          if error
            reject(error)
          else if body
            cache = body.items if ENABLE_CACHE
            complete(body.items)
)()

isAttributeSetExists = ( ()->

  cache = false

  options = 
    qs:
      searchCriteria:
        currentPage: 1
        page_size: 300

  magRequest = MagRequestFactory('GET', 'V1/products/attribute-sets/sets/list', access.old)
  
  return (targetName) ->
    return new Promise (resolve, reject) ->

      complete = (items) ->
        result = _.find items, (obj) -> 
          obj.attribute_set_name.toLowerCase() == targetName.toLowerCase()
        resolve(result)

      if ENABLE_CACHE and cache 
        complete(cache)
      else
        magRequest options, (error, response, body) ->
          if error
            reject(error)
          else if body
            cache = body.items if ENABLE_CACHE
            complete(body.items)

)()


createAttribute = ( () -> 

  magRequest = MagRequestFactory('POST', '/V1/products/attributes', access.new)
  
  return (attribute) ->
    return new Promise (resolve, reject) ->  

      options = body: {attribute}

      magRequest options, (error, response, body) ->
        if not error and body
          if response.statusCode == 200
            resolve(body)
          else
            reject(body.message)  
        else
          reject(error)    
)()

createAttributeSet = ( () -> 

  magRequest = MagRequestFactory('POST', 'V1/products/attribute-sets', access.new)
  
  return (attributeSet) ->
    return new Promise (resolve, reject) ->  

      options = body: {attributeSet, skeletonId: attributeSet.entity_type_id}

      magRequest options, (error, response, body) ->
        if not error and body
          if response.statusCode == 200
            resolve(body)
          else
            reject(body.message)  
        else
          reject(error)

)()

deleteAttribute = ( () -> 
  
  return (attributeId) ->

    magRequest = MagRequestFactory('DELETE', "V1/products/attributes/#{attributeId}", access.new)
    
    return new Promise (resolve, reject) ->  

      magRequest {}, (error, response, body) ->
        if not error
          if response.statusCode == 200
            resolve(null)
          else
            reject(body.message)  
        else
          reject(error)    
)()

deleteAttributeSet = ( () -> 
  
  return (attributeSetId) ->
    magRequest = MagRequestFactory('DELETE', "V1/products/attribute-sets/#{attributeSetId}", access.new)

    return new Promise (resolve, reject) ->  

      magRequest {}, (error, response, body) ->
        if not error
          if response.statusCode == 200
            resolve(null)
          else
            reject(body.message)  
        else
          reject(error)

)()

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

module.exports = {
  isAttributeExists
  isAttributeSetExists
  normalizeAttribute
  normalizeAttributeSet
  createAttribute
  createAttributeSet
  deleteAttribute
  deleteAttributeSet
}