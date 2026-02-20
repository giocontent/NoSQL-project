// 03_import_links.cypher
LOAD CSV WITH HEADERS FROM 'file:///links.csv' AS row
MATCH (m:Movie {movieId: toInteger(row.movieId)})
SET m.imdbId = row.imdbId,
    m.tmdbId = row.tmdbId;

// check
MATCH (m:Movie) WHERE m.imdbId IS NOT NULL RETURN count(m) AS linkedCount;
