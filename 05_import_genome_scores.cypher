// 05_import_genome_scores.cypher
// This may create many relationships. Consider running with a relevance threshold.
// Edit threshold below if you want fewer relationships.
WITH 0.5 AS threshold
LOAD CSV WITH HEADERS FROM 'file:///genome_scores.csv' AS row
WITH row WHERE toFloat(row.relevance) >= threshold
MATCH (m:Movie {movieId: toInteger(row.movieId)})
MATCH (t:GenomeTag {tagId: toInteger(row.tagId)})
MERGE (m)-[r:HAS_GENOME_TAG]->(t)
ON CREATE SET r.relevance = toFloat(row.relevance);

MATCH ()-[r:HAS_GENOME_TAG]->() RETURN count(r) AS genomeScoreCount;
