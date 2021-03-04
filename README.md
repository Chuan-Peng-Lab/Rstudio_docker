# rstudio_docker (my working env)

This repo is to ensure reproducibility of analyses from [Hu Chuan-Peng](https://huchuanpeng.com/)'s team. This [tutorial](http://ropenscilabs.github.io/r-docker-tutorial/) helped me to build and maintain this repo, many thanks.

The primary purpose of this docker image is to ensure my collaborators can run `brms` across different platforms, so that they don't need to worry about the installation problems.

This docker image can be used for Bayesian analyses, it includes the following packages: `brms`, `cmdstanr`, `tidybayes`. Also, it includes `tidyverse`, `metafor`. I will include more packages in the future. You can also easily install new packages and save the docker images locally, please see the [tutorial](http://ropenscilabs.github.io/r-docker-tutorial/) I mentioned above.

## About docker

Please see [here](https://www.docker.com/resources/what-container) for why using docker.

## How to use this docker images

### Step 1: install docker

Linux (ubuntu): https://docs.docker.com/engine/install/ubuntu/

Windows 10: https://docs.docker.com/docker-for-windows/install/

Mac OS: https://docs.docker.com/docker-for-mac/install/

**Make sure that docker was successfully installed on your machine**

### Step 2: pull this image form dock hub

```
docker pull hcp4715/rstudio_bayes            # docker will try to find a image "hcp4715/rstudio_bayes:latest"
docker pull hcp4715/rstudio_bayes:cmdstanr   # docker will try to find a image "hcp4715/rstudio_bayes:cmdstanr"
```

### Step 3: run the docker image:

```
docker run -e PASSWORD=hcplab2021 --cpus=4 -it --rm -p 8787:8787 -v /home/hcp4715/docker_R:/home/rstudio/tutorial hcp4715/rstudio_bayes:cmdstanr
```

docker run ---- Run a docker image in a container

-e PASSWORD=hcplab2021 ---- set a password for rstudio, you can set your own password.

-it ---- Keep STDIN open even if not attached

--rm ---- Automatically remove the container when it exits

--cpus=4 ---- Number of cores will be used by docker. Make sure that your machine has more thread than the number here.

-v ---- Mount a folder to the container

/home/hcp4715/docker_R ---- The directory of a local folder where I stored my data. [For Linux]

/d/hcp4715/docker_R ---- The directory of a local folder under drive D. It appears as D:\hcp4715\hddm_docker in windows system.

/home/rstudio/tutorial ---- The directory inside the docker image (the mounting point of the local folder in the docker image). Note that the docker container itself likes a mini virtual linux system, so the file system inside it is linux style.

-p ---- Publish a container’s port(s) to the host

hcp4715/rstudio_bayes:firsttry ---- The docker image to run. Note that you shoud include `:firsttry` part, otherwise docker will instead use "hcp4715/rstudio_bayes:latest", which does not exist.

**After running the code above, you shall see output as below:**

```
[s6-init] making user provided files available at /var/run/s6/etc...exited 0.
[s6-init] ensuring user provided files have correct perms...exited 0.
[fix-attrs.d] applying ownership & permissions fixes...
[fix-attrs.d] done.
[cont-init.d] executing container initialization scripts...
[cont-init.d] userconf: executing... 
[cont-init.d] userconf: exited 0.
[cont-init.d] done.
[services.d] starting services
[services.d] done.
```

Then, open your broswer (e.g., firefox, chrome), and input the follow in the address:

`localhost:8787` (for linux)

`http://192.168.99.100:8787` (for windows)


You are asked to input username and password

Username: rstudio
Password: hcplab2021

Now, you will see the familiar interface of rstudio! in the broswer!

### Step 4: test the iamge

Run the code below to test whether the image works
```
# load the libraries
library(brms)
library(tidyverse)

# fit a testing model from brms, use rstan as the backend
fit1 <- brm(count ~ zAge + zBase * Trt + (1|patient), 
	    cores = parallel::detectCores(),
	    chains = 4,  # this number should not exceed the number of cpus you assigned to docker.
        data = epilepsy, family = poisson())

# fit a testing model from brms, use cmdstanr as the backend
library(cmdstanr)
fit1 <- brm(count ~ zAge + zBase * Trt + (1|patient), 
	    cores = parallel::detectCores(),
	    chains = 4,  # this number should not exceed the number of cpus you assigned to docker.
		backend = 'cmdstanr',
        data = epilepsy, family = poisson())

# check the summary of the model
summary(fit1)
```