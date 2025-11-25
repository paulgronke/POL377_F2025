*******************************************************
* NEW PARTISAN VOTER: Exploring the ANES Cumulative File
* Stata version (Bafumi & Shapiro 2009 replication)
*******************************************************

capture log close
log using "new_partisan_voter.log", text replace

clear all
set more off

*******************************************************
* 1. Read in the cumulative file & keep relevant years
*******************************************************

* Assumes you are running from the "Final_Assignment_Voting_Models"
* folder, so the relative path is used:
use "../data/ANES/anes_timeseries_cdf_stata_20220916.dta", clear

* Keep ANES presidential years where PID is available: 1952+
keep if inlist(VCF0004, 1952, 1956, 1960, 1964, 1968, ///
                         1972, 1976, 1980, 1984, 1988, ///
                         1992, 1996, 2000, 2004, 2008, 2012)

* Drop cases with missing or nonpositive weight
drop if missing(VCF0009z)
drop if VCF0009z <= 0

* Set survey design using CDF full-sample weight (VCF0009z)
svyset _n [pweight = VCF0009z]


*******************************************************
* 2. Create recoded variables (match your R recodes)
*******************************************************

* Voted in election (0 = did not vote, 1 = voted)
generate byte voted = .
replace voted = 0 if VCF0702 == 1
replace voted = 1 if VCF0702 == 2
label variable voted "Voted in election (0=No, 1=Yes)"

* Voted for Democratic candidate
generate byte vote_democrat = .
replace vote_democrat = 1 if VCF0704a == 1
replace vote_democrat = 0 if VCF0704a == 2
label variable vote_democrat "Voted Democrat (1=Dem, 0=Rep)"

* Voted for Republican candidate
generate byte vote_republican = .
replace vote_republican = 1 if VCF0704a == 2
replace vote_republican = 0 if VCF0704a == 1
label variable vote_republican "Voted Republican (1=Rep, 0=Dem)"

* Democrat incumbent flipper
generate byte democrat_incumbent_flipper = .

replace democrat_incumbent_flipper =  1 if inlist(VCF0004, ///
  1948, 1952, 1964, 1968, 1980, 1996, 2000, 2012, 2016)

replace democrat_incumbent_flipper = -1 if inlist(VCF0004, ///
  1956, 1960, 1972, 1976, 1984, 1988, 1992, 2004, 2008, 2020)

label variable democrat_incumbent_flipper "Dem incumbent=1, Rep incumbent=-1"

* Race dummy: Black vs Non-Black (pol377black)
generate byte pol377black = .
replace pol377black = 1 if VCF0106 == 2      // Black
replace pol377black = 0 if VCF0106 == 1      // White (you only coded 1 in R)
label define pol377black_lbl 0 "Non-Black" 1 "Black"
label values pol377black pol377black_lbl
label variable pol377black "Black respondent (1=Black, 0=Non-Black)"

* Income dummies (pol377inc2–pol377inc5), following your R coding
generate byte pol377inc2 = .
replace pol377inc2 = 1 if VCF0114 == 2
replace pol377inc2 = 0 if inlist(VCF0114, 1, 3, 4, 5)

generate byte pol377inc3 = .
replace pol377inc3 = 1 if VCF0114 == 3
replace pol377inc3 = 0 if inlist(VCF0114, 1, 2, 4, 5)

generate byte pol377inc4 = .
replace pol377inc4 = 1 if VCF0114 == 4
replace pol377inc4 = 0 if inlist(VCF0114, 1, 2, 3, 5)

generate byte pol377inc5 = .
replace pol377inc5 = 1 if VCF0114 == 5
replace pol377inc5 = 0 if inlist(VCF0114, 1, 2, 3, 4)

label variable pol377inc2 "Income category 2 (vs others)"
label variable pol377inc3 "Income category 3 (vs others)"
label variable pol377inc4 "Income category 4 (vs others)"
label variable pol377inc5 "Income category 5 (vs others)"

* Age variable (numeric, scaled for later)
generate age = VCF0101
label variable age "Respondent age"

* 7-point Party ID (VCF0301), keep only 1–7
generate partyid = VCF0301
replace partyid = . if !inlist(partyid,1,2,3,4,5,6,7)
label variable partyid "7-point Party ID (1–7)"

* Male dummy (1=Male, 0=Female)
generate byte male = .
replace male = 1 if VCF0104 == 1
replace male = 0 if VCF0104 == 2
label define male_lbl 0 "Female" 1 "Male"
label values male male_lbl
label variable male "Male (1) vs Female (0)"

