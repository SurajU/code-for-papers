/*============================================================================== 
SECTION A
This section of the code runs the main estimation and stores the estimates and 
monotonicity tests (including figures like Figure 3 in the paper) in 
M:\SVN\healthcost\analysis\output.  

This file uses the datasets created by (ordered in the exact same way) 
"M:\SVN\healthcost\build\code\prepare data forward looking reduced form.do"
These datasets are stored in "T:\HealthCost\build\output", with the following 
naming convention: 

			dataToBeAnalyzed18151221(number that differentiates)
			
The (number that differentiates) refers to the sub-group we're studying. This 
number is defined as the local variable "specification". It takes on the following 
values:

1 = female
2 = male
3 = below 65
4 = above 65
5 = below median income
6 = above median income
7 = 1 RQ
8 = 2 RQ
9 = 3 RQ
10 = 4 RQ
11 = below median RQ
12 = above median RQ
13 = full aggregated sample
14 = full aggregate sample, only future price for yearly spending prediction
15 = placebo sample	

These additional values call the full aggregated sample and run our robustness 
checks.
	
16 = spot price
17 = log(exp + 1)
18 = PC at 5000
19 = Weekly level
20 = deflated coefficients
21 = Wednesday Donut
22 = Wednesday Donut with 1 more week (added in new year)
23 = Thursday Donut with 1 more week (added in new year)
24 = Uniform kernel with fixed bandwidth of 20 days
25 = Weekly level with donut hole defined by weeks.
26 = female, ipw with riskscore
27 = male, ipw with riskscore
28 = below median income, ipw with riskscore
29 = above median income, ipw with riskscore 
30 = age 35-45, ipw with riskscore
31 = age 45-55, ipw with riskscore
32 = includes weekends
33 = remove time trend from RDD
34 = use EUROSTAT data to deflate prices
35 = spending less than 155 euros
36 = prob. of having an expenditure greater than 500
37 = prob. of having an expenditure greater than 5000
38 = top 5% of spenders
39 = top 10% of spenders
40 = top 20% of spenders
41 = only look at gp care
42 = top 38% of spenders + only individuals who had at least 1 > 500 euro
	 claim.
43 = only 67+ sample
44 = 10th riskscore decile
45 = 20th riskscore ventile
46 = Weekly level (in appendix style) + weekends included
47 = only weekends in weekly spending
48 = only look at people with chronic conditions in year y - 1
49 = only look at people with diabetes or hypertension in year y - 1
50 = only look at people that almost surely hit

Directories:

data: "T:\HealthCost\build\output\"

temp directory (must match with temp directory declared in 
testsForMonotonicity.m! : "T:\HealthCost\analysis\temp\"

output directory (tables): "T:\HealthCost\analysis\output\forward looking reduced form"
tables naming convention: TestsForMonotonicity`specification'.xls & TestsForMonotonicityExtensive`specification'.xls

output directory (figures): "T:\HealthCost\analysis\output\forward looking reduced form\figures"
figures naming convention: Coefficients`specification' & CoefficientsExtensive`specification'

TO CHANGE DIRECTORIES:
Please use ctrl+h and replace all with directory of choice. 
E.g: to change data directory from "T:\HealthCost\build\output\" to "C:\"
1. ctrl+h
2. In "Find What" box, type "T:\HealthCost\build\output\
3. In "Replace With" box, type "C:\
4. Click "Replace All"

MATlab version 2021b used. If you use a different version, use ctrl+h to change 
R2021b to R(your version). 
==============================================================================*/ 
set more off, permanently
cd "T:\HealthCost\build\temp"
*log using buildLog, replace
clear

capture log close
log using analysisLog, replace

forvalues specification = 1(1)50 {

set more off, permanently

di `specification'

if `specification' == 14 {
	continue
	}
* Specify pseudo-censor threshold. Alternative specification: 5000

loc deflatorMax = 500
if `specification' == 18 {
	local deflatorMax = 5000
	}	

if `specification' <= 15 {
	local specName = 1815122`specification'
}

else if `specification' > 37 & `specification' < 41 {
	local newSpec = `specification' - 20
	local specName = 1815122`newSpec'
}

else if `specification' >= 42 & `specification' <= 45 {
	loc newSpec = `specification' - 21
	loc specName = 1815122`newSpec'
}

else {
	local specName = 181512213
}

if `specification' <= 25 | `specification' > 31 {
	use "T:\HealthCost\build\output\dataToBeAnalyzed`specName'.dta", clear
	}
else if `specification' == 26 | `specification' == 27 {
	use "T:\HealthCost\build\output\forProbWeightDataFemale.dta", clear
	}
else if `specification' == 28 | `specification' == 29 {
	use "T:\HealthCost\build\output\forProbWeightDataIncome.dta", clear
	}
else if `specification' == 30 | `specification' == 31 {
	use "T:\HealthCost\build\output\forProbWeightDataAge.dta", clear
	}

* create clustering variable
sort PSEUDONYM_B date_treatment
capture drop unique_ID
by PSEUDONYM_B: gen unique_ID = 1 if _n == 1
replace unique_ID = sum(unique_ID) 

* Run main analysis
g spot_price = (delta < 0 | delta == .)
gen rel_day = . 
gen rel_week = .
gen group = .
gen useThis = .
matrix define deflatorDay = J(8,1,.)
capture drop made_claim
gen made_claim = (covered_expenditure > 0)
gen cen_exp = covered_expenditure
replace cen_exp = `deflatorMax' if cen_exp > `deflatorMax'

if `specification' == 20 {

* The code below creates the deflator. Deflator stored in matrix deflatorDay.
	file open table10 using "M:\SVN\healthcost\write\03 forward looking reduced form\tables\tables.txt", write append

	file write table10 _n
	file write table10 "<tab:Expenditure-deflator-values>" _n
	sort PSEUDONYM_B year date_treatment
	sum cen_exp if year == 2015 & week_treatment > 15  & (day_of_week != 0 | day_of_week != 6)
	loc baseDeflateDay = r(mean)

	forvalues i = 2008(1)2015 {
		sum cen_exp if year == `i' & week_treatment > 16  & (day_of_week != 0 | day_of_week != 6)
		local numDeflate = r(mean)
		matrix deflatorDay[`i'-2007,1] = `numDeflate'/`baseDeflateDay'
		loc addToTable = `numDeflate'/`baseDeflateDay'
		file write table10 "`addToTable'" _n

		}		
	file close table10	 
}
matrix define A = J(7,1,.)
matrix define B = J(7,1,.)
matrix define C = J(7,1,.)
matrix define D = J(7,1,.)
matrix define E = J(7,1,.)
matrix define F = J(7,1,.)
matrix define G = J(7,1,.)
matrix define H = J(7,1,.)
matrix define I = J(7,1,.)
matrix define J = J(7,1,.)
matrix define K = J(7,1,.)
matrix define L = J(7,1,.)

