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
  
  CASE p.parkind WHEN 'r' THEN 'range' WHEN 'l' THEN 'list' ELSE '' END AS partition_scheme,
  CASE chp.parkind WHEN 'r' THEN 'range' WHEN 'l' THEN 'list' ELSE '' END AS sub_partition_scheme,
  des.description, pg_get_userbyid(cp.relowner) AS relowner,
  	substring(array_to_string(cp.reloptions, ',') FROM 'fillfactor=([0-9]*)') AS fillfactor,
	(substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_enabled=([a-z|0-9]*)'))::BOOL AS autovacuum_enabled,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_vacuum_threshold=([0-9]*)') AS autovacuum_vacuum_threshold,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_vacuum_scale_factor=([0-9]*[.]?[0-9]*)') AS autovacuum_vacuum_scale_factor,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_analyze_threshold=([0-9]*)') AS autovacuum_analyze_threshold,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_analyze_scale_factor=([0-9]*[.]?[0-9]*)') AS autovacuum_analyze_scale_factor,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_vacuum_cost_delay=([0-9]*)') AS autovacuum_vacuum_cost_delay,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_vacuum_cost_limit=([0-9]*)') AS autovacuum_vacuum_cost_limit,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_freeze_min_age=([0-9]*)') AS autovacuum_freeze_min_age,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_freeze_max_age=([0-9]*)') AS autovacuum_freeze_max_age,
	substring(array_to_string(cp.reloptions, ',') FROM 'autovacuum_freeze_table_age=([0-9]*)') AS autovacuum_freeze_table_age,
	(substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_enabled=([a-z|0-9]*)'))::BOOL AS toast_autovacuum_enabled,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_threshold=([0-9]*)') AS toast_autovacuum_vacuum_threshold,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_scale_factor=([0-9]*[.]?[0-9]*)') AS toast_autovacuum_vacuum_scale_factor,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_analyze_threshold=([0-9]*)') AS toast_autovacuum_analyze_threshold,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_analyze_scale_factor=([0-9]*[.]?[0-9]*)') AS toast_autovacuum_analyze_scale_factor,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_cost_delay=([0-9]*)') AS toast_autovacuum_vacuum_cost_delay,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_cost_limit=([0-9]*)') AS toast_autovacuum_vacuum_cost_limit,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_freeze_min_age=([0-9]*)') AS toast_autovacuum_freeze_min_age,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_freeze_max_age=([0-9]*)') AS toast_autovacuum_freeze_max_age,
	substring(array_to_string(tst.reloptions, ',') FROM 'autovacuum_freeze_table_age=([0-9]*)') AS toast_autovacuum_freeze_table_age,
	cp.reloptions AS reloptions, tst.reloptions AS toast_reloptions,
	chp.oid is not null  AS is_sub_partitioned,
	true as is_partitioned
FROM pg_partition_rule r
      join pg_partition p on r.paroid=p.oid
      join pg_class c on c.oid=p.parrelid
      join pg_class cp on cp.oid=r.parchildrelid  
      join pg_namespace np on np.oid=cp.relnamespace
      join pg_namespace n on n.oid=c.relnamespace
      LEFT OUTER JOIN pg_description des ON (des.objoid=r.parchildrelid AND des.objsubid=0 AND des.classoid='pg_class'::regclass)
      LEFT OUTER JOIN pg_class tst ON tst.oid = cp.reltoastrelid
      LEFT JOIN pg_partition_rule pr on pr.oid=r.parparentrule
      LEFT JOIN pg_partition_rule cr on cr.parparentrule=r.oid
      LEFT join pg_partition chp on cr.paroid=chp.oid
  WHERE
    {% if ptid %} cp.oid = {{ ptid }}::OID {% endif %}
    {% if not ptid %} (c.oid = {{ tid }}::OID AND pr.oid is null) OR pr.parchildrelid={{ tid }}::OID {% endif %}
ORDER BY cp.relname;

