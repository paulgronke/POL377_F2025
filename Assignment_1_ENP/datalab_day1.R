# ENP Data Lab Day One

# Load the required packages
library(tidyverse)

# Load the data 
# Loads clea_lc_20240419

load(url("https://www.dropbox.com/scl/fi/kp1lty1chtgzye8gnufl4/clea_lc_20240419.RData?rlkey=phvtoh91a48v9jky1m1120vnw&st=h7lnys7v&dl=1"))


# Explore the data
# glimpse(clea_lc_20240419)

# Filter the data for Italy

italy <- clea_lc_20240419 %>%
  filter(ctr_n == "Italy") 

# See how many years are in the data 
table(italy$yr)

# Filter for 2013

italy_2013 <- italy %>%
  filter(ctr_n == "Italy", yr == 2013) 

# See how many constituencies there are 

table(italy_2013$cst)


# Filter for just the first constituency
italy_2013_district1 <- italy_2013 %>%
  filter(ctr_n == "Italy", yr == 2013, cst == 1) 

# Calculate the ENP for votes and seats
# Notice that because we have only one constituency, this should result 
# in just two values 


italy_2013_district1_enp <- italy_2013_district1 %>%
  group_by(cst) %>%
  summarize(enp_v = 1/sum(pvs1^2),
            enp_s = 1/sum((seat/mag)^2))

# Print the results
print(italy_2013_district1_enp)
