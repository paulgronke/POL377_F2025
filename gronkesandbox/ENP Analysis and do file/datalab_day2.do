*******************************************************
* Italian Analysis (Stata version of your Rmd)
* ENP at constituency and national levels, Italy 2000–2025
*******************************************************

version 18
clear all
set more off

* ---------- Load CLEA directly from Dropbox (.dta) ----------
* Use ?dl=1 for a direct file
use "https://www.dropbox.com/scl/fi/kq3mhrpvi0dk3v67qnhkm/clea_lc_20240419.dta?rlkey=07cwz7k79drj0mt1g3d0hapei&st=4n8vpuxl&dl=1", clear

* ---------- Standardize variable names (lowercase if needed) ----------
capture confirm variable ctr_n
if _rc {
    foreach v in CTR CTR_N YR CST MAG PTY PV1 PVS1 SEAT {
        capture confirm variable `v'
        if !_rc {
            rename `v' `=lower("`v'")'
        }
    }
}

* ---------- Clean special missings in numeric vars ----------
local misscodes -990 -992 -994
ds, has(type numeric)
foreach v of varlist `r(varlist)' {
    quietly replace `v' = . if inlist(`v', `misscodes')
}

* ---------- Restrict to Italy, 2000–2025 ----------
keep if ctr_n == "Italy"
keep if inrange(yr, 2000, 2025)

tempfile italy_base
save "`italy_base'", replace

*******************************************************
* District-level ENP (Italy 2013)  — mirrors your italy_2013_enp
*******************************************************
use "`italy_base'", clear
keep if yr == 2013

* Vote share within district:
* If pvs1 exists (already a share), use it; else compute from pv1 totals
capture confirm variable pvs1
if _rc {
    * compute vote shares from pv1 per (yr,cst)
    bys yr cst: egen double tot_votes = total(pv1)
    gen double vote_share = cond(tot_votes>0, pv1 / tot_votes, .)
}
else {
    gen double vote_share = pvs1
}

* Seat share within district: seat/mag
gen double seat_share = cond(mag>0, seat/mag, .)

* ENP per district: 1 / sum(p_i^2)
gen double v2 = vote_share^2
gen double s2 = seat_share^2
bys yr cst: egen double sum_v2 = total(v2)
bys yr cst: egen double sum_s2 = total(s2)
gen double enp_v = 1/sum_v2
gen double enp_s = 1/sum_s2

* One row per district
bys yr cst: gen byte _keep = (_n==1)
keep if _keep
keep yr cst enp_v enp_s
tempfile italy_2013_enp
save "`italy_2013_enp'", replace

*******************************************************
* Scattergram for 2013 only (district ENP)
*******************************************************
use "`italy_2013_enp'", clear

twoway ///
    (scatter enp_s enp_v, msize(small)) ///
    (function y = x, range(1 6) lcolor(red) lpattern(dash)) ///
    (lowess enp_s enp_v, lcolor(blue)), ///
    xtitle("ENP Votes") ytitle("ENP Seats") ///
    xscale(range(1 6)) yscale(range(1 6)) ///
    xlabel(1(1)6) ylabel(1(1)6, angle(0)) legend(off) ///
    title("ENP Votes vs ENP Seats — Italy 2013", size(medsmall)) ///
    name(enp_it_2013, replace)

graph export "enp_it_2013.png", width(1600) replace

*******************************************************
* District-level ENP (all Italy, 2000–2025) — mirrors italy_enp
*******************************************************
use "`italy_base'", clear

* Vote share within district
capture confirm variable pvs1
if _rc {
    bys yr cst: egen double tot_votes = total(pv1)
    gen double vote_share = cond(tot_votes>0, pv1 / tot_votes, .)
}
else {
    gen double vote_share = pvs1
}

* Seat share within district
gen double seat_share = cond(mag>0, seat/mag, .)

* ENP per district
gen double v2 = vote_share^2
gen double s2 = seat_share^2
bys yr cst: egen double sum_v2 = total(v2)
bys yr cst: egen double sum_s2 = total(s2)
gen double enp_v = 1/sum_v2
gen double enp_s = 1/sum_s2

