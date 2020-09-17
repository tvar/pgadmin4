SELECT
    split_part(rolconfig, '=', 1) AS name, replace(rolconfig, split_part(rolconfig, '=', 1) || '=', '') AS value, NULL::text AS database
FROM
    (SELECT
            unnest(rolconfig) AS rolconfig, rolcanlogin, rolname
    FROM
        pg_catalog.pg_roles
    WHERE
        oid={{ rid|qtLiteral }}::OID
    ) r
