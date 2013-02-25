
drop table if exists madlibtestdata.evaluation_logregr_train;

create table madlibtestdata.evaluation_logregr_train (
    eval_src            text,   -- 'R'
    dataset             text,   -- Name of data set
    grouping_cols       text,   -- String of grouping columns delimited by comma
    grouping_vals       text,   -- Values converted into a string
    coef                double precision[],
    log_likelihood      double precision,
    std_err             double precision[],
    z_stats             double precision[],
    p_values            double precision[],
    odds_ratios         double precision[],
    condition_no        double precision
);

alter table madlibtestdata.evaluation_logregr_train owner to madlibtester;

----------------------------------------------------------------------------


