There are 4 scripts that are required to generate all the results, tables and figures in the text. 2 of these are STATA files and the other 2 are MATlab files. Only the STATA files need to be run. The MATlab files are called from within the STATA files themselves. HOWEVER, THE WORKING DIRECTORIES NEED TO BE CHANGED IN MATLAB TOO! These working directories need to be the same as the ones declared within the STATA files. Please see the MATlab files for more details.

Short description of do-files: 

1. "prepare forward looking reduced form.do" generates datasets for each subgroup we analyze. The source data come from Hayen et. al. (2018).

2. "paper forward looking reduced form.do" is broken down into 3 sections.
	A. Runs the main analysis for each subgroup. Calls MATlab function "testsForMonotonicity.m" that runs the tests for monotonicity and produces figures 3, 4, 5 (and other similar ones). The results from the tests are exported to an excel file (details in the first block of comments).
	B. Generates the RD figures (Figure 2 and Figures A.2 and A.3). Calls MATlab function "codeForFiguresRD.m" to do so.
	C. Does the counterfactual experiment in Section 7. 


How to generate all results, tables and figures: 

1. Get claims data from 2006 to 2015, choose output directory for output datasets and run "prepare data forward looking reduced form.do". 

2. Get data from step 1. Choose directories (more information in first comment block), make sure MATlab path is correct and working directories are correctly defined in all MATlab files. Run "paper forward looking reduced form.do"

For step 2 to work, you have to pay attention to where MATlab's executable lies. Ours was in C:\Program Files\MATLAB\R2021b\bin\matlab.exe. If yours is different, please ensure this is also changed in "paper forward looking reduced form.do". This also applies if you use a version of MATlab other than 2021b. You can change this easily by using ctrl+h (Find and Replace) in STATA. 


References:

1. Hayen, A., T. Klein, and M. Salm (2018, May). Does the framing of patient cost-sharing incentives matter? the effects of deductibles vs. no-claim refunds. C.E.P.R. Discussion Paper 12908.   
