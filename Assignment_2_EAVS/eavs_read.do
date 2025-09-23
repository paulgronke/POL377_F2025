*******************************************************
* Datalab  3 — Read EAVS SPSS (zipped) from the web
*******************************************************

version 18
clear all
set more off

* 1. Download the zip directly to your working folder
copy "https://www.eac.gov/sites/default/files/2025-06/2024_EAVS_for_Public_Release_V1.sav_.zip" ///
     "eavs_2024.zip", replace

* 2. Unzip (this will create a folder with the .sav inside)
unzipfile "eavs_2024.zip", replace

* 3. Import the known SPSS file directly from its path
import spss using "2024_EAVS_for_Public_Release_V1.sav/2024_EAVS_for_Public_Release_V1.sav", clear

* Optional: make variable names lowercase
capture noisily rename *, lower

* 4. Quick check
describe
count
codebook _all, compact

* OPTIONAL 5. Save as a Stata dataset for easy reuse
* save "eavs_2024.dta", replace
