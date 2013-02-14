drop table if exists  madlibtestdata.evaluation_ridge_regression;
create table madlibtestdata.evaluation_ridge_regression (
    source          text,
    dataset         text,
    lambda          double precision,
    normalization   boolean,
    coefficients    double precision[],
    intercept       double precision,
    log_likelihood  double precision
);

alter table madlibtestdata.evaluation_ridge_regression owner to madlibtester;

