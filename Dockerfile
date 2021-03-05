FROM rocker/verse:latest

# install r packages
RUN R -e "install.packages('tidyverse', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('brms', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))"

# install cmdstanr
RUN mkdir -p /home/rstudio/.cmdstanr
ENV PATH="/home/rstudio/.cmdstanr:${PATH}"
RUN R -e "cmdstanr::install_cmdstan(dir = '/home/rstudio/.cmdstanr', cores = 4)"

# install lib dependencies

# add data
ADD data/df_pilot_online_SALT_open.csv /home/rstudio/data/
