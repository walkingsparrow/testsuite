SET client_min_messages TO WARNING;
DROP TABLE IF EXISTS madlibtestdata.lin_noobservation_oi;
CREATE TABLE madlibtestdata.lin_noobservation_oi (x float8[],y float8);
ALTER TABLE madlibtestdata.lin_noobservation_oi OWNER TO madlibtester;
SET client_min_messages TO WARNING;
DROP TABLE IF EXISTS madlibtestdata.lin_noobservation_wi;
CREATE TABLE madlibtestdata.lin_noobservation_wi (x float8[],y float8);
ALTER TABLE madlibtestdata.lin_noobservation_wi OWNER TO madlibtester;


SET client_min_messages TO WARNING;DROP TABLE IF EXISTS madlibtestdata.lin_singleobservation_oi;
CREATE TABLE madlibtestdata.lin_singleobservation_oi (x float8[],y float8);
COPY madlibtestdata.lin_singleobservation_oi FROM STDIN NULL '?';
{5.0, 2.0}	3.0
\.
ALTER TABLE madlibtestdata.lin_singleobservation_oi OWNER TO madlibtester;SET client_min_messages TO WARNING;DROP TABLE IF EXISTS madlibtestdata.lin_singleobservation_wi;
CREATE TABLE madlibtestdata.lin_singleobservation_wi (x float8[],y float8);
COPY madlibtestdata.lin_singleobservation_wi FROM STDIN NULL '?';
{1, 5.0, 2.0}	3.0
\.
ALTER TABLE madlibtestdata.lin_singleobservation_wi OWNER TO madlibtester;

SET client_min_messages TO WARNING;DROP TABLE IF EXISTS madlibtestdata.lin_redundantobservations_oi;
CREATE TABLE madlibtestdata.lin_redundantobservations_oi (x float8[],y float8);
COPY madlibtestdata.lin_redundantobservations_oi FROM STDIN NULL '?';
{2.0,3.0}	5.0
{2.0,3.0}	5.0
{4.0,6.0}	10.0
\.
ALTER TABLE madlibtestdata.lin_redundantobservations_oi OWNER TO madlibtester;SET client_min_messages TO WARNING;DROP TABLE IF EXISTS madlibtestdata.lin_redundantobservations_wi;
CREATE TABLE madlibtestdata.lin_redundantobservations_wi (x float8[],y float8);
COPY madlibtestdata.lin_redundantobservations_wi FROM STDIN NULL '?';
{1,2.0,3.0}	5.0
{1,2.0,3.0}	5.0
{1,4.0,6.0}	10.0
\.
ALTER TABLE madlibtestdata.lin_redundantobservations_wi OWNER TO madlibtester;

--not yet done
DROP SEQUENCE IF EXISTS madlibtestdata.lin_communities_agg_seq;
CREATE SEQUENCE madlibtestdata.lin_communities_agg_seq MAXVALUE 2 CYCLE MINVALUE 0;
DROP TABLE IF EXISTS madlibtestdata.lin_communities_oi_agg, madlibtestdata.lin_communities_wi_agg;
CREATE TABLE madlibtestdata.lin_communities_oi_agg AS SELECT nextval('madlibtestdata.lin_communities_agg_seq') AS id, madlibtestdata.lin_communities_oi.* FROM madlibtestdata.lin_communities_oi;
CREATE TABLE madlibtestdata.lin_communities_wi_agg AS SELECT nextval('madlibtestdata.lin_communities_agg_seq') AS id, madlibtestdata.lin_communities_wi.* FROM madlibtestdata.lin_communities_wi;

ALTER TABLE madlibtestdata.lin_communities_oi_agg OWNER TO madlibtester;
ALTER TABLE madlibtestdata.lin_communities_wi_agg OWNER TO madlibtester;

------------------------------------------------------------------------
/*
    compute the difference between two arrays from two tables
*/
create or replace function madlibtestdata.compare_array (
    table1      text,
    table2      text,
    source_name text,
    hetero_flag text,
    var         text,
    dim         integer
) returns double precision as $$
declare
    diff         double precision;
