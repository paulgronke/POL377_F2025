*******************************************************
* Exploring the ANES Cumulative File (1948–2012)
* Stata version 
*******************************************************

* Start a log file so your work and results are saved
capture log close
log using "anes_cdf_exploration.log", text replace

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
                         1992, 1996, 2000, 2004, 2008, 2012)

*******************************************************
* 2. Explore the data: unweighted and weighted year tables
*******************************************************

* Unweighted frequency table for VCF0004
preserve
tabulate VCF0004
restore

* Drop cases with missing or non-positive CDF weight VCF0009z
drop if missing(VCF0009z)
drop if VCF0009z <= 0

* Set survey design using CDF full-sample weight (VCF0009z)
svyset _n [weight = VCF0009z]

* Weighted table for VCF0004 (like tbl_svysummary on the year)
svy: tabulate VCF0004, percent format(%5.1f)

* Now create the same table using the aweight command
tabulate VCF0004 [aweight = VCF0009z]

*******************************************************
* 3. Create recoded variables (voted, vote_democrat, flipper)
*******************************************************

* Voted in election (0 = did not vote, 1 = voted)
generate byte voted = .
replace voted = 0 if VCF0702 == 1
replace voted = 1 if VCF0704 == 2

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
replace democrat_incumbent_flipper =  1 if inlist(VCF0004, 1948, 1952, 1964, 1968, 1980, 1996, 2000, 2012)

* Republican incumbent years
replace democrat_incumbent_flipper = -1 if inlist(VCF0004, 1956, 1960, 1972, 1976, 1984, 1988, 1992, 2004, 2008)

label variable democrat_incumbent_flipper "Dem incumbent=1, Rep incumbent=-1"

* Code missing values for Likes and Dislines

replace VCF0322 = . if VCF0322 == 999

*******************************************************
* 4. Turnout over time (tables + line chart)
*******************************************************

* Weighted proportion who voted by year 
preserve
collapse (mean) prop_voted = voted [aweight = VCF0009z], by(VCF0004)
sort VCF0004

* Format to two decimals, roughly like rounding in R
format prop_voted %4.2f

* Table: Year and proportion who voted
list VCF0004 prop_voted, noobs abbreviate(12)

* Line plot of turnout over time
twoway line prop_voted VCF0004, ///
    title("Estimated Turnout in ANES Presidential Years") ///
    xtitle("Year of ANES Study (VCF0004)") ///
    ytitle("Proportion Who Voted (survey-weighted)") ///
    xlabel(1948(4)2012, angle(45)) ///
    ylabel(0(.1)1)

restore

*******************************************************
* 5. "The Simple Act" (VCF0322) over time and by vote choice
*******************************************************

* (a) Mean Simple Act score over time (weighted)
preserve
collapse (mean) mean_simple_act = VCF0322 [aweight = VCF0009z], by(VCF0004)
sort VCF0004
format mean_simple_act %4.2f
list VCF0004 mean_simple_act, noobs abbreviate(12)
restore

* (b) Simple Act by vote choice, wide table (Dem vs Rep)
preserve

* Drop missing vote choice
drop if missing(vote_democrat)

* Weighted mean of VCF0322 by year and vote_democrat
collapse (mean) mean_simple_act = VCF0322 [aweight = VCF0009z], ///
         by(VCF0004 vote_democrat)

* Reshape to have separate columns for vote choice
reshape wide mean_simple_act, i(VCF0004) j(vote_democrat)

* vote_democrat == 0 -> Republican; == 1 -> Democrat
label variable mean_simple_act0 "Mean Simple Act: Voted Republican"
label variable mean_simple_act1 "Mean Simple Act: Voted Democrat"

sort VCF0004
list VCF0004 mean_simple_act1 mean_simple_act0, noobs abbreviate(12)

restore

* Close the log file
log close

*******************************************************
* End of do-file
*******************************************************
