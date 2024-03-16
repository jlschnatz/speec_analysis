n_cores=$1
echo "Running on $n_cores cores"


#R -e 'install.packages("remotes");remotes::install_version("renv", version = "1.0.3");renv::restore()'
R -e 'if (!require("remotes")) {install.packages("remotes")}; remotes::install_version("renv", version = "1.0.3");renv::restore()'


# Run R-Script
Rscript --vanilla parallel_optim.R "$n_cores"
