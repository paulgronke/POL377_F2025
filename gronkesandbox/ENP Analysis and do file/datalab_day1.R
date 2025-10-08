# ENP Data Lab Day One

# Load the required packages
library(tidyverse)

# Load the data 
# Loads clea_lc_20240419

load(url("https://www.dropbox.com/scl/fi/kp1lty1chtgzye8gnufl4/clea_lc_20240419.RData?rlkey=phvtoh91a48v9jky1m1120vnw&st=h7lnys7v&dl=1"))


# Explore the data
# glimpse(clea_lc_20240419)

# Filter the data for Italy

# clea_lc_20240419 %>%
#  filter(ctr_n == "Italy") %>%
#  glimpse()

# Filter for one year
table(clea_lc_20240419$yr)

taitaly_2020 <- clea_lc_20240419 %>%
  filter(ctr_n == "Italy", yr == 2020) 

italy_2000_2025 <- clea_lc_20240419 %>%
  filter(ctr_n == "Italy", yr > 2000) 

# Filter for 2013
italy_2013 <- clea_lc_20240419 %>%
  filter(ctr_n == "Italy", yr == 2013) 

italy_2013_district1 <- italy_2013 

italy_2013_district1 <- italy_2013_district1 %>%
  group_by(cst) %>%
  summarize(enp_v = 1/sum(pvs1^2),
            enp_s = 1/sum((seat/mag)^2))

