
read_data <- function(path) {
  data_df <- utils::read.csv(path)
  split_data <- split(data_df[, c("id_meta", "n", "d")], ~id_meta) 
  out <- lapply(split_data, function(x) as.matrix(x[, c("d", "n")]))
  return(out)
}

de_optim <- function(emp_data, bw = "sheather-jones", n_grid = rep(2^7 +1, 2), lower, upper, k_sim = 1e4,
                   np = 100, f = .8, bs = TRUE, strategy = 1, itermax = 100, p = .2,
                   c = 0, cr = .5, storepopfrom = 1, storepopfreq = 1
                   ) {
  lims <- speec:::find_kde_limits(emp_data)
  fhat_emp <- speec:::bivariate_kde(emp_data, bw = bw, n_grid = n_grid, lims = lims)
  fn <- function(par) {
    theo_data <- speec::simulate_meta(
      k_sim = k_sim, phi_n = par[1], mu_n = par[2],
      mu_d = par[3], sigma2_d = par[4], delta_hat = 1, w_pbs = par[5],
      only_pbs = TRUE
    )
    fhat_theo <- speec:::bivariate_kde(theo_data, bw = bw, n_grid = n_grid, lims = lims)
    speec:::kl_div(fhat_emp, fhat_theo)
  }
  t1 <- Sys.time()
  opt <- RcppDE::DEoptim(
    fn = fn,
    lower = lower,
    upper = upper,
    control = RcppDE::DEoptim.control(
      "NP" = np,
      "strategy" = strategy,
      "itermax" = itermax,
      "CR" = cr,
      "bs" = bs,
      "F" = f,
      trace = TRUE,
      storepopfreq = storepopfreq,
      storepopfrom = storepopfrom
    )
  )
  t2 <- Sys.time()
  return(runtime = difftime(t2, t1), optim_results = opt)
}

run_optim <- function(data_list, n_cores = 4, out_dir, 
                      bw = "sheather-jones", n_grid = rep(2^7 +1, 2), lower, upper, k_sim = 1e4,
                      np = 100, f = .8, bs = TRUE, strategy = 1, itermax = 100, p = .2,
                      c = 0, cr = .5, storepopfrom = 1, storepopfreq = 1
                      ) {
  if (!file.exists(out_dir)) dir.create(out_dir)
  if(!endsWith(out_dir, "/")) out_dir <- paste0(out_dir, "/")
  out <- vector("list", length(data_list))
  names(out) <- names(data_list)
  parallel::mclapply(
    X = seq_len(length(data_list)),
    FUN = function(i) {
      cli::cli_alert_info("Processing meta-analysis {i}")
      out[[i]] <- de_optim(
        emp_data = data_list[[i]], bw = bw, n_grid = n_grid, 
        lower = lower, upper = upper, k_sim = k_sim, np = np, f = f, 
        bs = bs, strategy = strategy, itermax = itermax, p = p, c = c, 
        cr = cr, storepopfrom = storepopfrom, storepopfreq = storepopfreq
        )
      filename <- paste0(out_dir, "optim_de", names(out)[i], ".rds")
      out[[i]]$id_meta <- names(out)[i]
      saveRDS(out[[i]], file = filename)
    },
    mc.cores = n_cores,
    mc.silent = TRUE
  )
  cli::cli_alert_success("Done!")
}

arg <- commandArgs(trailingOnly = TRUE)
if(length(arg) == 0) {
  n_cores = 12
} else {
  n_cores <- as.numeric(arg[1])
}

set.seed(42)
data_list <- read_data("data/meta/data_lindenhonekopp_proc.csv")
run_optim(
  data_list = data_list,
  n_cores = n_cores,
  out_dir = here::here("data/optim_de"),
  bw = "sheather-jones",
  n_grid = rep(2^7+1, 2),
  lower = c(.01, 30, -4, 0, 0),
  upper = c(1000, 15000, 4, 6, 1),
  k_sim = 1e5,
  np = 150,
  f = 0.4,
  bs = TRUE,
  strategy = 1,
  itermax = 150,
  p = 0.8,
  c = 0,
  cr = 0.9,
  storepopfrom = 1,
  storepopfreq = 1
)
