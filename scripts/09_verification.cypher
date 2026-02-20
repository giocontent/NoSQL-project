// 09_verification.cypher
// Verify node and relationship counts and sample data
MATCH (n)
RETURN labels(n)[0] AS nodeType, count(n) AS count
ORDER BY count DESC;

MATCH ()-[r]->()
RETURN type(r) AS relationshipType, count(r) AS count
ORDER BY count DESC;

// sample
MATCH (u:User)-[r:RATED]->(m:Movie)
RETURN u.userId AS userId, m.title AS title, r.rating AS rating
LIMIT 10;