forvalues i = 2008(1)2014 {
	preserve
	if `specification' == 26 {
		keep if inFemaleSample == 1
		}
	else if `specification' == 27 {
		keep if inMaleSample == 1
		}
	else if `specification' == 28 {
		keep if inBelowMedIncSample == 1
		}
	else if `specification' == 29 {
		keep if inAboveMedIncSample == 1
		}
	else if `specification' == 30 {
		keep if inBelow45Sample == 1
		}
	else if `specification' == 31 {
		keep if inAbove45Sample == 1
		}	
	* define donut holes for each year. For different days, define `donut' as 1 
	* (Wednesday), 2 (Tuesday) and so on. To change the size of the donut, 
	* change the local macro `donutSizeBeginning' or `donutSizeEnd' to a number.
	* E.g. to increase donut hole by 1 week, set `donutSizeEnd' = 7.
	local donut = 0
	local donutSizeBeginning = 0
	local donutSizeEnd = 0

	if `specification' == 21 | `specification' == 22 {
		local donut = 1
	}
	
	if `specification' == 23 | `specification' == 22 {
		local donutSizeEnd = 7
	}
	
	if `i' == 2008 {
		local j = 354 - `donut' + `donutSizeBeginning'
		local k = 365 + 9 - `donut' + `donutSizeEnd'
		
		local deflator_before = 78.73/100
		local deflator_after = 79.19/100
		local deductibleS = 155
		}
		
	else if `i' == 2009 {
		local j = 352 - `donut' + `donutSizeBeginning'
		local k = 365 + 7 - `donut' + `donutSizeEnd'
		local deflator_before = 80.36/100
		local deflator_after = 80.66/100
		local deductibleS = 160

		}
	else if `i' == 2010 {
		local j = 351 - `donut' + `donutSizeBeginning'
		local k = 365 + 6 - `donut' + `donutSizeEnd'
		
		local deflator_before = 80.84/100
		local deflator_after = 84.86/100
		local deductibleS = 170

		} 
	else if `i' == 2011 {
		local j = 357 - `donut' + `donutSizeBeginning'
		local k = 365 + 5 + 7 - `donut' + `donutSizeEnd'
		
		local deflator_before = 84.08/100
		local deflator_after = 94.12/100
		local deductibleS = 220	
		} 
	else if `i' == 2012 {
		local j = 356 - `donut' + `donutSizeBeginning'
		local k = 365 + 11 - `donut' + `donutSizeEnd'
		
		local deflator_before = 95.27/100
		local deflator_after = 99.92/100
		local deductibleS = 350
		}
	else if `i' == 2013 {
		local j = 354 - `donut' + `donutSizeBeginning'
		local k = 365 + 9 - `donut' + `donutSizeEnd'
	
		local deflator_before = 100.13/100
		local deflator_after = 101.23/100
		local deductibleS = 360
		}
	else if `i' == 2014 {
		local j = 353 - `donut' + `donutSizeBeginning'
		local k = 365 + 8 - `donut' + `donutSizeEnd'

		local deflator_before = 101.02/100
		local deflator_after = 100.83/100
		local deductibleS = 375
		}	
	else if `i' == 2015 { 
		local j = 352 - `donut' + `donutSizeBeginning'
		local k = 365 + 7 - `donut' + `donutSizeEnd'
			
		}

	matrix K[`i'-2007,1] = `deductibleS'
	
	if `specification' == 20 {
			* deflate expenditures
			replace covered_expenditure = covered_expenditure/deflatorDay[`i'-2007,1] if year == `i' 
			replace covered_expenditure = covered_expenditure/deflatorDay[`i'-2006,1] if year == `i' + 1
		}		
	if `specification' >= 34 & `specification' <= 37 {
		* deflate using Eurostat data. These are stored in deflator_before and 
		* deflator_after. These deflators are also used when looking at prob. of
		* spending more than a certain amount (specifications 35-37).
		
		gen undeflated_exp = covered_expenditure
		replace covered_expenditure = covered_expenditure/`deflator_before' if year == `i'
		replace covered_expenditure = covered_expenditure/`deflator_after' if year == `i' + 1
		
		}
	
	* get a specific year pair {i,i+1}
	keep if week_treatment > 36 & year == `i' | week_treatment < 15 & year == `i' + 1
	
	if `specification' == 48 {
		
		merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\chronic_indicator_wide.dta"
		* if this dataset isn't there, needs to be created. It has three variables: 
		* PSEUDONYM_B, year and the rowmax of all chronic indicators (hasChronic)
		* from INSURED_DDD_long.dta
		* use chronic info from year y-1
		loc selectYear = `i'-1
		keep if hasChronic`selectYear' == 1 & _merge == 3
		
	}
	
	else if `specification' == 49 {
		
		merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\chronic_indicator_wide.dta"
		* if this dataset isn't there, needs to be created. It has three variables: 
		* PSEUDONYM_B, year and the rowmax of all chronic indicators (hasChronic)
		* from INSURED_DDD_long.dta 
		loc selectYear = `i' - 1
		keep if hasDiabOrHyp`selectYear' == 1 & _merge == 3
		
	}
	
	else if `specification' == 50 {
		
		merge m:1 PSEUDONYM_B year using "T:\HealthCost\build\temp\almostSurelyHit.dta"
		gen almostSurelyHitBase = almostSurelyHit if year == `i'
		bys PSEUDONYM_B: egen almostSurelyHitBase_max = max(almostSurelyHitBase)
		keep if almostSurelyHitBase_max == 1 & _merge == 3
		
	}
	
	if `i' == 2008 | `i' == 2012 {
		* for leap years
		replace day = day + 366 if year == `i' + 1
	}
	
	else {
	
		replace day = day + 365 if year == `i' + 1
		
		}
	
	* generate days to end of year variable (depends on donut hole). The last 
	* day of year i has rel_day = -1 and the first day of year i + 1 has 
	* rel_day = 0
	
	replace rel_day = day - `j' if year == `i' & day < `j' 
	replace rel_day = day - `k' if year == `i' + 1 & day >= `k'
	
	if `specification' != 32 & `specification' != 46  & `specification' != 47 {
		* for 3 specifications, keep weekend data
		replace rel_day = . if day_of_week == 0 | day_of_week == 6
		
	}
	
	
	
	* generate probability of crossing.
	
	unique PSEUDONYM_B if delta != ., by(year)
	sum _Unique
	local nextCross = r(min)
	local crossed = r(max)
	matrix H[`i'-2007,1] = `crossed'
	di `nextCross'/`crossed'
	matrix B[`i'-2007,1] = `nextCross'/`crossed'
	
	if `specification' > 25 & `specification' < 32 {
		* generate (weighted) probability of crossing.
		
		gen crossesNY = (delta !=.) & year == `i' + 1
		egen tagInd = tag(PSEUDONYM_B year)
		egen sumInd = sum(tagInd)
		egen sumIPW = sum(ipw) if tagInd == 1 & year == `i' + 1
		egen max_sumIPW = max(sumIPW)
		gen newWeights = ipw/max_sumIPW
		gen probCross = (ipw*crossesNY)/sumIPW if tagInd == 1 & year == `i' + 1
		sum probCross
		di r(sum)
		
		matrix B[`i'-2007,1] = r(sum)
		
	}
	
	* run the analysis
	if `specification' <= 15 | (`specification' >= 20 & `specification' < 35) | `specification' == 18 | (`specification' > 37 & `specification' < 41) | (`specification' >= 42 & `specification' < 46) | `specification' >= 48 {
	
		capture gen made_claim = (covered_expenditure > 0)
	
		
		if `specification' == 24 {
		
			rdrobust made_claim rel_day, kernel(uniform) vce(cluster unique_ID) h(27) masspoints(off)
		}
		
		else if `specification' > 25 & `specification' < 32 {
		
			rdrobust made_claim rel_day, vce(cluster unique_ID) weights(newWeights) masspoints(off)
			
			}
			
		else if `specification' == 32 {
		
			rdrobust made_claim rel_day, vce(cluster unique_ID) h(20) masspoints(off)
			
		}
		
		else if `specification' == 33 {
			
			rdrobust made_claim rel_day, kernel(uniform) vce(cluster unique_ID) p(0) masspoints(off)
			
			}

		else {
		
			rdrobust made_claim rel_day, vce(cluster unique_ID) masspoints(off)
			
		}
		matrix D[`i'-2007,1] = e(tau_cl)
		matrix E[`i'-2007,1] = e(se_tau_cl)
		matrix I[`i'-2007,1] = e(tau_cl_l)
		matrix J[`i'-2007,1] = e(tau_cl_r)
			
		replace cen_exp = covered_expenditure
		replace cen_exp = `deflatorMax' if cen_exp > `deflatorMax'
			
		if `specification' == 24 {
		
			rdrobust cen_exp rel_day, kernel(uniform) vce(cluster unique_ID) h(27) masspoints(off)
			
		}
		
		else if `specification' > 25 & `specification' < 32 { 
		
			rdrobust cen_exp rel_day, vce(cluster unique_ID) weights(newWeights) masspoints(off)
			
			}
		else if `specification' == 32 {
		
			rdrobust cen_exp rel_day, vce(cluster unique_ID) h(20) masspoints(off)
			
			}
		
		else if `specification' == 33 {
			
			rdrobust cen_exp rel_day, kernel(uniform) vce(cluster unique_ID) p(0) masspoints(off)
			
			}
			
		else {
		
			rdrobust cen_exp rel_day, vce(cluster unique_ID) masspoints(off)
			
		}
			
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		
		if `specification' > 25 & `specification' < 32 { 
		
			qui rdrobust covered_expenditure rel_day, vce(cluster unique_ID) weights(newWeights) h(27) masspoints(off)
			
			}
			
		else {
		
			qui rdrobust covered_expenditure rel_day, vce(cluster unique_ID) h(27) masspoints(off)
			
		}
		
		matrix L[`i'-2007,1] = e(tau_cl_r)
		
	}
	
	else if `specification' == 16 {
		
		rdrobust spot_price rel_day, vce(cluster unique_ID) masspoints(off)
				
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		
		}
		
	else if `specification' == 17 {
		gen log_exp = log(covered_expenditure + 1)
		
		rdrobust log_exp rel_day, vce(cluster unique_ID) masspoints(off)
			
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		}
		
	else if `specification' == 35 {
		gen less_than_155 = (covered_expenditure < 155 & covered_expenditure > 0)
		
		rdrobust less_than_155 rel_day, vce(cluster unique_ID) masspoints(off)
		
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		
		gen less_than_155_ud = (undeflated_exp < 155 & covered_expenditure > 0)
		rdrobust less_than_155_ud rel_day, vce(cluster unique_ID) masspoints(off)
		
		matrix D[`i'-2007,1] = e(tau_cl)
		matrix E[`i'-2007,1] = e(se_tau_cl)
		matrix I[`i'-2007,1] = e(tau_cl_l)
		matrix J[`i'-2007,1] = e(tau_cl_r)
		
		}
	
	else if `specification' == 36 {
		gen above500 = (covered_expenditure > 500)
		
		rdrobust above500 rel_day, vce(cluster unique_ID) masspoints(off)
		
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		
		gen above500UD = (undeflated_exp > 500)
		rdrobust above500UD rel_day, vce(cluster unique_ID) masspoints(off)
		
		matrix D[`i'-2007,1] = e(tau_cl)
		matrix E[`i'-2007,1] = e(se_tau_cl)
		matrix I[`i'-2007,1] = e(tau_cl_l)
		matrix J[`i'-2007,1] = e(tau_cl_r)
		}
	else if `specification' == 37 {
		gen above5000 = (covered_expenditure > 5000)
		
		rdrobust above5000 rel_day, vce(cluster unique_ID) masspoints(off)
		
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		
		gen above5000UD = (undeflated_exp < 5000)
		rdrobust above5000UD rel_day, vce(cluster unique_ID) masspoints(off)
		
		matrix D[`i'-2007,1] = e(tau_cl)
		matrix E[`i'-2007,1] = e(se_tau_cl)
		matrix I[`i'-2007,1] = e(tau_cl_l)
		matrix J[`i'-2007,1] = e(tau_cl_r)
		}
	
	else if `specification' == 41 {
	
		gen gpCare = amountSpentOnGPCare
		
		rdrobust gpCare rel_day, vce(cluster unique_ID) masspoints(off)
		
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		}
	
	
	else if `specification' == 19 | `specification' == 25 | `specification' == 46 | `specification' == 47 {
		
		* generate weekly level data. Weekly data is created using the steps 
		* mentioned in Appendix D.2.
	
		if `specification' == 19 | `specification' == 46 | `specification' == 47 {
		
			replace useThis = abs(mod(rel_day,7))
			replace group = 1 if useThis == 0
			sort PSEUDONYM_B year date_treatment
			by PSEUDONYM_B year: replace group = sum(group)
		
			sum group if rel_day == -1
			local j1 = r(mean) + 1
			sum group if rel_day == 0
			local k1 = r(mean)
		
			if `specification' == 19 {
				* remove weekends for specification 19, but leave it for 46.
				replace rel_day = . if day_of_week == 0 | day_of_week == 6
			
			}
			
			else if `specification' == 47 {
				* only keep weekends for specification 47				
				replace rel_day = . if day_of_week != 0 & day_of_week != 6
				
			}
			
			keep if rel_day != . 
			
			drop if group == 0
			sort PSEUDONYM_B year group date_treatment
			
			by PSEUDONYM_B year group: egen summed_week_exp = total(covered_expenditure)
			
			
			replace rel_week = group - `j1' if year == `i' & group < `j1'
			replace rel_week = group - `k1' if year == `i' + 1 & group >= `k1' 
			
			by PSEUDONYM_B year group: keep if _n == _N 
		}
		
		else {
			
			* define weekly donut holes
			loc j1 = 51
			loc k1 = 2
			
			replace rel_week = week_treatment -`j1' if year == `i' & week_treatment < `j1'
			replace rel_week = week_treatment - `k1' if year == `i' + 1 & week_treatment >= `k1'
			
			bys PSEUDONYM_B year week_treatment: egen summed_week_exp = total(covered_expenditure)
			
		}
		
		gen made_claim2 = (summed_week_exp > 0)
		rdrobust made_claim2 rel_week, h(5) vce(cluster unique_ID) masspoints(off)
		matrix D[`i'-2007,1] = e(tau_cl)
		matrix E[`i'-2007,1] = e(se_tau_cl)
		matrix I[`i'-2007,1] = e(tau_cl_l)
		matrix J[`i'-2007,1] = e(tau_cl_r)
		
		gen cen_summed_week = summed_week_exp
		replace cen_summed_week = `deflatorMax' if summed_week_exp > `deflatorMax'
		rdrobust cen_summed_week rel_week, h(5) vce(cluster unique_ID) masspoints(off)
		matrix A[`i'-2007,1] = e(tau_cl)
		matrix C[`i'-2007,1] = e(se_tau_cl)
		matrix G[`i'-2007,1] = e(tau_cl_l)
		matrix F[`i'-2007,1] = e(tau_cl_r)
		
		
		}

restore
	}
	
* prepare data for analysis using MATlab. Calls testsForMonotonicity.m.
	
clear
svmat A 
svmat B
svmat C
svmat D
svmat E
svmat F
svmat G
svmat H
svmat I
svmat J
svmat K 
svmat L

sort B1

export delimited using "T:\HealthCost\analysis\temp\relevantEstimates`specification'.csv", novarnames replace
	
}


* might have to change MATlab's path if running from a computer other than the 
* blade.

winexec C:\Program Files\MATLAB\R2021b\bin\matlab.exe -r cd('M:\SVN\healthcost\analysis\code\'),testsForMonotonicity,exit

sleep 60000


* do BCHK-style analysis for anticipatory effects
use "T:\HealthCost\build\output\dataToBeAnalyzed181512213.dta", clear

replace yearPair = year if week_treatment > 15
replace yearPair = year - 1 if week_treatment < 15

gen log_exp = log(covered_expenditure) if covered_expenditure > 0
sum log_exp

gen cen_exp = covered_expenditure
replace cen_exp = 500 if covered_expenditure > 500

* first get histogram of daily spending across all years
histogram cen_exp if cen_exp > 0 & yearPair == 2014, percent ytitle("percent of data") ///
xtitle("pseudo-censored expenditure") graphregion(color(white)) color(emidblue) ///
 lcolor(black%50)

graph export "T:\HealthCost\analysis\output\forward looking reduced form\figures\densityPCExp.pdf", replace

* check correlation of september spending and jan spending
gen month_treatment = month(date_treatment)

bys month_treatment year: egen avg_spending_day = mean(covered_expenditure)
by month_treatment year: egen avg_spending_day_PC = mean(cen_exp)

preserve

egen keepThese = tag(month_treatment year)
keep if keepThese

gen spending_sept = avg_spending_day if month_treatment == 9
bys yearPair: egen max_spending_sept = max(spending_sept)

gen spending_sept_PC = avg_spending_day_PC if month_treatment == 9
by yearPair: egen max_spending_sept_PC = max(spending_sept_PC)

gen spending_jan = avg_spending_day if month_treatment == 1
by yearPair: egen max_spending_jan = max(spending_jan)

gen spending_jan_PC = avg_spending_day_PC if month_treatment == 1
by yearPair: egen max_spending_jan_PC = max(spending_jan_PC)

keep if month_treatment == 1 & yearPair != 2015
keep max_spending_sept max_spending_jan max_spending_sept_PC max_spending_jan_PC month_treatment year yearPair

corr max_spending_sept max_spending_jan
corr max_spending_sept_PC max_spending_jan_PC

restore


egen pctile_of_cen_exp = mean((cen_exp == 500)/(cen_exp < . & cen_exp > 0))
sum pctile_of_cen_exp

egen pctile_of_5000 = mean((covered_expenditure >= 5000)/(covered_expenditure > 0))
sum pctile_of_5000

egen pctile_of_155 = mean((covered_expenditure >= 155)/(covered_expenditure > 0))
sum pctile_of_155

gen made_claim = (covered_expenditure > 0)
sum made_claim

* get monthly version of spending for each individual
*gen month_treatment = month(date_treatment)
bys PSEUDONYM_B month_treatment year: egen monthly_spending = sum(covered_expenditure)
gen hits_deductible = (delta != .)

egen monthlyObs = tag(PSEUDONYM_B month_treatment year)
keep if monthlyObs == 1 

gen denom = 1 if year == yearPair + 1

bys yearPair: egen allObs = sum(denom) 
by yearPair: egen numeratorP = sum(hits_deductible) if year == yearPair + 1
by yearPair: egen max_allObs = max(allObs)
by yearPair: egen max_numP = max(numeratorP)

gen p_e = 1-max_numP / max_allObs

keep if yearPair == year & yearPair != 2015

tab month_treatment, gen(monthDum)

* create clustering variable at individual-yearpair level.
bys PSEUDONYM_B year: gen clusterVar = 1 if _n == 1
replace clusterVar = sum(clusterVar)

gen cen_month_spend = monthly_spending
replace cen_month_spend = 500 if cen_month_spend > 500

gen monthly_made_claim = (monthly_spending > 0)
* use avg cen_month_spend
bys month_treatment yearPair: egen avg_cen_month_spend = mean(cen_month_spend)
by month_treatment yearPair: egen avg_month_spend = mean(monthly_spending)
by month_treatment yearPair: egen mean_made_claim = mean(monthly_made_claim)

preserve

egen monthYObs = tag(month_treatment yearPair)
keep if monthYObs == 1
keep if month_treatment > 9

reg avg_cen_month_spend i.year i.month_treatment##c.p_e, vce(robust)
reg avg_month_spend i.year i.month_treatment##c.p_e, vce(robust)
reg mean_made_claim i.year i.month_treatment##c.p_e, vce(robust)



restore

* END OF SECTION A
/*==============================================================================
SECTION B
Get RD figures:
This section of the code produces all the RD figures in the paper. Figure 2 in 
the paper is produced when the local macro `i' is equal to 2010. Figures A.2 and
 A.3 are produced when the local macro `i' takes on other values.
 
 The code loads the dataset, retains data around the donut hole and exports this
 data. The MATlab file "codeForFigureRD.m" is called to produce the final 
 figures.
==============================================================================*/

forvalues marginToLook = 1(1)1 {
	* Specify yes or no weekend
	forvalues weekendVal = 1(1)1 {
	use "T:\HealthCost\build\output\dataToBeAnalyzed181512213.dta", clear	
	
	gen cen_exp = covered_expenditure
	replace cen_exp = 500 if cen_exp > 500
	g spot_price = (delta < 0 | delta == .)
	gen rel_day = . 
	g made_claim = (covered_expenditure > 0)
	
	local marginLook = `marginToLook' - 1

		if `marginLook' == 0 |`marginLook' == 3 {
			local deflatorMax = 500
			}
			
		* Specify weekend (1) / no weekend (0)
		local weekendY = `weekendVal' - 1

		local donut = 0
		local donutSizeBeginning = 0
		local donutSizeEnd = 0

		forvalues i = 2008(1)2014 {
				preserve
				if `i' == 2008 {
				local j = 354 - `donut' + `donutSizeBeginning'
				local k = 365 + 9 - `donut' + `donutSizeEnd'
				
				local deflator_before = 78.73/100
				local deflator_after = 79.19/100
				local leapYear = 1
				local deductible = 150
				}
			else if `i' == 2009 {
				local j = 352 - `donut' + `donutSizeBeginning'
				local k = 365 + 7 - `donut' + `donutSizeEnd'
				
				local deflator_before = 80.36/100
				local deflator_after = 80.66/100
				local leapYear = 0
				local deductible = 155

				}
			else if `i' == 2010 {
				local j = 351 - `donut' + `donutSizeBeginning'
				local k = 365 + 6 - `donut' + `donutSizeEnd'
				
				local deflator_before = 80.84/100
				local deflator_after = 84.86/100
				local leapYear = 0
				local deductible = 165

				} 
			else if `i' == 2011 {
				local j = 350 - `donut' + `donutSizeBeginning'
				local k = 365 + 5 + 7 - `donut' + `donutSizeEnd'
				
				local deflator_before = 84.08/100
				local deflator_after = 94.12/100
				local leapYear = 0
				local deductible = 170		
				} 
			else if `i' == 2012 {
				local j = 356 - `donut' + `donutSizeBeginning'
				local k = 365 + 11 - `donut' + `donutSizeEnd'
				
				local deflator_before = 95.27/100
				local deflator_after = 99.92/100
				local leapYear = 1
				local deductible = 220
				}
			else if `i' == 2013 {
				local j = 354 - `donut' + `donutSizeBeginning'
				local k = 365 + 9 - `donut' + `donutSizeEnd'
			
				local deflator_before = 100.13/100
				local deflator_after = 101.23/100
				local leapYear = 0		
				local deductible = 350
				}
			else if `i' == 2014 {
				local j = 353 - `donut' + `donutSizeBeginning'
				local k = 365 + 8 - `donut' + `donutSizeEnd'

				local deflator_before = 101.02/100
				local deflator_after = 100.83/100
				local leapYear = 0		
				local deductible = 360
				}	
			else if `i' == 2015 { 
				local j = 352 - `donut' + `donutSizeBeginning'
				local k = 365 + 7 - `donut' + `donutSizeEnd'
					
				}
			
			sort PSEUDONYM_B date_treatment
			keep if week_treatment > 15 & year == `i' | week_treatment < 13 & year == `i' + 1
			
			replace day = day + 365 + `leapYear' if year == `i' + 1
				
			replace rel_day = day - `j' if year == `i' & day < `j' 
			replace rel_day = day - `k' if year == `i' + 1 & day >= `k'
			
			if `weekendY' == 0 {
				replace rel_day = . if day_of_week == 0 | day_of_week == 6
				keep if rel_day >= -28 & year == `i' | rel_day < 28 & year == `i' + 1 | rel_day == .
				}
			else if `weekendY' == 1 {
				keep if rel_day >= -20 & year == `i' & rel_day != .| rel_day < 21 & year == `i' + 1
				}
		
			unique day, by(year)
			qui sum _Unique if year == `i'
			local toKeep1 = r(mean)
			qui sum _Unique if year == `i'+1
			local toKeep2 = r(mean)
			
			if `marginLook' == 0 {
				replace cen_exp = 500 if cen_exp > 500
				
			* run rdplot and store the variables. These are used in the MATlab 
			* code
			
				if `weekendY' == 1 {
					rdplot cen_exp rel_day, nbins(20 20) genvars p(1) kernel(tri)
					}
				else {
					rdplot cen_exp rel_day, nbins(28 27) genvars p(1) kernel(tri)
					}
				}
				
			else {
				if `weekendY' == 1 {
					rdplot made_claim rel_day, nbins(20 20) genvars p(1) kernel(tri)
					}
				else {
					rdplot made_claim rel_day, nbins(28 27) genvars p(1) kernel(tri)
					}
				}
				
			gen isDonut = (day < `k' & day >= `j')
			gen isFirstYear = (year == `i')
			gen isWeekend = (day_of_week == 0 | day_of_week == 6)
			bys day: egen mean_spend_that_day = mean(cen_exp)
			replace rdplot_mean_y = mean_spend_that_day if rdplot_mean_y == . | rdplot_mean_y == 0
			egen keep_obs = tag(day)
			keep if keep_obs
			*keep if _n <= `toKeep1' + `toKeep2'
			keep year day rel_day rdplot_mean_y rdplot_hat_y isWeekend isFirstYear isDonut 
			
			cd "T:\HealthCost\analysis\temp"

			export excel using "figureForRD.xls", replace
			
			winexec C:\Program Files\MATLAB\R2021b\bin\matlab.exe -r cd('M:\SVN\healthcost\analysis\code'),codeForFigureRD,exit
			
			sleep 30000
			
			if `i' != 2010 & `marginLook' == 0 {
				!ren "RD Figure.pdf" "RD Figure "`i'".pdf"
				!ren "RD Figure (with omitted days).pdf" "RD Figure "`i'" (with omitted days).pdf"
				!move /y "RD Figure "`i'".pdf" "T:\HealthCost\analysis\output\forward looking reduced form\figures"	
				!move /y "RD Figure "`i'" (with omitted days).pdf" "T:\HealthCost\analysis\output\forward looking reduced form\figures"
				}
			else if `marginLook' == 1 {
				!ren "RD Figure.pdf" "RD Figure spot price "`i'".pdf"
				!ren "RD Figure (with omitted days).pdf" "RD Figure spot price "`i'" (with omitted days).pdf"
				!move /y "RD Figure spot price "`i'".pdf" "T:\HealthCost\analysis\output\forward looking reduced form\figures"	
				!move /y "RD Figure spot price "`i'" (with omitted days).pdf" "T:\HealthCost\analysis\output\forward looking reduced form\figures"	
				}
				
			else {
				!ren "RD Figure.pdf" "RD Figure (in text).pdf"
				!ren "RD Figure (with omitted days).pdf" "RD Figure (with omitted days) (in text).pdf"
				!move /y "RD Figure (in text).pdf" "T:\HealthCost\analysis\output\forward looking reduced form\figures"
				!move /y "RD Figure (with omitted days) (in text).pdf" "T:\HealthCost\analysis\output\forward looking reduced form\figures"
				}
			restore
	}
}
}

* END OF SECTION B
	
*===============================================================================
* IGNORE 
/*==============================================================================
Get the summary statistics for each subgroup to get elasticity estimates.
==============================================================================
forvalues specification = 1(1)13 {
	local specName = 1815122`specification'
	use "T:\HealthCost\build\output\dataToBeAnalyzed`specName'.dta", clear
	gen cen_exp = covered_expenditure
	replace cen_exp = 500 if covered_expenditure > 500
	matrix define Y = J(2,1,.)
	gen made_claim = (covered_expenditure > 0)
	
	qui sum cen_exp if year == 2015 & week_treatment > 15
	matrix Y[1,1] = r(mean)
	qui sum made_claim if year == 2015 & week_treatment > 15
	matrix Y[2,1] = r(mean)
	
	clear
	svmat Y
	
	cd "T:\HealthCost\analysis\temp"
	export excel using "meanSpending`specification'.xls", replace
	}*/
