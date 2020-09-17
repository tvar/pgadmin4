SELECT
  c.oid,
  c.relname  AS name,
  (SELECT count(*) FROM pg_trigger WHERE tgrelid = c.oid AND tgisconstraint = FALSE) AS triggercount,
  (SELECT count(*) FROM pg_trigger WHERE tgrelid = c.oid AND tgisconstraint = FALSE AND tgenabled = 'O') AS has_enable_triggers,
  regexp_replace(replace(replace(replace(
    pg_get_partition_rule_def(r.oid, true), 
      'START (', 'FOR VALUES FROM ('),
      ') END', ') TO'),
      'VALUES(', 'FOR VALUES IN ('), '(.*) WITH .*', '\1')
    AS partition_value,
  n.oid AS schema_id,
  np.nspname as schema_name,
  parlevel > max(parlevel) OVER(PARTITION BY cp.oid)  AS is_partitioned,
  CASE p.parkind WHEN 'r' THEN 'range' WHEN 'l' THEN 'list' ELSE '' END AS partition_scheme
FROM pg_partition_rule r
      join pg_partition p on r.paroid=p.oid
      join pg_class cp on cp.oid=p.parrelid
      join pg_class c on c.oid=r.parchildrelid  
      join pg_namespace np on np.oid=cp.relnamespace
      join pg_namespace n on n.oid=c.relnamespace
  WHERE
    {% if ptid %} cp.oid = {{ ptid }}::OID {% endif %}
    {% if not ptid %} cp.oid = {{ tid }}::OID {% endif %}
ORDER BY c.relname;

