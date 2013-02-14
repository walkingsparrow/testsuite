source("01_linregr-logregr_cv.r")

## linear regression R result
lin.append.results <- function(datasets, fold = 10)
{
    con <- file("evaluation_general_cv_lin.sql", "a")
    for (i in seq_along(datasets))
    {
        name <- datasets[i]
        z <- system(paste("ls ~/workspace/testsuite/dataset/sql/", name, ".sql.gz", sep=""), ignore.stdout = TRUE, ignore.stderr = TRUE)
        if (z == 0)
        {
            system(paste("rm -rf ", name, ".*", sep=""))
            system(paste("cp ~/workspace/testsuite/dataset/sql/", name, ".sql.gz .", sep=""))
            system(paste("gunzip ", name, ".sql.gz", sep=""))
            system(paste("python sql2r.py ", name, ".sql ", name, ".txt", sep=""))
            ##
            dat <- read.csv(paste(name, ".txt", sep=""), header = FALSE)
            if (sum(is.na(dat)) > 0) next
            ##
            mm <- rep(0, 50)
            for (i in 1:50) {
                linregr.cv <- cv(lin.modelling, lin.prediction, lin.error, dat, -1, k = fold)
                mm[i] <- linregr.cv$metric
            }
            ##
            cat("insert into madlibtestdata.evaluation_general_cv_lin values\n", file = con)
            cat(paste("    ('R', '", name, "', ", fold, ",\n", sep=""), file = con)
            cat(paste("    ", mean(mm), ");\n\n", sep=""), file=con)
        }
    }
    close(con)
}

## datasets <- c("lin_Concrete_oi", "lin_Concrete_wi", "lin_auto_mpg_oi", "lin_auto_mpg_wi", "lin_communities_unnormalized_oi", "lin_communities_unnormalized_wi", "lin_communities_oi", "lin_communities_wi", "lin_flare_oi", "lin_flare_wi", "lin_forestfires_oi", "lin_forestfires_wi", "lin_housing_oi", "lin_housing_wi", "lin_imports_85_oi", "lin_imports_85_wi", "lin_machine_oi", "lin_machine_wi", "lin_o_ring_erosion_only_oi", "lin_o_ring_erosion_only_wi", "lin_o_ring_erosion_or_blowby_oi", "lin_o_ring_erosion_or_blowby_wi", "lin_parkinsons_updrs_oi", "lin_parkinsons_updrs_wi", "lin_servo_oi", "lin_servo_wi", "lin_slump_oi", "lin_slump_wi", "lin_winequality_red_oi", "lin_winequality_red_wi", "lin_winequality_white_oi", "lin_winequality_white_wi")

datasets <- c("lin_Concrete_wi", "lin_auto_mpg_wi", "lin_communities_wi", "lin_flare_wi", "lin_forestfires_wi", "lin_housing_wi", "lin_imports_85_wi", "lin_machine_wi", "lin_o_ring_erosion_only_wi", "lin_o_ring_erosion_or_blowby_wi", "lin_parkinsons_updrs_wi", "lin_servo_wi", "lin_slump_wi", "lin_winequality_red_wi", "lin_winequality_white_wi")

setwd("data/"); system("rm -rf evaluation_general_cv_lin.sql; cp template_lin.sql evaluation_general_cv_lin.sql"); setwd("..")
setwd("data/"); lin.append.results(datasets, fold = 10); setwd("..")
setwd("data/"); lin.append.results(datasets, fold = 20); setwd("..")

## ------------------------------------------------------------------------

## linear regression R result
log.append.results <- function(datasets, fold = 10)
{
    con <- file("evaluation_general_cv_log.sql", "a")
    for (i in seq_along(datasets))
    {
        name <- datasets[i]
        z <- system(paste("ls ~/workspace/testsuite/dataset/sql/", name, ".sql.gz", sep=""), ignore.stdout = TRUE, ignore.stderr = TRUE)
        if (z == 0)
        {
            system(paste("rm -rf ", name, ".*", sep=""))
            system(paste("cp ~/workspace/testsuite/dataset/sql/", name, ".sql.gz .", sep=""))
            system(paste("gunzip ", name, ".sql.gz", sep=""))
            system(paste("python sql2r.py ", name, ".sql ", name, ".txt", sep=""))
            ##
            dat <- read.csv(paste(name, ".txt", sep=""), header = FALSE)
            if (sum(is.na(dat)) > 0) next
            ##
            mm <- rep(0, 50)
            for (i in 1:50) {
                logregr.cv <- cv(log.modelling, log.prediction, log.error, dat, -1, k = fold)
                mm[i] <- logregr.cv$metric
            }
            ##
            cat("insert into madlibtestdata.evaluation_general_cv_log values\n", file = con)
            cat(paste("    ('R', '", name, "', ", fold, ",\n", sep=""), file = con)
            cat(paste("    ", mean(mm), ");\n\n", sep=""), file=con)
        }
    }
    close(con)
}

## datasets <- c()

datasets <- c("log_breast_cancer_wisconsin", "log_ticdata2000", "log_wdbc", "log_wpbc")


setwd("data/"); system("rm -rf evaluation_general_cv_log.sql; cp template_log.sql evaluation_general_cv_log.sql"); setwd("..")
setwd("data/"); log.append.results(datasets, fold = 10); setwd("..")
setwd("data/"); log.append.results(datasets, fold = 20); setwd("..")

