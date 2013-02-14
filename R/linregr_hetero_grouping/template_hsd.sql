drop table if exists  madlibtestdata.evaluation_lin_hsd;
create table madlibtestdata.evaluation_lin_hsd (
    source          text,
    dataset         text,
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

alter table madlibtestdata.evaluation_lin_hsd owner to madlibtester;

