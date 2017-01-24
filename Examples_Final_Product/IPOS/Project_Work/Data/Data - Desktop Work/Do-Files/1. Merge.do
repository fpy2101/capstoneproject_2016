clear all
cd "C:\Users\puyan\Desktop\Data"

import excel Source\electiond.xlsx, sh(Data) first case(l)
drop if location!="National"
sort country year

*Elimination Duplicates
duplicates tag country year, g(tag)
drop if tag>0 & incumbentparty==""
drop if tag==2 & incumbentleader==""
duplicates tag country year, g(tag2)
drop if tag2==1 & fhr==.
drop tag tag2
destring incumbant_or_successor_wins, force replace

save data1.dta, replace

*Merge with annual employment
import excel Source\employmenta.xlsx, sh(data) first case(l) clear
destring employ, force replace
sort country year
bysort country: gen increase=employ-employ[_n-1]
bysort country: gen y_employ=increase*100/employ[_n-1]
label var y_employ "Increase in Annual Employment (%)"
drop if year==2016
keep iso3 year y_employ
save data2.dta, replace

use data1.dta, clear
merge 1:1 iso3 year using data2.dta
drop if _merge==2
drop _merge

save data1.dta, replace

*Merge with quarterly employment
import excel Source\employmentq.xlsx, sh(data) first case(l) clear
destring q1 q2 q3 q4, force replace
bysort country: replace q1=. if year==1980
sort country year
forvalues i=1/4{
	bysort country: gen increaseq`i'=q`i'-q`i'[_n-1]
	bysort country: gen q`i'_employ=increaseq`i'*100/q`i'[_n-1]
	label var q`i'_employ "Increase in Quarterly Employment (%, Q`i')"
}
drop if year==2016
keep iso3 year q*employ q4
rename q4 empq4
save data2.dta, replace

use data1.dta, clear
merge 1:1 iso3 year using data2.dta
drop if _merge==2
drop _merge

save data1.dta, replace

*Merge with quarterly inflation
import excel Source\inflationq.xlsx, sh(data) first case(l) clear
destring q1 q2 q3 q4, force replace
bysort country: replace q1=. if year==1980
sort country year
forvalues i=1/4{
	bysort country: gen q`i'_inflation=q`i'-q`i'[_n-1]
	label var q`i'_inflation "Increase in Quarterly Inflation (%, Q`i')"
}
drop if year==2016
keep iso3 year q*inflation
save data2.dta, replace

use data1.dta, clear
merge 1:1 iso3 year using data2.dta
drop if _merge==2
drop _merge

save data1.dta, replace

*Merge with quarterly gdp
import excel Source\gdpq.xlsx, sh(data) first case(l) clear
destring q1 q2 q3 q4, force replace
bysort country: replace q1=. if year==1980
sort country year
forvalues i=1/4{
	rename q`i' q`i'_gdp
	label var q`i'_gdp "Quarterly GDP Growth (%, Q`i')"
}
drop if year==2016
keep iso3 year q*gdp
save data2.dta, replace

use data1.dta, clear
merge 1:1 iso3 year using data2.dta
drop if _merge==2
drop _merge

save data1.dta, replace

*Merge with annual freedom house rating
import excel Source\fhra.xlsx, sh(data) first case(l) clear
destring rating, force replace
sort country year
rename rating fhra
label var fhra "Freedom House Rating (1-7)"
drop if year==2016
keep iso3 year fhra
save data2.dta, replace

use data1.dta, clear
merge 1:1 iso3 year using data2.dta
drop if _merge==2
drop _merge
drop fhr
rename fhra fhr

save data1.dta, replace

*Merge with war data
import excel Source\midb.xlsx, sh(data) first case(l) clear
destring war, force replace
sort country year
label var war "Country is at war"
drop if year==2016
keep iso3 year war
save data2.dta, replace

use data1.dta, clear
merge 1:1 iso3 year using data2.dta
replace war=0 if _merge==1 & war==.
drop if _merge==2
drop _merge

replace war=1 if war>1 & war!=.

save data1.dta, replace

*Create decade variable
drop if year<1980
gen decade=1 if year<=1989
replace decade=2 if year>=1990 & year<=1999
replace decade=3 if year>=2000 & year<=2009
replace decade=4 if year>=2010 & year<2019

*Merge PennTables employment
merge 1:1 iso3 year using Source\pwt81.dta, keepus(emp)
drop if _merge==2

replace empq4=empq4/1000000
gen emp1=emp if emp!=.
replace emp1=empq4 if emp==.
drop empq4 emp
rename emp1 emp
bysort country: gen emp_a=(emp[_n-1]-emp[_n-2])*100/emp[_n-2]
drop emp
rename emp_a emp

drop if electionwinner==""

*Create appropriate variable with quarter
destring electionquarter, force replace

gen employment_quarter=.
forvalues i=1/4{
	replace employment_quarter=q`i'_employ if electionquarter==`i'
}

gen inflation_quarter=.
forvalues i=1/4{
	replace inflation_quarter=q`i'_inflation if electionquarter==`i'
}
replace inflation_quarter=. if inflation_quarter>1000 | inflation_quarter<-1000

gen gdp_quarter=.
forvalues i=1/4{
	replace gdp_quarter=q`i'_gdp if electionquarter==`i'
}

gen result_gov=1 if partywinner== incumbentparty
replace result_gov=0 if result_gov!=1
label var result_gov "Incumbent party wins"

gen candidate=1 if incumbent==1
replace candidate=1 if namegovtcand==incumbentleader & incumbent==.
replace candidate=0 if sucessor==1 & candidate!=1
replace candidate=0 if namegovtcand=="" & candidate!=1
label var candidate "Candidate is incumbent"

replace etype="" if etype=="#N/A"
encode etype, gen(etype2)
drop etype
rename etype2 etype
recode etype (2=0)

recode govapproval (0.44=44)

*Change in units
replace govapproval=govapproval/100
replace employment_quarter=employment_quarter/100
replace inflation_quarter=inflation_quarter/100
replace gdp_quarter=gdp_quarter/100

*Create US observation
local new = _N + 1
set obs `new'
replace year=2016 in `new'
replace country="United States" in `new'
replace iso3="USA" in `new'
replace govapproval=0.51 in `new' 
replace candidate=0 in `new' 
replace fhr=1 in `new' 
replace war=1 in `new' 
replace employment_quarter=0.0211 in `new' 
replace inflation_quarter=0.01 in `new' 
replace gdp_quarter=0.014 in `new' 
replace etype=0 in `new'


save data1.dta, replace
erase data2.dta

*Summary statistics
tabstat result_gov govapproval candidate fhr war employment_quarter inflation_quarter gdp_quarter etype, s(n mean sd min max) format(%9.3f)

*Label for Variables
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

drop excellentgood incumbant_or_successor_wins gov_in_office_on_ballot gov_in_office_supporting_candida new_democracy _merge
sort iso3 year

*Export database to excel
export excel using "C:\Users\puyan\Desktop\Data\Election Data - Capstone.xlsx", sheet("Election Data") sheetreplace firstrow(varlabels)
