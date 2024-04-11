delete from pulp_2to3_migration_pulp2content a
  using pulp_2to3_migration_pulp2content b


DELETE FROM pulp_2to3_migration_pulp2content
WHERE pulp_id IN
    (SELECT pulp_id
    FROM
        (SELECT pulp_id,
         ROW_NUMBER() OVER(PARTITION BY pulp2_id, pulp2_content_type_id, pulp2_repo_id, pulp2_subid
        ORDER BY pulp_created) AS row_num
        FROM pulp_2to3_migration_pulp2content ) t
        WHERE t.row_num > 1 );


pulp_2to3_migration_pulp2erratum
pulp_2to3_migration_pulp2srpm
pulp_2to3_migration_pulp2packagegroup
pulp_2to3_migration_pulp2modulemd
pulp_2to3_migration_pulp2debreleasearchitecture
pulp_2to3_migration_pulp2rpm
pulp_2to3_migration_pulp2debcomponent
pulp_2to3_migration_pulp2manifest
pulp_2to3_migration_pulp2modulemddefaults
pulp_2to3_migration_pulp2manifestlist
pulp_2to3_migration_pulp2debpackage
pulp_2to3_migration_pulp2packagelangpacks
pulp_2to3_migration_pulp2blob
pulp_2to3_migration_pulp2debcomponentpackage
pulp_2to3_migration_pulp2yumrepometadatafile
pulp_2to3_migration_pulp2packageenvironment
pulp_2to3_migration_pulp2packagecategory
pulp_2to3_migration_pulp2distribution
pulp_2to3_migration_pulp2tag
pulp_2to3_migration_pulp2iso
pulp_2to3_migration_pulp2debrelease

# find removeable-dups
SELECT pulp_id FROM pulp_2to3_migration_pulp2content
WHERE pulp_id IN
    (SELECT pulp_id
    FROM
        (SELECT pulp_id,
         ROW_NUMBER() OVER(PARTITION BY pulp2_id, pulp2_content_type_id, pulp2_repo_id, pulp2_subid
        ORDER BY pulp_created) AS row_num
        FROM pulp_2to3_migration_pulp2content ) t
        WHERE t.row_num > 1 )
order by pulp_id;

# find The Keepers
SELECT pulp_id FROM pulp_2to3_migration_pulp2content
WHERE pulp_id IN
    (SELECT pulp_id
    FROM
        (SELECT pulp_id,
         ROW_NUMBER() OVER(PARTITION BY pulp2_id, pulp2_content_type_id, pulp2_repo_id, pulp2_subid
        ORDER BY pulp_created) AS row_num
        FROM pulp_2to3_migration_pulp2content ) t
        WHERE t.row_num > 1 )
order by pulp_id;
