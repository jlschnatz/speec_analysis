n_cores=$1
echo $n_cores

R -e 'install.packages("remotes");remotes::install_version("renv", version = "1.0.3");renv::restore()'

# Run R-Script
Rscript --vanilla parallel_optim.R "$n_cores"
