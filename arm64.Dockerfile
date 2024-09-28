# This is an Dockerfile for building a docker image for RStudio,
# with R packages for Bayesian data analysis, and cmdstanr as the backend for Stan.
# Use R 4.4.1 as base image, which has images for both amd64 and arm64.
# This tag itself is minimal, and you need to install other R packages for your purpose by yourself.

ARG BASE_CONTAINER=rocker/rstudio:4.4.1
FROM $BASE_CONTAINER

# install libraries for R packages, using docker's root user
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfontconfig1-dev \
    libxml2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libgit2-dev \
    libudunits2-dev \
    zlib1g-dev \
    libgdal-dev \
    cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

    # gcc && \
    # g++ && \
    # gfortran && \

# from Tsinghua's mirror if you are in china: https://mirrors.tuna.tsinghua.edu.cn/CRAN/
# the original US mirror: http://cran.us.r-project.org
RUN R -e "install.packages(c('pacman','tidyverse', 'lme4','brms','osfr','papaja'), repos = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')"
# RUN R -e "install.packages('rstanarm', repos = 'https://mirror-hk.koddos.net/CRAN/')"
RUN R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))"
#RUN R -e "install.packages('tinytex', repos = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/')"
#RUN R -e "tinytex::install_tinytex()"

# install cmdstanr
RUN mkdir -p /home/rstudio/.cmdstanr
ENV PATH="/home/rstudio/.cmdstanr:${PATH}"
RUN R -e "cmdstanr::install_cmdstan(dir = '/home/rstudio/.cmdstanr', cores = 4)"

# add data and script for testing
RUN mkdir -p /home/rstudio/example/
COPY /example/Script_example.Rmd /home/rstudio/example/
COPY /example/Script_example.r /home/rstudio/example/
COPY /example/df_example.csv /home/rstudio/example/
COPY /example/cmdstanrTest.r /home/rstudio/example/
