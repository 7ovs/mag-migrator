require('colors')
request = require('request')
_ = require('lodash')
fs = require 'fs'

s_access_token = {}

module.exports = (method, reqStr, access) ->

  REST = "#{access.domain}/index.php/rest/"
  TOKEN_URL = REST + 'V1/integration/admin/token'

  return (options, callback) ->

    complete = () ->
      params = 
        url: REST + reqStr
        method: method
        json: yes
        auth: { bearer: s_access_token[access.id] }
      _.extend(params, options)  
      request(params, callback)

    unless s_access_token[access.id]
      request 
          url: TOKEN_URL
          method: 'POST'
          json: yes
          body: 
            username: access.login
            password: access.password
        , (error, response, body) ->
          if error
            console.log error
          s_access_token[access.id] = body
          complete()
    else
      complete()