/*==============================================================================
Create price difference figures
==============================================================================*/

use "T:\HealthCost\build\output\dataToBeAnalyzed181512214.dta", clear

gen month_treatment = month(date_treatment)

replace hit_deductible = (delta == 0)
bys PSEUDONYM_B year month_treatment: egen max_hit = max(hit_deductible)

bys month_treatment year: egen mean_hit = mean(max_hit)

egen taggedObs = tag(month_treatment year)
keep if taggedObs

keep month_treatment year mean_hit

save "T:\HealthCost\build\output\priceDataMonth.dta", replace

use "T:\HealthCost\build\output\priceDataMonth.dta", clear

gen geometricDiscounting = 0
gen toUseForPrice = 0
gen quasiHyperbolicDiscounting = 0
bys year: egen probCross = sum(mean_hit)
gen trueFuturePrice = 1 - probCross 

* here the z variable denotes the hyperbolic discount factor and j denotes the 
* geometric (monthly) discount factor.

forvalues k = 1(1)2 {
	
	if `k' == 1 {
		loc z = 1
		}
	else if `k' == 2 {
		loc z = 0.5
		}
	
	forvalues i = 1(1)3 {
	
		local j = `i'/10
		
		if `i' == 1 {
			local j = 0.85
			}
		else if `i' == 2 {
			local j = 0.995
			}
		else if `i' == 3 {
			local i = 10
			local j = 1
			}
			
		replace quasiHyperbolicDiscounting = `z'*(`j'^month_treatment)
		replace toUseForPrice = mean_hit*quasiHyperbolicDiscounting
		bys year: egen abaluckPrice`i'`k' = sum(toUseForPrice)
		* trueAblaluckPrice is 1 - \beta \sum \delta^(t-1)Xq(t). 
		gen trueAbaluckPrice`i'`k' = 1-abaluckPrice`i'`k'
		gen trueEllisPrice`i'`k' = trueFuturePrice*`z'*(`j'^12)
	}
}


