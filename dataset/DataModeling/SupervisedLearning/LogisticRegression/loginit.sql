SET client_min_messages TO WARNING;DROP TABLE IF EXISTS madlibtestdata.log_noobservation;
CREATE TABLE madlibtestdata.log_noobservation (x float8[],y boolean);
ALTER TABLE madlibtestdata.log_noobservation OWNER TO madlibtester;

SET client_min_messages TO WARNING;DROP TABLE IF EXISTS madlibtestdata.log_singleobservation;
CREATE TABLE madlibtestdata.log_singleobservation (x float8[],y boolean);
COPY madlibtestdata.log_singleobservation FROM STDIN NULL '?' ;
{2, 1}	f
\.
ALTER TABLE madlibtestdata.log_singleobservation OWNER TO madlibtester;

SET client_min_messages TO WARNING;DROP TABLE IF EXISTS madlibtestdata.log_redundantobservations;
CREATE TABLE madlibtestdata.log_redundantobservations (x float8[],y boolean);
COPY madlibtestdata.log_redundantobservations FROM STDIN NULL '?' ;
{2.0,1}	f
{2.0,1}	f
{4.0,1}	f
\.
ALTER TABLE madlibtestdata.log_redundantobservations OWNER TO madlibtester;

------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

/*
    Whether a float value produced by MADlib is meaningful
*/
create or replace function madlibtestdata.is_meaningful (
    val                     double precision
) returns boolean as $$
begin
    if
        val is Null                         or
        val = 'Infinity'::double precision  or
        val = '-Infinity'::double precision or
        val = 'NaN'::double precision
    then
        return False;
    end if;
    return True;
end;
$$ language plpgsql;

------------------------------------------------------------------------

/*
    Compare two array values for all groups
*/
create or replace function madlibtestdata.compare_arrays (
    tbl_madlib              text,
    tbl_r                   text,
    dataset_name            text,
    grouping_cols           text,   -- grouping column names, cannot be Null
    var_name                text,
    dim                     integer
) returns double precision as $$
declare
    diff                        double precision;
    grouping_cols_cast          text;
    grouping_cols_cast_replace  text;
    grouping_cols_replace       text;
begin
    grouping_cols_cast := madlibtestdata.cast_grouping_cols(grouping_cols);

    if grouping_cols is Null then
        grouping_cols_cast_replace := 'Null';
        grouping_cols_replace := 'Null';
    else
        grouping_cols_cast_replace := grouping_cols_cast;
        grouping_cols_replace := ''''|| grouping_cols ||'''';
    end if;

    execute '
        select
            avg(
                case when
                    madlibtestdata.is_meaningful(m.val) and
                    r.val is not Null
                then
                    abs((m.val - r.val)/(case when r.val <> 0
                                              then r.val
                                              else 1
                                         end))
                else
                    0
                end)
        from
            (
            select
                generate_series(1, '|| dim ||') as idx,
                unnest('|| var_name ||') as val,
                (
                case when '|| grouping_cols_cast_replace ||' is not Null
                then
                    array['|| grouping_cols_cast_replace ||']
                else
                    Null::text[]
                end
                ) as grouping_vals
            from '|| tbl_madlib ||'
            ) m,
            (
            select
                generate_series(1, '|| dim ||') as idx,
                unnest('|| var_name ||') as val,
                grouping_vals
            from '|| tbl_r ||'
            where
                dataset = '''|| dataset_name ||''' and
                madlibtestdata.grouping_cols_equal(grouping_cols, '|| grouping_cols_replace ||')
            ) r
        where
            m.idx = r.idx and
            madlibtestdata.grouping_values_equal(m.grouping_vals, r.grouping_vals)
    ' into diff;
    return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------

/*
    Cast grouping string 'a, b, c' into 'a::text, b::text, c::text'
    so that it can be used in the expression
        select array[a::text, b::text, c::text] from tbl;
*/
create or replace function madlibtestdata.cast_grouping_cols(
    grp_r                   text
) returns text as $$
    if grp_r is None:
        return None
    import re
    elm = []
    for m in re.finditer(r"(\"(\\\"|[^\"])*\"|[^\",\s]+)", grp_r):
        elm.append(m.group(1))
    rst = ""
    for i in range(len(elm)):
        rst += elm[i] + "::text"
        if i != len(elm) - 1:
            rst += ", "
    return rst
$$ language plpythonu;

------------------------------------------------------------------------

