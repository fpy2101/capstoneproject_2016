clear all
cd "C:\Users\puyan\Dropbox\CapstoneProject_2015\Project_Work\Data\Stata Data"
use Data\FH.dta

rename pr propr
rename cl civicl
replace status="" if status==".."
encode status, gen(status1)
drop status
destring propr civicl, replace force
rename status1 status

label var propr "Property Rights Index: 1 Greates degree of freedom"
label var civicl "Civic Liberties Index: 1 Greates degree of freedom"
label var status "FH Country Status: Free, Partly Free, Not Free"

save Data\FHuse1.dta, replace
