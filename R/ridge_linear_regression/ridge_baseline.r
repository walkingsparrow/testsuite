library(MASS)
library(ridge)

to.str <- function(beta)
{
    rst <- "array["
    for (i in seq_along(beta))
    {
        rst <- paste(rst, beta[i], sep = "")
        if (i != length(beta))
            rst <- paste(rst, ", ", sep = "")
    }
    rst <- paste(rst, "]", sep = "")
    return (rst)
}

log.likelihood <- function(x, y, coef, a0, lambda, scaling = FALSE)
{
    s <- 0
    for (i in seq(length(y)))
    {
        t <- sum(coef * x[i,]) + a0 - y[i]
        s <- s + 0.5 * t^2
    }
    s <- s / length(y)
    if (!scaling)
    {
        s <- s + 0.5 * lambda * sum(coef * coef)
    }
    else
    {
        xsd <- apply(x, 2, sd) * sqrt(1 - 1./length(y))
        s <- s + 0.5 * lambda * sum((coef * xsd)^2)
    }
    ##
    return (-s)
}

append.results <- function(lambda, datasets)
{
    con <- file("evaluation_ridge_regression.sql", "a")
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
            x <- as.matrix(dat[,-dim(dat)[2]])
            y <- as.vector(dat[,dim(dat)[2]])
            sf <- sd(y) * sqrt(1 - 1./length(y))
            ##
            if (lambda == 0)
            {
                fit <- lm(formula(paste("V", dim(dat)[2], " ~ .", sep = "")), data = dat)
                cfs <- fit$coefficients
                cfs[is.na(cfs)] <- 0
                coefs <- cfs[-1]
                a0 <- cfs[1]
                ##
                cat("insert into madlibtestdata.evaluation_ridge_regression values\n", file = con)
                cat(paste("    ('R', '", name, "', ", lambda, ", True,\n", sep=""), file = con)
                cat(paste("    ", to.str(coefs), "::double precision[],\n", sep=""), file=con)
                cat(paste("    ", a0, ",\n", sep=""), file=con)
                cat(paste("    ", log.likelihood(x, y, coefs, a0, lambda, TRUE), ");\n\n", sep=""), file=con)
                ##
                cat("insert into madlibtestdata.evaluation_ridge_regression values\n", file = con)
                cat(paste("    ('R', '", name, "', ", lambda, ", False,\n", sep=""), file = con)
                cat(paste("    ", to.str(coefs), "::double precision[],\n", sep=""), file=con)
                cat(paste("    ", a0, ",\n", sep=""), file=con)
                cat(paste("    ", log.likelihood(x, y, coefs, a0, lambda, FALSE), ");\n\n", sep=""), file=con)
            }
            else
            {
                xsd <- apply(x, 2, sd)
                dat1 <- dat[,c(xsd,1) != 0]
                target <- names(dat1)[dim(dat1)[2]]
                ##fit <- glmnet(x, y, alpha = 0, lambda = lambda * sf, standardize = FALSE)
                fit <- lm.ridge(formula(paste(target, "~ .")), data = dat1, lambda = lambda * length(y))
                coefs <- rep(0, dim(dat)[2]-1)
                coefs[xsd!=0] <- coef(fit)[-1]
                a0 <- coef(fit)[1]
                cat("insert into madlibtestdata.evaluation_ridge_regression values\n", file = con)
                cat(paste("    ('R', '", name, "', ", lambda, ", True,\n", sep=""), file = con)
                cat(paste("    ", to.str(coefs), "::double precision[],\n", sep=""), file=con)
                cat(paste("    ", a0, ",\n", sep=""), file=con)
                cat(paste("    ", log.likelihood(x, y, coefs, a0, lambda, TRUE), ");\n\n", sep=""), file=con)
                ##
                ## fit1 <- glmnet(x, y, alpha = 0, lambda = lambda * sf, standardize = TRUE)
                fit1 <- linearRidge(formula(paste(target, "~ .")), data = dat1, lambda = lambda * length(y), scaling = "none")
                coefs <- rep(0, dim(dat)[2]-1)
                coefs[xsd!=0] <- coef(fit1)[-1]
                a0 <- coef(fit1)[1]
                cat("insert into madlibtestdata.evaluation_ridge_regression values\n", file = con)
                cat(paste("    ('R', '", name, "', ", lambda, ", False,\n", sep=""), file = con)
                cat(paste("    ", to.str(coefs), "::double precision[],\n", sep=""), file=con)
                cat(paste("    ", a0, ",\n", sep=""), file=con)
                cat(paste("    ", log.likelihood(x, y, coefs, a0, lambda, FALSE), ");\n\n", sep=""), file=con)
            }
        }
    }
    close(con)
}

