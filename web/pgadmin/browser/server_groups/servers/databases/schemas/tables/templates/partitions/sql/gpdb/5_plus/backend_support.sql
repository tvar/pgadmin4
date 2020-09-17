SELECT COALESCE(
  (SELECT TRUE FROM pg_partition WHERE parrelid={{ tid }}::oid LIMIT 1 ),
  FALSE)