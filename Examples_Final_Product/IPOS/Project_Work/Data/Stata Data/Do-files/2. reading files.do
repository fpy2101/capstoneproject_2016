clear all

local A "D:\CONSULTA_VAGAS_1945"
cd `A'

local files : dir "`A'" files ".txt" 		

foreach file in `files' {
dis "`file'"
*import delimited `file', delimiter(";")
*save `file'.dta, replace
}

*! dir *.dta /a-d /b >`A'\filelist.txt


