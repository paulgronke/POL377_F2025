*******************************************************
* Exploring the ANES Cumulative File (1948–2012)
* Stata version 
*******************************************************

* Start a log file so your work and results are saved
capture log close
log using "final_assignment_turnout.log", text replace

clear all
set more off

*******************************************************
* 1. Read in the cumulative file & keep presidential years
*******************************************************

* Assumes you are running from the "Final_Assignment_Voting_Models"
* folder, so the relative path is used to read the data.
use "../data/ANES/anes_timeseries_cdf_stata_20220916.dta", clear

* Keep only presidential election years (VCF0004 = year of study)
keep if inlist(VCF0004, 1948, 1952, 1956, 1960, 1964, 1968, ///
                         1972, 1976, 1980, 1984, 1988, ///
                         1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020)

* Drop cases with missing or non-positive CDF weight VCF0009z
drop if missing(VCF0009z)
drop if VCF0009z <= 0

* Set survey design using CDF full-sample weight (VCF0009z)
svyset _n [pweight = VCF0009z]


*******************************************************
* 3. Create recoded variables (voted, vote_democrat, flipper, race, income)
*******************************************************

* Voted in election (0 = did not vote, 1 = voted)
generate byte voted = .
replace voted = 0 if VCF0702 == 1
replace voted = 1 if VCF0702 == 2

label variable voted "Voted in election (0=No, 1=Yes)"

* Voted for Democratic candidate (1 = Democrat, 0 = Republican)
generate byte vote_democrat = .
replace vote_democrat = 1 if VCF0704a == 1
replace vote_democrat = 0 if VCF0704a == 2

label variable vote_democrat "Voted for Democratic candidate (1=Dem, 0=Rep)"

* Democrat incumbent flipper:
* +1 in years with a Democratic incumbent
* -1 in years with a Republican incumbent
generate byte democrat_incumbent_flipper = .

* Democratic incumbent years
replace democrat_incumbent_flipper =  1 if inlist(VCF0004, 1948, 1952, 1964, 1968, 1980, 1996, 2000, 2012, 2016)

* Republican incumbent years
replace democrat_incumbent_flipper = -1 if inlist(VCF0004, 1956, 1960, 1972, 1976, 1984, 1988, 1992, 2004, 2008, 2020)

label variable democrat_incumbent_flipper "Dem incumbent=1, Rep incumbent=-1"

* Race dummy: Black vs Non-Black (matches pol377black in R)
generate byte pol377black = .
replace pol377black = 1 if VCF0106 == 2                  // Black
replace pol377black = 0 if inlist(VCF0106, 1)         // White 
label define pol377black_lbl 0 "Non-Black" 1 "Black"
label values pol377black pol377black_lbl
label variable pol377black "Black respondent (1=Black, 0=Non-Black)"

* Income dummies (pol377inc2–pol377inc5), following your R coding
* VCF0114 categories assumed 1–5
generate byte pol377inc2 = .
replace pol377inc2 = 1 if VCF0114 == 2
replace pol377inc2 = 0 if inlist(VCF0114, 1, 3, 4, 5)
label variable pol377inc2 "Income category 2 (vs others)"

generate byte pol377inc3 = .
replace pol377inc3 = 1 if VCF0114 == 3
replace pol377inc3 = 0 if inlist(VCF0114, 1, 2, 4, 5)
label variable pol377inc3 "Income category 3 (vs others)"

generate byte pol377inc4 = .
replace pol377inc4 = 1 if VCF0114 == 4
replace pol377inc4 = 0 if inlist(VCF0114, 1, 2, 3, 5)
label variable pol377inc4 "Income category 4 (vs others)"

generate byte pol377inc5 = .
replace pol377inc5 = 1 if VCF0114 == 5
replace pol377inc5 = 0 if inlist(VCF0114, 1, 2, 3, 4)
label variable pol377inc5 "Income category 5 (vs others)"

* Age variable (numeric)
generate age = VCF0101
label variable age "Respondent age"

* Code missing values for Likes and Dislikes example
replace VCF0322 = . if VCF0322 == 999


*******************************************************
* 4. Turnout over time (tables + line chart)
*******************************************************

* Weighted proportion who voted by year 
preserve
collapse (mean) prop_voted = voted [aweight = VCF0009z], by(VCF0004)
sort VCF0004

* Format to two decimals
format prop_voted %4.2f

list VCF0004 prop_voted, sepby(VCF0004)

* Line plot of turnout over time
twoway line prop_voted VCF0004, ///
    title("Estimated Turnout in ANES Presidential Years") ///
    xtitle("Year of ANES Study (VCF0004)") ///
    ytitle("Proportion Who Voted (survey-weighted)") ///
    xlabel(1948(4)2020, angle(45)) ///
    ylabel(0(.1)1)

