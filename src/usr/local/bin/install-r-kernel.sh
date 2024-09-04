#!/usr/bin/env bash

# Install R kernel for Jupyter
# This does show R in the Launcher but it is version 4.3.1 and not 4.4.1 which is what we have installed in the Analytical Platform Cloud Environment Base Image
# conda install r-irkernel

# This does show R in the launcher and it's version 4.4.0 :(
# This does appear to be the cleanest way so far
conda install r-irkernel -c conda-forge -y

# R -e "install.packages('IRkernel')"
# R -e "IRkernel::installspec(user = TRUE)"
# R -e "if ('IRkernel' %in% rownames(installed.packages())) { cat('IRkernel is installed.\n') } else { cat('IRkernel is not installed.\n') }"
