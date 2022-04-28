	
/*==============================================================================
Create smaller data set with every sample selection procedure done so that I can
just use this data set instead of having to run the whole thing over and over.
DOES NOT CREATE REL_DAY VARIABLE!! 
Stores created data set in T:\HealthCost\build\output\ as 
"dataToBeAnalyzed`specName'.dta" where `specName' is a local variable defined in 
the do-file.

specName consists of many local variables (see line 94). However, all local variables but `hetero' are the same across all datasets. This means that specName will have the following structure: specName = 18151221`hetero', where `hetero' ranges from 1 to 20, with specific values referring to the following:

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
14 = full aggregated sample, but only future price analysis
15 = placebo, dental care removed (not included in basic package for above 18)
16 = age 35-44
17 = age 45-55
18 = top 5% of spenders
19 = top 10% of spenders
20 = top 20% of spenders
21 = adds additional condition: individuals must have had a claim greater than 
	 500 in the past to be included in the sample.
22 = 67+
23 = top decile riskscore
24 = top ventile riskscore
==============================================================================*/
set more off, permanently
cd "T:\HealthCost\build\temp"
*log using buildLog, replace
clear

capture log close
log using buildLog, replace
* in all the code below, locals defined as 1 is false and 2 is true.
* if you want to create data sets for ALL samples, the range of the for-loop 
* should be set to 1(1)15.
* If you only want to create the daily level data set for the full sample, the 
* range of the for-loop should be 13(1)13 (hetero = 13 is the full sample)

* create data set with quartile risk score
use "../output/yearly riskscore wide"

forvalues i = 2008(1)2015 {
	
	xtile ventile_riskscore_`i' = riskscore_`i', n(20)

}

keep PSEUDONYM_B quartile_riskscore_* decile_riskscore_* ventile_riskscore_*
save "../output/individual quartile riskscore.dta", replace
clear

local predictYearlySpending = 0

