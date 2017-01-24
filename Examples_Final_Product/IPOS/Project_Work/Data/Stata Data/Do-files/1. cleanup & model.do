clear all
cd "C:\Users\puyan\Dropbox\CapstoneProject_2015\Project_Work\Data\Stata Data"
import excel Data\Data.xlsx, first case(l)
drop in 545/l

*clean of obs
drop if electionwinner=="Mike Moore"

*destring of numerical string variables
destring fhr votegovtcand, replace force

*generate vote difference
egen maxvote=rowmax(votecand1 votecand2 votecand3 votecand4)
gen vote_diff=votegovtcand-maxvote
drop maxvote
label var vote_diff "Margin between the winner and the governnment candidate"

*categories of approval
gen approval=1 if govapproval>=0 & govapproval<40
replace approval=2 if govapproval>=40 & govapproval<55
replace approval=3 if govapproval>=55
replace approval=. if govapproval==.

label define approval 1 "Change" 2 "Middle" 3 "Continuity"
label val approval approval
label var approval "Government Approval"

*generate incumbancy variable
gen candidate=1-sucessornewcandidatefromthe
replace candidate=. if sucessornewcandidatefromthe==.

label define candidate 1 "Incumbent" 0 "Sucessor"
label val candidate candidate
label var candidate "Incumbency Status"

*labels for election type
encode electiontype, gen(etype) label(electiontype) 
recode etype (2=1) (5=1) (6=1) (7=1) (4=2) (8=3) (9=3) (10=3) (1=4) (3=4)
*They include governor as presidential

label define etype 1 "Presidential" 2 "Parliamentary" 3 "Prime Minister" 4 "Other/Unkown"
label val etype etype
label var etype "Type of Election"

*erase non-elections and elections with no winner or year
destring election_year, gen(year) force
drop if year==.

*encode region and glevel
encode region, gen(regioncode)
label var regioncode "Region"

replace governmentlevel="State" if state!="National"
replace governmentlevel="National" if state=="National"
encode governmentlevel, gen(glevel)
label var glevel "Government Level"
drop governmentlevel

*gen replacement variable with government approval
egen govapproval_mean=mean(govapproval)
replace govapproval_mean=govapproval if govapproval!=.

*rename dependent variable
rename result_depgovernmentinoffice result_gov
label var result_gov "Incembent party or candidate wins election"

/*
*********************
** Database set-up **
*********************
*creation of country year list
preserve
keep country
duplicates drop country, force
expandby 36, by(country)
sort country
gen year=.
replace year=_n+1979 in 1/36
replace year=year[_n-36] in 37/3060
duplicates report
export excel "country_year.xlsx", replace
restore

*merge country year
order country year
sort country year
keep if glevel==1
duplicates drop country year, force
save newdata.dta, replace

clear all
import excel country_year, case(l)
rename A country
rename B year

merge 1:1 country year using "newdata.dta"
drop _merge
save Data\data.dta, replace
erase newdata.dta
erase country_year.xlsx
*/

*Only keep the variables used in the model*
keep result_gov govapproval candidate glevel country year
order result_gov govapproval candidate glevel country year

*Summary Satistics
tabstat result_gov govapproval candidate glevel year, sta(mean sd n)

***********************************
** Model 1 - Logit w Pooled Data **
***********************************

logit result_gov govapproval candidate
predict probability1
estat clas
lsens, graphr(c(white)) title("Sensitivity and Specificity Analysis") xtitle("Cutoff Probability") ytitle("")
gr export Results\SS_M1.pdf , replace
window manage close graph

	*Best fit of the model
estat clas, cut(0.60)

	*Generating predictions
gen prediction1=1 if probability1>=0.5 & result_gov==0 & probability1!=.
replace prediction1=0 if probability1<0.5 & result_gov==1 & probability1!=.
tab prediction1

label var probability1 "Predicted P Model 1"
label var prediction1 "Predicted Result Model 1"

******************************
** Model 2 - Logit National **
******************************

logit result_gov govapproval candidate if glevel==1
predict probability2
estat clas
label var probability2 "Predicted P Model 2"

***************************
** Model 3 - Logit State **
***************************

logit result_gov govapproval candidate if glevel==2
predict probability3
estat clas
label var probability3 "Predicted P Model 3"

************************************
** Model 4 - Logit Pooled and RSE **
************************************

logit result_gov govapproval candidate, vce(r)
predict probability4
estat clas
lsens, graphr(c(white)) title("Sensitivity and Specificity Analysis") xtitle("Cutoff Probability") ytitle("")
gr export Results\SS_M4.pdf , replace
window manage close graph

	*Best fit of the model
estat clas, cut(0.60)
gen prediction4=1 if probability4>=0.5 & result_gov==0 & probability4!=.
replace prediction4=0 if probability4<0.5 & result_gov==1 & probability4!=.
tab prediction4

label var probability4 "Predicted P Model 4"
label var prediction4 "Predicted P Model 4"