/*
    Whether two sets of grouping columns have the same names
*/
create or replace function madlibtestdata.grouping_cols_equal (
    grp_1                   text,
    grp_2                   text
) returns boolean as $$
    if grp_1 is None:
        return True
    elm1 = []
    for m in re.finditer(r"(\"(\\\"|[^\"])*\"|[^\",\s]+)", grp_1):
        elm1.append(m.group(1))
    elm2 = []
    for m in re.finditer(r"(\"(\\\"|[^\"])*\"|[^\",\s]+)", grp_2):
        elm2.append(m.group(1))
    if len(elm1) != len(elm2):
        return False
    for i in range(len(elm1)):
        g1 = elm1[i].strip(" \"")
        g2 = elm2[i].strip(" \"")
        if g1 != g2:
            return False
    return True
$$ language plpythonu;

------------------------------------------------------------------------

/*
    Whether two sets of grouping values are equal
*/
create or replace function madlibtestdata.grouping_values_equal (
    grp_mad                 text[],
    grp_r                   text
) returns boolean as $$
    if grp_r is None:
        return True
    import re
    elm = []
    for m in re.finditer(r"(\"(\\\"|[^\"])*\"|[^\",\s]+)", grp_r):
        elm.append(m.group(1))
    if len(elm) != len(grp_mad):
        return False
    for i in range(len(elm)):
        g1 = elm[i].strip(" \"")
        g2 = grp_mad[i].strip(" \"")
        if g1 != g2:
            return False
    return True
$$ language plpythonu;

------------------------------------------------------------------------

/*
    Compare two single values for all groups
*/
create or replace function madlibtestdata.compare_ones (
    tbl_madlib          text,
    tbl_r               text,
    dataset_name        text,
    grouping_cols       text,
    var_name            text
) returns double precision as $$
declare
    diff                        double precision;
    grouping_cols_cast          text;
    grouping_cols_cast_replace  text;
    grouping_cols_replace       text;
begin
    grouping_cols_cast := madlibtestdata.cast_grouping_cols(grouping_cols);

    if grouping_cols is Null then
        grouping_cols_cast_replace := 'Null';
        grouping_cols_replace := 'Null';
    else
        grouping_cols_cast_replace := grouping_cols_cast;
        grouping_cols_replace := ''''|| grouping_cols ||'''';
    end if;
    
    execute '
        select
            avg(
                case when
                    madlibtestdata.is_meaningful(m.val) and
                    r.val is not Null
                then
                    abs((m.val - r.val)/(case when r.val <> 0
                                              then r.val
                                              else 1
                                         end))
                else
                    0
                end)
        from
            (
            select
                '|| var_name ||' as val,
                (
                case when '|| grouping_cols_cast_replace ||' is not Null
                then
                    array['|| grouping_cols_cast_replace ||']
                else
                    Null::text[]
                end
                ) as grouping_vals
            from '|| tbl_madlib ||'
            ) m,
            (
            select
                '|| var_name ||' as val,
                grouping_vals
            from '|| tbl_r ||'
            where
                dataset = '''|| dataset_name ||''' and
                madlibtestdata.grouping_cols_equal(grouping_cols, '|| grouping_cols_replace ||')
            ) r
        where
            madlibtestdata.grouping_values_equal(m.grouping_vals, r.grouping_vals)
    ' into diff;
    return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------

/*
    compare the prediction accuracies of MADlib model and R model
*/
create or replace function madlibtestdata.compare_accuracy (
    tbl_madlib      text,
    tbl_r           text,
    dataset_name    text,
    dep_val         text,
    ind_val         text,
    grouping_cols   text
) returns double precision as $$
declare
    ac1                     double precision;
    ac2                     double precision;
    diff                    double precision;
    grouping_cols_cast      text;
begin
    grouping_cols_cast := madlibtestdata.cast_grouping_cols(grouping_cols);

    if grouping_cols is Null then
        execute '
            select
                avg(madlib.logregr_accuracy(coef, '|| ind_val ||', '|| dep_val ||'))
            from '|| tbl_madlib ||', madlibtestdata.'|| dataset_name
        into ac1;

        execute '
            select    
                avg(madlib.logregr_accuracy(coef, '|| ind_val ||', '|| dep_val ||')) as ac
            from '|| tbl_r ||', madlibtestdata.'|| dataset_name ||'
            where
                dataset = '''|| dataset_name ||'''
        ' into ac2;

        diff := abs(ac1 - ac2);
    else
        execute '
            select
                avg(abs(m.ac - r.ac))
            from
                (
                select
                    avg(madlib.logregr_accuracy(coef, '|| ind_val ||', '|| dep_val ||')) as ac,
                    array['|| grouping_cols_cast ||'] as grouping_vals
                from '|| tbl_madlib ||', madlibtestdata.'|| dataset_name ||'
                group by '|| grouping_cols ||'
                ) m,
                (
                select
                    avg(madlib.logregr_accuracy(coef, '|| ind_val ||', '|| dep_val ||')) as ac,
                    grouping_vals
                from '|| tbl_r ||', madlibtestdata.'|| dataset_name ||'
                where
                    dataset = '''|| dataset_name ||''' and
                    madlibtestdata.grouping_cols_equal(grouping_cols, '|| grouping_cols ||')
                group by grouping_vals
                ) r
            where
                madlibtestdata.grouping_values_equal(m.grouping_vals, r.grouping_vals)
        ' into diff;
    end if;
   return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------