if `predictYearlySpending' == 0 {

	forvalues hetero = 14(1)14 {
	*forvalues hetero = 1(1)17 {
	if `hetero' == 13 {
		matrix define sampleSizeMatch = J(7,2,.)
	}
	
	set more off, permanently
	use "T:\HealthCost\build\output\data 2006 to 2015 claims.dta", clear
	drop _merge
	
	if (`hetero' > 6 & `hetero' < 13) | `hetero' >= 23 & `hetero' <= 24 {
		merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\individual quartile riskscore.dta"
		}
	* run only for year pair {2014-2015} first to get the highest % of sick people 
	* used in percentile matching.
	
	local keepMental = 2
	local keepDental = 2
	local ageRangeL = 18
	local ageRangeU = 151

	* Specify months to select sample on
	local dayBegin = 32
	local dayEnd = 241

	* Specification Name
	local specName = "`ageRangeL'`ageRangeU'`keepMental'`keepDental'`hetero'"
	di `specName'
	local i = 2014
		
	keep if year == `i' | year == `i' + 1
	
	if (`hetero' > 6 & `hetero' < 13) | `hetero' >= 23 & `hetero' <= 24 {
		keep PERC_NWALL pc6_income pc4_ses_score age female voluntary_deductible deductible ///
			PSEUDONYM_B date_treatment cum_exp_treatment_before covered_expenditure hit_deductible ///
			year ZORG_PRESTATIE isMental isdental isGer isGpCare quartile_riskscore_`i' decile_riskscore_`i' ///
			ventile_riskscore_`i' BEDRAG_GED
		}
		
	else {
		keep PERC_NWALL pc6_income pc4_ses_score age female voluntary_deductible deductible ///
			PSEUDONYM_B date_treatment cum_exp_treatment_before covered_expenditure hit_deductible ///
			year ZORG_PRESTATIE isMental isdental isGer isGpCare BEDRAG_GED
		}
	
	
	g yearPair = `i'
			
	if `hetero' == 1 {
		keep if female == 1
		}
	else if `hetero' == 2 {
		drop if female == 1
		}
	else if `hetero' == 3 {
		keep if age < 65 
		}
	else if `hetero' == 4 {
		keep if age >=65
		}
	else if `hetero' == 5 {
		keep if pc6_income <= 2000
		}
	else if `hetero' == 6 {
		keep if pc6_income > 2000 & pc6_income != . 
		}	
	else if `hetero' == 7 {
		keep if quartile_riskscore_`i' == 1
		}
	else if `hetero' == 8 {
		keep if quartile_riskscore_`i' == 2
		}
	else if `hetero' == 9 {
		keep if quartile_riskscore_`i' == 3
		}
	else if `hetero' == 10 {
		keep if quartile_riskscore_`i' == 4
		}
	else if `hetero' == 11 {
		keep if quartile_riskscore_`i' < 3
		}
	else if `hetero' == 12 {
		keep if quartile_riskscore_`i' > 2
		}
	else if `hetero' == 16 {
		keep if age >= 35 & age < 45
		}
	else if `hetero' == 17 {
		keep if age >= 45 & age < 55
		}
	else if `hetero' == 22 {
		keep if age >= 67
	}
	else if `hetero' == 23 {
		keep if decile_riskscore_`i' == 10
	}
	else if `hetero' == 24 {
		keep if ventile_riskscore_`i' == 20
	}
	
	if `hetero' != 15 {
		keep if age > `ageRangeL' & age < `ageRangeU'
		}
	else {
		keep if age > 10 & age < 18
		drop if isdental == 1
		}
		
	drop if voluntary_deductible > 0
	drop if deductible == .

	* might be useful for extra analysis
	gen amountSpentOnMental = covered_expenditure if isMental == 1
	gen amountSpentOnDental = covered_expenditure if isdental == 1
	gen amountSpentOnGPCare = BEDRAG_GED * isGpCare
		
	* drop anybody with claims related to geriatric rehabilitation (included in the 
	* basic package from 2013 onwards)
	bys PSEUDONYM_B: egen max_ger = max(isGeriatric)
	drop if isGeriatric == 1

	* create daily level data set	
	sort PSEUDONYM_B date_treatment cum_exp_treatment_before, stable
	
	by PSEUDONYM_B: egen minYear = min(year)
	by PSEUDONYM_B: egen maxYear = max(year)
	
	fillin PSEUDONYM_B date_treatment
	replace covered_expenditure = 0 if covered_expenditure == .
	replace amountSpentOnMental = 0 if amountSpentOnMental == .
	replace amountSpentOnDental = 0 if amountSpentOnDental == .
	replace amountSpentOnGPCare = 0 if amountSpentOnGPCare == .
	
	by PSEUDONYM_B: egen max_minYear = max(minYear) 
	replace minYear = max_minYear
	by PSEUDONYM_B: egen max_maxYear = max(maxYear)
	replace maxYear = max_maxYear
	
	drop max_minYear max_maxYear
	
	by PSEUDONYM_B date_treatment: egen max_hit_deductible = max(hit_deductible) if hit_deductible != .
	by PSEUDONYM_B date_treatment: replace hit_deductible = max_hit_deductible
	drop max_hit_deductible
	by PSEUDONYM_B date_treatment: egen spending_on_that_day = sum(covered_expenditure)
	replace covered_expenditure = spending_on_that_day
	by PSEUDONYM_B date_treatment: egen mentalSpendingOnThatDay = sum(amountSpentOnMental)
	replace amountSpentOnMental = mentalSpendingOnThatDay
	by PSEUDONYM_B date_treatment: egen dentalSpendingOnThatDay = sum(amountSpentOnDental)
	replace amountSpentOnDental = dentalSpendingOnThatDay
	by PSEUDONYM_B date_treatment: egen gpSpendingOnThatDay = sum(amountSpentOnGPCare)
	replace amountSpentOnGPCare = gpSpendingOnThatDay
	
	by PSEUDONYM_B date_treatment: egen hadGpCare = max(isGpCare)
	replace isGpCare = hadGpCare

	sort PSEUDONYM_B year date_treatment, stable

	by PSEUDONYM_B year: egen min_age = min(age)
	replace age = min_age
	drop min_age
	by PSEUDONYM_B: egen min_female = min(female)
	replace female = min_female
	drop min_female

	by PSEUDONYM_B year: egen min_pc6_income = min(pc6_income)
	replace pc6_income = min_pc6_income
	drop min_pc6_income

	by PSEUDONYM_B year: egen min_PERC_NWALL = min(PERC_NWALL)
	replace PERC_NWALL = min_PERC_NWALL
	drop min_PERC_NWALL
	
	by PSEUDONYM_B year: egen min_pc4_ses_score = min(pc4_ses_score)
	replace pc4_ses_score = min_pc4_ses_score
	drop min_pc4_ses_score	
	
	bys PSEUDONYM_B date_treatment: keep if _n == _N

	replace year = year(date_treatment)
	drop spending_on_that_day dentalSpendingOnThatDay mentalSpendingOnThatDay hadGpCare gpSpendingOnThatDay

	* create delta (delta = 0 ==> day in which deductible was reached)
	sort PSEUDONYM_B year date_treatment, stable
	by PSEUDONYM_B year: gen day = _n
	by PSEUDONYM_B year: gen day_hit = _n if hit_deductible == 1
	by PSEUDONYM_B year: egen min_day_hit_deductible = min(day_hit) 
	gen delta = day - min_day_hit_deductible if min_day_hit_deductible!=.
	drop min_day_hit_deductible
	
	* Create CDF of accumulated spending (till date specified by dayEnd)
	by PSEUDONYM_B: egen total_spending_until_August = sum(covered_expenditure) if day <= `dayEnd' + 1 & year == `i'
	egen pctile_of_spender = mean((total_spending_until_August < 360)/(total_spending_until_August < . )) if year == `i'
	sum pctile_of_spender
	
	* store this percentile for comparison with other years
	local toBeCompared = r(mean)
	cumul total_spending_until_August if day == `dayEnd' + 1 & year == `i', gen(rel_CDF_`i')
		
	gen day_of_week = dow(date_treatment)
	
	* for specification 21, need to create a variable that has information on 
	* whether individual had a claim larger than 500 euros prior to being
	* selected into the sample.
	if `hetero' == 21 {
		gen spending500 = (covered_expenditure > 500 & day <= `dayEnd' + 1 & year == `i')
		by PSEUDONYM_B: egen has500ClaimBeforeSelect = max(spending500)
		keep if has500ClaimBeforeSelect == 1
		drop has500ClaimBeforeSelect
	}
	
	* remove January crossers
	by PSEUDONYM_B: keep if delta[1] <= - `dayBegin' | delta[1] == .
	
	* keep only crossers in year i
	keep if delta ~=. & year == `i' | year == `i' + 1
	* make sure only balanced sample remains
	by PSEUDONYM_B: keep if  delta[1] >= - `dayEnd' & year[1] == `i' & year[400] == `i' + 1	
	
	* run percentile matching using percentile from 2014 as the cutoff
	if `hetero' >= 18 {
		if `hetero' == 18 {
			loc toBeCompared = 0.95
			}
		else if `hetero' == 19 {
			loc toBeCompared = 0.9
			}
		else if `hetero' == 20 {
			loc toBeCompared = 0.8
			}
		by PSEUDONYM_B: keep if rel_CDF_`i'[`dayEnd' + 1] >= `toBeCompared'
	}
	
	keep if maxYear == `i' + 1 & minYear == `i'
	unique PSEUDONYM_B, by(year)
	sum _Unique
	
	if `hetero' == 13 {
		matrix sampleSizeMatch[`i'-2007,1] = r(mean)
		matrix sampleSizeMatch[`i'-2007,2] = r(mean)
		}
	
	by PSEUDONYM_B: gen unique_ID = 1 if _n == 1
	replace unique_ID = sum(unique_ID)
	g week_treatment = week(date_treatment)


	if `hetero' != 14 {
		keep if year == `i' & week_treatment > 36 | year == `i' + 1 & week_treatment < 14
	}

	else {
		keep if year == `i' + 1
	}
	
	save "T:\HealthCost\build\output\dataToBeAnalyzedYear`i'.dta", replace

	* do the exact same thing for all other year pairs

	forvalues i = 2008(1)2013 {
		set more off, permanently

		use "T:\HealthCost\build\output\data 2006 to 2015 claims.dta", clear
		drop _merge
		
	if (`hetero' > 6 & `hetero' < 13) | `hetero' >= 23 & `hetero' <= 24 {
		merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\individual quartile riskscore.dta"
		}
		
		keep if year == `i' | year == `i' + 1
				
	if (`hetero' > 6 & `hetero' < 13) | `hetero' >= 23 & `hetero' <= 24 {
			keep PERC_NWALL pc6_income pc4_ses_score age female voluntary_deductible deductible ///
			PSEUDONYM_B date_treatment cum_exp_treatment_before covered_expenditure hit_deductible ///
			year ZORG_PRESTATIE isMental isdental isGer isGpCare quartile_riskscore_`i' decile_riskscore_`i' ///
			ventile_riskscore_`i' BEDRAG_GED
			}
			
		else {
			keep PERC_NWALL pc6_income pc4_ses_score age female voluntary_deductible deductible ///
				PSEUDONYM_B date_treatment cum_exp_treatment_before covered_expenditure hit_deductible ///
				year ZORG_PRESTATIE isMental isdental isGer isGpCare BEDRAG_GED
			}
		
		g yearPair = `i'
		
		if `hetero' == 1 {
			keep if female == 1
			}
		else if `hetero' == 2 {
			drop if female == 1
			}
		else if `hetero' == 3 {
			keep if age < 65 
			}
		else if `hetero' == 4 {
			keep if age >=65
			}
		else if `hetero' == 5 {
			keep if pc6_income <= 2000
			}
		else if `hetero' == 6 {
			keep if pc6_income > 2000 & pc6_income != . 
			}	
		else if `hetero' == 7 {
			keep if quartile_riskscore_`i' == 1
			}
		else if `hetero' == 8 {
			keep if quartile_riskscore_`i' == 2
			}
		else if `hetero' == 9 {
			keep if quartile_riskscore_`i' == 3
			}
		else if `hetero' == 10 {
			keep if quartile_riskscore_`i' == 4
			}
		else if `hetero' == 11 {
			keep if quartile_riskscore_`i' < 3
			}
		else if `hetero' == 12 {
			keep if quartile_riskscore_`i' > 2
			}
		else if `hetero' == 16 {
			keep if age >= 35 & age < 45
		}
		else if `hetero' == 17 {
			keep if age >= 45 & age < 55
		}
		else if `hetero' == 22 {
			keep if age >= 67
		}
		else if `hetero' == 23 {
			keep if decile_riskscore_`i' == 10
		}
		else if `hetero' == 24 {
			keep if ventile_riskscore_`i' == 20
		}
		
		if `hetero' != 15 {
			keep if age > `ageRangeL' & age < `ageRangeU'
		}
		
		else {
			keep if age > 10 & age < 18
			drop if isdental == 1
		}
		
		drop if voluntary_deductible > 0
		drop if deductible == .
		
		gen amountSpentOnMental = covered_expenditure if isMental == 1
		gen amountSpentOnDental = covered_expenditure if isdental == 1
		gen amountSpentOnGPCare = BEDRAG_GED * isGpCare
			
		* drop anybody with claims related to geriatric rehabilitation (included in the 
		* basic package from 2013 onwards)
		bys PSEUDONYM_B: egen max_ger = max(isGeriatric)
		drop if isGeriatric == 1

		* create daily level data set	
		sort PSEUDONYM_B date_treatment cum_exp_treatment_before, stable
		
		by PSEUDONYM_B: egen minYear = min(year)
		by PSEUDONYM_B: egen maxYear = max(year)
		
		fillin PSEUDONYM_B date_treatment
		replace covered_expenditure = 0 if covered_expenditure == .
		replace amountSpentOnMental = 0 if amountSpentOnMental == .
		replace amountSpentOnDental = 0 if amountSpentOnDental == .
		replace amountSpentOnGPCare = 0 if amountSpentOnGPCare == .
		
		by PSEUDONYM_B: egen max_minYear = max(minYear) 
		replace minYear = max_minYear
		by PSEUDONYM_B: egen max_maxYear = max(maxYear)
		replace maxYear = max_maxYear
		
		drop max_minYear max_maxYear
		
		by PSEUDONYM_B date_treatment: egen max_hit_deductible = max(hit_deductible) if hit_deductible != .
		by PSEUDONYM_B date_treatment: replace hit_deductible = max_hit_deductible
		drop max_hit_deductible
		by PSEUDONYM_B date_treatment: egen spending_on_that_day = sum(covered_expenditure)
		replace covered_expenditure = spending_on_that_day
		by PSEUDONYM_B date_treatment: egen mentalSpendingOnThatDay = sum(amountSpentOnMental)
		replace amountSpentOnMental = mentalSpendingOnThatDay
		by PSEUDONYM_B date_treatment: egen dentalSpendingOnThatDay = sum(amountSpentOnDental)
		replace amountSpentOnDental = dentalSpendingOnThatDay
		by PSEUDONYM_B date_treatment: egen gpSpendingOnThatDay = sum(amountSpentOnGPCare)
		replace amountSpentOnGPCare = gpSpendingOnThatDay
		
		by PSEUDONYM_B date_treatment: egen hadGpCare = max(isGpCare)
		replace isGpCare = hadGpCare

		sort PSEUDONYM_B year date_treatment, stable

		by PSEUDONYM_B year: egen min_age = min(age)
		replace age = min_age
		drop min_age
		by PSEUDONYM_B: egen min_female = min(female)
		replace female = min_female
		drop min_female

		by PSEUDONYM_B year: egen min_pc6_income = min(pc6_income)
		replace pc6_income = min_pc6_income
		drop min_pc6_income

		by PSEUDONYM_B year: egen min_PERC_NWALL = min(PERC_NWALL)
		replace PERC_NWALL = min_PERC_NWALL
		drop min_PERC_NWALL
		
		by PSEUDONYM_B year: egen min_pc4_ses_score = min(pc4_ses_score)
		replace pc4_ses_score = min_pc4_ses_score
		drop min_pc4_ses_score	
		
		bys PSEUDONYM_B date_treatment: keep if _n == _N

		replace year = year(date_treatment)
		drop spending_on_that_day dentalSpendingOnThatDay mentalSpendingOnThatDay hadGpCare gpSpendingOnThatDay

			
		sort PSEUDONYM_B year date_treatment, stable
		by PSEUDONYM_B year: gen day = _n
		by PSEUDONYM_B year: gen day_hit = _n if hit_deductible == 1
		by PSEUDONYM_B year: egen min_day_hit_deductible = min(day_hit) 
		gen delta = day - min_day_hit_deductible if min_day_hit_deductible!=.
		drop min_day_hit_deductible
		
		by PSEUDONYM_B: egen total_spending_until_August = sum(covered_expenditure) if day <= `dayEnd' + 1 & year == `i'
		cumul total_spending_until_August if day == `dayEnd' + 1 & year == `i', gen(rel_CDF_`i')
			
		* for specification 21, need to create a variable that has information on 
		* whether individual had a claim larger than 500 euros prior to being
		* selected into the sample.
		if `hetero' == 21 {
		
			gen spending500 = (covered_expenditure > 500 & day <= `dayEnd' + 1 & year == `i')
			by PSEUDONYM_B: egen has500ClaimBeforeSelect = max(spending500)
			keep if has500ClaimBeforeSelect == 1
			drop has500ClaimBeforeSelect
			
		}
		
		
		* remove January crossers
		by PSEUDONYM_B: keep if delta[1] <= - `dayBegin' | delta[1] == .

		keep if delta ~=. & year == `i'| year == `i' + 1
		
		by PSEUDONYM_B: keep if  delta[1] >= - `dayEnd'  & year[1] == `i' & year[400] == `i' + 1 
		
		keep if maxYear == `i' + 1 & minYear == `i'
		unique PSEUDONYM_B, by(year)
		sum _Unique
		local numberWOMatch = r(mean)
	
		* run percentile matching using percentile from 2014 as the cutoff
		by PSEUDONYM_B: keep if rel_CDF_`i'[`dayEnd' + 1] >= `toBeCompared'
		
		unique PSEUDONYM_B, by(year)
		sum _Unique
		local numberWMatch = r(mean)
		
		if `hetero' == 13 {
			matrix sampleSizeMatch[`i'-2007,1] = `numberWOMatch'
			matrix sampleSizeMatch[`i'-2007,2] = `numberWMatch'
		}
		
		gen day_of_week = dow(date_treatment)
		
		g week_treatment = week(date_treatment)

		unique PSEUDONYM_B, by(year)
		if `hetero' != 14 {
			keep if year == `i' & week_treatment > 36 | year == `i' + 1 & week_treatment < 14
		}

		else {
			keep if year == `i' + 1
		}
		
		save "T:\HealthCost\build\output\dataToBeAnalyzedYear`i'.dta", replace
		
		}

		
	* also get the data for 2015 to use for creating the deflator
	if `hetero' != 14 {
		
		use "T:\HealthCost\build\output\data 2006 to 2015 claims.dta", clear
		drop _merge
		
	if (`hetero' > 6 & `hetero' < 13) | `hetero' >= 23 & `hetero' <= 24 {
		merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\individual quartile riskscore.dta"
		}
		local i = 2015
		
		keep if year == `i' | year == `i' + 1
				
				
	if (`hetero' > 6 & `hetero' < 13) | `hetero' >= 23 & `hetero' <= 24 {
			keep PERC_NWALL pc6_income pc4_ses_score age female voluntary_deductible deductible ///
			PSEUDONYM_B date_treatment cum_exp_treatment_before covered_expenditure hit_deductible ///
			year ZORG_PRESTATIE isMental isdental isGer isGpCare quartile_riskscore_`i' decile_riskscore_`i' ///
			ventile_riskscore_`i' BEDRAG_GED
			}
			
		else {
			keep PERC_NWALL pc6_income pc4_ses_score age female voluntary_deductible deductible ///
				PSEUDONYM_B date_treatment cum_exp_treatment_before covered_expenditure hit_deductible ///
				year ZORG_PRESTATIE isMental isdental isGer isGpCare BEDRAG_GED
			}
		
		g yearPair = `i'

		if `hetero' == 1 {
			keep if female == 1
			}
		else if `hetero' == 2 {
			drop if female == 1
			}
		else if `hetero' == 3 {
			keep if age < 65 
			}
		else if `hetero' == 4 {
			keep if age >=65
			}
		else if `hetero' == 5 {
			keep if pc6_income <= 2000
			}
		else if `hetero' == 6 {
			keep if pc6_income > 2000 & pc6_income != . 
			}	
		else if `hetero' == 7 {
			keep if quartile_riskscore_`i' == 1
			}
		else if `hetero' == 8 {
			keep if quartile_riskscore_`i' == 2
			}
		else if `hetero' == 9 {
			keep if quartile_riskscore_`i' == 3
			}
		else if `hetero' == 10 {
			keep if quartile_riskscore_`i' == 4
			}
		else if `hetero' == 11 {
			keep if quartile_riskscore_`i' < 3
			}
		else if `hetero' == 12 {
			keep if quartile_riskscore_`i' > 2
			}
		else if `hetero' == 16 {
			keep if age >= 35 & age < 45
		}
		else if `hetero' == 17 {
			keep if age >= 45 & age < 55
		}	
		else if `hetero' == 22 {
			keep if age >= 67
		}
		else if `hetero' == 23 {
			keep if decile_riskscore_`i' == 10
		}
		else if `hetero' == 24 {
			keep if ventile_riskscore_`i' == 20
		}
		
		if `hetero' != 15 {
			keep if age > `ageRangeL' & age < `ageRangeU'
		}
		else {
			keep if age > 10 & age < 18
			drop if isdental == 1
		}
			
		drop if voluntary_deductible > 0
		drop if deductible == .

		gen amountSpentOnMental = covered_expenditure if isMental == 1
		gen amountSpentOnDental = covered_expenditure if isdental == 1
		gen amountSpentOnGPCare = BEDRAG_GED * isGpCare
			
		* drop anybody with claims related to geriatric rehabilitation (included in the 
		* basic package from 2013 onwards)
		bys PSEUDONYM_B: egen max_ger = max(isGeriatric)
		drop if isGeriatric == 1

		* create daily level data set	
		sort PSEUDONYM_B date_treatment cum_exp_treatment_before, stable
		
		by PSEUDONYM_B: egen minYear = min(year)
		by PSEUDONYM_B: egen maxYear = max(year)
		
		fillin PSEUDONYM_B date_treatment
		replace covered_expenditure = 0 if covered_expenditure == .
		replace amountSpentOnMental = 0 if amountSpentOnMental == .
		replace amountSpentOnDental = 0 if amountSpentOnDental == .
		replace amountSpentOnGPCare = 0 if amountSpentOnGPCare == .
		
		by PSEUDONYM_B: egen max_minYear = max(minYear) 
		replace minYear = max_minYear
		by PSEUDONYM_B: egen max_maxYear = max(maxYear)
		replace maxYear = max_maxYear
		
		drop max_minYear max_maxYear
		
		by PSEUDONYM_B date_treatment: egen max_hit_deductible = max(hit_deductible) if hit_deductible != .
		by PSEUDONYM_B date_treatment: replace hit_deductible = max_hit_deductible
		drop max_hit_deductible
		by PSEUDONYM_B date_treatment: egen spending_on_that_day = sum(covered_expenditure)
		replace covered_expenditure = spending_on_that_day
		by PSEUDONYM_B date_treatment: egen mentalSpendingOnThatDay = sum(amountSpentOnMental)
		replace amountSpentOnMental = mentalSpendingOnThatDay
		by PSEUDONYM_B date_treatment: egen dentalSpendingOnThatDay = sum(amountSpentOnDental)
		replace amountSpentOnDental = dentalSpendingOnThatDay
		by PSEUDONYM_B date_treatment: egen gpSpendingOnThatDay = sum(amountSpentOnGPCare)
		replace amountSpentOnGPCare = gpSpendingOnThatDay
		
		by PSEUDONYM_B date_treatment: egen hadGpCare = max(isGpCare)
		replace isGpCare = hadGpCare

		sort PSEUDONYM_B year date_treatment, stable

		by PSEUDONYM_B year: egen min_age = min(age)
		replace age = min_age
		drop min_age
		by PSEUDONYM_B: egen min_female = min(female)
		replace female = min_female
		drop min_female

		by PSEUDONYM_B year: egen min_pc6_income = min(pc6_income)
		replace pc6_income = min_pc6_income
		drop min_pc6_income

		by PSEUDONYM_B year: egen min_PERC_NWALL = min(PERC_NWALL)
		replace PERC_NWALL = min_PERC_NWALL
		drop min_PERC_NWALL
		
		by PSEUDONYM_B year: egen min_pc4_ses_score = min(pc4_ses_score)
		replace pc4_ses_score = min_pc4_ses_score
		drop min_pc4_ses_score	
		
		bys PSEUDONYM_B date_treatment: keep if _n == _N

		replace year = year(date_treatment)
		drop spending_on_that_day dentalSpendingOnThatDay mentalSpendingOnThatDay hadGpCare gpSpendingOnThatDay

		sort PSEUDONYM_B year date_treatment, stable
		by PSEUDONYM_B year: gen day = _n
		by PSEUDONYM_B year: gen day_hit = _n if hit_deductible == 1
		by PSEUDONYM_B year: egen min_day_hit_deductible = min(day_hit) 
		gen delta = day - min_day_hit_deductible if min_day_hit_deductible!=.
		drop min_day_hit_deductible

		by PSEUDONYM_B: egen total_spending_until_August = sum(covered_expenditure) if day <= `dayEnd' + 1 & year == `i'
		egen pctile_of_spender = mean((total_spending_until_August < 375)/(total_spending_until_August < . )) if year == `i'
		sum pctile_of_spender
		local toBeCompared = r(mean)
		cumul total_spending_until_August if day == `dayEnd' + 1 & year == `i', gen(rel_CDF_`i')

		gen day_of_week = dow(date_treatment)
		
		* for specification 21, need to create a variable that has information on 
		* whether individual had a claim larger than 500 euros prior to being
		* selected into the sample.
		if `hetero' == 21 {
			gen spending500 = (covered_expenditure > 500 & day <= `dayEnd' + 1 & year == `i')
			by PSEUDONYM_B: egen has500ClaimBeforeSelect = max(spending500)
			keep if has500ClaimBeforeSelect == 1
			drop has500ClaimBeforeSelect
		}
	
		by PSEUDONYM_B: keep if delta[1] <= - `dayBegin' | delta[1] == .

		keep if delta ~=. & year == `i' | year == `i' + 1
		
		
		if `i' != 2015 {
			by PSEUDONYM_B: keep if  delta[1] >= -`dayEnd' & year[1] == `i' & year[400] == `i' + 1
		}
		else {
			by PSEUDONYM_B: keep if  delta[1] >= -`dayEnd' & year[1] == `i'
			}
			
		by PSEUDONYM_B: keep if rel_CDF_`i'[`dayEnd'+1] >= `toBeCompared'
			
		g week_treatment = week(date_treatment)

		if `hetero' != 14 {
			keep if year == `i' & week_treatment > 36 | year == `i' + 1 & week_treatment < 14
		}

		else {
			keep if year == `i' + 1
	}

	unique PSEUDONYM_B, by(year)
	}

	forvalues i = 2008(1)2014 {
		append using "T:\HealthCost\build\output\dataToBeAnalyzedYear`i'.dta"
	}
	
	if `hetero' != 14 {
		sort PSEUDONYM_B year date_treatment, stable
		by PSEUDONYM_B year: egen min_age = min(age)
		replace age = min_age
		drop min_age

		by PSEUDONYM_B: egen min_female = min(female)
		replace female = min_female
		drop min_female

		by PSEUDONYM_B year: egen min_pc6_income = min(pc6_income)
		replace pc6_income = min_pc6_income
		drop min_pc6_income

		by PSEUDONYM_B year: egen min_PERC_NWALL = min(PERC_NWALL)
		replace PERC_NWALL = min_PERC_NWALL
		drop min_PERC_NWALL

		by PSEUDONYM_B year: egen min_pc4_ses_score = min(pc4_ses_score)
		replace pc4_ses_score = min_pc4_ses_score
		drop min_pc4_ses_score
	}

	save "T:\HealthCost\build\output\dataToBeAnalyzed`specName'.dta", replace
	
	if `hetero' == 13 {
		* generate summary statistics table
		* if need to get matched/not matched sample numbers without running 
		* whole thing: 
		
		matrix define sampleSizeMatch = J(7,2,.)
		matrix sampleSizeMatch[1,1] = 29289
		matrix sampleSizeMatch[2,1] = 32953
		matrix sampleSizeMatch[3,1] = 33985
		matrix sampleSizeMatch[4,1] = 36329
		matrix sampleSizeMatch[5,1] = 33845
		matrix sampleSizeMatch[6,1] = 31282
		matrix sampleSizeMatch[7,1] = 29626
		matrix sampleSizeMatch[1,2] = 22798
		matrix sampleSizeMatch[2,2] = 25090
		matrix sampleSizeMatch[3,2] = 27473
		matrix sampleSizeMatch[4,2] = 26706
		matrix sampleSizeMatch[5,2] = 28045
		matrix sampleSizeMatch[6,2] = 30864
		matrix sampleSizeMatch[7,2] = 29626
				
		
		use "T:\HealthCost\build\output\dataToBeAnalyzed181512213.dta", clear
		matrix define summaryTable = J(7,10,.)

		forvalues i = 2008(1)2014 {
					
			preserve 
			if `i' == 2008 {
				local j = 354
				local k = 365 + 9
				}
		
			else if `i' == 2009 {
				local j = 352 
				local k = 365 + 7 

				}
			else if `i' == 2010 {
				local j = 351
				local k = 365 + 6
				
				} 
			else if `i' == 2011 {
				local j = 357
				local k = 365 + 5 + 7
				} 
			else if `i' == 2012 {
				local j = 356
				local k = 365 + 11
				}
			else if `i' == 2013 {
				local j = 354
				local k = 365 + 9
				}
			else if `i' == 2014 {
				local j = 353
				local k = 365 + 8
				}	
			else if `i' == 2015 { 
				local j = 352
				local k = 365 + 7
				}
				
			gen inDonut = (year == `i' & day > `j' | year == `i' + 1 & day < `k' - 365)	
			
			gen notRegularDay = (day_of_week == 0 | day_of_week == 6 | inDonut == 1)
			
			gen made_claim = (covered_expenditure > 0) if notRegularDay == 0
			keep if year == `i' & week_treatment > 36 | year == `i' + 1 & week_treatment < 15
			gen noPriceTime = (year == `i')
			
			sum covered_expenditure if noPriceTime == 1 & notRegularDay == 0
			matrix summaryTable[`i'-2007,5] = r(mean)
			
			sum covered_expenditure if noPriceTime == 0 & week_treatment < 5 & notRegularDay == 0
			matrix summaryTable[`i'-2007,6] = r(mean)			
			
			gen cen_exp = covered_expenditure 
			replace cen_exp = 500 if cen_exp > 500
			sum cen_exp if noPriceTime == 1 & notRegularDay == 0
			matrix summaryTable[`i'-2007,7] = r(mean)
			
			sum cen_exp if noPriceTime == 0 & week_treatment < 5 & notRegularDay == 0
			matrix summaryTable[`i'-2007,8] = r(mean)
			
			sort PSEUDONYM_B date_treatment 
			by PSEUDONYM_B: egen max_fem = max(female)
			replace female = max_fem
			sum female if noPriceTime
			matrix summaryTable[`i'-2007,2] = r(mean)
			
			by PSEUDONYM_B: egen max_age = max(age)
			replace age = max_age
			sum age if noPriceTime
			matrix summaryTable[`i'-2007,1] = r(mean)
			
			by PSEUDONYM_B: egen max_inc = max(pc6_income)
			replace pc6_income = max_inc
			sum pc6_income if noPriceTime == 1
			matrix summaryTable[`i'-2007,3] = r(mean)
			
			unique PSEUDONYM_B if delta != ., by(year)
			sum _Unique
			local nextCross = r(min)
			local crossed = r(max)
			
			di `nextCross'/`crossed'
			matrix summaryTable[`i'-2007,4] = 1-`nextCross'/`crossed'
			
			sum made_claim if noPriceTime == 1 & notRegularDay == 0
			matrix summaryTable[`i'-2007,9] = r(mean)
			
			sum made_claim if noPriceTime == 0 & week_treatment < 5 & notRegularDay == 0
			matrix summaryTable[`i'-2007,10] = r(mean)
			
			restore
		}
		
		file open sumTable using "M:\SVN\healthcost\write\03 forward looking reduced form\tables\summTable.txt", write append

		file write sumTable _n
		file write sumTable "<tab:summStats>" _n
		
		forvalues yearPair = 2008(1)2014 {
			forvalues column = 1(1)10 {
				loc relevantVariable`column'`yearPair' = summaryTable[`yearPair'-2007,`column']
			}
			
			loc relevantVariable11`yearPair' = sampleSizeMatch[`yearPair'-2007,1]
			loc relevantVariable12`yearPair' = sampleSizeMatch[`yearPair'-2007,2]
			
		}
	
			forvalues row = 1(1)12 {
				file write sumTable "`relevantVariable`row'2008'" _tab "`relevantVariable`row'2009'" _tab ///
				"`relevantVariable`row'2010'" _tab "`relevantVariable`row'2011'" _tab "`relevantVariable`row'2012'" _tab ///
				"`relevantVariable`row'2013'" _tab "`relevantVariable`row'2014'" _n
			}
		file close sumTable
	}
	}
}

	
else {
	set more off, permanently
	use "T:\HealthCost\build\output\data 2006 to 2015 claims.dta", clear
	drop _merge
	merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\individual quartile riskscore.dta"
	
	forvalues i = 2008(1)2015 {
	
		preserve
		keep if year == `i' 
			
		keep age voluntary_deductible deductible year hit_deductible ///
		PSEUDONYM_B date_treatment cum_exp_treatment_before covered_expenditure /// 
		quartile_riskscore_`i'
			
		gen aboveMedianRiskscore = (quartile_riskscore_`i' > 2)
			
		drop quartile_riskscore_`i'
	
		keep if age > 18
		drop if voluntary_deductible > 0
		drop if deductible == .
			
		sort PSEUDONYM_B date_treatment cum_exp_treatment_before, stable
		fillin PSEUDONYM_B date_treatment
		replace covered_expenditure = 0 if covered_expenditure == .

		by PSEUDONYM_B date_treatment: egen max_hit_deductible = max(hit_deductible) if hit_deductible != .
		by PSEUDONYM_B date_treatment: replace hit_deductible = max_hit_deductible
		drop max_hit_deductible
		by PSEUDONYM_B date_treatment: egen spending_on_that_day = sum(covered_expenditure)
		replace covered_expenditure = spending_on_that_day
		by PSEUDONYM_B: egen max_above_med_r = max(aboveMedianRiskscore)
		replace aboveMedianRiskscore = max_above_med_r
		drop max_above_med_r
			
		by PSEUDONYM_B date_treatment: keep if _n == _N
		replace year = year(date_treatment)
		drop spending_on_that_day
		sort PSEUDONYM_B date_treatment, stable
		by PSEUDONYM_B: gen day = _n
		by PSEUDONYM_B: gen day_hit = _n if hit_deductible == 1
		by PSEUDONYM_B: egen min_day_hit_deductible = min(day_hit) 	
			
		replace day_hit = min_day_hit_deductible
		
		gen delta = day - min_day_hit_deductible if min_day_hit_deductible!=.
		gen ever_hit = (delta != .)
		
		gen made_claim = (covered_expenditure > 0)
		gen cen_exp = covered_expenditure
		replace cen_exp = 500 if covered_expenditure > 500
		
		drop age min_day_hit_deductible voluntary_deductible cum_exp_treatment_before _fillin
		
		egen rel_deductible = max(deductible)
		replace deductible = rel_deductible
		drop rel_deductible
		replace hit_deductible = 0 if delta != 0
		replace hit_deductible = 1 if delta == 0
		gen has_hit = (day > day_hit & day_hit != .)
		bys day aboveMedianRiskscore: egen shareAbove = mean(has_hit)
		by day aboveMedianRiskscore: egen mean_day_hit = mean(hit_deductible)
		by day aboveMedianRiskscore: egen mean_hit = mean(ever_hit) if has_hit == 0
		
		bys day: egen shareAboveMedianRiskscore = mean(aboveMedianRiskscore)
		bys day aboveMedianRiskscore: egen mean_spending_PC = mean(cen_exp)
		by day aboveMedianRiskscore: egen mean_made_claim = mean(made_claim)
		
		bys day: egen mean_spending = mean(covered_expenditure) if has_hit == 1
		by day: egen max_mean_spending = min(mean_spending)
		replace mean_spending = max_mean_spending
		drop max_mean_spending
		by day: egen mean_spending_agg = mean(covered_expenditure)
		
		by day: egen mean_spending_below_100 = mean(covered_expenditure) if delta >= 0 & delta != . & covered_expenditure < 100
		by day: egen max_mean_spending_below = min(mean_spending_below_100)
		replace mean_spending_below_100 = max_mean_spending_below
		drop max_mean_spending_below
		
		by day: egen shareAbove_agg = mean(has_hit)
		by day: egen mean_day_hit_agg = mean(hit_deductible)
		
		drop cen_exp made_claim covered_expenditure
		
		egen relObs = tag(day has_hit aboveMedianRiskscore)
		keep if relObs == 1 & has_hit == 0
		bys aboveMedianRiskscore: egen probCross = max(shareAbove)
		gen EEYOP = 1 - probCross
		gen EEYOP_t = EEYOP/(1 - shareAbove)
		
		save "T:\HealthCost\build\output\dataForYearlySpendingPrediction`i'.dta", replace
		
		restore
	}
		
		use "T:\HealthCost\build\output\dataForYearlySpendingPrediction2008.dta", clear

		forvalues i = 2009(1)2015 {
			append using "T:\HealthCost\build\output\dataForYearlySpendingPrediction`i'.dta"
			}
			
		save "T:\HealthCost\build\output\dataForYearlySpendingPrediction.dta", replace
		
	* Weekly level
	
	use "T:\HealthCost\build\output\data 2006 to 2015 weekly.dta", clear
	merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\individual quartile riskscore.dta"
	
	set more off, permanently
	forvalues i = 2008(1)2015 {
	
		preserve
		keep if year == `i' 
		keep age voluntary_deductible deductible year hit_deductible ///
		 PSEUDONYM_B week_treatment cum_exp_treatment_before covered_expenditure /// 
		 quartile_riskscore_`i'
		
		gen aboveMedianRiskscore = (quartile_riskscore_`i' > 2)
			
		drop quartile_riskscore_`i'
		
		keep if age > 18
		drop if voluntary_deductible > 0
		drop if deductible == .
		
		

		sort PSEUDONYM_B week_treatment, stable
		by PSEUDONYM_B: gen week_hit = week_treatment if hit_deductible == 1
		by PSEUDONYM_B: egen min_week_hit_deductible = min(week_hit) 

		replace week_hit = min_week_hit_deductible
		
		gen delta = week_treatment - min_week_hit_deductible if min_week_hit_deductible!=.
		gen made_claim = (covered_expenditure > 0)
		
		gen cen_exp = covered_expenditure
		replace cen_exp = 500 if covered_expenditure > 500
		
		drop age min_week_hit_deductible voluntary_deductible cum_exp_treatment_before
		
		egen rel_deductible = max(deductible)
		replace deductible = rel_deductible
		drop rel_deductible

		replace hit_deductible = 0 if delta != 0
		replace hit_deductible = 1 if delta == 0
		gen has_hit = (week_treatment > week_hit & week_hit != .)
		bys week_treatment aboveMedianRiskscore: egen shareAbove = mean(has_hit)
		bys week_treatment has_hit: egen shareAboveMedianRiskscore = mean(aboveMedianRiskscore)
		
		bys week_treatment: egen mean_spending = mean(covered_expenditure) if has_hit == 1
		by week_treatment: egen max_mean_spending = min(mean_spending)
		replace mean_spending = max_mean_spending
		
		bys week_treatment: egen mean_spending_agg = mean(covered_expenditure)
		drop max_mean_spending
		drop cen_exp made_claim
		
		egen relObs = tag(week_treatment has_hit aboveMedianRiskscore)
		keep if relObs == 1 & has_hit == 0
		
		bys aboveMedianRiskscore: egen probCross = max(shareAbove)
		gen EEYOP = 1 - probCross
		gen EEYOP_t = EEYOP/(1 - shareAbove)
		
		save "T:\HealthCost\build\output\dataForYearlySpendingPredictionWeekly`i'.dta", replace
		
		restore
		}
		
		use "T:\HealthCost\build\output\dataForYearlySpendingPredictionWeekly2008.dta", clear
		forvalues i = 2009(1)2015 {
			append using "T:\HealthCost\build\output\dataForYearlySpendingPredictionWeekly`i'.dta"
			}
			
		save "T:\HealthCost\build\output\dataForYearlySpendingPredictionWeekly.dta", replace
		
		* create for 2015 spending above deductible
		*use "T:\HealthCost\build\output\data 2006 to 2015 weekly.dta", clear

}	


* Create probability weighted data (for heterogeneity analysis)	
* by sex

local specName = 181512213

use "T:\HealthCost\build\output\dataToBeAnalyzed`specName'.dta", clear
replace yearPair = year if week_treatment > 20
replace yearPair = year-1 if week_treatment < 20

merge m:1 PSEUDONYM_B using "T:\HealthCost\build\output\yearly riskscore wide.dta"
drop if _merge == 2
drop _merge

save "T:\HealthCost\build\temp\baselineDataWithRiskscore.dta", replace

egen uniqueInd = tag(PSEUDONYM_B yearPair)
gen ipw = 1
gen inFemaleSample = (female == 1)
gen inMaleSample = (female == 0)

forvalues i = 2008(1)2014 {
	capture drop dummyVar*
	gen quintile_riskscore_`i' = 1 if decile_riskscore_`i' >= 1 & decile_riskscore_`i' < 3
	replace quintile_riskscore_`i' = 2 if decile_riskscore_`i' >= 3 & decile_riskscore_`i' < 5
	replace quintile_riskscore_`i' = 3 if decile_riskscore_`i' >= 5 & decile_riskscore_`i' < 7
	replace quintile_riskscore_`i' = 4 if decile_riskscore_`i' >= 7 & decile_riskscore_`i' < 9
	replace quintile_riskscore_`i' = 5 if decile_riskscore_`i' >= 9 & decile_riskscore_`i' < 10
	
	replace quintile_riskscore_`i' = 0 if quintile_riskscore_`i' == .

	tab quintile_riskscore_`i', gen(dummyVar)
	
	logit inMaleSample dummyVar* if uniqueInd == 1 & yearPair == `i', iterate(20)
	predict pi`i', p
	replace ipw = 1/pi`i' if inMaleSample == 1 & yearPair == `i' 
	
	logit inFemaleSample dummyVar* if uniqueInd == 1 & yearPair == `i', iterate(20)
	predict pi2`i', p
	replace ipw = 1/pi2`i' if inFemaleSample == 1 & yearPair == `i' 
	
}

save "T:\HealthCost\build\output\forProbWeightDataFemale.dta", replace

** Check if riskscores are balanced exactly. Check for a single year
/*
loc i = 2014
keep if year == `i'
sum quintile_riskscore_`i'

loc toBeComparedTo = r(mean)

egen sumIPW = sum(ipw) if inFemaleSample == 1
gen weights = ipw/sumIPW

sum weights
di r(sum)

gen weighted_quintile = weights*quintile_riskscore_`i'
sum weighted_quintile
di r(sum)
di `toBeComparedTo'
*/

* by income 
use "T:\HealthCost\build\temp\baselineDataWithRiskscore.dta", clear

egen uniqueInd = tag(PSEUDONYM_B yearPair)
gen ipw = 1
qui sum pc6_income, d
loc medInc = r(p50)
gen inBelowMedIncSample = (pc6_income < `medInc')
gen inAboveMedIncSample = (pc6_income >= `medInc' & pc6_income != .)

forvalues i = 2008(1)2014 {
	capture drop dummyVar*
	gen quintile_riskscore_`i' = 1 if decile_riskscore_`i' >= 1 & decile_riskscore_`i' < 3
	replace quintile_riskscore_`i' = 2 if decile_riskscore_`i' >= 3 & decile_riskscore_`i' < 5
	replace quintile_riskscore_`i' = 3 if decile_riskscore_`i' >= 5 & decile_riskscore_`i' < 7
	replace quintile_riskscore_`i' = 4 if decile_riskscore_`i' >= 7 & decile_riskscore_`i' < 9
	replace quintile_riskscore_`i' = 5 if decile_riskscore_`i' >= 9 & decile_riskscore_`i' < 10

	replace quintile_riskscore_`i' = 0 if quintile_riskscore_`i' == .
	
	tab quintile_riskscore_`i', gen(dummyVar)
	
	
	logit inBelowMedIncSample dummyVar* if uniqueInd == 1 & yearPair == `i', iterate(20)
	predict pi`i', p
	replace ipw = 1/pi`i' if inBelowMedIncSample == 1 & yearPair == `i' 
	
	logit inAboveMedIncSample dummyVar* if uniqueInd == 1 & yearPair == `i', iterate(20)
	predict pi2`i', p
	replace ipw = 1/pi2`i' if inAboveMedIncSample == 1 & yearPair == `i'
}

save "T:\HealthCost\build\output\forProbWeightDataIncome.dta", replace



* by age

use "T:\HealthCost\build\temp\baselineDataWithRiskscore.dta", clear

egen uniqueInd = tag(PSEUDONYM_B yearPair)
gen ipw = 1
gen inBelow45Sample = (age < 45)
gen inAbove45Sample = (age >= 45)

forvalues i = 2008(1)2014 {
	capture drop dummyVar*
	gen quintile_riskscore_`i' = 1 if decile_riskscore_`i' >= 1 & decile_riskscore_`i' < 3
	replace quintile_riskscore_`i' = 2 if decile_riskscore_`i' >= 3 & decile_riskscore_`i' < 5
	replace quintile_riskscore_`i' = 3 if decile_riskscore_`i' >= 5 & decile_riskscore_`i' < 7
	replace quintile_riskscore_`i' = 4 if decile_riskscore_`i' >= 7 & decile_riskscore_`i' < 9
	replace quintile_riskscore_`i' = 5 if decile_riskscore_`i' >= 9 & decile_riskscore_`i' < 10
	
	replace quintile_riskscore_`i' = 0 if quintile_riskscore_`i' == .

	tab quintile_riskscore_`i', gen(dummyVar)
	
	logit inBelow45Sample dummyVar* if uniqueInd == 1 & yearPair == `i', iterate(20)
	predict pi5`i', p
	replace ipw = 1/pi5`i' if inBelow45Sample == 1 & yearPair == `i'
	
	logit inAbove45Sample dummyVar* if uniqueInd == 1 & yearPair == `i', iterate(20)
	predict pi6`i', p
	replace ipw = 1/pi6`i' if inAbove45Sample == 1 & yearPair == `i'
} 

save "T:\HealthCost\build\output\forProbWeightDataAge.dta", replace

	
log close
