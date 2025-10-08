/* Set the system to zero state */

clear all
set more off

/* Start by creating a log file */
capture log close
log using "Assignment_3_SPAE_results.log", replace

*******************************************************
* Assignment_3_SPAE.do
* Purpose: Stata version of the SPAE lab
***************************************************

*******************************************************
* Step 1: Read in the SPAE (Stata and SPSS versions)
*******************************************************

* --- Option A: Read the Stata (.dta) version ---

use "/Users/gronkep/Library/CloudStorage/GoogleDrive-gronkep@reed.edu/Shared drives/POL377_F2025/data/SPAE/mitu0051_output.dta", clear
tempfile spae_stata
save "`spae_stata'", replace

* --- Option B: Read the SPSS (.sav) version ---
* Stata 18+ can directly import .sav;
* labels and value labels are brought in as Stata variable/value labels.

 import spss using "/Users/gronkep/Library/CloudStorage/GoogleDrive-gronkep@reed.edu/Shared drives/POL377_F2025/data/SPAE/MITU0051_OUTPUT.sav", clear

tempfile spae_spss
save "`spae_spss'", replace

*******************************************************
* Step 2: Explore the SPAE
*   Compare SPSS vs Stata versions (labels, counts, etc.)
*******************************************************

* Quick structure and summary (SPSS import)
use "`spae_spss'", clear
describe
codebook, compact

* Peek at key variables (Q1, pid3); Stata uses value labels automatically
tabulate Q1, missing
tabulate pid3, missing

* Compare with the Stata version
use "`spae_stata'", clear
describe
codebook q1 pid3 weight_stacked, compact
tabulate q1, missing
tabulate pid3, missing

*******************************************************
* Step 3: Working with labels
*   (In Stata, value labels from .dta or .sav are used automatically by tabulate)
*******************************************************


* Example: show both numeric codes and labels
tabulate q1, nolabel
tabulate q1, missing

*******************************************************
* Step 4: Use survey weights (aweights) in Stata
******************************************************

use "`spae_stata'", clear


* One-way weighted distributions
* - Weighted distribution of PID3
tabulate pid3 [aweight = weight_stacked], missing

* - Weighted distribution of Q1
tabulate q1   [aweight = weight_stacked], missing


*******************************************************
* Step 5: Recode a few variables (simple, readable)
* - Put "I don't know" -> missing
* - Collapse confidence items to Confident vs Not confident
* - Recode pid3 to 3 buckets (D/R/Ind); drop Other/Not sure
*******************************************************

* We'll work from the Stata version for consistency
use "`spae_stata'", clear

* Make a convenient copy of pid3 as string (robust if pid3 is labeled numeric)
capture confirm string variable pid3
if _rc {
    decode pid3, gen(pid3_s)
}
else {
    gen strL pid3_s = pid3
}

* Keep only D/R/Independent; set Other / Not sure / missing to .
gen str15 pid3_3 = .
replace pid3_3 = "Democrat"    if pid3_s == "Democrat"
replace pid3_3 = "Republican"  if pid3_s == "Republican"
replace pid3_3 = "Independent" if pid3_s == "Independent"
label define pid3_3_lbl 1 "Democrat" 2 "Republican" 3 "Independent"
encode pid3_3, gen(pid3_3cat) label(pid3_3_lbl)

* Q39/Q42 as strings (again robust to labeled numeric)
capture confirm string variable Q39
if _rc  decode Q39, gen(Q39_s)
else    gen strL Q39_s = Q39

capture confirm string variable Q42
if _rc  decode Q42, gen(Q42_s)
else    gen strL Q42_s = Q42

* Turn "I don't know" into missing for both
gen str20 Q39_clean = Q39_s
replace Q39_clean = "" if trim(Q39_s) == "I don't know"

gen str20 Q42_clean = Q42_s
replace Q42_clean = "" if trim(Q42_s) == "I don't know"

* Collapse each to Confident / Not confident (own vote and national)
gen str14 Q39_2 = "" 
replace Q39_2 = "Confident"     if inlist(Q39_clean,"Very confident","Somewhat confident")
replace Q39_2 = "Not confident" if inlist(Q39_clean,"Not too confident","Not at all confident")

gen str14 Q42_2 = "" 
replace Q42_2 = "Confident"     if inlist(Q42_clean,"Very confident","Somewhat confident")
replace Q42_2 = "Not confident" if inlist(Q42_clean,"Not too confident","Not at all confident")

* Indicator for “Confident” on national item (useful for % calculations)
gen byte confident_nat = (Q42_2=="Confident") if Q42_2!=""
label var confident_nat "Confident about national vote (Q42_2==Confident)"

* Clean up a state variable name: use inputstate if present, else State
capture confirm variable inputstate
if _rc {
    capture confirm variable State
    if !_rc {
        clonevar inputstate = State
    }
}
label var inputstate "State"

*******************************************************
* Step 6: Weighted one-way tables & by-group tables
*******************************************************

* Weighted distribution of pid3 (3 groups), excluding missing
tabulate pid3_3cat if pid3_3cat<., [aweight=weight_stacked], missing

* Weighted distribution of Q1 (turnout)
capture noisily tabulate q1 [aweight=weight_stacked], missing

* Weighted 2-way: Voter confidence (national, collapsed) by PID3
tabulate pid3_3cat Q42_2 if pid3_3cat<. & Q42_2!="", ///
    [aweight=weight_stacked], row column nofreq

*******************************************************
* Step 7: “Nice” figures mirroring the R examples
*******************************************************

* 7A. Bar chart – % Confident (national) by PID3
* We compute weighted means of the indicator and plot.
preserve
    keep if pid3_3cat<. & Q42_2!=""
    collapse (mean) pct_conf=confident_nat [aweight=weight_stacked], by(pid3_3cat)
    label var pct_conf "% Confident (national)"
    * Plot as vertical bars
    graph bar pct_conf, over(pid3_3cat, label(angle(0))) ///
        ytitle("Percent Confident") ///
        ylabel(0(.1)1, format(%3.0f) angle(0)) ///
        bargap(30) bar(1, fcolor(navy*0.6)) ///
        title("Voter Confidence (national) by Party ID") ///
        yscale(range(0 1))
restore

* 7B. “Voter confidence by State” table (weighted % confident)
* Simple, readable: collapse then list (or export)
preserve
    keep if inputstate!="" & Q42_2!=""
    collapse (mean) pct_conf=confident_nat [aweight=weight_stacked], by(inputstate)
    sort inputstate
    format pct_conf %4.1f
    list inputstate pct_conf, abbreviate(16) noobs sepby()
restore

* 7C. Horizontal bar chart – % Confident by State (sorted), with whitespace
preserve
    keep if inputstate!="" & Q42_2!=""
    collapse (mean) pct_conf=confident_nat [aweight=weight_stacked], by(inputstate)
    * Encode to order by mean descending
    egen ord = rank(pct_conf), field
    sort pct_conf
    encode inputstate, gen(state_cat)
    label var pct_conf "% Confident (national)"
    graph hbar pct_conf, over(state_cat, sort(1) descending ///
        label(labsize(small)) gap(20)) ///
        ytitle("Percent Confident") ///
        ylabel(0(.1)1, format(%3.0f)) ///
        bargap(40) bar(1, fcolor(navy*0.6)) ///
        title("Voter Confidence (national) by State") ///
        yscale(range(0 1))
restore