/*
    Evaluating the MADlib logistic regression result with
    respect to R result for the same data sets and same
    grouping
*/
create or replace function madlibtestdata.eval_logregr_train (
    dataset_name            text, -- only name
    tbl_r                   text, -- R results
    dep_val                 text, -- dependent value
    ind_val                 text, -- independent value
    grouping_cols           text, -- a string of all grouping columns
    max_iter                integer,
    optimizer               text,
    tolerance               double precision
) returns double precision as $$
declare
    tbl_output              text := madlib.__unique_string();
    diff                    double precision;
    dim                     integer;
    grp_replace             text;
    matches                 boolean := True;
    old_msg_level                 TEXT;
begin
    EXECUTE 'SELECT setting FROM pg_settings WHERE name=''client_min_messages''' INTO old_msg_level;
    EXECUTE 'SET client_min_messages TO info';

    if grouping_cols is Null then
        grp_replace := 'Null';
    else
        grp_replace := ''''|| grouping_cols ||'''';
    end if;

    execute '
        drop table if exists tbl_output;
        select madlib.logregr_train(
            ''madlibtestdata.'|| dataset_name ||''',
            '''|| tbl_output ||''',
            '''|| dep_val ||''',
            '''|| ind_val ||''',
            '|| grp_replace ||',
            '|| max_iter ||',
            '''|| optimizer ||''',
            '|| tolerance ||'
        )
    ';
    
    execute '
        select array_upper(coef, 1)
        from '|| tbl_output
    into dim;
    
    /* accuracy when applied onto training set */
    if matches then
        diff := madlibtestdata.compare_accuracy(tbl_output, tbl_r, dataset_name,
                                                dep_val, ind_val, grouping_cols);
        --raise exception 'diff is %', diff;
        if diff is Null or diff > 1e-2 then
            matches := False;
        end if;
    end if;

    /* fitting coefficients */
    -- if matches then
    --     diff := madlibtestdata.compare_arrays(tbl_output, tbl_r, dataset_name,
    --                                             grouping_cols, 'coef', dim);
    --     if diff is Null or diff > 1e-4 then
    --         matches := False;
    --     end if;
    -- end if;

    -- /* log likelihood */
    -- if matches then
    --     diff := madlibtestdata.compare_ones(tbl_output, tbl_r, dataset_name,
    --                                         grouping_cols, 'log_likelihood');
    --     if diff is Null or diff > 1e-2 then
    --         matches := False;
    --     end if;
    -- end if;
    
    -- /* standard error of fitting coefficients */
    -- if matches then
    --     diff := madlibtestdata.compare_arrays(tbl_output, tbl_r, dataset_name,
    --                                             grouping_cols, 'std_err', dim);
    --     if diff is Null or diff > 1e-4 then 
    --         matches := False;
    --     end if;
    -- end if;

    -- /* z statistics */
    -- if matches then
    --     diff := madlibtestdata.compare_arrays(tbl_output, tbl_r, dataset_name,
    --                                             grouping_cols, 'z_stats', dim);
    --     if diff is Null or diff > 1e-4 then
    --         matches := False;
    --     end if;
    -- end if;

    -- /* p values */
    -- if matches then
    --     diff := madlibtestdata.compare_arrays(tbl_output, tbl_r, dataset_name,
    --                                             grouping_cols, 'p_values', dim);
    --     if diff is Null or diff > 1e-4 then
    --         matches := False;
    --     end if;
    -- end if;

    /* exp(coef) */
    -- if matches then
    --     diff := madlibtestdata.compare_arrays(tbl_output, tbl_r, dataset_name,
    --                                             grouping_cols, 'odds_ratios', dim);
    --     raise warning 'diff is %', diff;
    --     if diff is Null or diff > 1e-4 then
    --         matches := False;
    --     end if;
    -- end if;
    
    /* condition number */
    -- if matches then
    --     diff := madlibtestdata.compare_ones(tbl_output, tbl_r, dataset_name,
    --                                         grouping_cols, 'condition_no');
    --     raise warning 'diff is %', diff;
    --     if diff is Null or diff > 1e-4 then
    --         matches := False;
    --     end if;
    -- end if;

    execute 'drop table if exists '|| tbl_output;
    execute 'SET client_min_messages TO '|| old_msg_level;

    if matches then
        return 100.0;
    end if;
    return -100.0;
end;
$$ language plpgsql;

