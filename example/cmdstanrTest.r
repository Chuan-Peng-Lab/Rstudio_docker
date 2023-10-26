# test cmdstanr, from: https://mc-stan.org/cmdstanr/articles/cmdstanr.html
# load the cmdstanr and bayesplot
library(cmdstanr)
library(bayesplot)

# get model file from cmdstanr package
file <- file.path(cmdstan_path(), "examples", "bernoulli", "bernoulli.stan")
mod <- cmdstan_model(file)

# check the model code
mod$print()

# check model file
mod$exe_file()

# create a data list
# names correspond to the data block in the Stan program
data_list <- list(N = 10, y = c(0,1,0,0,0,0,0,0,0,1))

# fit the model
fit <- mod$sample(
  data = data_list,
  seed = 123,
  chains = 4,
  parallel_chains = 4,
  refresh = 500 # print update every 500 iters
)

# get model summary
fit$summary()
fit$summary(variables = c("theta", "lp__"), "mean", "sd")

# use a formula to summarize arbitrary functions, e.g. Pr(theta <= 0.5)
fit$summary("theta", pr_lt_half = ~ mean(. <= 0.5))

# summarise all variables with default and additional summary measures
fit$summary(
  variables = NULL,
  posterior::default_summary_measures(),
  extra_quantiles = ~posterior::quantile2(., probs = c(.0275, .975))
)

# plot histogram of theta
mcmc_hist(fit$draws("theta"))

# this is a draws_array object from the posterior package
str(fit$sampler_diagnostics())

# test brms, from https://github.com/paul-buerkner/brms
library(brms)
library(tidyverse)

# fit a testing model from brms, use rstan as the backend
fit1 <- brm(count ~ zAge + zBase * Trt + (1|patient), 
            cores = parallel::detectCores(), # detect how many cpus/threads are available
            chains = 4,
            data = epilepsy, family = poisson())

# or fit a testing model from brms, use cmdstanr as the backend
# fit1 <- brm(count ~ zAge + zBase * Trt + (1|patient), 
#            cores = parallel::detectCores(), # detect how many cpus/threads are available
#            chains = 4,  
#            backend = 'cmdstanr',
#            data = epilepsy, family = poisson())

# check the summary of the model
summary(fit1)

#To visually investigate the chains as well as the posterior distributions
plot(fit1, variable = c("b_Trt1", "b_zBase"))

fit2 <- brm(count ~ zAge + zBase * Trt + (1|patient) + (1|obs),
            data = epilepsy, family = poisson())

loo(fit1, fit2)