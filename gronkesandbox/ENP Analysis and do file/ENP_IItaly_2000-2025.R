# --------------------------------------------
# ENP from CLEA constituency data (2000-2025)
# Countries: Italy
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

# --- Scope: Italy, 1980–2005 ---
#
countries <- c("Italy")
italy <- clea_lc_20240419 %>%
  filter(ctr_n %in% countries, yr >= 2000, yr <= 2025)

# --- District-level ENP (votes & seats) ---
# 
# 2013 - This replicates what we did in Data Lab 1, but I keep a few other
# variables for context

italy_2013_district1 <- italy %>%
  filter(yr == 2013 & cst == 1) %>%
  group_by(cst, cst_n) %>%
  summarize(enp_v = 1/sum(pvs1^2),
            enp_s = 1/sum((seat/mag)^2),
            yr = first(yr),
            mag = first(mag),
            cst_n = first(cst_n)) %>%
  ungroup()

#
# -- District level ENP for all districts in 2013
#

italy_2013_alldistricts <- italy %>%
  filter(yr == 2013) %>%
  group_by(cst, cst_n) %>%
  summarize(enp_v = 1/sum(pvs1^2),
            enp_s = 1/sum((seat/mag)^2),
            yr = first(yr),
            mag = first(mag),
            cst_n = first(cst_n)) %>%
  ungroup()

#
# -- Plot values for 2013 
#

# --- Plot: ENP_votes vs ENP_seats, LOESS fit  ---


ggplot(italy_2013_alldistricts, aes(x = enp_v, y = enp_s)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  # Use LOESS instead of linear fit
  geom_smooth(method = "loess", formula = y ~ x, se = FALSE, color = "blue") +
  facet_wrap(~ yr) +
  # Axes from 1 up to the overall max
  scale_x_continuous(limits = c(1, 6)) +
  scale_y_continuous(limits = c(1, 6)) +
  labs(title = "ENP Votes vs ENP Seats for Italy, 2013",
       x = "ENP Votes",
       y = "ENP Seats") +
  theme_minimal()

# Now do all years 2000-2025

italy_2000_2025 <- italy %>%
  filter(yr > 2000) %>%
  group_by(yr, cst, cst_n) %>%
  summarize(enp_v = 1/sum(pvs1^2),
            enp_s = 1/sum((seat/mag)^2),
            yr = first(yr),
            mag = first(mag),
            cst_n = first(cst_n)) %>%
  ungroup()

kable(italy_2000_2025, caption = "ENP for Italy, All Years, All Constituencies")

ggplot(italy_2000_2025, aes(x = enp_v, y = enp_s)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  # Use LOESS instead of linear fit
  geom_smooth(method = "loess", formula = y ~ x, se = FALSE, color = "blue") +
  facet_wrap(~yr) +
  # Axes from 1 up to the overall max
  scale_x_continuous(limits = c(1, 6)) +
  scale_y_continuous(limits = c(1, 6)) +
  labs(title = "ENP Votes vs ENP Seats for Italy, 2013",
       x = "ENP Votes",
       y = "ENP Seats") +
  theme_minimal()



# --- Nationwide ENP by election (YR) ---
# Sum parties across districts, then compute shares & ENP
nat_party_totals <- italy %>%
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


ggplot(nationwide_enp, aes(x = yr)) +
  geom_line(aes(y = ENP_votes, color = "Votes"), linewidth = 1.1) +
  geom_point(aes(y = ENP_votes, color = "Votes"), size = 2) +
  geom_line(aes(y = ENP_seats, color = "Seats"), linewidth = 1.1) +
  geom_point(aes(y = ENP_seats, color = "Seats"), size = 2) +
  facet_wrap(~ ctr_n, scales = "free_y") +
  scale_color_manual(values = c("Votes" = "darkgreen", "Seats" = "darkred")) +
  labs(
    title = "Nationwide Effective Number of Italian Parties (ENP), 2000-2025",
    x = "Election Year",
    y = "ENP"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

