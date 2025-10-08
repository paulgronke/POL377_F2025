*******************************************************
* ENP from CLEA constituency data (2000–2025)
* Countries: Denmark & Italy
* Source file (Stata): clea_lc_20240419.dta
* Uses vars: CTR, YR, CST, MAG, PTY, PV1, SEAT (names case-insensitive)
*******************************************************

version 18
clear all
set more off


* Load CLEA data directly from Dropbox (.dta)

use "https://www.dropbox.com/scl/fi/lsvfiky9lkc1kizdhh11x/clea_lc_20240419.dta?rlkey=vzt02aymcz40rtgmcy3ak5wph&st=b0ah5xkk&dl=1"


*--- Clean special missing codes across ALL variables ---
local missnum  -990 -992 -994

* numeric vars: change codes to system missing .
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    quietly replace `v' = .  if inlist(`v', `missnum')
}

* string vars: blank out those codes
ds, has(type string)
foreach v of varlist `r(varlist)' {
    quietly replace `v' = "" if inlist(`v', "-990", "-992", "-994")
}

*--- Restrict scope: Denmark & Italy, 2000–2025 ---
keep if inlist(ctr_n, "Denmark", "Italy")
keep if inrange(yr, 2000, 2025)

tempfile base
save "`base'", replace

*******************************************************
* DISTRICT-LEVEL ENP (Votes & Seats)
*******************************************************
use "`base'", clear

* Aggregate to party x district totals
collapse (sum) votes=pv1 seats=seat, by(ctr ctr_n yr cst pty)

* Totals within each district
bysort ctr ctr_n yr cst: egen tot_votes = total(votes)
bysort ctr ctr_n yr cst: egen tot_seats = total(seats)

gen double vote_share = cond(tot_votes>0, votes/tot_votes, .)
gen double seat_share = cond(tot_seats>0, seats/tot_seats, .)

* ENP per district: ENP = 1/sum(p_i^2)
gen double v2 = vote_share^2
gen double s2 = seat_share^2
bysort ctr ctr_n yr cst: egen double sum_v2 = total(v2)
bysort ctr ctr_n yr cst: egen double sum_s2 = total(s2)

gen double enp_votes = 1/sum_v2
gen double enp_seats = 1/sum_s2

* Keep one row per district
bysort ctr ctr_n yr cst: gen byte _tag = (_n==1)
keep if _tag
drop v2 s2 sum_v2 sum_s2 _tag votes seats tot_*

tempfile enp_district
save "`enp_district'", replace

* -------- Plots: scatter ENP_seats vs ENP_votes with LOWESS, faceted by year --------
levelsof ctr_n, local(countries)
foreach C of local countries {
    preserve
        keep if ctr_n=="`C'"
        keep if enp_votes<. & enp_seats<.

        * The by(yr) layout will create small multiples by election year
        twoway ///
            (scatter enp_seats enp_votes, msize(vsmall) msymbol(o) ///
                    xtitle("ENP (Votes)") ytitle("ENP (Seats)")) ///
            (lowess  enp_seats enp_votes, bwidth(.8) lwidth(medthick)), ///
            by(yr, title("`C': District-level ENP (Votes vs Seats), 2000–2025") ///
                    note("Source: CLEA (PV1, SEAT). LOWESS fitted per panel.") ///
                    cols(5) compact)

        graph export "enp_scatter_stata`=lower("`C'")'_2000_2025.jpg", width(2400) replace
    restore
}

*******************************************************
* NATIONWIDE ENP (by election)
*******************************************************
use "`base'", clear

* Party totals by country-year
collapse (sum) votes=pv1 seats=seat, by(ctr ctr_n yr pty)

* Shares within country-year
bysort ctr ctr_n yr: egen double tot_votes = total(votes)
bysort ctr ctr_n yr: egen double tot_seats = total(seats)

gen double vote_share = cond(tot_votes>0, votes/tot_votes, .)
gen double seat_share = cond(tot_seats>0, seats/tot_seats, .)

* ENP by country-year
gen double v2 = vote_share^2
gen double s2 = seat_share^2
bysort ctr ctr_n yr: egen double sum_v2 = total(v2)
bysort ctr ctr_n yr: egen double sum_s2 = total(s2)

gen double ENP_votes = 1/sum_v2
gen double ENP_seats = 1/sum_s2

* Keep one obs per country-year
bysort ctr ctr_n yr: gen byte _tag = (_n==1)
keep if _tag
keep ctr ctr_n yr ENP_votes ENP_seats
sort ctr_n yr
tempfile enp_nat
save "`enp_nat'", replace

* -------- Plot: ENP (Votes vs Seats) over time, by country --------
use "`enp_nat'", clear

twoway ///
    (line ENP_votes yr, lwidth(medthick) lpattern(solid) msymbol(circle) msize(small)) ///
    (line ENP_seats yr, lwidth(medthick) lpattern(shortdash) msymbol(triangle) msize(small)), ///
    by(ctr_n, cols(1) legend(on order(1 "Votes" 2 "Seats") pos(6) ring(0))) ///
    xtitle("Election Year") ytitle("ENP") ///
    title("Nationwide ENP, 2000–2025") ///
    note("Denmark and Italy · ENP = 1 / Σ p_i^2")

graph export "enp_nationwide_denmark_italy_2000_2025.png", width(2400) replace

