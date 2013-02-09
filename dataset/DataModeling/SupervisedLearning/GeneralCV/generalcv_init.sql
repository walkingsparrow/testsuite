
create or replace function madlibtestdata.generalcv_linregr (
    dataset_name    varchar,
    col_ind_var     varchar,
    col_dep_var     varchar,
    fold            integer,
    tbl_r_rst       varchar     -- R's result
) returns double precision as $$
declare
    tbl_output      varchar := madlib.__cv_unique_string();
    cv_error        double precision;
    cv_error_std    double precision;
    r_error         double precision;
    compare_rst     double precision;
begin
    execute '
        select madlib.cross_validation_general(
            $_valString$madlib.cv_linregr_train$_valString$,
            $_valString${%data%, '|| col_ind_var ||', '|| col_dep_var ||', %model%}$_valString$::varchar[],
            $_valString${varchar, varchar, varchar, varchar}$_valString$::varchar[],
            NULL::varchar,
            NULL,
            --
            $_valString$madlib.cv_linregr_predict$_valString$,
            $_valString${%model%, %data%, '|| col_ind_var ||', %id%, %prediction%}$_valString$::varchar[],
            $_valString${varchar, varchar, varchar, varchar, varchar}$_valString$::varchar[],
            --
            $_valString$madlib.mse_error$_valString$,
            $_valString${%prediction%, %data%, %id%, '|| col_dep_var ||', %error%}$_valString$::varchar[],
            $_valString${varchar, varchar, varchar, varchar, varchar}$_valString$::varchar[],
            --
            $_valString$madlibtestdata.'|| dataset_name ||'$_valString$,
            NULL,
            False,
            --
            $_valString$madlibtestdata.'|| tbl_output ||'$_valString$,
            $_valString${'|| col_ind_var ||', '|| col_dep_var ||'}$_valString$::varchar[],
            '|| fold ||'            
        )';

    execute 'select mean_squared_error_avg from madlibtestdata.'|| tbl_output into cv_error;
    execute 'select mean_squared_error_stddev from madlibtestdata.'|| tbl_output into cv_error_std;
    execute 'select error from '|| tbl_r_rst ||'
            where fold = '|| fold ||' and dataset = $_valString$'|| dataset_name ||'$_valString$'
            into r_error;

    if r_error >= cv_error - cv_error_std and r_error <= cv_error + cv_error_std then
        compare_rst := 1;
    else
        compare_rst := 0;
    end if;

    execute 'drop table if exists madlibtestdata.'|| tbl_output;

    return compare_rst;
end;
$$ language plpgsql;

alter function madlibtestdata.generalcv_linregr(varchar, varchar, varchar, integer, varchar) owner to madlibtester;

------------------------------------------------------------------------

create or replace function madlibtestdata.generalcv_logregr (
    dataset_name    varchar,
    col_ind_var     varchar,
    col_dep_var     varchar,
    fold            integer,
    tbl_r_rst       varchar     -- R's result
) returns double precision as $$
declare
    tbl_output      varchar := madlib.__cv_unique_string();
    cv_error        double precision;
    cv_error_std    double precision;
    r_error         double precision;
    compare_rst     double precision;
begin
    execute '
        select madlib.cross_validation_general(
            $_valString$madlib.cv_logregr_train$_valString$,
            $_valString${%data%, '|| col_ind_var ||', '|| col_dep_var ||', %model%, 100, cg, 1e-8}$_valString$::varchar[],
            $_valString${varchar, varchar, varchar, varchar, integer, varchar, double precision}$_valString$::varchar[],
            NULL::varchar,
            NULL,
            --
            $_valString$madlib.cv_logregr_predict$_valString$,
            $_valString${%model%, %data%, '|| col_ind_var ||', %id%, %prediction%}$_valString$::varchar[],
            $_valString${varchar, varchar, varchar, varchar, varchar}$_valString$::varchar[],
            --
            $_valString$madlib.cv_logregr_accuracy$_valString$,
            $_valString${%prediction%, %data%, %id%, '|| col_dep_var ||', %error%}$_valString$::varchar[],
            $_valString${varchar, varchar, varchar, varchar, varchar}$_valString$::varchar[],
            --
            $_valString$madlibtestdata.'|| dataset_name ||'$_valString$,
            NULL,
            False,
            --
            $_valString$madlibtestdata.'|| tbl_output ||'$_valString$,
            $_valString${'|| col_ind_var ||', '|| col_dep_var ||'}$_valString$::varchar[],
            '|| fold ||'
        )';

    execute 'select accuracy_avg from madlibtestdata.'|| tbl_output into cv_error;
    execute 'select accuracy_stddev from madlibtestdata.'|| tbl_output into cv_error_std;
    execute 'select error from '|| tbl_r_rst ||'
            where fold = '|| fold ||' and dataset = $_valString$'|| dataset_name ||'$_valString$'
            into r_error;

    if r_error >= cv_error - cv_error_std and r_error <= cv_error + cv_error_std then
        compare_rst := 1;
    else
        compare_rst := 0;
    end if;

    execute 'drop table if exists madlibtestdata.'|| tbl_output;

    return compare_rst;
end;
$$ language plpgsql;

alter function madlibtestdata.generalcv_logregr(varchar, varchar, varchar, integer, varchar) owner to madlibtester;
