// 10_analysis.cypher
// Sample analysis and prediction queries. Edit :param lines or replace $userId/$movieId.

// Example: movie stats
MATCH (m:Movie {movieId: 1})
OPTIONAL MATCH (m)<-[r:RATED]-()
RETURN m.title AS title, m.genres AS genres, count(r) AS numRatings, avg(r.rating) AS avgRating;

// Example: user stats
MATCH (u:User {userId: 1})-[r:RATED]->(m:Movie)
RETURN u.userId AS userId, count(m) AS numRatings, avg(r.rating) AS avgRating LIMIT 1;

// Recommend top-N for user using the TOP-N query (adjust parameters inline before running)
// Set userId and topN in the selection or replace $userId/$topN with literals
// Example selection to run: set userId=1 and topN=10
