
source("../utils/utils.r")

## cats is a list, each item is a vector of strings
str.combine <- function (cats)
{
    rst <- character(0)
    n <- length(cats)
    if (n > 1) {
        for (i in seq(length(cats[1][[1]]))) {
            pre <- str.combine(cats[2:n])
            rst <- c(rst, paste("\"", cats[1][[1]][i], "\", ", pre, sep = ""))
        }
    } else {
        for (i in seq(length(cats[1][[1]]))) {
            rst <- c(rst, paste("\"", cats[1][[1]][i], "\"", sep = ""))
        }
    }
    return (rst)
}

## ------------------------------------------------------------------------

## append R calculation result into the SQL table file
eval.logregr.append.results <- function (data.set, # data set name
                                         target = "y", # fitting target column
                                         predictors = "~ . - 1", # fitting formula
                                         grouping.cols = character(0), # a vector of strings
                                         not.xcols = grouping.cols, # x colums that are not predictors
                                        # also a vector of strings
                                        # not.xcols might not be the same as grouping.cols
                                         sql.path = "~/workspace/testsuite/dataset/sql/",
                                        # Where the original .gz data files are located
                                         data.path = "../data/",
                                        # where to unpack .gz file and store the temporary SQL data file
                                        # It is also the folder that the text data file
                                        # generated from these SQL data file will be stored
                                        # temporarily
                                         py.path = "../utils/"
                                        # location of the Python script that extracts data
                                        # from SQL data file and converts into text file that
                                        # R can read without error
                                         )
{
    ## copy the original .gz data file, extract it, convert it into R compatible
    ## format, and then read in
    dat <- prepare.dataset(data.set, sql.path = sql.path, data.path = data.path,
                           py.path = py.path)
    ##
    if (! is.null(dat))
    {
        ## The independent variable columns
        xcols <- setdiff(names(dat), c(target, not.xcols))
        n <- length(xcols)
        grouping.str <- paste("\"", grouping.cols, "\"", collapse = ", ", sep = "")
        ##
        conn <- file("evaluation_logregr_train.sql", "a")
        ##
        if (length(grouping.cols) != 0) {
            ## grouping the original data
            grps <- by(dat, dat[grouping.cols], rbind)
            ## extract grouping column values
            cats <- attr(grps, "dimnames")
            ## for each combination of grouping column values, form a string
            grouping.vals <- str.combine(cats) 
        } else {
            grps <- list(dat = dat)
            grouping.vals <- ""
        }
        ##
        for (gval in grouping.vals)
        {
            ## extract the data for a specific combination of grouping column values
            dat.use <- eval(parse(text = paste("grps[", gval, "][[1]]", sep = "")))
            ##
            ## All the previous parts should be refactored out later, and can be
            ## utilized in other modules that support grouping
            ## The following computation & output parts are just module-specific
            ##
            ## Actual computation part
            fit <- glm(formula(paste(target,  predictors)), family = binomial, data = dat.use,
                       control = list(epsilon = 1e-8, maxit = 2000))
            ##
            X <- as.matrix(dat.use[xcols])
            sigma <- colSums(t(X) * fit$coefficients)
            a <- diag((1/(1 + exp(-sigma))) * (1/(1+exp(sigma))))
            A <- t(X) %*% a %*% X
            ##
            condition.no <- kappa(A, exact = TRUE)
            log.likelihood <- - sum(log1p(exp((-1)^(as.integer(dat.use$y)-1)*sigma)))
            ##
            smry <- summary(fit)$coefficients
            coef <- smry[seq(n)]
            std.err <- smry[n + seq(n)]
            z.stats <- smry[2*n + seq(n)]
            p.value <- smry[3*n + seq(n)]
            odds.ratios <- exp(coef)
            ##
            ## Output the result to SQL table
            output.head("madlibtestdata.evaluation_logregr_train", conn)
            output.one("R", "text", ",\n", conn)
            output.one(data.set, "text", ",\n", conn)
            if (gval == "") {
                output.one(NULL, "text", ",\n", conn)
                output.one(NULL, "text", ",\n", conn)
            } else {
                output.one(grouping.str, "text", ",\n", conn)
                output.one(gval, "text", ",\n", conn)
            }
            output.vec(coef, "double precision[]", ",\n", conn)
            output.one(log.likelihood, "double precision", ",\n", conn)
            output.vec(std.err, "double precision[]", ",\n", conn)
            output.vec(z.stats, "double precision[]", ",\n", conn)
            output.vec(p.value, "double precision[]", ",\n", conn)
            output.vec(odds.ratios, "double precision[]", ",\n", conn)
            output.one(condition.no, "double precision", ");\n\n", conn)
        }
        ##
        close(conn)
    }
}

## ------------------------------------------------------------------------

## datasets <- c("log_breast_cancer_wisconsin", "log_ticdata2000", "log_wdbc", "log_wpbc")

## system("rm -rf evaluation_logregr_train.sql; cp template.sql evaluation_logregr_train.sql")

## eval.logregr.append.results(data.set = "log_breast_cancer_wisconsin",
##                             predictors = "~ . - 1 - x2 - x1",
##                             grouping.cols = c("x1", "x2"),
##                             not.xcols = c("x1", "x2"))

