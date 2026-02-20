// 06_import_users.cypher
// Create distinct users from ratings.csv
LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row
WITH DISTINCT toInteger(row.userId) AS userId
MERGE (u:User {userId: userId});

MATCH (u:User) RETURN count(u) AS userCount;
