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
* Step 5: Table of voter confidence (Q1) by Party ID (pid3)
*******************************************************

