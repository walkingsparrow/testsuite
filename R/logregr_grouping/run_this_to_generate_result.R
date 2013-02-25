
source("logregr_newapi_baseline.R")

## ------------------------------------------------------------------------

datasets <- c("log_breast_cancer_wisconsin", "log_ticdata2000", "log_wdbc", "log_wpbc")

system("rm -rf evaluation_logregr_train.sql; cp template.sql evaluation_logregr_train.sql")

for (data.set in datasets) eval.logregr.append.results(data.set = data.set)

## eval.logregr.append.results(data.set = "log_breast_cancer_wisconsin",
##                             predictors = "~ . - 1 - x2 - x1",
##                             grouping.cols = c("x1", "x2"))
