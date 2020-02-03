SELECT
  cp.oid,
  cp.relname AS name,
  (SELECT count(*) FROM pg_trigger WHERE tgrelid = cp.oid AND tgisinternal = FALSE) AS triggercount,
  (SELECT count(*) FROM pg_trigger WHERE tgrelid = cp.oid AND tgisinternal = FALSE AND tgenabled = 'O') AS has_enable_triggers,
  regexp_replace(replace(replace(replace(
    pg_get_partition_rule_def(r.oid, true), 
      'START (', 'FOR VALUES FROM ('),
      ') END', ') TO'),
      'VALUES(', 'FOR VALUES IN ('), '(.*) WITH .*', '\1')
    AS partition_value,
  n.oid AS schema_id,
  np.nspname as schema_name,
  --(exists (select 1 from pg_partition_rule cr where cr.parparentrule = r.oid)) as is_partitioned,
  parlevel < max(parlevel) OVER(PARTITION BY c.oid)  AS is_partitioned,
  CASE p.parkind WHEN 'r' THEN 'range' WHEN 'l' THEN 'list' ELSE '' END AS partition_scheme
FROM pg_partition_rule r
      join pg_partition p on r.paroid=p.oid
      join pg_class c on c.oid=p.parrelid
      join pg_class cp on cp.oid=r.parchildrelid  
      join pg_namespace np on np.oid=cp.relnamespace
      join pg_namespace n on n.oid=c.relnamespace
  WHERE
    {% if ptid %} cp.oid = {{ ptid }}::OID {% endif %}
    {% if not ptid %} c.oid = {{ tid }}::OID {% endif %}
ORDER BY cp.relname;

