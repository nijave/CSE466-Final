use bio466;
-- Queries: --

SELECT 'Total genes in common' as 'Description';
SELECT COUNT(*) as 'Genes in Common' FROM (SELECT name FROM genes GROUP BY name HAVING COUNT(DISTINCT filename) > 1) t;

SELECT 'Genes unique to each organism' as 'Description';
SELECT genome_build as 'Organism', COUNT(*) as 'Count' 
FROM genes JOIN genome USING(filename) 
WHERE name IN (
	SELECT name FROM genes GROUP BY name HAVING COUNT(DISTINCT filename) = 1
) GROUP BY genome_build;

SELECT 'Gene count for each organism' as 'Description';
SELECT genome_build as 'Organism', COUNT(DISTINCT name) as 'Gene Count' FROM genes LEFT JOIN genome ON genome.filename = genes.filename GROUP BY genome_build;

SELECT 'Totals for each type (RNA, genes, transcripts)' as 'Description';
SELECT genome_build as 'Organism', 'RNA' as 'Type', COUNT(*) as 'Count' FROM rna JOIN genome USING(filename) GROUP BY genome_build
UNION ALL
SELECT genome_build as 'Organism', 'Gene' as 'Type', COUNT(*) as 'Count' FROM genes JOIN genome USING(filename) GROUP BY genome_build
UNION ALL
SELECT genome_build as 'Organism', 'Transcripts' as 'Type', COUNT(*) as 'Count' FROM transcripts JOIN genome USING(filename) GROUP BY genome_build;

SELECT 'Gene (bio) type totals' as 'Description';
SELECT genome_build as 'Organism', `type` as 'Type', COUNT(`type`) as 'Count' FROM genes JOIN genome USING(filename) GROUP BY filename, `type` ORDER BY filename, `type`;