* South dummy (VCF0113: 1=South, 2=Non-South)
generate byte south = .
replace south = 1 if VCF0113 == 1
replace south = 0 if VCF0113 == 2
label define south_lbl 0 "Non-South" 1 "South"
label values south south_lbl
label variable south "South (1) vs Non-South (0)"


*******************************************************
* 3. Replicate Bafumi & Shapiro (2009) Figure 1
*    SD of 7-point party ID over time, with LOWESS
*******************************************************

preserve

tempfile pid_sd
postfile sd_handle int year double sd_weighted sd_unweighted using `pid_sd', replace

* Get the list of years in the data
levelsof VCF0004, local(years)

foreach y of local years {

    * weighted SD using svy: mean (variance -> SD)
    quietly svy, subpop(if VCF0004 == `y'): mean partyid
    matrix V = e(V)
    scalar sd_w = sqrt(V[1,1])

    * unweighted SD
    quietly summarize partyid if VCF0004 == `y', meanonly
    scalar sd_u = r(sd)

    post sd_handle (`y') (sd_w) (sd_u)
}

postclose sd_handle

use `pid_sd', clear
label variable year "Election year"
label variable sd_weighted   "SD (survey-weighted)"
label variable sd_unweighted "SD (unweighted)"

list, sepby(year)

* Plot: SD of Party ID over time with LOWESS smoother
twoway ///
    (scatter sd_weighted year, msize(medium)) ///
    (lowess sd_weighted year, bwidth(0.5) lwidth(medthick)), ///
    title("Standard Deviation of 7-Point Party Identification, 1952–2012") ///
    subtitle("Replication of Bafumi & Shapiro (2009) Figure 1") ///
    xtitle("Election Year") ///
    ytitle("SD of Party ID (survey-weighted)") ///
    xlabel(1952(4)2012, angle(45)) ///
    ylabel(0(.1)1) ///
    legend(off)

restore


*******************************************************
* 4. Partial replication of Bafumi & Shapiro Figure 3
*    Logit coefficients over time: age, age^2, PID, male, south
*******************************************************

* Scale age (like in your R code)
generate age10 = age/10
generate age10_sq = age10^2
label variable age10    "Age / 10"
label variable age10_sq "Age^2 / 100"

preserve

* We’ll loop over presidential years and estimate:
* svy: logit vote_republican age10 age10_sq partyid male south
tempfile coef_time
postfile coef_handle int year str10 term double estimate se using `coef_time', replace

* Define the years you want (match your R voting_years)
local voting_years 1952 1956 1960 1964 1968 1972 1976 1980 1984 1988 ///
                   1992 1996 2000 2004 2008 2012

foreach y of local voting_years {

    * Skip if year not in data (for safety)
    quietly count if VCF0004 == `y'
    if r(N) == 0 continue

    * Survey-weighted logit for this year
    quietly svy, subpop(if VCF0004 == `y'): ///
        logit vote_republican age10 age10_sq partyid male south

    * Post coefficients and SEs for the key terms
    foreach v in age10 age10_sq partyid male south {
        * Skip if coefficient not estimated
        capture confirm scalar _b[`v']
        if _rc continue

        scalar b  = _b[`v']
        scalar se = _se[`v']
        post coef_handle (`y') ("`v'") (b) (se)
    }
}

postclose coef_handle

use `coef_time', clear
label variable year "Election year"
label variable term "Predictor"
label variable estimate "Logit coefficient"
label variable se "Std. Error"

* 95% confidence intervals
generate double lower = estimate - 1.96*se
generate double upper = estimate + 1.96*se

* Nice labels for plotting (match R facet labels)
generate str30 term_label = term
replace term_label = "Age (/10)"                 if term == "age10"
replace term_label = "Age^2 ((age/10)^2)"        if term == "age10_sq"
replace term_label = "Party ID (7-point)"        if term == "partyid"
replace term_label = "Male (1) vs Female (0)"    if term == "male"
replace term_label = "South (1) vs Non-South"    if term == "south"

* Plot: coefficients with CIs and LOWESS, by predictor
twoway ///
    (rcap upper lower year, lwidth(thin)) ///
    (scatter estimate year, msize(small)) ///
    (lowess estimate year, lwidth(medthick)), ///
    by(term_label, cols(2) note("")) ///
    yline(0, lpattern(dash) lcolor(gs10)) ///
    title("Logit Coefficients for Vote Republican, 1952–2012") ///
    subtitle("Age, Age^2, Party ID, Male, South (partial replication of Bafumi & Shapiro Figure 3)") ///
    xtitle("Election Year") ///
    xlabel(1952(4)2012, angle(45)) ///
    ytitle("Logit coefficient (log-odds)") ///
    legend(off)

restore


*******************************************************
* End
*******************************************************
log close