begin
    execute '
        select avg((t.coef - s.coef)^2)
        from (
            select
                generate_series(1, '|| dim ||') as idx,
                unnest('|| var ||') as coef
            from '|| table1 ||'
        ) t, (
            select
                generate_series(1, '|| dim ||') as idx,
                unnest('|| var ||') as coef
            from '|| table2 ||'
            where
                dataset = '''|| source_name ||'''
                and hetero = '|| hetero_flag ||'            
        ) s
        where t.idx = s.idx
    ' into diff;
    return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------
/*
    compute the difference of two values from two tables
*/
create or replace function madlibtestdata.compare_one (
    table1      text,
    table2      text,
    source_name text,
    hetero_flag text,
    var         text
) returns double precision as $$
declare
    diff        double precision;
begin
    execute '
        select abs((t.'|| var ||' - s.'|| var ||') / s.'|| var ||')
        from '|| table1 ||' t,
            '|| table2 ||' s
        where
            s.dataset = '''|| source_name ||'''
            and s.hetero = '|| hetero_flag 
    into diff;
    return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------

/*
    compute and compare the fitting residuals
*/
create or replace function madlibtestdata.compare_residual(
    table1      text, -- output of linregr
    table2      text, -- R results
    source_name text,
    hetero_flag text,
    dep         text,
    ind         text
) returns double precision as $$
declare
    res1        double precision;
    res2        double precision;
    diff        double precision;
begin
    execute '
        select avg(abs('||dep||' - madlib.linregr_predict(s.coef, t.'||ind||')))
        from '|| table1 ||' as s, madlibtestdata.'|| source_name ||' as t
    ' into res1;

    execute '
        select avg(abs('||dep||' - madlib.linregr_predict(s.coef, t.'||ind||')))
        from '|| table2 ||' as s, madlibtestdata.'|| source_name ||' as t
        where s.dataset = '''|| source_name ||'''
            and s.hetero = '|| hetero_flag
    into res2;

    diff := abs((res2 - res1) / res2);
    return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------
/*
    Evaluate heteroskedasticity
*/
create or replace function madlibtestdata.linregr_eval_hetero (
    source_name                 text,
    dependent_varname           text,
    independent_varname         text,
    heteroskedasticity_option   boolean,
    eval_r_table                text
) returns double precision as $$
declare
    out_table                   text := 'out_table_i86riw34';
    hetero_flag                 text;
    dim                         integer;
    diff                        double precision;
    thresh                      double precision := 1e-4;
    condition_thresh            double precision := 1000;
    condition_no                double precision;
begin
    if heteroskedasticity_option then
        hetero_flag := 'True';
    else
        hetero_flag := 'False';
    end if;

    execute '
        select
            array_upper(coef, 1)
        from '|| eval_r_table ||'
        where dataset = '''|| source_name ||'''
            and hetero = '|| hetero_flag
        into dim;
    
    execute '
        select madlib.linregr_train(
            ''madlibtestdata.'|| source_name ||''',
            '''|| out_table ||''',
            '''|| dependent_varname ||''',
            '''|| independent_varname ||''',
            NULL,
            '|| hetero_flag ||')
    ';

    execute '
        select condition_no
        from '|| out_table
        into condition_no;

    if condition_no > condition_thresh then
        diff := madlibtestdata.compare_residual(out_table, eval_r_table, source_name, hetero_flag,
                                                dependent_varname, independent_varname);
        if diff > thresh then
            execute 'drop table if exists '|| out_table;
            return 0;
        end if;

    else
    -- compare coef, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        hetero_flag, 'coef', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;

    -- compare r2, one
    -- diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
    --                                     hetero_flag, 'r2');
    -- if diff > thresh then
    --     execute 'drop table if exists '|| out_table;
    --     return 0;
    -- end if;

    -- compare std_err, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        hetero_flag, 'std_err', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    -- compare t_stats, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        hetero_flag, 't_stats', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    -- compare p_values, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        hetero_flag, 'p_values', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    -- condition_no, one
    diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
                                        hetero_flag, 'condition_no');
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    if heteroskedasticity_option then
        -- compare test_statistic, one
        diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
                                            hetero_flag, 'bp_stats');
        if diff > 1e-2 then
            execute 'drop table if exists '|| out_table;
            return 0;
        end if;
        
        -- compare test_p_value, one
        diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
                                            hetero_flag, 'bp_p_value');
        if diff > 1e-2 then
            execute 'drop table if exists '|| out_table;
            return 0;
        end if;
        
        -- -- compare robust_std_err, vec
        -- diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
        --                                     hetero_flag, 'corrected_std_err', dim);
        -- if diff > thresh then
        --     execute 'drop table if exists '|| out_table;
        --     return 0;
        -- end if;
    
        -- -- comprae robust_t_stats, vec
        -- diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
        --                                     hetero_flag, 'corrected_t_stats', dim);
        -- if diff > thresh then
        --     execute 'drop table if exists '|| out_table;
        --     return 0;
        -- end if;
    
        -- -- compare robust_p_values, vec
        -- diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
        --                                     hetero_flag, 'corrected_p_values', dim);
        -- if diff > thresh then
        --     execute 'drop table if exists '|| out_table;
        --     return 0;
        -- end if;
    end if;
    end if;

    execute 'drop table if exists '|| out_table;
    return 1;
