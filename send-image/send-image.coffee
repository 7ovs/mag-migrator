fs = require('fs')
path = require('path')
require('colors')
_ = require('lodash')
MagRequestFactory = require("../mag-request-factory")

EXT_TO_MIME = 
  gif: "image/gif"
  jpeg: "image/jpeg"
  jpg: "image/jpeg"
  png: "image/png"
  tiff: "image/tiff"
  tif: "image/tiff"

access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../etc/access.json"), "utf-8"))


sendMedia = (sku, imagePath) ->
    magRequest = MagRequestFactory('POST', "/V1/products/#{sku}/media", access.new)

    base64 = new Buffer(fs.readFileSync(imagePath)).toString('base64')
    mediaType = EXT_TO_MIME(path.extname(imagePath).slice(1))

    assert(mediaType)

    options = 
      'entry':
        'media_type': 'image'
        'label': ''
        'disabled': false
        'types': [
          'image'
          'small_image'
          'thumbnail'
        ]
        'file': 'string'
        'content':
          'base64_encoded_data': base64
          'type': mediaType
          'name': path.basename(imagePath)

    return new Promise (resolve, reject) ->
      magRequest options, (error, response, body) ->


getMedia = (sku) ->
  magRequest = MagRequestFactory('GET', "/V1/products/#{sku}/media", access.old)
  return new Promise (resolve, reject) ->
    magRequest {}, (error, response, body) ->  
      if error
        reject(error)
      else if response.statusCode == 200
        resolve(body)
      else
        reject(body.message)  

(->
  result = await getMedia('LO-01-02')
  console.log JSON.stringify(result, null, '  ')
)()
