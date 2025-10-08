* Calculate ENP for one district in Italy

version 18
clear all
set more off


* Load CLEA data directly from Dropbox (.dta)

use "https://www.dropbox.com/scl/fi/lsvfiky9lkc1kizdhh11x/clea_lc_20240419.dta?rlkey=vzt02aymcz40rtgmcy3ak5wph&st=b0ah5xkk&dl=1"


--- Restrict scope: Italy ---
keep if inlist(ctr_n, "Italy")

tab(yr)


keep if inrange(yr, 2013, 2013)

tab(yr)

tab(cst_n)

tab(cst)

keep if cst == 1

tab(cst)

gen votes2 =  (pvs1^2)

gen seats2 = (seat/mag)^2


egen double env_sum = total(votes2)
egen double enp_sum = total(seats2)

gen enp_v = 1/env_sum
gen enp_s = 1/enp_sum
