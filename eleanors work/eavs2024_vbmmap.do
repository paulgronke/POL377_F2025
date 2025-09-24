* 1) Build the state rates table from your EAVS file (if you haven't already)
use eavs_2024.dta, clear
collapse (sum) vbm_cast=F1d valid_cast=F1a, by(State_Full)
gen vbm_rate = cond(valid_cast>0, 100*vbm_cast/valid_cast, .)
keep State_Full vbm_rate vbm_cast valid_cast
gen _st_join = lower(State_Full)
tempfile state_rates
save "`state_rates'", replace

* -----------------------------
* 2) State-level table
* -----------------------------

* Clean display and export
format vbm_rate %9.2f
label var vbm_cast "VBM Ballots Cast"
label var valid_cast "Valid Ballots Cast"
label var vbm_rate  "VBM Usage (%)"

list, noobs abbreviate(20)


* 2) Load the STATE attributes (NOT the _shp file), drop territories, prep join key
use us_states, clear              // <-- attributes file created by spshape2dta
drop if inlist(STATEFP, "02","15","60","66","69","72","78") 

ds STATEFP*
local statevar `r(varlist)'
ds NAME*
local namevar `r(varlist)'

drop if inlist(`statevar', "60","66","69","72","78")   // AS, GU, MP, PR, VI
gen _st_join = lower(`namevar')

* 3) Merge the rates into the attributes by state name
merge 1:1 _st_join using "`state_rates'", nogen keep(match)

* (Optional) sanity checks
count if missing(vbm_rate)
summ vbm_rate

* 4) Draw the map using the COORDINATES file via 'using', but keep attributes in memory
spmap vbm_rate using us_states_shp, id(_ID) ///
    fcolor(Blues) ocolor(white ..) osize(vthin ..) ///
    clmethod(quantile) clnumber(5) ///
    legend(position(6) ring(0) rows(1)) ///
    ndocolor(gs14) ndfcolor(gs14) ///
    title("VBM Ballot Usage by State (EAVS 2024)") ///
    note("Rate = (VBM ÷ Valid) × 100    Source: EAVS 2024") ///
    plotregion(margin(2 2 2 2)) graphregion(margin(6 6 6 6))
