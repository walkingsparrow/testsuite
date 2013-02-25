
output.vec <- function(vec, type = "double precision[]", ending = ",", con)
{
    l <- length(vec)
    cat("    '{", file = con)
    for (k in 1:l) {
        if (is.null(vec[k]) || is.infinite(vec[k]) || is.na(vec[k]))
            cat("Null", file = con)
        else
            cat(vec[k], file = con)
        if (k != l)
            cat(", ", file = con)
        else
            cat(paste("}'::", type, ending, sep = ""), file = con)
    }
}

## ------------------------------------------------------------------------

output.one <- function(one, type = "double precision", ending = ",", con)
{
    if (is.null(one) || is.infinite(one) || is.na(one)) {
        cat(paste("    Null::", type, ending, sep = ""), file = con)
    } else {
        cat(paste("    '", one, "'::", type, ending, sep = ""), file = con)
    }
}

## ------------------------------------------------------------------------

output.head <- function(table, con)
{
    cat(paste("insert into ", table, " values (\n", sep = ""), file = con)
}

## ------------------------------------------------------------------------

prepare.dataset <- function(dataset, sql.path = "~/workspace/testsuite/dataset/sql/",
                            data.path = "data/", py.path = ".")
{
    w1 <-  system(paste("ls -ld ", sql.path, sep = ""),
                  ignore.stdout = TRUE, ignore.stderr = TRUE)
    w2 <-  system(paste("ls -ld ", data.path, sep = ""),
                  ignore.stdout = TRUE, ignore.stderr = TRUE)
    if (w1 != 0 || w2 != 0)
        stop("Either sql.gz path or data path does not exist!")
    ##
    z <- system(paste("ls ", sql.path, "/", dataset, ".sql.gz", sep = ""),
                ignore.stdout = TRUE, ignore.stderr = TRUE)
    if (z != 0) return (NULL)
    z1 <- system(paste("ls ", data.path, "/", dataset, ".sql", sep = ""),
                 ignore.stdout = TRUE, ignore.stderr = TRUE)
    z2 <- system(paste("ls ", data.path, "/", dataset, ".txt", sep = ""),
                 ignore.stdout = TRUE, ignore.stderr = TRUE)
    if (z1 != 0 || z2 != 0)
    {
        system(paste("rm -rf ", data.path, "/", dataset, ".*", sep=""))
        system(paste("cp ", sql.path, "/", dataset, ".sql.gz ", data.path, sep=""))
        system(paste("gunzip ", data.path, "/", dataset, ".sql.gz", sep=""))
        system(paste("python ", py.path, "/sql2r.py ", data.path, "/", dataset, ".sql ", data.path, "/", dataset, ".txt", sep=""))
    }
    ##
    dat <- read.csv(paste(data.path, "/", dataset, ".txt", sep = ""))
    return (dat)
}

## ------------------------------------------------------------------------

analyze.var <- function(var)
{
    
}