bys year: keep if _n == 1
sort trueFuturePrice
keep trueFuturePrice trueAbaluckPrice* trueEllisPrice*

export excel "T:\HealthCost\build\output\priceComparison.xls", replace

capture winexec C:\Program Files\MATLAB\R2017a\bin\matlab.exe -r cd('M:\SVN\healthcost\analysis\code\'),codeForFigureRD,exit
capture winexec C:\Program Files\MATLAB\R2021b\bin\matlab.exe -r cd('M:\SVN\healthcost\analysis\code\'),codeForFigureRD,exit

sleep 60000

/*==============================================================================*/

* Figure A.1

* work in temp directory
cd "T:\HealthCost\analysis\temp"

use "T:\HealthCost\build\output\priceDataMonth.dta", clear

local counter = 1

* Einav/Finkelstein/Schrimpf is 0.83746

foreach delta of numlist 0.992 0.996 1 {
	display `delta'
	gen contributionBonusOurModel`counter' = `delta'^(month_treatment-1)*mean_hit
	gen contributionBonusEllis`counter' = `delta'^(12-1)*mean_hit
	local counter = `counter'+1
	}

collapse (sum) contributionBonusOurModel* contributionBonusEllis*, by(year)

twoway scatter contributionBonusEllis1 contributionBonusOurModel1 if year!=2009, msymbol(S) mcolor(teal)  ///
	|| scatter contributionBonusEllis2 contributionBonusOurModel2 if year!=2009, msymbol(O) mcolor(midblue)   ///
	|| scatter contributionBonusEllis3 contributionBonusOurModel3 if year!=2009, msymbol(D) mcolor(navy)  mlabposition(10) mlabel(year) mlabcolor(navy) ///
	|| scatter contributionBonusEllis1 contributionBonusOurModel1 if year==2009, msymbol(S) mcolor(teal)  ///
	|| scatter contributionBonusEllis2 contributionBonusOurModel2 if year==2009, msymbol(O) mcolor(midblue)   ///
	|| scatter contributionBonusEllis3 contributionBonusOurModel3 if year==2009, msymbol(D) mcolor(navy)  mlabposition(4) mlabel(year) mlabcolor(navy) ///	
	|| function y = x, ra(0.6 0.85) clpat(dash) lcolor(gs5) xlabel(0.6(0.05)0.85) ylabel(0.6(0.05)0.85) ///
	xtitle("value bonus our model") ytitle("value bonus generlized Ellis (1986) model") ///
	legend(size(small) pos(11) ring(0) col(1) ///
	order(1 "10 percent yearly discount rate, monthly {&delta}=0.992" ///
	2 "5 percent yearly discount rate, monthly {&delta}=0.996" 3 "no discounting, {&delta}=1"))
	
graph export "..\output\forward looking reduced form\figures\priceComparisonStata.pdf", replace

* number mentioned in text
regress contributionBonusEllis1 contributionBonusOurModel1




/*==============================================================================
SECTION C:
Dataset to predict change in daily/weekly EEYOP created in other do-file. 
Produces table 7 in text. 
==============================================================================*/
* Set annualDiscountFactor to 1. Other values are from Table 5 in the 
* paper. 
use "T:\HealthCost\build\output\dataForYearlySpendingPrediction.dta", clear
gen day_of_week = dow(date_treatment)

gen toRemoveWeekends = (day_of_week == 0 | day_of_week == 6)

matrix define EEYOP = J(365,2,.)
matrix define EEYOPOrg = J(365,2,.)
matrix define shareOfIndAbove = J(365,2,.)
matrix define shareOfIndAboveOrg = J(365,2,.)
matrix define changeOfIndAbove = J(365,2,.)
matrix define changeInMeanDayHit = J(365,2,.)
matrix define shareAboveMedianR = J(365,1,.)
matrix define shareAboveMedianROrg = J(365,1,.)
* For each day, predict the change in EEYOP for individuals who have not yet 
* crossed the deductible and the share of individuals who have not yet crossed 
* the deductible. 

forvalues k = 1(1)2 {
	
	loc j = `k' - 1
		
	forvalues v = 1(1)365 { 
		
		* predict change in EEYOP for individuals below the deductible.
		qui reg EEYOP_t deductible if day == `v' & aboveMedianRiskscore == `j'
		matrix EEYOP[`v',`k'] = _b[_cons] + _b[deductible]*475
		matrix EEYOPOrg[`v',`k'] =  _b[_cons] + _b[deductible]*375
		
		* predict change in share of individuals above the deductible. 1 minus 
		* this amount is the change in the share of individuals below the 
		* deductible.
		qui reg shareAbove deductible if day == `v' & aboveMedianRiskscore == `j'
		matrix shareOfIndAbove[`v',`k'] = _b[_cons] + _b[deductible]*475
		matrix shareOfIndAboveOrg[`v',`k'] = _b[_cons] + _b[deductible]*375
		
		* for change in individuals who hit, use aggregate sample.
		qui reg shareAbove deductible if day == `v'
		matrix changeOfIndAbove[`v',`k'] = _b[deductible]*100
		
		qui reg mean_day_hit deductible if day == `v' & aboveMedianRiskscore == `j'
		matrix changeInMeanDayHit[`v',`k'] = _b[deductible]*100
		
		}
}

local annualDiscountFactor = 1

import excel using "T:\HealthCost\analysis\output\forward looking reduced form\Tests For Monotonicity12", clear cellrange(A2:A2)
loc effectForAboveMedian = A[1]
di `effectForAboveMedian'

import excel using "T:\HealthCost\analysis\output\forward looking reduced form\Tests For Monotonicity11", clear cellrange(A2:A2)
local effectForBelowMedian = A[1]
di `effectForBelowMedian'


use "T:\HealthCost\build\output\dataForYearlySpendingPrediction.dta", clear
gen day_of_week = dow(date_treatment)

gen toRemoveWeekends = (day_of_week == 0 | day_of_week == 6)

* Get effect for people below median riskscore. Total reduction in expenditure
* from this subgroup is the mean of the variable totalEffect


preserve
keep if year == 2015
sort day
keep if aboveMedianRiskscore == 0
keep toRemoveWeekends
svmat EEYOP
svmat EEYOPOrg
svmat shareOfIndAboveOrg
svmat shareOfIndAbove
loc betaLambda = `effectForBelowMedian'

*gen dailyEffectBelowMed = -`betaLambda'*(EEYOP1*(1-shareOfIndAbove1) - EEYOPOrg1*(1-shareOfIndAboveOrg1))*(1-toRemoveWeekends)
gen part1EffB = -`betaLambda'*(EEYOP1*(shareOfIndAboveOrg1 - shareOfIndAbove1))*(1-toRemoveWeekends)
gen part2EffB = -`betaLambda'*((1-shareOfIndAboveOrg1)*(EEYOP1 - EEYOPOrg1))*(1-toRemoveWeekends)


sum part1EffB
loc part1EffectB = r(sum)
di `part1EffectB'

sum part2EffB
loc part2EffectB = r(sum)
di `part2EffectB'

*egen totalEffect1 = sum(dailyEffectBelowMed)
*sum totalEffect1
*loc belowMedEff = r(mean) 

restore

* Get effect for people above median riskscore. Total reduction in expenditure
* from this subgroup is the mean of the variable totalEffect
preserve

keep if year == 2015
sort day
keep if aboveMedianRiskscore == 1
svmat EEYOP
svmat EEYOPOrg
svmat shareOfIndAboveOrg
svmat shareOfIndAbove
loc betaLambda = `effectForAboveMedian'
gen dailyEffectAboveMed = -`betaLambda'*(EEYOP2*(1-shareOfIndAbove2) - EEYOPOrg2*(1-shareOfIndAboveOrg2))*(1-toRemoveWeekends)

gen part1EffA = -`betaLambda'*(EEYOP2*(shareOfIndAboveOrg2 - shareOfIndAbove2))*(1-toRemoveWeekends)
gen part2EffA = -`betaLambda'*((1-shareOfIndAboveOrg2)*(EEYOP2 - EEYOPOrg2))*(1-toRemoveWeekends)

egen totalEffect = sum(dailyEffectAboveMed)
sum totalEffect 
loc aboveMedEff = r(mean)

sum part1EffA
loc part1EffectA = r(sum)
di `part1EffectA'

sum part2EffA
loc part2EffectA = r(sum)
di `part2EffectA'

restore

loc dynamicEffectPart1 = 0.5*`part1EffectB' + 0.5*`part1EffectA'
loc dynamicEffectPart2 = 0.5*`part2EffectB' + 0.5*`part2EffectA'
loc dynamicEffect = `dynamicEffectPart1' + `dynamicEffectPart2'
di `dynamicEffect'

* Get spot price effects for different assumed values
foreach spotEffect of numlist 20 40 90 {
	
	preserve
	keep if year == 2015
	keep if aboveMedianRiskscore == 1
	egen mean_exp = mean(mean_spending)
	* get mean expenditures for each day
	sort day
	svmat changeOfIndAbove
	gen spotEffectAgg = (-`spotEffect'/100)*changeOfIndAbove1*(1-toRemoveWeekends)*mean_exp
	
	sum spotEffectAgg
	loc magSpot = r(sum)
	
	loc spotPriceEffect`spotEffect' = `magSpot'
	loc totalEffect`spotEffect' = `dynamicEffect' + `spotPriceEffect`spotEffect''
	di `totalEffect`spotEffect''
	restore
	}

file open table7 using "M:\SVN\healthcost\write\03 forward looking reduced form\tables\tables.txt", write append

file write table7 _n
file write table7 "<tab:spotPriceAnnualReduction>" _n

file write table7 "`spotPriceEffect90'" _tab "`dynamicEffectPart1'" _tab "`dynamicEffectPart2'" _tab "`totalEffect90'" _n
file write table7 "`spotPriceEffect40'" _tab "`dynamicEffectPart1'" _tab "`dynamicEffectPart2'" _tab "`totalEffect40'" _n
file write table7 "`spotPriceEffect20'" _tab "`dynamicEffectPart1'" _tab "`dynamicEffectPart2'" _tab "`totalEffect20'" _n
file write table7 "0" _tab "`dynamicEffectPart1'" _tab "`dynamicEffectPart2'" _tab "`dynamicEffect'" _n
file close table7

* END OF SECTION C


*===============================================================================
* The commented out code below allows for delta < 1 which complicates things. 
* Now, just assumed delta = 1 and get annual and spot price effects


/*
preserve
clear 

svmat changeInMeanDayHit
sum changeInMeanDayHit1 
loc totalChangeInMeanDayHitBelow = r(sum)

sum changeInMeanDayHit2
loc totalChangeInMeanDayHitAbove = r(sum)

gen day = _n
loc geometricDiscountFactor = `annualDiscountFactor'^(1/365)
gen geometricDiscountFactorPerDay = `geometricDiscountFactor'^(day - 1)

gen abaluckQuantity1 = geometricDiscountFactorPerDay*changeInMeanDayHit1  
gen abaluckQuantity2 = geometricDiscountFactorPerDay*changeInMeanDayHit2

sum abaluckQuantity1
loc totalChangeBelow = r(sum)
di `totalChangeBelow'

sum abaluckQuantity2 
loc totalChangeAbove = r(sum)

restore


* need to check this. The true quantity we regress on is the future price and 
* here we use the probability of crossing. it should be correct, but still. 

loc relationship1 = -`totalChangeInMeanDayHitBelow'/`totalChangeBelow'
di `relationship1'

loc relationship2 = -`totalChangeInMeanDayHitAbove'/`totalChangeAbove'
di `relationship2'

loc abaluckEffectBelow = `relationship1'*`effectForBelowMedian'
loc abaluckEffectAbove = `relationship2'*`effectForAboveMedian'
di `abaluckEffectBelow'

loc abaluckOmLamBelow = `abaluckEffectBelow'
loc abaluckOmLamAbove = `abaluckEffectAbove'

capture gen tempMeanDayHit = 0
matrix define priceMeasureAGS = J(365,2,.)
matrix define finalPriceMeasureAGS = J(365,2,.)

forvalues i = 1(1)365 {
	
	replace tempMeanDayHit = mean_day_hit
	
	if `i' != 1 {
		bys year aboveMedianRiskscore: egen haveAlreadyHit = sum(mean_day_hit) if day < `i'
		bys year aboveMedianRiskscore: egen max_have = max(haveAlreadyHit)
		replace haveAlreadyHit = max_have
		drop max_have
			
		replace tempMeanDayHit = mean_day_hit/(1 - haveAlreadyHit)
			
		drop haveAlreadyHit
	}
	
	forvalues k = `i'(1)365 {
		forvalues z = 1(1)2 {

			reg tempMeanDayHit deductible if day == `k' & aboveMedianRiskscore == `z'-1
			matrix priceMeasureAGS[`k',`z'] = _b[deductible]*100
		
		}
	}
	
	
	preserve
	di `i'
	clear
	svmat priceMeasureAGS
	keep if _n >= `i'
	gen day = _n
	gen geoDiscount = `geometricDiscountFactor'^day
	gen newPriceMeasureAGS1 = geoDiscount*priceMeasureAGS1
	
	sum newPriceMeasureAGS1
	matrix finalPriceMeasureAGS[`i',1] = r(sum)
	
	gen newPriceMeasureAGS2 = geoDiscount*priceMeasureAGS2
	sum newPriceMeasureAGS2
	matrix finalPriceMeasureAGS[`i',2] = r(sum)
	
	restore
}


preserve 

keep if year == 2015
sort day
keep if aboveMedianRiskscore == 0
svmat finalPriceMeasureAGS
svmat shareOfIndAbove
gen dailyEffectBelowMed = `abaluckOmLamBelow'*finalPriceMeasureAGS1*(1-shareOfIndAbove1)*(1-shareAboveMedianRiskscore)*(1-toRemoveWeekends)
sum dailyEffectBelowMed
di r(sum)

restore

preserve 

keep if year == 2015
sort day
keep if aboveMedianRiskscore == 1
svmat finalPriceMeasureAGS
svmat shareOfIndAbove
gen dailyEffectAboveMed = `abaluckOmLamAbove'*finalPriceMeasureAGS2*(1-shareOfIndAbove2)*(shareAboveMedianRiskscore)*(1-toRemoveWeekends)
sum dailyEffectAboveMed
di r(sum)

restore

* Get effect for people below median riskscore. Total reduction in expenditure
* from this subgroup is the mean of the variable totalEffect
preserve

keep if year == 2015
sort day
keep if aboveMedianRiskscore == 0
svmat changeInEEYOP
svmat shareOfIndAbove
loc dailyGeoDiscountFactor = `annualDiscountFactor'^(1/365)
loc firstGeoDiscount = `annualDiscountFactor'
loc betaLambda = `effectForBelowMedian'/`firstGeoDiscount'
di `betaLambda'
gen geometricDiscount = `dailyGeoDiscountFactor'^(365 - _n)
gen dailyEffectBelowMed = -`betaLambda'*changeInEEYOP1*(1-shareOfIndAbove1)*(1-shareAboveMedianRiskscore)*(1-toRemoveWeekends)*geometricDiscount
egen totalEffect = sum(dailyEffectBelowMed)
sum totalEffect 
restore

* Get effect for people above median riskscore. Total reduction in expenditure
* from this subgroup is the mean of the variable totalEffect
preserve

keep if year == 2015
sort day
keep if aboveMedianRiskscore == 1
svmat changeInEEYOP
svmat shareOfIndAbove
loc dailyGeoDiscountFactor = `annualDiscountFactor'^(1/365)
loc firstGeoDiscount = `annualDiscountFactor'
loc betaLambda = `effectForAboveMedian'/`firstGeoDiscount'
gen geometricDiscount = `dailyGeoDiscountFactor'^(365 - _n)
gen dailyEffectAboveMed = -`betaLambda'*changeInEEYOP2*(1-shareOfIndAbove2)*(shareAboveMedianRiskscore)*(1-toRemoveWeekends)*geometricDiscount
egen totalEffect = sum(dailyEffectAboveMed)
sum totalEffect 

restore
*/
*===============================================================================

* export data and use MATlab file "codeForFigureRD.m" to generate 
*svmat changeInEEYOP
*scatter changeInEEYOP* day, legend(label(1 "Below Median Riskscore") label(2 "Above Median Riskscore"))
clear
svmat EEYOP
svmat EEYOPOrg
svmat shareOfIndAboveOrg
svmat shareOfIndAbove

putexcel set "T:\HealthCost\analysis\output\forward looking reduced form\EEYOP.xlsx", sheet("M") replace
putexcel A1 = matrix(EEYOP)
putexcel set "T:\HealthCost\analysis\output\forward looking reduced form\EEYOPOrg.xlsx", sheet("M") replace
putexcel A1 = matrix(EEYOPOrg)
putexcel set "T:\HealthCost\analysis\output\forward looking reduced form\shareOfIndAbove.xlsx", sheet("M") replace
putexcel A1 = matrix(shareOfIndAbove)
putexcel set "T:\HealthCost\analysis\output\forward looking reduced form\shareOfIndAboveOrg.xlsx", sheet("M") replace
putexcel A1 = matrix(shareOfIndAboveOrg)

winexec C:\Program Files\MATLAB\R2021b\bin\matlab.exe -r cd('M:\SVN\healthcost\analysis\code'),codeForFigureRD,exit
			
sleep 30000


/*==============================================================================
* Do the annual spending reduction but for the weekly level

local annualDiscountFactor = 1

use "T:\HealthCost\build\output\dataForYearlySpendingPredictionWeekly.dta", clear

sort year week_treatment
	
matrix define changeInEEYOPWeekly = J(52,2,.)
matrix define shareOfIndAboveWeekly = J(52,2,.)

forvalues k = 1(1)2 {

	loc j = `k' - 1
		
	forvalues v = 1(1)52 { 
		reg EEYOP_t deductible if week_treatment == `v' & aboveMedianRiskscore == `j'
		matrix changeInEEYOPWeekly[`v',`k'] = _b[deductible]*100
		

		reg shareAbove deductible if week_treatment == `v' & aboveMedianRiskscore == `j'
		matrix shareOfIndAboveWeekly[`v',`k'] = _b[_cons] + _b[deductible]*475
			
		}
}

preserve
keep if year == 2015
keep if aboveMedianRiskscore == 0
svmat changeInEEYOPWeekly
svmat shareOfIndAboveWeekly
gen dynamicResponseBelowMed = -9.47998 
gen dailyEffectBelowMed = dynamicResponseBelowMed*changeInEEYOPWeekly1*(1-shareOfIndAboveWeekly1)*(1-shareAboveMedianRiskscore)
egen totalEffectWeek = sum(dailyEffectBelowMed)
sum totalEffectWeek

restore

preserve
keep if year == 2015
keep if aboveMedianRiskscore == 1
svmat changeInEEYOPWeekly
svmat shareOfIndAboveWeekly
gen dynamicResponseAboveMed = -76.529
gen dailyEffectAboveMed = dynamicResponseAboveMed*changeInEEYOPWeekly2*(1-shareOfIndAboveWeekly2)*shareAboveMedianRiskscore
egen totalEffectWeek = sum(dailyEffectAboveMed)
sum totalEffectWeek 

restore
*/
log close