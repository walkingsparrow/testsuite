
source("logregr_newapi_baseline.R")

## ------------------------------------------------------------------------

datasets <- c("log_breast_cancer_wisconsin", "log_ticdata2000", "log_wdbc", "log_wpbc")

system("rm -rf evaluation_logregr_train.sql; cp template.sql evaluation_logregr_train.sql")

for (data.set in datasets) eval.logregr.append.results(data.set = data.set)

eval.logregr.append.results(data.set = "log_ornstein",
                            target = "interlocks",
                            predictors = "~ . -1 - nation",
                            grouping.cols = c("nation"))


eval.logregr.append.results(data.set = "log_breast_cancer_wisconsin",
                            target = "y",
                            predictors = "~ . - 1 - x2 - x1",
                            grouping.cols = c("x1", "x2"))

eval.logregr.append.results(data.set = "log_ticdata2000",
                            target = "y",
                            predictors = "~ . - 1 - x8",
                            grouping.cols = c("x8"))

## ------------------------------------------------------------------------

dat <- prepare.dataset("log_ornstein", sql.path = "~/workspace/testsuite/dataset/sql/", data.path = "../data/", py.path = "../utils/")

fit <- glm(interlocks ~ . - nation, family = binomial, data = dat[dat$nation == 4,])

