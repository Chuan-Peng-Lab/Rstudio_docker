FROM rocker/verse:latest

# install r packages
USER $NB_UID
RUN R -e "install.packages('tidyverse', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('brms', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))"
RUN R -e "cmdstanr::install_cmdstan(path = '/hom/rstudio/.cmdstanr')"

# install lib dependencies

# add data
ADD data/df_pilot_online_SALT_open.csv /home/rstudio/data/
