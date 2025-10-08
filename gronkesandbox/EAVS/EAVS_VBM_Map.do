*******************************************************
* EAVS 2024 – Vote-by-Mail (VBM) Usage Maps (State + County)
* Stata 18
* Requires: spmap, spshape2dta (from Stata/SSC)
*******************************************************



version 18
clear all
set more off
set scheme s2color

* Install spmap if needed
cap which spmap
if _rc ssc install spmap, replace

* -----------------------------
* 1) STATE table with full-VBM fix
* -----------------------------
*use "eavs_2024.dta", clear

import spss using ///
"2024_EAVS_for_Public_Release_V1.sav/2024_EAVS_for_Public_Release_V1.sav", ///
    clear 

capture confirm numeric variable FIPSCode
if !_rc {
    tostring FIPSCode, gen(fips_str) format(%010.0f)
    drop FIPSCode
    rename fips_str FIPSCode
}

* Now FIPSCode is a 10-character string.
* Keep only the first 5 digits (state+county code)
gen GEOID = substr(FIPSCode, 1, 5)

collapse (sum) vbm_d=F1e (sum) vbm_g=F1g (sum) valid_cast=F1a, by(State_Full)

* Use F1G when present and >0, otherwise F1D
gen double vbm_ballots = cond(!missing(vbm_g) & vbm_g>0, vbm_g, vbm_d)
gen double vbm_rate    = cond(valid_cast>0, 100*vbm_ballots/valid_cast, .)

order State_Full vbm_ballots valid_cast vbm_rate
sort  State_Full
label var vbm_ballots "Vote-by-Mail Ballots Cast"
label var valid_cast  "Valid Ballots Cast"
label var vbm_rate    "VBM Usage (%)"
format vbm_rate %9.2f

gen _st_join = lower(State_Full)
save "state_rates.dta", replace

list in 1/10, noobs abbreviate(20)

* -----------------------------
* 2) STATE map (using Census shapefile)
* -----------------------------
* Convert shapefile to Stata format (only needs to be run once)
* Download cb_2023_us_state_20m.zip from Census TIGER if not already
* spshape2dta cb_2023_us_state_20m, replace saving(us_states)

use us_states, clear
drop if inlist(STATEFP, "60","66","69","72","78")   // drop territories
* optionally: drop if inlist(STATEFP, "02","15")    // drop Alaska, Hawaii

gen _st_join = lower(NAME)
merge 1:1 _st_join using state_rates.dta, nogen keep(match)

spmap vbm_rate using us_states_shp, id(_ID) ///
    fcolor(Blues) ocolor(white ..) osize(vthin ..) ///
    clmethod(quantile) clnumber(5) ///
    legend(position(6) ring(0) rows(1)) ///
    ndocolor(gs14) ndfcolor(gs14) ///
    title("Vote-by-Mail Usage by State (EAVS 2024)") ///
    note("Rate = (VBM Ballots ÷ Valid Ballots) × 100   Source: EAVS 2024")

graph export "vbm_state_map.png", width(2800) replace

* -----------------------------
* 3) COUNTY table (FIPS-based)
* -----------------------------
*use "eavs_2024.dta", clear

import spss using ///
"2024_EAVS_for_Public_Release_V1.sav/2024_EAVS_for_Public_Release_V1.sav", ///
    clear 

capture confirm numeric variable FIPSCode
if !_rc {
    tostring FIPSCode, gen(fips_str) format(%010.0f)
    drop FIPSCode
    rename fips_str FIPSCode
}

* Now FIPSCode is a 10-character string.
* Keep only the first 5 digits (state+county code)
gen GEOID = substr(FIPSCode, 1, 5)



collapse (sum) vbm_d=F1d (sum) vbm_g=F1g (sum) valid_cast=F1a, by(GEOID)

gen double vbm_ballots = cond(!missing(vbm_g) & vbm_g>0, vbm_g, vbm_d)
gen double vbm_rate    = cond(valid_cast>0, 100*vbm_ballots/valid_cast, .)

label var vbm_rate "VBM Usage (%)"
format vbm_rate %9.2f

save "county_rates.dta", replace

* -----------------------------
* 4) COUNTY map (using Census shapefile)
* -----------------------------
* Convert shapefile to Stata format (only once)
* spshape2dta cb_2023_us_county_20m, replace saving(us_counties)

use us_counties, clear
drop if inlist(STATEFP, "60","66","69","72","78")

keep GEOID _ID
merge 1:1 GEOID using county_rates.dta, nogen keep(match)

spmap vbm_rate using us_counties_shp, id(_ID) ///
    fcolor(YlOrRd) ocolor(white ..) osize(vvthin ..) ///
    clmethod(quantile) clnumber(7) ///
    legend(position(6) ring(0) rows(1)) ///
    ndocolor(gs14) ndfcolor(gs14) ///
    title("Vote-by-Mail Usage by County (EAVS 2024)") ///
    note("Rate = (VBM Ballots ÷ Valid Ballots) × 100   Source: EAVS 2024")

graph export "vbm_county_map.png", width(3200) replace

****************
