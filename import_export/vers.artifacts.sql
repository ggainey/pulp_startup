SELECT "core_artifact"."pulp_id", "core_artifact"."pulp_created", "core_artifact"."pulp_last_updated", "core_artifact"."file", "core_artifact"."size", "core_artifact"."md5", "core_artifact"."sha1", "core_artifact"."sha224", "core_artifact"."sha256", "core_artifact"."sha384", "core_artifact"."sha512"
 FROM "core_artifact"
      INNER JOIN "core_contentartifact" ON ("core_artifact"."pulp_id" = "core_contentartifact"."artifact_id")
WHERE "core_contentartifact"."content_id" IN (
      SELECT V0."pulp_id"
        FROM "core_content" V0
             INNER JOIN "core_repositorycontent" V1 ON (V0."pulp_id" = V1."content_id")
       WHERE V1."pulp_id" IN (
             SELECT U0."pulp_id"
               FROM "core_repositorycontent" U0
                    INNER JOIN "core_repositoryversion" U2 ON (U0."version_added_id" = U2."pulp_id")
                    LEFT OUTER JOIN "core_repositoryversion" U3 ON (U0."version_removed_id" = U3."pulp_id")
              WHERE (U0."repository_id"='d085053b-8005-4453-9c40-b0209c7f2f92' AND U2."number" <= 1 AND NOT (U3."number" <= 1 AND U3."number" IS NOT NULL))
        )
    )
