library(speec)
library(here)
library(parallel)

read_data <- function(path) {
  data_df <- read.csv(path)
  split_data <- split(data_df[, c("id_meta", "n", "d")], ~id_meta) 
  out <- lapply(split_data, function(x) as.matrix(x[, c("d", "n")]))
  return(out)
}

# run_optim <- function(data_list, n_cores = 4, out_dir) {
#   if (!file.exists(out_dir)) dir.create(out_dir)
#   if(!endsWith(out_dir, "/")) out_dir <- paste0(out_dir, "/")
#   out <- vector("list", length(data_list))
#   names(out) <- names(data_list)
#   parallel::mclapply(
#     X = seq_len(length(data_list)),
#     FUN = function(i) {
#       out[[i]] <- apply(data_list[[i]], 2, mean)
#       filename <- paste0(out_dir, "optim_", names(out)[i], ".rds")
#       saveRDS(out[[i]], file = filename)
#     },
#     mc.cores = n_cores
#   )
#   cli::cli_alert_success("Done!")
# }


#run_optim(data_list, n_cores = 4, out_dir = here("data/optim"))

 
run_optim <- function(data_list, n_cores = 4, out_dir, control) {
  if (!file.exists(out_dir)) dir.create(out_dir)
  if(!endsWith(out_dir, "/")) out_dir <- paste0(out_dir, "/")
  out <- vector("list", length(data_list))
  names(out) <- names(data_list)
  parallel::mclapply(
    X = seq_len(length(data_list)),
    FUN = function(i) {
      out[[i]] <- speec::speec(data_list[[i]], speec_control = control)
      filename <- paste0(out_dir, "optim_", names(out)[i], ".rds")
      saveRDS(out[[i]], file = filename)
    },
    mc.cores = n_cores,
    mc.silent = TRUE
  )
  cli::cli_alert_success("Done!")
}

control <- speec_control(
  bw = "sheather-jones",
  n_grid = c(2^7+1, 2^7+1),
  pr = c(0.005, 0.995),
  k_sim = 1e3,
  bounds = set_boundaries(
    phi_n = c(1, 100),
    mu_n = c(10, 500),
    mu_d = c(-4, 4),
    sigma2_d = c(0.01, 3),
    delta_hat = c(0.05, 3),
    w_pbs = c(0, 1)
  ),
  start = set_start(
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
  hyperparameters = set_hyperparameters(
    ac_acc = 1e-4,
    nlimit = 10,
    r = .5,
    maxgood = 200,
    t0 = 1e3,
    dyn_rf = TRUE,
    vf = NULL,
    rf = 5,
    k = 1,
    t_min = .2,
    stopac = 100
  )
)

data_list <- read_data(here("data/meta/data_lindenhonekopp_proc.csv"))  
run_optim(test, n_cores = 4, out_dir = here("data/optim"), control = control)



dat <- simulate_meta(100, 5, 100, 0, 0.5, 1, 1)
speec(dat, control)
lapply(test, function(x) speec(x, control))

test <- data_list[c(1, 2, 3)]

speec(test, control)

# control <- speec_control(
#   bw = "sheather-jones",
#   n_grid = c(2^7+1, 2^7+1),
#   pr = c(0.005, 0.995),
#   k_sim = 1e4,
#   bounds = set_boundaries(
#     phi_n = c(1, 50),
#     mu_n = c(20, 500),
#     mu_d = c(-4, 4),
#     sigma2_d = c(0.01, 2),
#     delta_hat = c(0.05, 3),
#     w_pbs = c(0, 1)
#   ),
#   start = set_start(
#     phi_n = NULL,
#     mu_n = NULL,
#     mu_d = NULL,
#     sigma2_d = NULL,
#     delta_hat = NULL,
#     w_pbs = 0.5
#   ),
#   alpha = 0.05,
#   beta = 0.2,
#   slope_ssp = 0,
#   only_pbs = TRUE,
#   trace = TRUE,
#   hyperparameters = set_hyperparameters(
#     ac_acc = 1e-4,
#     nlimit = 10,
#     r = .99,
#     maxgood = 200,
#     t0 = 1e4,
#     dyn_rf = TRUE,
#     vf = NULL,
#     rf = 5,
#     k = 1,
#     t_min = .2,
#     stopac = 100
#   )
# )
