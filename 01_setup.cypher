// 01_setup.cypher
// Create constraints and indexes (idempotent)
CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.userId IS UNIQUE;
CREATE CONSTRAINT movie_id IF NOT EXISTS FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;
CREATE CONSTRAINT genome_tag_id IF NOT EXISTS FOR (t:GenomeTag) REQUIRE t.tagId IS UNIQUE;

CREATE INDEX user_ratings IF NOT EXISTS FOR ()-[r:RATED]-() ON (r.rating);
CREATE INDEX movie_title IF NOT EXISTS FOR (m:Movie) ON (m.title);

// confirm
MATCH (n) RETURN labels(n)[0] AS label, count(n) AS count LIMIT 25;
