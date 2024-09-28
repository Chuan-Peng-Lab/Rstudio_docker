###### uncomment the code below, you can use the latest verse
# ARG BASE_CONTAINER=rocker/verse:latest

# rocker/rstudio:4.4.1
ARG BASE_CONTAINER=rocker/rstudio:4.4.1
FROM $BASE_CONTAINER

# install r packages
RUN R -e "install.packages('tidyverse', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('brms', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('osfr', repos = 'http://cran.us.r-project.org')"
RUN R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))"
#RUN R -e "install.packages('tinytex', repos = 'http://cran.us.r-project.org')"
#RUN R -e "tinytex::install_tinytex()"
RUN R -e "install.packages('papaja', repos = 'http://cran.us.r-project.org')"

# install cmdstanr
RUN mkdir -p /home/rstudio/.cmdstanr
ENV PATH="/home/rstudio/.cmdstanr:${PATH}"
RUN R -e "cmdstanr::install_cmdstan(dir = '/home/rstudio/.cmdstanr', cores = 4)"

# install lib dependencies

# add data
COPY /example/Script_example.Rmd /home/rstudio/example/
COPY /example/Script_example.r /home/rstudio/example/
COPY /example/df_example.csv /home/rstudio/example/
