/*pga4dash*/
SELECT
    pid AS pid,
    datname,
    usename,
    application_name,
    client_addr,
    to_char(backend_start, 'YYYY-MM-DD HH24:MI:SS TZ') AS backend_start,
    state AS state,
    CASE WHEN waiting THEN '{{ _('yes') }}' ELSE '{{ _('no') }}' END AS waiting
FROM
    pg_stat_activity
{% if did %}WHERE
    datid = {{ did }} {% endif %}
ORDER BY pid
