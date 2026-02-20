// 08_import_tags.cypher
// Import user tags (sample for testing)
LOAD CSV WITH HEADERS FROM 'file:///tags.csv' AS row
WITH row LIMIT 10000
MATCH (u:User {userId: toInteger(row.userId)})
MATCH (m:Movie {movieId: toInteger(row.movieId)})
MERGE (u)-[r:TAGGED {tag: row.tag}]->(m)
ON CREATE SET r.timestamp = toInteger(row.timestamp);

MATCH ()-[r:TAGGED]->() RETURN count(r) AS userTagCount;