bys yr cst: gen byte _keep = (_n==1)
keep if _keep
keep yr cst enp_v enp_s
tempfile italy_enp_all
save "`italy_enp_all'", replace

*******************************************************
* Separate scattergram for each year (district ENP)
*******************************************************
use "`italy_enp_all'", clear

* Get the set of available years
levelsof yr if !missing(enp_v, enp_s), local(years)

* Create one graph per year and export
foreach Y of local years {
    twoway ///
        (scatter enp_s enp_v if yr==`Y', msize(small)) ///
        (function y = x, range(1 6) lcolor(red) lpattern(dash)) ///
        (lowess enp_s enp_v if yr==`Y', lcolor(blue)), ///
        xtitle("ENP Votes") ytitle("ENP Seats") ///
        xscale(range(1 6)) yscale(range(1 6)) ///
        xlabel(1(1)6) ylabel(1(1)6, angle(0)) legend(off) ///
        title("ENP Votes vs ENP Seats — Italy `Y'", size(medsmall)) ///
        name(enp_it_`Y', replace)

    graph export "enp_it_`Y'.png", width(1600) replace
}

* Optional: also show all years in a single multi-panel figure
* Adjust cols() as you like (e.g., 4 or 5 depending on how many years)
* by(yr) will remake the graph; use this just for visual inspection
twoway ///
    (scatter enp_s enp_v, msize(tiny)) ///
    (function y = x, range(1 6) lcolor(red) lpattern(dash)) ///
    (lowess enp_s enp_v, lcolor(blue)), ///
    by(yr, cols(4) compact note("") title("ENP Votes vs ENP Seats — Italy by Year")) ///
    xtitle("ENP Votes") ytitle("ENP Seats") ///
    xscale(range(1 6)) yscale(range(1 6)) ///
    xlabel(1(1)6) ylabel(1(1)6, angle(0)) legend(off) ///
    name(enp_it_all_by, replace)

* graph export "enp_it_all_by.png", width(2400) replace

*******************************************************
* National party totals and National ENP — mirrors your mk_party_key + national calc
*******************************************************
use "`italy_base'", clear

* Create a stable party key like your mk_party_key():
* - If pty is labeled numeric, decode to string; else stringify
capture confirm variable pty
if !_rc {
    capture confirm value label pty
    if !_rc {
        decode pty, gen(pty_key)
    }
    else {
        tostring pty, gen(pty_key) force
    }
    replace pty_key = strtrim(pty_key)
}
else {
    * fallback if column is different in your file
    display as error "Variable 'pty' not found."
    exit 111
}

* Collapse to one row per (yr, party): totals of votes and seats
collapse (sum) pty_v = pv1 pty_s = seat, by(yr pty_key)

tempfile italy_national_partydata
save "`italy_national_partydata'", replace

* National ENP by year
* vote_share = party votes / total votes (year)
* seat_share = party seats / total seats (year)
bys yr: egen double tot_votes = total(pty_v)
bys yr: egen double tot_seats = total(pty_s)

gen double vote_share = cond(tot_votes>0, pty_v/tot_votes, .)
gen double seat_share = cond(tot_seats>0, pty_s/tot_seats, .)

gen double v2 = vote_share^2
gen double s2 = seat_share^2
bys yr: egen double sum_v2 = total(v2)
bys yr: egen double sum_s2 = total(s2)

gen double ENP_votes = 1/sum_v2
gen double ENP_seats = 1/sum_s2

* One row per year
bys yr: gen byte _keep = (_n==1)
keep if _keep
keep yr ENP_votes ENP_seats
tempfile italy_enp_national
save "`italy_enp_national'", replace



*******************************************************
* (Optional) Quick previews
*******************************************************
use "`italy_2013_enp'", clear
list in 1/5, abbrev(20)

use "`italy_enp_all'", clear
list in 1/5, abbrev(20)

use "`italy_enp_national'", clear
list, sepby(yr)

