### Cross Validation

### User needs to provide
### (1) modelling function: modelling(data, explore) returns model,
### where explore is the parameter to CV
### (2) prediction function: predict(model, data) returns prediction
### (3) error function: error(pred, actual)
### All these functions are wrapped so that no parameters are exposed

### explores has all explore values
cv <- function (modelling, prediction, metric, data, explores, k = 10, loop.inside = FALSE)
{
    n <- nrow(data)
    idx <- sample(1:n, n)
    chunks <- split(idx, ceiling(seq_along(idx) / (n/k)))
    ##
    rst <- numeric(0)
    for (i in 1:k)
    {
        valid.idx <- chunks[[i]]
        train.idx <- setdiff(idx, valid.idx)
        valid.data <- data[valid.idx,]
        train.data <- data[train.idx,]
        ##
        if (!loop.inside)
        {
            for (explore in explores)
            {
                model <- modelling(train.data, explore)
                pred <- prediction(model, valid.data)
                error <- metric(pred, valid.data)
                rst <- rbind(rst, c(explore, error))
            }
        }
        else
        { # loop in the three functions
            model <- modelling(train.data, explores)
            pred <- prediction(model, valid.data, explores)
            error <- metric(pred, valid.data)
            rst <- rbind(rst, cbind(explores, error))
        }
    }
    ##
    colnames(rst) <- c("param", "metric")
    rst <- as.data.frame(rst)
    avg <- by(rst$metric, rst$param, mean)
    std <- by(rst$metric, rst$param, sd)
    vals <- as.numeric(names(avg))
    f.rst <- numeric(0)
    for (i in seq_along(vals))
    {
        f.rst <- rbind(f.rst, c(vals[i], avg[[i]], std[[i]]))
    }
    colnames(f.rst) <- c("param", "metric", "metric.std")
    f.rst <- as.data.frame(f.rst)
    class(f.rst) <- c("cv.rst", "data.frame")
    return (f.rst)
}

plot.cv.rst <- function(f, ...)
{
    plot(f$param, f$metric, xlab = "params", ylab = "metric", ylim = range(f$metric-f$metric.std, f$metric+f$metric.std), type = "n")
    ##error.bars(f$param, f$metric+f$metric.std, f$metric-f$metric.std, width = 0.01, col = "darkgrey")
    points(f$param, f$metric, pch = 20, col = "red")
    invisible()
}
