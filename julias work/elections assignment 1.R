```{r setup, include=TRUE}

knitr::opts_chunk$set(echo = FALSE)

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(here)
  library(knitr)
})
```



```{r}
load(url("https://www.dropbox.com/scl/fi/kp1lty1chtgzye8gnufl4/clea_lc_20240419.RData?rlkey=phvtoh91a48v9jky1m1120vnw&st=h7lnys7v&dl=1"))
```

```{r}
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
```

```{r}
jpn <- clea_lc_20240419 %>%
  filter(ctr_n == "Japan") %>%
  filter(yr >= 1990, yr <= 2000)
```

```{r}
jpn_district_enp <- jpn %>%
  group_by(yr, cst, cst_n) %>%
  summarize(
    enp_votes = enp(pvs1),
    enp_seats = enp(seat / mag),
    mag = dplyr::first(mag),
    .groups = "drop"
  )

```

The question I'm adressing is how did Japan's 1994 electoral reform alter the relationship between votes and seats in terms of ENP?
  
  My hypothesis is that the reform, which replaced multi member districts under single non-transferable vote with a mixed member system (single member plus proportional representation), fundamentally changed how voter preferences translated into legislative representation. 

My analysis will evaluate whether or not the reform effectively shifted Japan to a two party seat structure from a multi-party seat distribution even when voters continued to express support for multiple parties as intended by those who created the change.

In 1994, Japan passed a national electoral reform law that transformed the electoral system from a multi-member single non-transferable vote (SNTV) system to a single member plurality voting system. This reform was created to allow for changes in power after the LDP had been the dominant political power for several decades. This change can be seen in the following plots:
  
  
  ```{r}
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
```


Pre-reform (1990 & 1993), ENP seats are much higher, hovering around 4 seats. This coincides with a high ENP in votes which means that there was voter support across multiple parties. Post-reform (1996-2000) most ENP seats are at 1 which is reflective of the change to single member districts. The gap between votes and seats in 1996 is significant. This is likely due to voters having preferences for multiple parties, yet most seats were awarded to only one or two parties as the new system had designed. This becomes changes during the 2000 election. The curve bending upward means that it took a lot of voters splitting for more than two parties to win representation. What's interesting is that voters splitting in 1996 for multiple parties did not transfer into there being more seat-winners, however, in 2000 this does happen slightly more successfully. In 1996, parties were still navigating how to run under this new system. As a result, multiple parties were running candidates but only one seat was available. By 2000, they decided that it would be effective for some parties to merge together, thus consolidating power. This created the modern day DPJ. Thus those districts with higher ENP votes were also like to elect more than one party which explains the upwards curve. 


```{r}
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

```


A lot of my above analysis is reflected in the below plot. Pre-reform there are more ENP seats compared to ENP votes because the multi-member SNTV system allowed for a greater number of parties to win compared to relative votes. This changes up in 1996 after the reform where there are more votes relative to seats with that gap increasing in the 2000 election. That huge drop in seats for the 1996 election shows how parties were unable to convert votes into seats with a single member district system. The 2000 election gap between ENP votes and seats shows that the system is filtering out parties at the seat level.


```{r}
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
```

I think what's really interesting from the data is that is shows how institutional rules rather than voter preferences alone shape the effective structure of the party system. The 1994 reform was designed to break up the dominance of factional competition under the old SNTV system and encourage consolidation into larger, more stable blocs. This was deliberate from political officials and it was effective as they intended. Representation was funneled into a two-party structure. Japan's experience quickly reconfigured representation, leading to an entirely new political party that dominated the 2012 election.

Citation: https://en.wikipedia.org/wiki/1994_Japanese_electoral_reform 