graph export "turnout_over_time.png", replace width(2000)

restore


*******************************************************
* 5. Turnout model for 1988: OLS vs Logit + margins
*******************************************************

* Keep things simple: focus on 1988 
preserve
keep if VCF0004 == 1988

* OLS / Linear Probability Model (LPM) with survey weights
svy: regress voted pol377black pol377inc2 pol377inc3 pol377inc4 pol377inc5 age

* Average marginal effects for all predictors 
margins, dydx(*) 

* Show marginal effects table
estimates table

* Logistic regression (logit) with survey weights
svy: logit voted pol377black pol377inc2 pol377inc3 pol377inc4 pol377inc5 age

* Average marginal effects for all predictors 
margins, dydx(*) 

* Show marginal effects table
estimates table


* ------------------------------------------------------
* METHOD 1: Predicted turnout by age for a REFERENCE PROFILE
* ------------------------------------------------------
* Non-Black (pol377black=0), baseline income (all income dummies = 0),
* age from 18 to 75

quietly margins, at( ///
    age = (18(1)75) ///
    pol377black = (0) ///
    pol377inc2 = (0) ///
    pol377inc3 = (0) ///
    pol377inc4 = (0) ///
    pol377inc5 = (0) ///
) predict(pr)

* Plot predicted probability of turnout over age: reference voter
marginsplot, ///
    noci ///
    title("Predicted Pr(Voted) by Age (1988)") ///
    subtitle("Reference: Non-Black, baseline income") ///
    xtitle("Age") ///
    ytitle("Pr(Voted)") ///
    ylabel(0(.1)1)

graph export "turnout_by_age_1988_reference.png", replace width(2000)


* ------------------------------------------------------
* METHOD 2: Average adjusted predictions by age
* ------------------------------------------------------
* Here we vary AGE from 18 to 75, but leave all other
* covariates at their OBSERVED values for each respondent.
* This matches the R code using `prediction()` + averaging.

quietly margins, at(age = (18(1)75)) predict(pr)

* Plot average predicted Pr(voted) by age (over observed covariates)
marginsplot, ///
    noci ///
    title("Predicted Pr(Voted) by Age (1988)") ///
    subtitle("Average adjusted prediction (other vars at observed values)") ///
    xtitle("Age") ///
    ytitle("Pr(Voted)") ///
    ylabel(0(.1)1)

graph export "turnout_by_age_1988_avg_adjusted.png", replace width(2000)

restore



*******************************************************
* 6. Marginal effect of being Black on turnout, 1972–2020
*******************************************************

* We will estimate a survey-weighted logit for each year
* and store the AME of pol377black, then plot them.

preserve

* Keep only the years we want for the Leighley & Nagler-style plot
keep if inlist(VCF0004, 1972, 1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020)

* Create a temporary file to hold AMEs by year
tempfile ame_by_year
postfile ame_handle int year double ame se using `ame_by_year', replace

* Get list of years present
levelsof VCF0004, local(years)

foreach y of local years {
    
    * Survey-weighted logit for that year
    quietly svy: logit voted pol377black pol377inc2 pol377inc3 pol377inc4 pol377inc5 age ///
        if VCF0004 == `y'
    
    * Average marginal effect of being Black vs Non-Black
    quietly margins, dydx(pol377black)
    
    * margins stores results in r(b) and r(V)
    matrix M = r(b)
    matrix V = r(V)
    
    scalar ame = M[1,1]
    scalar se  = sqrt(V[1,1])
    
    * Post results to temporary file
    post ame_handle (`y') (ame) (se)
}

postclose ame_handle

* Use the AME dataset
use `ame_by_year', clear

label variable year "Election year"
label variable ame  "AME: Black vs Non-Black"
label variable se   "Std. Error"

* 95% confidence intervals
generate double lower = ame - 1.96*se
generate double upper = ame + 1.96*se

* Plot: AME with 95% CI and linear trend line
twoway ///
    (rcap upper lower year, lwidth(medthin)) ///
    (scatter ame year, msize(medlarge)) ///
    (lfit ame year, lpattern(solid)), ///
    yline(0, lpattern(dash) lcolor(gs10)) ///
    title("Effect of Being Black on Turnout, 1972–2020") ///
    subtitle("Average marginal effects from survey-weighted logit models") ///
    xtitle("Election Year") ///
    xlabel(1972(4)2020, angle(45)) ///
    ytitle("Change in Pr(Voted) (Black vs Non-Black)") ///
    ylabel(-0.05(0.05)0.15)

graph export "black_ame_over_time.png", replace width(2000)

restore


* Close the log file
log close

*******************************************************
* End of do-file
*******************************************************
