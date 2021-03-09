###### uncomment the code below, you can use the latest verse
# ARG BASE_CONTAINER=rocker/verse:latest

# I fixed this image to use 4.04 based R
# https://hub.docker.com/layers/rocker/verse/4.0.4/images/sha256-c98bc2327babaef10deb3f0aad3eebe6fc981f0f835da6735cbd33c3468fd2b7?context=explore
ARG BASE_CONTAINER=rocker/verse:4.0.4
FROM $BASE_CONTAINER

# install r packages
RUN R -e "install.packages('tidyverse', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('brms', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('osfr', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))"

# install cmdstanr
RUN mkdir -p /home/rstudio/.cmdstanr
ENV PATH="/home/rstudio/.cmdstanr:${PATH}"
RUN R -e "cmdstanr::install_cmdstan(dir = '/home/rstudio/.cmdstanr', cores = 4)"

# install lib dependencies

# add data
COPY /example/Script_example.Rmd /home/rstudio/example/
COPY /example/Script_example.r /home/rstudio/example/
COPY /example/df_example.csv /home/rstudio/example/
