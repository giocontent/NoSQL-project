// 04_import_genome_tags.cypher
LOAD CSV WITH HEADERS FROM 'file:///genome_tags.csv' AS row
MERGE (t:GenomeTag {tagId: toInteger(row.tagId)})
ON CREATE SET t.tag = row.tag;

MATCH (t:GenomeTag) RETURN count(t) AS genomeTagCount;
