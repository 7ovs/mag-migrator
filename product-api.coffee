require "colors"
fs = require "fs"
_ = require "lodash"
path = require "path"
mysql = require "mysql"
Promise = require "bluebird"
TunnelSSH = require "tunnel-ssh"

access = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/access2.json"), "utf-8"))
access = _.mapValues access, (cfg, key) -> 
  cfg.ssh.privateKey = fs.readFileSync(cfg.ssh.privateKey)
  return cfg

getProductsCount = (access) ->
  return new Promise (resolve, reject) ->
    TunnelSSH access.ssh, (error, tunnel) ->
      connection = mysql.createConnection(access.mysql)

      QUERY = "SELECT count(*) FROM `catalog_product_entity`"
      connection.query QUERY, (error, results, fields) ->
        connection.destroy()
        tunnel.close()
        reject(error) if error
        resolve(parseInt(results[0]['count(*)'],10))

module.exports = {}
    
getProductsCount(access.old).then (result) ->
  console.log result