end;
$$ language plpgsql;

------------------------------------------------------------------------
/*
    Is two text vector equal element by element?
*/
create or replace function madlibtestdata.array_equal (
    vec1        text[],
    vec2        text[]
) returns boolean as $$
declare
    dim         integer;
    i           integer;
begin
    dim := array_upper(vec1, 1);
    for i in 1..dim loop
        if vec1[i] != vec2[i] then
            return False;
        end if;
    end loop;
    return True;
end;
$$ language plpgsql;

------------------------------------------------------------------------
/*
    Is two integer vector equal element by element?
*/
create or replace function madlibtestdata.array_equal (
    vec1        integer[],
    vec2        integer[]
) returns boolean as $$
declare
    dim         integer;
    i           integer;
begin
    dim := array_upper(vec1, 1);
    for i in 1..dim loop
        if vec1[i] != vec2[i] then
            return False;
        end if;
    end loop;
    return True;
end;
$$ language plpgsql;

------------------------------------------------------------------------

create or replace function madlibtestdata.compare_array (
    table1          text,
    table2          text,
    source_name     text,
    grouping_str    text,
    grouping_str1   text,
    hetero_flag     text,
    var             text,
    dim             integer
) returns double precision as $$
declare
    diff         double precision;
begin
    execute '
        select avg((t.coef - s.coef)^2)
        from (
            select
                generate_series(1, '|| dim ||') as idx,
                unnest('|| var ||') as coef,
                '|| grouping_str ||' as grouping_vals
            from '|| table1 ||'
        ) t, (
            select
                generate_series(1, '|| dim ||') as idx,
                unnest('|| var ||') as coef,
                grouping_vals
            from '|| table2 ||'
            where
                dataset = '''|| source_name ||'''
                and hetero = '|| hetero_flag ||'
                and madlibtestdata.array_equal(grouping, '|| grouping_str1 ||')
        ) s
        where t.idx = s.idx and
            madlibtestdata.array_equal(t.grouping_vals, s.grouping_vals)
    ' into diff;
    return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------

create or replace function madlibtestdata.compare_one (
    table1          text,
    table2          text,
    source_name     text,
    grouping_str    text,
    grouping_str1   text,  
    hetero_flag     text,
    var             text
) returns double precision as $$
declare
    diff        double precision;
begin
    execute '
        select abs((t.'|| var ||' - s.'|| var ||') / s.'|| var ||')
        from (
            select '|| var ||', '|| grouping_str ||' as grouping_vals
            from '|| table1 ||') t,
            '|| table2 ||' s
        where
            s.dataset = '''|| source_name ||'''
            and s.hetero = '|| hetero_flag ||'
            and madlibtestdata.array_equal(grouping, '|| grouping_str1 ||')
            and madlibtestdata.array_equal(t.grouping_vals, s.grouping_vals) 
    ' into diff;
    return diff;
end;
$$ language plpgsql;

