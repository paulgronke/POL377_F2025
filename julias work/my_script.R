## ----setup, include=FALSE------------------------------------------------------------

knitr::opts_chunk$set(echo = TRUE)

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(here)
  library(knitr)
})


## ------------------------------------------------------------------------------------
load(url("https://www.dropbox.com/scl/fi/kp1lty1chtgzye8gnufl4/clea_lc_20240419.RData?rlkey=phvtoh91a48v9jky1m1120vnw&st=h7lnys7v&dl=1"))


## ------------------------------------------------------------------------------------
missing_codes_num  <- c(-990, -992, -994)
missing_codes_char <- as.character(missing_codes_num)

#had some issues around here so i threw it into chatGPT and it gave me this, i think it worked. it's a bit extra but defining this formula as a function helped a lot.
enp <- function(share_vec) {
  share_vec <- share_vec[!is.na(share_vec)]
  if (length(share_vec) == 0) return(NA_real_)
  1 / sum(share_vec^2)
}

clea_lc_20240419 <- clea_lc_20240419 %>%
  mutate(across(where(is.numeric), ~ ifelse(. %in% missing_codes_num, NA, .))) %>%
  mutate(across(where(is.character), ~ ifelse(. %in% missing_codes_char, NA, .))) %>%
  mutate(across(where(is.factor), ~ {
    x <- as.character(.)
    x[x %in% missing_codes_char] <- NA_character_
    factor(x)
  }))


## ------------------------------------------------------------------------------------
jpn <- clea_lc_20240419 %>%
  filter(ctr_n == "Japan") %>%
  filter(yr >= 1990, yr <= 2025)


## ------------------------------------------------------------------------------------
jpn_district_enp <- jpn %>%
  group_by(yr, cst, cst_n) %>%
  summarize(
    enp_votes = enp(pvs1),
    enp_seats = enp(seat / mag),
    mag = dplyr::first(mag),
    .groups = "drop"
 )



## ------------------------------------------------------------------------------------
ggplot(jpn_district_enp, aes(x = enp_votes, y = enp_seats)) +
  geom_point(alpha = 0.6, size = 1.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  geom_smooth(method = "loess", formula = y ~ x, se = FALSE) +
  facet_wrap(~ yr) +
  labs(
    title = "Japan: District-level ENP (Votes vs Seats) by Election Year",
    x = "ENP (Votes)",
    y = "ENP (Seats)"
  ) +
  coord_cartesian(xlim = c(1, max(6, max(jpn_district_enp$enp_votes, na.rm = TRUE))),
                  ylim = c(1, max(6, max(jpn_district_enp$enp_seats, na.rm = TRUE)))) +
  theme_minimal(base_size = 12)


## ------------------------------------------------------------------------------------
jpn_nat_party_totals <- jpn %>%
  group_by(ctr, ctr_n, yr, pty, .drop = TRUE) %>%
  summarize(
    votes = sum(pv1, na.rm = TRUE),
    seats = sum(seat, na.rm = TRUE),
    .groups = "drop"
  )

jpn_nationwide_enp <- jpn_nat_party_totals %>%
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
  arrange(yr)

kable(jpn_nationwide_enp, caption = "Japan: Nationwide Effective Number of Parties (Votes & Seats) by Election Year")



## ------------------------------------------------------------------------------------
ggplot(jpn_nationwide_enp, aes(x = yr)) +
  geom_line(aes(y = ENP_votes, linetype = "Votes"), linewidth = 1) +
  geom_point(aes(y = ENP_votes, shape = "Votes"), size = 2) +
  geom_line(aes(y = ENP_seats, linetype = "Seats"), linewidth = 1) +
  geom_point(aes(y = ENP_seats, shape = "Seats"), size = 2) +
  scale_linetype_manual(values = c("Votes" = "solid", "Seats" = "dashed"), name = NULL) +
  scale_shape_manual(values = c("Votes" = 16, "Seats" = 17), name = NULL) +
  labs(
    title = "Japan: Nationwide ENP (Votes vs Seats) by Election Year",
    x = "Election Year",
    y = "ENP"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

