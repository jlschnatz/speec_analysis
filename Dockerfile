# Base image
FROM eddelbuettel/r2u:20.04 

# Copy the current directory contents into the container at /analysis
RUN mkdir /analysis
COPY . /analysis
WORKDIR /analysis

# Restore R Packages 
RUN R -e 'install.packages("remotes")'
RUN R -e 'remotes::install_version("renv", version = "1.0.3")'
RUN R -e "renv::restore()"

# Run the R script
cmd ["Rscript", "parallel_optim.R"]

