# --------------------------------------------
# ENP from CLEA constituency data (2000-2025)
# Countries: Denmark and Italy
# Object in .RData: clea_lc_20240419
# Uses: CTR, YR, CST, MAG, PTY, PV1 (votes, round 1), SEAT
# --------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(here)
})

# --- Load exactly your file and object ---
load(url("https://www.dropbox.com/scl/fi/kp1lty1chtgzye8gnufl4/clea_lc_20240419.RData?rlkey=phvtoh91a48v9jky1m1120vnw&st=h7lnys7v&dl=1"))

 # Loads clea_lc_20240419


missing_codes_num  <- c(-990, -992, -994)
missing_codes_char <- as.character(missing_codes_num)

clea_lc_20240419 <- clea_lc_20240419 %>%
  # numeric columns
  mutate(across(
    where(is.numeric),
    ~ ifelse(. %in% missing_codes_num, NA, .)
  )) %>%
  # character columns
  mutate(across(
    where(is.character),
    ~ ifelse(. %in% missing_codes_char, NA, .)
  )) %>%
  # factor columns
  mutate(across(
    where(is.factor),
    ~ {
      x <- as.character(.)
      x[x %in% missing_codes_char] <- NA_character_
      factor(x)
    }
  ))

# Short alias
dat <- clea_lc_20240419

# --- Scope: Germany & France, 1980–2005 ---
countries <- c("Denmark", "Italy")
dat_sub <- dat %>%
  filter(ctr_n %in% countries, yr >= 2000, yr <= 2025)

# --- Helper: Laakso–Taagepera ENP ---
enp <- function(p) {
  p <- p[is.finite(p) & !is.na(p) & p > 0]
  if (!length(p)) return(NA_real_)
  1 / sum(p^2)
}

# --- District-level ENP (votes & seats) ---
# Aggregate to party x district (in case of multiple rows per party)
pd <- dat_sub %>% 
  group_by(ctr, ctr_n, yr, cst, pty, .drop = TRUE) %>%
  summarize(
    votes = sum(pv1, na.rm = TRUE),
    seats = sum(seat, na.rm = TRUE),
    .groups = "drop"
  )

# Shares within each district (CST)
pd_shares <- pd %>%
  group_by(ctr, ctr_n, yr, cst, .drop = TRUE) %>%
  mutate(
    tot_votes = sum(votes, na.rm = TRUE),
    tot_seats = sum(seats, na.rm = TRUE),
    vote_share = ifelse(tot_votes > 0, votes / tot_votes, NA_real_),
    seat_share = ifelse(tot_seats > 0, seats / tot_seats, NA_real_)
  ) %>%
  ungroup()

district_enp <- pd_shares %>%
  group_by(ctr, ctr_n, yr, cst, .drop = TRUE) %>%
  summarize(
    ENP_votes = enp(vote_share),
    ENP_seats = enp(seat_share),
    .groups = "drop"
  ) %>%
  filter(is.finite(ENP_votes), is.finite(ENP_seats))

# --- Plot: ENP_votes vs ENP_seats, LOESS fit, faceted by year ---
plot_one_country <- function(ctry) {
  df <- district_enp %>% filter(ctr_n == ctry)
  if (nrow(df) == 0) return(invisible(NULL))
  p <- ggplot(df, aes(x = ENP_votes, y = ENP_seats)) +
    geom_point(alpha = 0.6, size = 1.7) +
    geom_smooth(method = "loess", se = FALSE, linewidth = 1) +
    facet_wrap(~ yr, scales = "free") +
    labs(
      title = paste0(ctry, ": District-level ENP (Votes vs Seats), 1980–2005"),
      subtitle = "CLEA: PV1 for votes, SEAT for seats; LOESS fit per election year",
      x = "Effective Number of Parties (Votes)",
      y = "Effective Number of Parties (Seats)"
    ) +
    theme_minimal(base_size = 12) +
    theme(panel.grid.minor = element_blank())
  out <- paste0("enp_scatter_", tolower(ctry), "_1980_2005.jpg")
  ggsave(out, p, width = 12, height = 7, dpi = 300)
  message("Saved: ", out)
}

plot_one_country("Denmark")
plot_one_country("Italy")

# --- Nationwide ENP by election (CTR,YR) ---
# Sum parties across districts, then compute shares & ENP
nat_party_totals <- dat_sub %>%
  group_by(ctr, ctr_n, yr, pty, .drop = TRUE) %>%
  summarize(
    votes = sum(pv1, na.rm = TRUE),
    seats = sum(seat, na.rm = TRUE),
    .groups = "drop"
  )

nationwide_enp <- nat_party_totals %>%
  group_by(ctr, ctr_n, yr, .drop = TRUE) %>%
  mutate(
    vote_share = votes / sum(votes, na.rm = TRUE),
    seat_share = seats / sum(seats, na.rm = TRUE)
  ) %>%
  summarize(
    ENP_votes = enp(vote_share),
    ENP_seats = enp(seat_share),
    .groups = "drop"
  ) %>%
  arrange(ctr, yr)

# --- Save outputs ---
#rite_csv(district_enp,  "enp_district_germany_france_1980_2005.csv")
#rite_csv(nationwide_enp,"enp_nationwide_germany_france_1980_2005.csv")

ggplot(nationwide_enp, aes(x = yr)) +
  geom_line(aes(y = ENP_votes, color = "Votes"), linewidth = 1.1) +
  geom_point(aes(y = ENP_votes, color = "Votes"), size = 2) +
  geom_line(aes(y = ENP_seats, color = "Seats"), linewidth = 1.1) +
  geom_point(aes(y = ENP_seats, color = "Seats"), size = 2) +
  facet_wrap(~ ctr_n, scales = "free_y") +
  scale_color_manual(values = c("Votes" = "darkgreen", "Seats" = "darkred")) +
  labs(
    title = "Nationwide Effective Number of Parties (ENP), 2000-2025",
    subtitle = "Denmark and Italy",
    x = "Election Year",
    y = "ENP",
    color = "Based on"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

