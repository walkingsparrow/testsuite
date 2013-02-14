
## generate grouping results

library(car)
library(lmtest)
library(RPostgreSQL)
source("utils.r")

data(Ornstein)

orn <- Ornstein
orn$assets <- as.numeric(orn$assets)
orn$sector <- as.numeric(orn$sector)
orn$nation <- as.numeric(orn$nation)
orn$interlocks <- as.numeric(orn$interlocks)

table(orn$sector)

table(orn$nation)

table(orn[c("sector", "nation")])

## group by nation only
v <- table(orn$nation)
hsd <- FALSE
##
con <- file("evaluation_lin_grouping.sql", "a")
dat <- orn
##
for (nation in as.numeric(names(v)))
{
    fit <- lm(interlocks ~ assets + sector, data = dat[dat$nation == nation,])
    fit.sum <- summary(fit)
    l <- length(fit$coefficients)
    if (hsd) {
        bp <- bptest(fit)
        cf <- coeftest(fit, vcov = hccm(fit, type = "hc0"))
        ## bp <- list(statistic = 0, p.value = 0.9)
        ## cf <- rep(0, 4*l)
        hsd.flag <- "True"
    } else {
        hsd.flag <- "False"
    }
    kp <- kappa(fit, exact = TRUE)
    ##
    output.head("madlibtestdata.evaluation_lin_grouping", con)
    output.one("R", "text", ",\n", con)
    output.one("lin_ornstein", "text", ",\n", con)
    output.vec(c("nation"), "text[]", ",\n", con)
    output.vec(c(nation), "integer[]", ",\n", con)
    output.one(hsd.flag, "boolean", ",\n", con)
    output.vec(fit$coefficients, "double precision[]", ",\n", con)
    output.one(fit.sum$r.square, "double precision", ",\n", con)
    output.vec(fit.sum$coefficients[(1:l) + l], "double precision[]", ",\n", con)
    output.vec(fit.sum$coefficients[(1:l) + 2*l], "double precision[]", ",\n", con)
    output.vec(fit.sum$coefficients[(1:l) + 3*l], "double precision[]", ",\n", con)
    output.one(kp, "double precision", ",\n", con)
    if (hsd) {
        output.one(bp$statistic, "double precision", ",\n", con)
        output.one(bp$p.value, "double precision", ",\n", con)
        output.vec(cf[(1:l) + l], "double precision[]", ",\n", con)
        output.vec(cf[(1:l) + 2*l], "double precision[]", ",\n",  con)
        output.vec(cf[(1:l) + 3*l], "double precision[]", ");\n\n",  con)
    } else {
        cat("    Null, Null,\n", file = con)
        cat("    Null, Null, Null);\n\n", file = con)
    }
}
close(con)

## ------------------------------------------------------------------------

## group by nation & sector
v <- table(orn$nation, orn$sector)
hsd <- FALSE
##
con <- file("evaluation_lin_grouping.sql", "a")
dat <- orn
##
for (nation in as.numeric(rownames(v)))
{
    for (sector in as.numeric(colnames(v)))
    {
        tdat <- dat[dat$nation == nation & dat$sector == sector,]
        if (dim(tdat)[1] != 0)
        {
            fit <- lm(interlocks ~ assets, data = tdat)
            fit.sum <- summary(fit)
            l <- length(fit$coefficients)
            if (hsd) {
                bp <- bptest(fit)
                cf <- coeftest(fit, vcov = hccm(fit, type = "hc0"))
                ## bp <- list(statistic = 0, p.value = 0.9)
                ## cf <- rep(0, 4*l)
                hsd.flag <- "True"
            } else {
                hsd.flag <- "False"
            }
            kp <- kappa(fit, exact = TRUE)
            ##
            output.head("madlibtestdata.evaluation_lin_grouping", con)
            output.one("R", "text", ",\n", con)
            output.one("lin_ornstein", "text", ",\n", con)
            output.vec(c("sector", "nation"), "text[]", ",\n", con)
            output.vec(c(sector, nation), "integer[]", ",\n", con)
            output.one(hsd.flag, "boolean", ",\n", con)
            output.vec(fit$coefficients, "double precision[]", ",\n", con)
            output.one(fit.sum$r.square, "double precision", ",\n", con)
            output.vec(fit.sum$coefficients[(1:l) + l], "double precision[]", ",\n", con)
            output.vec(fit.sum$coefficients[(1:l) + 2*l], "double precision[]", ",\n", con)
            output.vec(fit.sum$coefficients[(1:l) + 3*l], "double precision[]", ",\n", con)
            output.one(kp, "double precision", ",\n", con)
            if (hsd) {
                output.one(bp$statistic, "double precision", ",\n", con)
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
}
close(con)
    
