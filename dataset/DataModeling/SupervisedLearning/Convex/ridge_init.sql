
create or replace function madlibtestdata.ridge_precision (
    tbl_source      varchar,
    col_ind_var     varchar,
    col_dep_var     varchar,
    lambda_value    double precision,
    normalization   boolean,
    tbl_r_result    varchar
) returns double precision as $$
declare
    rst double precision;
    tbl_output varchar := madlib.__cv_unique_string();
begin
    execute 'select madlib.ridge_newton_train(
        $_valString$madlibtestdata.'|| tbl_source ||'$_valString$,
        $_valString$'|| col_ind_var ||'$_valString$,
        $_valString$'|| col_dep_var ||'$_valString$,
        $_valString$madlibtestdata.'|| tbl_output ||'$_valString$,
        '|| lambda_value ||',
        '|| normalization ||'
    )';

    execute 'select abs(t1.log_likelihood - t2.log_likelihood)
    from
        madlibtestdata.'|| tbl_output ||' t1,
        '|| tbl_r_result ||' as t2
    where '|| lambda_value ||' = t2.lambda
    and t1.normalization = t2.normalization
    and t2.dataset = $_valString$'|| tbl_source ||'$_valString$'
    into rst;

    execute 'drop table if exists madlibtestdata.'|| tbl_output;
    return rst;
end;
$$ language plpgsql;

alter function madlibtestdata.ridge_precision(varchar, varchar, varchar, double precision, boolean, varchar) owner to madlibtester;

-- \i ./evaluation_ridge_regression.sql