## ------------------------------------------------------------------------

datasets <- c("lin_Concrete_oi", "lin_Concrete_wi", "lin_auto_mpg_oi", "lin_auto_mpg_wi", "lin_communities_unnormalized_oi", "lin_communities_unnormalized_wi", "lin_communities_oi", "lin_communities_wi", "lin_flare_oi", "lin_flare_wi", "lin_forestfires_oi", "lin_forestfires_wi", "lin_housing_oi", "lin_housing_wi", "lin_imports_85_oi", "lin_imports_85_wi", "lin_machine_oi", "lin_machine_wi", "lin_o_ring_erosion_only_oi", "lin_o_ring_erosion_only_wi", "lin_o_ring_erosion_or_blowby_oi", "lin_o_ring_erosion_or_blowby_wi", "lin_parkinsons_updrs_oi", "lin_parkinsons_updrs_wi", "lin_servo_oi", "lin_servo_wi", "lin_slump_oi", "lin_slump_wi", "lin_winequality_red_oi", "lin_winequality_red_wi", "lin_winequality_white_oi", "lin_winequality_white_wi")

## datasets <- c("lin_auto_mpg_wi", "lin_communities_oi", "lin_winequality_red_wi", "lin_winequality_white_oi")

system("rm -rf evaluation_ridge_regression.sql; cp template.sql evaluation_ridge_regression.sql")
append.results(lambda = 0., datasets)
append.results(lambda = 0.1, datasets)
append.results(lambda = 0.6, datasets)
append.results(lambda = 1, datasets)

good.names <- character(0)
for (i in seq_along(datasets)) {
    tmp <- read.csv(paste(datasets[i],".txt",sep=""), header = FALSE)
    if (sum(is.na(tmp)) == 0)
        good.names <- c(good.names, datasets[i])
}





## ## ------------------------------------------------------------------------
## ## ------------------------------------------------------------------------
## ## ------------------------------------------------------------------------

name <- "lin_communities_unnormalized_wi"
system(paste("rm -rf ", name, ".*", sep=""))
system(paste("cp ~/workspace/testsuite/dataset/sql/", name, ".sql.gz .", sep=""))
system(paste("gunzip ", name, ".sql.gz", sep=""))
system(paste("python sql2r.py ", name, ".sql ", name, ".txt", sep=""))
##
dat <- read.csv(paste(name, ".txt", sep=""), header = FALSE)
sum(is.na(dat)) == 0
x <- as.matrix(dat[,-dim(dat)[2]])
y0 <- as.vector(dat[,dim(dat)[2]])
sdy <- sqrt(mean((y0 - mean(y0))^2))
y <- (y0 - mean(y0)) / sdy
sf <- sd(y) * sqrt(1 - 1./length(y))
##

fit <- glmnet(x, y0, alpha = 0, lambda = 0, standardize = TRUE)

as.vector(fit$beta)
fit$a0

log.likelihood(x, y0, as.vector(fit$beta) * sdy, fit$a0 * sdy + mean(y0), lambda, FALSE)

## dat1 <- dat
## dat1[,9] <- y

fl <- lm(V126 ~ ., data = dat)

as.vector(fl$coefficients)

lambda <- 0
xsd <- apply(x, 2, sd)
dat1 <- dat[,c(xsd,1) != 0]
target <- names(dat1)[dim(dat1)[2]]
fit <- lm.ridge(formula(paste(target, "~ .")), data = dat1, lambda = lambda * length(y))
coefs <- rep(0, dim(dat)[2]-1)
coefs[xsd!=0] <- coef(fit)[-1]
a0 <- coef(fit)[1]

coefs
a0

lambda = 1
fit1 <- linearRidge(formula(paste(target, "~ .")), data = dat1, lambda = lambda * length(y), scaling = "none")
coefs <- rep(0, dim(dat)[2]-1)
coefs[xsd!=0] <- coef(fit1)[-1]
a0 <- coef(fit1)[1]

coefs
a0

log.likelihood(x, y0, coefs, a0, lambda, FALSE)

## ------------------------------------------------------------------------

cf <- scan("temp.txt", sep = ",")

mean(y0)
sum(cf * colMeans(x))

xsd <- apply(x, 2, sd)
x1 <- x[,xsd != 0]

cf1 <- solve(t(x1) %*% x1) %*% (t(x1) %*% y0)

dat2 <- as.data.frame(cbind(x1, y0))

fl <- lm(y0 ~ ., data = dat2)

as.vector(fl$coefficients)
