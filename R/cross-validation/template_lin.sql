drop table if exists  madlibtestdata.evaluation_general_cv_lin;
create table madlibtestdata.evaluation_general_cv_lin (
    source          text,
    dataset         text,
    fold            integer,
    error           double precision
);

alter table madlibtestdata.evaluation_general_cv_lin owner to madlibtester;

