FROM eddelbuettel/r2u:20.04 

RUN mkdir /app
COPY . /app
WORKDIR /app

RUN R -e 'install.packages("remotes")'
RUN R -e 'remotes::install_version("renv", version = "1.0.3")'
RUN R -e "renv::restore()"

cmd ["Rscript", "run_optim.R"]

