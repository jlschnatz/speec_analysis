#' @title Read data
#' @description Read-in meta-analysis data as list of matrices
#' @param path Path to the file
#' @return List of matrices
read_data <- function(path) {
  data_df <- utils::read.csv(path)
  split_data <- split(data_df[, c("id_meta", "n", "d")], ~id_meta) 
  out <- lapply(split_data, function(x) as.matrix(x[, c("d", "n")]))
  return(out)
}

#' @title Run optimization in parallel
#' @param data_list List of matrices (as returned by `read_data`)
#' @param n_cores Number of cores to use 
#' @param out_dir Directory to save the results
#' @param control speec_control object
run_optim <- function(data_list, n_cores = 4, out_dir, control) {
  if (!file.exists(out_dir)) dir.create(out_dir)
  if(!endsWith(out_dir, "/")) out_dir <- paste0(out_dir, "/")
  out <- vector("list", length(data_list))
  names(out) <- names(data_list)
  parallel::mclapply(
    X = seq_len(length(data_list)),
    FUN = function(i) {
      cli::cli_alert_info("Processing meta-analysis {i}")
      out[[i]] <- speec::speec(data_list[[i]], speec_control = control)
      filename <- paste0(out_dir, "optim_", names(out)[i], ".rds")
      out[[i]]$id_meta <- names(out)[i]
      saveRDS(out[[i]], file = filename)
    },
    mc.cores = n_cores,
    mc.silent = TRUE
  )
  cli::cli_alert_success("Done!")
}

set.seed(42)
data_list <- read_data(here::here("data/meta/data_lindenhonekopp_proc.csv")) 
control <- speec::speec_control(
  bw = "sheather-jones",
  n_grid = c(2^7+1, 2^7+1),
  pr = c(0.005, 0.995),
  k_sim = 1e5,
  bounds = speec::set_boundaries(
    phi_n = c(0.1, 15000),
    mu_n = c(5, 15000),
    mu_d = c(-4, 4),
    sigma2_d = c(0.0005, 5)**2,
    delta_hat = c(0.05, 3),
    w_pbs = c(0, 1)
  ),
  start = speec::set_start(
    phi_n = NULL,
    mu_n = NULL,
    mu_d = NULL,
    sigma2_d = NULL,
    delta_hat = NULL,
    w_pbs = 0.5
  ),
  alpha = 0.05,
  beta = 0.2,
  slope_ssp = 0,
  only_pbs = TRUE,
  trace = TRUE,
  hyperparameters = speec::set_hyperparameters(
    ac_acc = 1e-4,
    nlimit = 10,
    r = .99,
    maxgood = 200,
    t0 = 1e4,
    dyn_rf = TRUE,
    vf = NULL,
    rf = 5,
    k = 1,
    t_min = .2,
    stopac = 100
  )
)

arg <- commandArgs(trailingOnly = TRUE)
if(length(arg) == 0) {
  n_cores = 12
} else {
  n_cores <- as.numeric(arg[1])
}

control_path <- here::here("data/optim/speec_control_settings.rds")
saveRDS(control, file = control_path)
run_optim(data_list, n_cores = n_cores, out_dir = here::here("data/optim"), control = control)

