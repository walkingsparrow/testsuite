drop table if exists  madlibtestdata.evaluation_general_cv_log;
create table madlibtestdata.evaluation_general_cv_log (
    source          text,
    dataset         text,
    fold            integer,
    error           double precision
);

alter table madlibtestdata.evaluation_general_cv_log owner to madlibtester;

