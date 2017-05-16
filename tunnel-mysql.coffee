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
        resolve(results)


getGroupsForAttributeSet = (attrSetId, access) ->
  return new Promise (resolve, reject) ->
    TunnelSSH access.ssh, (error, tunnel) ->
      connection = mysql.createConnection(access.mysql)

      QUERY = """
      SELECT ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
      FROM eav_attribute_group AS ag
      WHERE attribute_set_id = #{attrSetId}
      ORDER BY sort_order
      """
      connection.query QUERY, (error, results, fields) ->
        connection.destroy()
        tunnel.close()
        reject(error) if error
        resolve(results)

getGroupsAndSetsForAttribute = (attrId, access) ->
  return new Promise (resolve, reject) ->
    TunnelSSH access.ssh, (error, tunnel) ->
      connection = mysql.createConnection(access.mysql)

      QUERY = """
      SELECT ea.attribute_set_id, ae.attribute_set_name, ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
      FROM eav_entity_attribute AS ea 
      INNER JOIN eav_attribute_group AS ag ON ea.`attribute_group_id` = ag.`attribute_group_id` 
      INNER JOIN eav_attribute_set AS ae ON ae.`attribute_set_id` = ea.`attribute_set_id`
      WHERE attribute_id = #{attrId}
      """

      connection.query QUERY, (error, results, fields) ->
        connection.destroy()
        tunnel.close()
        reject(error) if error
        resolve(results)

getGroupsAndSetsForAttributesList = (list, access) ->
  return new Promise (resolve, reject) ->
    TunnelSSH access.ssh, (error, tunnel) ->
      connection = mysql.createConnection(access.mysql)

      Promise.mapSeries list, (attrId) ->
        QUERY = """
        SELECT ea.attribute_set_id, ae.attribute_set_name, ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
        FROM eav_entity_attribute AS ea 
        INNER JOIN eav_attribute_group AS ag ON ea.`attribute_group_id` = ag.`attribute_group_id` 
        INNER JOIN eav_attribute_set AS ae ON ae.`attribute_set_id` = ea.`attribute_set_id`
        WHERE attribute_id = #{attrId}
        """

        return new Promise (resolve, reject) ->
          connection.query QUERY, (error, results, fields) ->
            return reject(error) if error
            resolve(results)
      .then (results) ->
        connection.destroy()
        tunnel.close()
        resolve(results)
        return results
      .catch (e) ->
        connection.destroy()
        tunnel.close()
        reject(e)

getGroupsForAttributeSetsList = (list, access) ->
  return new Promise (resolve, reject) ->
    TunnelSSH access.ssh, (error, tunnel) ->
      connection = mysql.createConnection(access.mysql)

      Promise.mapSeries list, (attrSetId) ->
        QUERY = """
        SELECT ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
        FROM eav_attribute_group AS ag
        WHERE attribute_set_id = #{attrSetId}
        ORDER BY sort_order
        """
        return new Promise (resolve, reject) ->
          connection.query QUERY, (error, results, fields) ->
            return reject(error) if error
            resolve(results)
      .then (results) ->
        connection.destroy()
        tunnel.close()
        resolve(results)
        return results
      .catch (e) ->
        connection.destroy()
        tunnel.close()
        reject(e)


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


module.exports = {
  getGroupsForAttributeSet
  getGroupsAndSetsForAttribute
  getGroupsAndSetsForAttributesList
  getGroupsForAttributeSetsList
  getProductsCount
}
    
  
# getGroupsAndSetsForAttributesList([100, 101, 102], access.new).then (results) ->
#   console.log JSON.stringify(results, null, '  ')
#   console.log results.length
# .catch (error) ->
#   console.log error

# getGroupsForAttributeSetsList([50, 51, 52], access.new).then (results) ->
#   console.log JSON.stringify(results, null, '  ')
#   console.log results.length
# .catch (error) ->
#   console.log error

# getGroupsForAttributeSet(43, access.old).then (results) ->
#   console.log JSON.stringify(results, null, '  ')
# .catch (error) ->
#   console.log error

# getGroupsAndSetsForAttribute(171, access.old).then (results) ->
#   console.log JSON.stringify(results, null, '  ')
# .catch (error) ->
#   console.log error