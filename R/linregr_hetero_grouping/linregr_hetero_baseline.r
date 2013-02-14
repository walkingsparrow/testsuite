
library(lmtest)
library(car)

source("utils.r")

## linear regression R result
hsd.append.results <- function(datasets, hsd = TRUE, 
                               sql.path = "~/workspace/testsuite/dataset/sql/",
                               data.path = "data/", py.path = ".")
{
    con <- file("evaluation_lin_hsd_dummy.sql", "a")
    for (i in seq_along(datasets))
    {
        name <- datasets[i]
        dat <- prepare.dataset(name, sql.path = sql.path,
                               data.path = data.path,
                               py.path = py.path)
        if (! is.null(dat))
        {
            if (sum(is.na(dat)) > 0) next
            ##
            fit <- lm(y ~ . - 1, data = dat)
            fit.sum <- summary(fit)
            l <- length(fit$coefficients)
            if (hsd) {
                ## bp <- bptest(fit)
                ## cf <- coeftest(fit, vcov = hccm(fit, type = "hc0"))
                bp <- list(statistic = 0, p.value = 0.9)
                cf <- rep(0, 4*l)
                hsd.flag <- "True"
            } else {
                hsd.flag <- "False"
            }
            kp <- kappa(fit, exact = TRUE)
            ##
            output.head("madlibtestdata.evaluation_lin_hsd", con)
            output.one("R", "text", ", ", con)
            output.one(name, "text", ", ", con)
            output.one(hsd.flag, "boolean", ",\n", con)
            output.vec(fit$coefficients, "double precision[]", ",\n", con)
            output.one(fit.sum$r.square, "double precision", ",\n", con)
            output.vec(fit.sum$coefficients[(1:l) + l], "double precision[]", ",\n", con)
            output.vec(fit.sum$coefficients[(1:l) + 2*l], "double precision[]", ",\n", con)
            output.vec(fit.sum$coefficients[(1:l) + 3*l], "double precision[]", ",\n", con)
            output.one(kp, "double precision", ",\n", con)
            if (hsd) {
                output.one(bp$statistic, "double precision", ", ", con)
                output.one(bp$p.value, "double precision", ",\n", con)
                output.vec(cf[(1:l) + l], "double precision[]", ",\n", con)
                output.vec(cf[(1:l) + 2*l], "double precision[]", ",\n",  con)
                output.vec(cf[(1:l) + 3*l], "double precision[]", ");\n\n",  con)
            } else {
                cat("    Null, Null,\n", file = con)
                cat("    Null, Null, Null);\n\n", file = con)
            }
        }
    }
    close(con)
}

## datasets <- c("lin_Concrete_oi", "lin_Concrete_wi", "lin_auto_mpg_oi", "lin_auto_mpg_wi", "lin_communities_unnormalized_oi", "lin_communities_unnormalized_wi", "lin_communities_oi", "lin_communities_wi", "lin_flare_oi", "lin_flare_wi", "lin_forestfires_oi", "lin_forestfires_wi", "lin_housing_oi", "lin_housing_wi", "lin_imports_85_oi", "lin_imports_85_wi", "lin_machine_oi", "lin_machine_wi", "lin_o_ring_erosion_only_oi", "lin_o_ring_erosion_only_wi", "lin_o_ring_erosion_or_blowby_oi", "lin_o_ring_erosion_or_blowby_wi", "lin_parkinsons_updrs_oi", "lin_parkinsons_updrs_wi", "lin_servo_oi", "lin_servo_wi", "lin_slump_oi", "lin_slump_wi", "lin_winequality_red_oi", "lin_winequality_red_wi", "lin_winequality_white_oi", "lin_winequality_white_wi")

## datasets <- c("lin_Concrete_wi", "lin_auto_mpg_wi", "lin_communities_wi", "lin_flare_wi", "lin_forestfires_wi", "lin_housing_wi", "lin_imports_85_wi", "lin_machine_wi", "lin_o_ring_erosion_only_wi", "lin_o_ring_erosion_or_blowby_wi", "lin_parkinsons_updrs_wi", "lin_servo_wi", "lin_slump_wi", "lin_winequality_red_wi", "lin_winequality_white_wi")

datasets <- c("lin_auto_mpg_wi", "lin_auto_mpg_wi", "lin_communities_wi", "lin_flare_wi", "lin_forestfires_wi", "lin_housing_wi", "lin_imports_85_wi", "lin_machine_wi", "lin_parkinsons_updrs_wi", "lin_servo_wi", "lin_slump_wi", "lin_winequality_red_wi", "lin_winequality_white_wi", "lin_ornstein_wi", "lin_auto_mpg_oi", "lin_auto_mpg_oi", "lin_communities_oi", "lin_flare_oi", "lin_forestfires_oi", "lin_housing_oi", "lin_imports_85_oi", "lin_machine_oi", "lin_parkinsons_updrs_oi", "lin_servo_oi", "lin_slump_oi", "lin_winequality_red_oi", "lin_winequality_white_oi", "lin_ornstein_oi")

system("rm -rf evaluation_lin_hsd_dummy.sql; cp template_hsd.sql evaluation_lin_hsd_dummy.sql"); 
hsd.append.results(datasets, hsd = TRUE);
hsd.append.results(datasets, hsd = FALSE);

