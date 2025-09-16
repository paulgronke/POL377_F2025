 Calculate ENP for one district in Italy

version 18
clear all
set more off


* Load CLEA data directly from Dropbox (.dta)

use "https://www.dropbox.com/scl/fi/kq3mhrpvi0dk3v67qnhkm/clea_lc_20240419.dta?rlkey=07cwz7k79drj0mt1g3d0hapei&st=4n8vpuxl&dl=1", clear


* --- Restrict scope: Italy ---
keep if inlist(ctr_n, "Italy")

tab(yr)


keep if inrange(yr, 2013, 2013)

tab(yr)

tab(cst_n)

tab(cst)

* keep if cst == 1

* tab(cst)


gen seatshare = (seat/mag)
gen voteshare2 = pvs1^2
gen seatshare2 = seatshare^2


bysort cst: egen double env_sum = total(voteshare2)
bysort cst: egen double enp_sum = total(seatshare2)

gen enp_v = 1/env_sum
gen enp_s = 1/enp_sum

*Keep one obs per country-year-constituency
bysort yr ctr ctr_n cst cst_n: gen byte _tag = (_n==1)
keep if _tag


* Keep one obs per country-year
*bysort ctr ctr_n yr: gen byte _tag = (_n==1)
*keep if _tag


twoway ///
    (scatter enp_s enp_v, msize(small)) ///
    (function y = x, range(1 6) lcolor(red) lpattern(dash)) ///
    (lowess enp_s enp_v, lcolor(blue)), ///
    xtitle("ENP Votes") ytitle("ENP Seats") ///
    xscale(range(1 6)) yscale(range(1 6)) ///
    xlabel(1(1)6) ylabel(1(1)6, angle(0)) legend(off) ///
    title("ENP Votes vs ENP Seats — Italy 2013", size(medsmall)) ///
    name(enp_it_2013, replace)
