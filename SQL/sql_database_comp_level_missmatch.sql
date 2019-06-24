/****** Script for SelectTopNRows command from SSMS  ******/
SELECT b.[servername],
    b.[name] AS databasename,
    CASE 
		WHEN b.compatibility_level = '80'
			THEN 'SQL 2000'
		WHEN b.compatibility_level = '90'
			THEN 'SQL 2005'
		WHEN b.compatibility_level = '100'
			THEN 'SQL 2008'
		WHEN b.compatibility_level = '110'
			THEN 'SQL 2012'
		WHEN b.compatibility_level = '120'
			THEN 'SQL 2014'
		WHEN b.compatibility_level = '130'
			THEN 'SQL 2016'
		WHEN b.compatibility_level = '140'
			THEN 'SQL 2017'
		WHEN b.compatibility_level = '150'
			THEN 'SQL 2019'
		ELSE 'unknown'
		END AS database_compatibility_level_desc,
    (m.compatibility_level - b.compatibility_level) / 10 AS compatibility_level_steps_missmatch,
    b.compatibility_level AS database_compatibility_level,
    m.compatibility_level AS master_compatibility_level
FROM [WB_DSkunder].[dbo].[vsysdatabases] m
    INNER JOIN [WB_DSkunder].[dbo].[vsysdatabases] b ON m.servername = b.servername
        AND m.compatibility_level != b.compatibility_level
-- master db = 1
WHERE m.database_id = '1'
ORDER BY b.servername,
	b.name