------------------------------------------------------------------------
/*
    Evaluate grouping functionality
*/
create or replace function madlibtestdata.linregr_eval_grouping (
    source_name             text,
    dependent_varname       text,
    independent_varname     text,
    grouping_vars           text[],
    hetero_option           boolean,
    eval_r_table            text
) returns double precision as $$
declare
    out_table               text := 'out_table_o3y9289';
    hetero_flag             text;
    dim                     integer;
    diff                    double precision;
    grouping_dim            integer;
    grouping_str            text;
    grouping_str1           text;
    i                       integer;
    thresh                  double precision := 1e-4;
begin
    if hetero_option then
        hetero_flag := 'True';
    else
        hetero_flag := 'False';
    end if;

    execute '
        select
            array_upper(coef, 1)
        from '|| eval_r_table ||'
        where dataset = '''|| source_name ||'''
            and hetero = '|| hetero_flag
        into dim;
  
    grouping_dim := array_upper(grouping_vars, 1);

    grouping_str := 'array[';
    grouping_str1 := 'array[';
    for i in 1..grouping_dim loop
        grouping_str := grouping_str || grouping_vars[i];
        grouping_str1 := grouping_str1 || '''' || grouping_vars[i] || '''';
        if i != grouping_dim then
            grouping_str := grouping_str || ', ';
            grouping_str1 := grouping_str1 || ', ';
            
        else
            grouping_str := grouping_str || ']';
            grouping_str1 := grouping_str1 || ']::text[]';
        end if;
    end loop;
    
    execute '
        select madlib.linregr_train(
            ''madlibtestdata.'|| source_name ||''',
            '''|| out_table ||''',
            '''|| dependent_varname ||''',
            '''|| independent_varname ||''',
            '|| grouping_str1 ||',
            '|| hetero_flag ||')
    ';

        -- compare coef, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        grouping_str, grouping_str1, hetero_flag, 'coef', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;

    -- compare r2, one
    -- diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
    --                                    grouping_str, grouping_str1, hetero_flag, 'r2');
    -- if diff > thresh then
    --     execute 'drop table if exists '|| out_table;
    --     return 0;
    -- end if;

    -- compare std_err, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        grouping_str, grouping_str1, hetero_flag,
                                        'std_err', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    -- compare t_stats, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        grouping_str, grouping_str1, hetero_flag, 't_stats', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    -- compare p_values, vec
    diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
                                        grouping_str, grouping_str1, hetero_flag, 'p_values', dim);
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    -- condition_no, one
    diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
                                        grouping_str, grouping_str1, hetero_flag, 'condition_no');
    if diff > thresh then
        execute 'drop table if exists '|| out_table;
        return 0;
    end if;
    
    if hetero_option then
        -- compare test_statistic, one
        diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
                                           grouping_str, grouping_str1, hetero_flag, 'bp_stats');
        if diff > 1e-2 then
            execute 'drop table if exists '|| out_table;
            return 0;
        end if;
        
        -- compare test_p_value, one
        diff := madlibtestdata.compare_one(out_table, eval_r_table, source_name,
                                           grouping_str, grouping_str1, hetero_flag, 'bp_p_value');
        if diff > 1e-2 then
            execute 'drop table if exists '|| out_table;
            return 0;
        end if;
        
        -- -- compare robust_std_err, vec
        -- diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
        --                                     grouping_str, hetero_flag,
        --                                     'corrected_std_err', dim);
        -- if diff > thresh then
        --     execute 'drop table if exists '|| out_table;
        --     return 0;
        -- end if;
    
        -- -- comprae robust_t_stats, vec
        -- diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
        --                                     grouping_str, hetero_flag,
        --                                     'corrected_t_stats', dim);
        -- if diff > thresh then
        --     execute 'drop table if exists '|| out_table;
        --     return 0;
        -- end if;
    
        -- -- compare robust_p_values, vec
        -- diff := madlibtestdata.compare_array(out_table, eval_r_table, source_name,
        --                                     grouping_str, hetero_flag,
        --                                     'corrected_p_values', dim);
        -- if diff > thresh then
        --     execute 'drop table if exists '|| out_table;
        --     return 0;
        -- end if;
    end if;

    execute 'drop table if exists '|| out_table;
    return 1;
end;
$$ language plpgsql;
