* 0. Import SPSS file directly
*    Force FIPSCode to be string on import


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
	
	
* 1) Build the state rates table from your EAVS file (if you haven't already)
*use eavs_2024.dta, clear
collapse (sum) prov_cast=F1e valid_cast=F1a, by(State_Full)
gen prov_rate = cond(valid_cast>0, 100*prov_cast/valid_cast, .)
keep State_Full prov_rate prov_cast valid_cast
gen _st_join = lower(State_Full)
tempfile state_rates
save "`state_rates'", replace

* -----------------------------
* 2) State-level table
* -----------------------------

* Clean display and export
format prov_rate %9.2f
label var prov_cast "Provisional Ballots Cast"
label var valid_cast "Valid Ballots Cast"
label var prov_rate  "Provisional Usage (%)"

list, noobs abbreviate(20)


* 2) Load the STATE attributes (NOT the _shp file), drop territories, prep join key
use us_states, clear              // <-- attributes file created by spshape2dta
ds STATEFP*
local statevar `r(varlist)'
ds NAME*
local namevar `r(varlist)'

drop if inlist(`statevar', "60","66","69","72","78")   // AS, GU, MP, PR, VI
gen _st_join = lower(`namevar')

* 3) Merge the rates into the attributes by state name
merge 1:1 _st_join using "`state_rates'", nogen keep(match)

* (Optional) sanity checks
count if missing(prov_rate)
summ prov_rate

* 4) Draw the map using the COORDINATES file via 'using', but keep attributes in memory
spmap prov_rate using us_states_shp, id(_ID) ///
    fcolor(Blues) ocolor(white ..) osize(vthin ..) ///
    clmethod(quantile) clnumber(5) legend(pos(3) ring(0)) ///
    ndocolor(gs14) ndfcolor(gs14) ///
    title("Provisional Ballot Usage by State (EAVS 2024)") ///
    note("Rate = (Provisional ÷ Valid) × 100    Source: EAVS 2024")
