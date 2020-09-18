SET LOCAL enable_nestloop=on;
SELECT ref.relname AS refname, d2.refclassid, dep.deptype AS deptype FROM pg_depend dep 
  LEFT JOIN pg_depend d2 ON dep.objid=d2.objid and d2.classid='pg_attrdef'::regclass AND dep.refobjid <> d2.refobjid 
  LEFT JOIN pg_class ref ON ref.oid=d2.refobjid 
  LEFT JOIN pg_attribute att ON att.attrelid=d2.refclassid AND att.attnum=d2.refobjsubid 
{{ where }} AND 
  dep.classid='pg_attrdef'::regclass AND 
  dep.refobjid NOT IN (SELECT d3.refobjid FROM pg_depend d3 WHERE d3.objid=d2.refobjid and d3.classid=d2.refclassid);

