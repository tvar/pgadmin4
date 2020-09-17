SELECT COALESCE(
  (SELECT TRUE FROM pg_partition WHERE parrelid={{ tid }}::oid LIMIT 1 ),
  (SELECT TRUE FROM pg_partition_rule pr JOIN pg_partition_rule cr on cr.parparentrule=pr.oid WHERE pr.parchildrelid={{ tid }}::oid LIMIT 1),
  FALSE)