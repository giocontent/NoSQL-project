// 02_import_movies.cypher
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
ON CREATE SET m.title = row.title,
              m.genres = CASE WHEN row.genres IS NOT NULL THEN split(row.genres, '|') ELSE [] END;

// check
MATCH (m:Movie) RETURN count(m) AS movieCount;
