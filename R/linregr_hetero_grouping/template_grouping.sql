drop table if exists  madlibtestdata.evaluation_lin_grouping;
create table madlibtestdata.evaluation_lin_grouping (
    source          text,
    dataset         text,
    grouping        text[],
    grouping_vals   integer[],
    hetero          boolean,
    coef            double precision[],
    r2              double precision,
    std_err         double precision[],
    t_stats         double precision[],
    p_values        double precision[],
    condition_no    double precision,
    bp_stats  double precision,
    bp_p_value    double precision,
    corrected_std_err  double precision[],
    corrected_t_stats  double precision[],
    corrected_p_values double precision[]
);

alter table madlibtestdata.evaluation_lin_grouping owner to madlibtester;

