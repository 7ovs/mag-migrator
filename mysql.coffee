require "colors"
fs = require "fs"
_ = require "lodash"
path = require "path"
mysql = require "mysql"

mysqlAccess = JSON.parse(fs.readFileSync(path.resolve(__dirname, "etc/mysql.json"), "utf-8"))

###
SELECT ea.attribute_set_id, ae.attribute_set_name, ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
FROM eav_entity_attribute AS ea 
INNER JOIN eav_attribute_group AS ag ON ea.`attribute_group_id` = ag.`attribute_group_id` 
INNER JOIN eav_attribute_set AS ae ON ae.`attribute_set_id` = ea.`attribute_set_id`
WHERE attribute_id = 163

SELECT ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
FROM eav_attribute_group AS ag
WHERE attribute_set_id = 43
ORDER BY sort_order;
###


getGroupsForAttributeSet = (attrSetId, mysqlAccess) ->
  return new Promise (resolve, reject) ->
    connection = mysql.createConnection(mysqlAccess)

    QUERY = """
    SELECT ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
    FROM eav_attribute_group AS ag
    WHERE attribute_set_id = #{attrSetId}
    ORDER BY sort_order
    """
    connection.query QUERY, (error, results, fields) ->
      reject(error) if error
      connection.destroy()
      resolve(results)

getGroupsAndSetsForAttribute = (attrId, mysqlAccess) ->
  return new Promise (resolve, reject) ->
    connection = mysql.createConnection(mysqlAccess)

    QUERY = """
    SELECT ea.attribute_set_id, ae.attribute_set_name, ag.attribute_group_id, ag.attribute_group_code, ag.attribute_group_name, ag.sort_order 
    FROM eav_entity_attribute AS ea 
    INNER JOIN eav_attribute_group AS ag ON ea.`attribute_group_id` = ag.`attribute_group_id` 
    INNER JOIN eav_attribute_set AS ae ON ae.`attribute_set_id` = ea.`attribute_set_id`
    WHERE attribute_id = #{attrId}
    """

    connection.query QUERY, (error, results, fields) ->
      reject(error) if error
      connection.destroy()
      resolve(results)


# getGroupsAndSetsForAttribute(163, mysqlAccess.old).then (results) ->
#   console.log JSON.stringify(results, null, '  ')
# .catch (error) ->
#   console.log error


getGroupsForAttributeSet(10, mysqlAccess.new).then (results) ->
  console.log JSON.stringify(results, null, '  ')
.catch (error) ->
  console.log error