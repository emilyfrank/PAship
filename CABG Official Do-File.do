clear all
set more off

use "C:\Users\efran\Box Sync\PAship\2018-2019\Data\CABG_data_cleaned20170113.dta"
drop if OtherHos==2

//CREATING NEW VARIABLE: HOSPITAL RAMR WITHOUT SPECIFIED DOCTOR

merge m:1 Hospital Year using "C:\Users\efran\Box Sync\PAship\2018-2019\Data\CABG_data_cleaned20170113_total.dta" 

/* doctorRAMR * Vol = risk-adjusted # of deaths
   hospRAMR * hospVol = risk-adjusted # of deaths
   
   (hospdeathswithoutdoctor + doctordeaths) / hospvol = hospRAMR
   hospdeathswithoutdoctor + doctordeaths = hospRAMR * hospvol
   (hospRAMR * hospvol) - doctordeaths = hospdeathswithoutdoctor 
   
   RAMR without doctor = hospdeathswithoutdoctor / hospvol 
   
   RAMR without doctor = [(hospRAMR * hospvol) - (doctorRAMR * doctorvol)] / hospvol */
  
/*gen RAMRwithoutMD=(((RAMR if OtherHos==2)*(IsolatedCABGCases if OtherHos==2))
  -((RAMR if OtherHos==1)*(IsolatedCABGCases if OtherHos==1)))
  /(IsolatedCABGCases if OtherHos==2) */

//merge based on hosp name; would have to change name of hosp variables, i.e. "HP_RAMR"

gen RAMRwithoutMD=((HospRAMR*HospIsolatedCABGCases)-(RAMR*IsolatedCABGCases))/HospIsolatedCABGCases

//CLEANING UP MDSCHOOL ERRORS

gen MDSchool_Clean=MDSchool
replace MDSchool_Clean="Univ Pennsylvania" if MDSchool=="Penn"
replace MDSchool_Clean="Univ Pennsylvania" if MDSchool=="U Penn"
replace MDSchool_Clean="Univ Chicago" if MDSchool=="U Chicago"
replace MDSchool_Clean="Johns Hopkins" if MDSchool=="John Hopkins"
replace MDSchool_Clean="Univ Connecticut" if MDSchool=="Univ Conn"
replace MDSchool_Clean="Univ Connecticut" if MDSchool=="Connecticut"
replace MDSchool_Clean="Pittsburgh" if MDSchool=="Pittsburg"
replace MDSchool_Clean="Univ Massachusetts" if MDSchool=="Univ Mass"

//COUNTING NUMBER OF INDIVIDUAL SURGEONS

egen tag=tag(Surgeon)
count if tag

// Encoding string variable and declaring dataset as panel for analysis
sort Surgeon Year Hospital
order Surgeon Year Hospital AgeSurgery
encode(Surgeon), generate(nSurgeon) label(Surgeon)
xtset nSurgeon

gen logRAMR = asinh(RAMR)
label variable logRAMR "inverse hyperbolic sine of RAMR (log)"
gen logTotalRAMR = asinh(TotalRAMR)
label variable logTotalRAMR "inverse hyperbolic sine of TotalRAMR (log)"
