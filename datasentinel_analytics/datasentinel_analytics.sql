CREATE OR REPLACE FUNCTION datasentinel_analytics
(
    action       text,               -- 'explain' or 'colstats' or 'extstats
    query_text   text      default NULL,   -- for 'explain': "[(generic_plan)] <statement>"
    schema_name  text      default NULL,
    table_name   text      default NULL
)
RETURNS SETOF record
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    explain_options text := 'ANALYZE off, FORMAT text';
    stmt            text;
BEGIN
    IF action = 'explain' THEN
        IF query_text IS NULL THEN
            RAISE EXCEPTION 'query_text must be supplied for action=explain';
        END IF;

        -- The EXPLAIN option list is built here and only here: the caller can never
        -- turn ANALYZE on (which would execute the statement as the function owner)
        -- and the output format is always TEXT.
        -- The only caller-controlled option is GENERIC_PLAN, requested by prefixing
        -- query_text with the literal marker "(generic_plan)".
        stmt := btrim(query_text);

        IF stmt ~* '^\(\s*generic_plan\s*\)' THEN
            explain_options := explain_options || ', GENERIC_PLAN';
            stmt := btrim(regexp_replace(stmt, '^\(\s*generic_plan\s*\)', '', 'i'));
        END IF;

        -- Exactly one statement: drop a trailing ';' and refuse any other one, so
        -- "select 1; delete from t" cannot smuggle a second command into EXECUTE.
        stmt := regexp_replace(stmt, '[\s;]+$', '');
        IF stmt = '' THEN
            RAISE EXCEPTION 'query_text must contain a statement to explain';
        END IF;
        IF position(';' IN stmt) > 0 THEN
            RAISE EXCEPTION 'query_text must contain a single statement (found ";")';
        END IF;

        RETURN QUERY EXECUTE format('EXPLAIN (%s) %s', explain_options, stmt);

    ELSIF action = 'extstats' THEN
        RETURN QUERY
        SELECT
            relnamespace::regnamespace::text AS schemaname,
            relname::text,
            jsonb_agg(jsonb_build_object('ext_stats', pg_get_statisticsobjdef(s.oid))) as pickled_ext_stats
        FROM pg_statistic_ext as s JOIN pg_class
        on stxrelid = pg_class.oid
        WHERE (schema_name IS NULL OR relnamespace::regnamespace::text = schema_name)
          AND (table_name  IS NULL OR relname = table_name)
        group by relnamespace::regnamespace, relname;
    ELSIF action = 'colstats' THEN
        RETURN QUERY
        SELECT
            s.schemaname::text,
            s.tablename::text,
            a.attnum        AS column_index,
            a.attname::text AS column_name,
            pg_catalog.format_type(a.atttypid,a.atttypmod)::text AS data_type,
            s.null_frac,
            s.avg_width,
            s.n_distinct,
            s.correlation,
            s.inherited,
            COALESCE(cardinality(s.most_common_vals),0) AS len_common_vals
        FROM pg_attribute a
        JOIN pg_class     c ON a.attrelid   = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_stats     s ON s.schemaname = n.nspname
                           AND s.tablename  = c.relname
                           AND s.attname    = a.attname
        WHERE a.attnum  > 0
          AND NOT a.attisdropped
          AND c.relkind IN ('r','p','m')
          AND n.nspname NOT IN ('information_schema','pg_catalog')
          AND (schema_name IS NULL OR n.nspname = schema_name)
          AND (table_name IS NULL OR c.relname   = table_name);

    ELSE
        RAISE EXCEPTION 'Unknown action: %. Must be one of: explain, colstats, extstats', action;
    END IF;
END;
$$;

-- CREATE FUNCTION grants EXECUTE to PUBLIC by default. This function is
-- SECURITY DEFINER (it runs as its owner, normally a superuser), so only the
-- monitoring role must be allowed to call it: deploy_datasentinel_function.sh
-- grants it back to that role after running this file.
REVOKE EXECUTE ON FUNCTION datasentinel_analytics(text, text, text, text) FROM PUBLIC;

/* GRANT EXECUTE ON FUNCTION datasentinel_analytics(TEXT, TEXT, TEXT, TEXT) TO datasentinel; */
