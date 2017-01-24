clear all
cd "C:\Users\puyan\Desktop\Data"

*************************************
* Model 1 - Original Model and Data *
*************************************
use dataoriginal.dta, clear

local new = _N + 1
set obs `new'
replace year=2016 in `new'
replace country="United States" in `new'
replace govapproval=51 in `new' 
replace candidate=0 in `new' 

logit result_gov govapproval candidate
predict prob1
outreg2 using Results\Table.xls, se bdec(2) excel replace e(r2_p) label
estat clas
sum prob1 if country=="United States" & year==2016

**************************************
* Model 2 - Original Model, New Data *
**************************************

use data1.dta, clear

logit result_gov govapproval candidate, robust
outreg2 using Results\Table.xls, se bdec(2) excel e(r2_p) label
predict probability1
estat clas
estat clas, cut(0.52)
lsens, graphr(c(white)) title("Sensitivity and Specificity Analysis") xtitle("Cutoff Probability") ytitle("")
gr export Results\SS_M2.pdf , replace
window manage close graph

*Generating predictions
gen prediction1=1 if probability1>=0.52 & result_gov==0 & probability1!=.
replace prediction1=2 if probability1<0.52 & result_gov==1 & probability1!=.
replace prediction1=0 if prediction1==. & probability!=.
tab prediction1

label define prediction 1 "False Positive" 2 "True Negative" 0 "Correctly Predicted"
label values prediction1 prediction

label var probability1 "Predicted P Model 2"
label var prediction1 "Predicted Result Model 2

sum probability1 if country=="United States" & year==2016


*********************************
* Model 3 - New Model, New Data *
*********************************

logit result_gov candidate fhr war employment_quarter inflation_quarter gdp_quarter etype, robust
outreg2 using Results\Table.xls, se bdec(2) excel e(r2_p) label
predict probability2
estat clas

label var probability2 "Predicted P Model 3"

sum probability2 if country=="United States" & year==2016


**************************************
* Model 4 - New Model 2, New Data *
**************************************

logit result_gov govapproval candidate war inflation_quarter, robust
outreg2 using Results\Table.xls, se bdec(2) excel e(r2_p) label
predict probability3
estat clas
estat clas, cut(0.52)
lsens, graphr(c(white)) title("Sensitivity and Specificity Analysis") xtitle("Cutoff Probability") ytitle("")
gr export Results\SS_M4.pdf , replace
window manage close graph

*Generating predictions
gen prediction3=1 if probability3>=0.5 & result_gov==0 & probability3!=.
replace prediction3=2 if probability3<0.5 & result_gov==1 & probability3!=.
replace prediction3=0 if prediction3==. & probability3!=.
tab prediction3

label var probability3 "Predicted P Model 4"
label values prediction3 prediction

label var prediction3 "Predicted Result Model 4"

gen c_prediction=1 if prediction3==. & probability3!=.
replace c_prediction=0 if prediction3!=.
tab c_prediction

gen fhr_high=1 if fhr>=3
replace fhr_high=0 if fhr<3

tab c_prediction fhr_high

sum probability3 if country=="United States" & year==2016

***************************************
* Determinants of government approval *
***************************************

reg govapproval war employment_quarter etype, robust
predict p_govapproval
gen p_govapproval2=govapproval if govapproval!=.
replace p_govapproval2=p_govapproval if govapproval==.

*Model 5 - Predicted Government Approval and Original Model
logit result_gov p_govapproval2 candidate, robust
outreg2 using Results\Table.xls, se bdec(2) excel e(r2_p) label
predict probability4
estat clas
lsens, graphr(c(white)) title("Sensitivity and Specificity Analysis") xtitle("Cutoff Probability") ytitle("")
gr export Results\SS_M5.pdf , replace
window manage close graph

gen prediction4=1 if probability4>=0.5 & result_gov==0 & probability4!=.
replace prediction4=2 if probability4<0.5 & result_gov==1 & probability4!=.
replace prediction4=0 if prediction4==. & probability4!=.
tab prediction4

label var probability4 "Predicted P Model 5"
label values prediction4 prediction

label var prediction4 "Predicted Result Model 5"

sum probability4 if country=="United States" & year==2016

*Model 6 - Predicted GA and Model 4
logit result_gov p_govapproval2 candidate war inflation_quarter, robust
outreg2 using Results\Table.xls, se bdec(2) excel e(r2_p) label
predict probability5
estat clas

sum probability5 if country=="United States" & year==2016

**************************
* Input through averages *
**************************
bysort war fhr etype decade: egen a_gov=mean(govapproval)
gen a_govapproval=govapproval if govapproval!=.
replace a_govapproval=a_gov if govapproval==.

logit result_gov a_govapproval candidate, robust
outreg2 using Results\Table.xls, se bdec(2) excel e(r2_p) label sortvar(govapproval a_govapproval p_govapproval2 candidate)
predict probability6
estat clas

sum probability6 if country=="United States" & year==2016



***************
**Export DataDump

label var namegovtcand "Name of Government Candidate"
label var namecand1 "Name of Other Candidate 1"
label var namecand2 "Name of Other Candidate 2"
label var namecand3 "Name of Other Candidate 3"
label var namecand4 "Name of Other Candidate 4"
label var votegovtcand "Vote Share of Government Candidate"
label var votecand1 "Vote Share of Other Candidate 1"
label var votecand2 "Vote Share of Other Candidate 2"
label var votecand3 "Vote Share of Other Candidate 3"
label var votecand4 "Vote Share of Other Candidate 4"
label var dateelection "Date of Election"
label var electionquarter "Quarter of Election"
label var govapproval "Government Approval"
label var approvaldate "Date of Government Approval"
label var sucessor "Government Candidate is a Sucessor"
label var incumbent "Government Candidate is an Incumbent"
label var source "Source of Information 1"
label var source2 "Source of Information 2"
label var decade "Decade of election"
label var source2 "Source of Information 2"
label var emp "Employment from Penn Tables"
label var employment_quarter "Change in Employment the quarter before the election"
label var inflation_quarter "Change in Inflation the Quarter before the election"
label var gdp_quarter "GDP growth the quarter before the election"
label var etype "Election Type"

#delimit ;
keep	country iso3 year electionwinner partywinner incumbentparty 
		firstroundsecondround namegovtcand namecand1 namecand2 namecand3 
		namecand4 votegovtcand votecand1 votecand2 votecand3 votecand4 
		dateelection govapproval result_gov candidate etype probability1 
		prediction1 probability3 prediction3 probability4 prediction4;
#delimit cr

export excel using "C:\Users\puyan\Desktop\Data\Election Data - Capstone.xlsx", sheet("Election Prediction") sheetreplace firstrow(varlabels)
