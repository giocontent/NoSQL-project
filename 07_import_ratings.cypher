// 07_import_ratings.cypher
// Import ratings in batches: this file uses a WHERE clause for safety during testing.
// Remove the WHERE clause to import all ratings, or adjust ranges as needed.

// Example: import all (careful - may be large)
// LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row
// MATCH (u:User {userId: toInteger(row.userId)})
// MATCH (m:Movie {movieId: toInteger(row.movieId)})
// MERGE (u)-[r:RATED]->(m)
// ON CREATE SET r.rating = toFloat(row.rating), r.timestamp = toInteger(row.timestamp);

// Import a manageable sample for recommendation system testing (50000 ratings)
// Safe import with a limit for testing purposes
// Increased to 1M for better collaborative filtering accuracy
LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row
WITH row LIMIT 1000000
MATCH (u:User {userId: toInteger(row.userId)})
MATCH (m:Movie {movieId: toInteger(row.movieId)})
MERGE (u)-[r:RATED]->(m)
ON CREATE SET r.rating = toFloat(row.rating), r.timestamp = toInteger(row.timestamp);

// Return count
MATCH ()-[r:RATED]->()
RETURN count(r) as ratingCount;
