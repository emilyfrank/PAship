/* Descriptive statistics for CABG data */
/* Data is set up as a panel in 'CABG Official Do-File.do'*/

use "/Users/lindsayjacobs/Dropbox/@ Current/CABG Surgeon Learning/CABG Data/CABG_data_cleaned20170113_merged.dta"
ssc install estout

/* Setting up the data as a panel: */
sort Surgeon Year Hospital AgeSurgery
order Surgeon Year Hospital AgeSurgery
encode(Surgeon), generate(nSurgeon) label(Surgeon)
xtset nSurgeon

* destring 'Hospital' to use as categroical variable 
encode Hospital, gen(cHospital)
encode Surgeon, gen(cSurgeon)
* scale variables for easier interpretation in regressions
gen IsolShareTotalCABG= IsolatedCABGCases/TotalCABGVolume
gen TotalCABGVolume_d10 = TotalCABGVolume/10
gen IsolShareTotalCABG_m100 = IsolShareTotalCABG*100
gen ExperSurgery2_d10 = ExperSurgery*ExperSurgery/10
gen ExperSurgery_d10 = ExperSurgery/10
gen HospTotalCABGVolume_d10 = HospTotalCABGVolume/10
gen HospTotalCABGVolumewithoutMD = HospTotalCABGVolume-TotalCABGVolume

save "/Users/lindsayjacobs/Dropbox/@ Current/CABG Surgeon Learning/CABG Data/CABG_data_cleaned20170113_merged.dta", replace


*********************************
/* Some descriptive statistics */ 
*********************************


* The mean share of isolated CABGs a surgeon performs falls from .75 in 2000 to .56 in 2013 
tabstat IsolShareTotalCABG if OtherHos==1&TotalCABGVolume>10, by(Year) s(n mean sd min p25 p50 p75 max) 
* What predicts the share of isolated CABGs?
* Surgeons who started doinf surgery earlier, the year (declines over time), higher volume associated with slightly lower share of isolated
reg IsolShareTotalCABG TotalCABGVolume_d10 Age2016 i.Year i.cHospital i.cSurgeon if OtherHos==1&TotalCABGVolume>10
* {results too long to post


* Surgeons are on average and at the median older throughout the years observed:
tabstat AgeSurgery if OtherHos==1&TotalCABGVolume>10, by(Year) s(n mean sd min p25 p50 p75 max) 
/*
Summary for variables: AgeSurgery
     by categories of: Year (Year)

    Year |         N      mean        sd       min       p25       p50       p75       max
---------+--------------------------------------------------------------------------------
    1994 |       116     44.75  7.719963        27        40        44        49        68
[1995-2012 omitted for space]
    2013 |       149  53.49664  8.610666        36        47        53        60        74
---------+--------------------------------------------------------------------------------
   Total |      3211  48.81781  8.282971        27        42        48        54        84
------------------------------------------------------------------------------------------

*/

* The mean (median) number of Total CABGs per surgeon also fell from steadily 399.75 (363.0) in 2000 to 301.43 (261.0) in 2013
tabstat TotalCABGVolume if OtherHos==1&TotalCABGVolume>10, by(Year) s(n mean sd min p25 p50 p75 max) 

* How does a surgeon's volume vary with experience and the total number performed at hospital?  There's an inverted- U-shape over years of
* experience, and a surgeon' volume is higher if at a high-volume hospital.  Fewer surgeries in later years. Share of Isolated does not seem to affect the total volume.
xtreg TotalCABGVolume ExperSurgery ExperSurgery2_d10 IsolShareTotalCABG_m100 HospTotalCABGVolumewithoutMD i.Year if OtherHos==1&TotalCABGVolume>10, re vce(cluster Surgeon)
predict p 
graph twoway (scatter TotalCABGVolume  ExperSurgery) (scatter p ExperSurgery)  (qfit p ExperSurgery) if  OtherHos==1&TotalCABGVolume>10
drop p
/*
Random-effects GLS regression                   Number of obs     =      2,340
Group variable: nSurgeon                        Number of groups  =        250

R-sq:                                           Obs per group:
     within  = 0.0960                                         min =          1
     between = 0.0180                                         avg =        9.4
     overall = 0.0453                                         max =         28

                                                Wald chi2(17)     =      62.87
corr(u_i, X)   = 0 (assumed)                    Prob > chi2       =     0.0000

                                              (Std. Err. adjusted for 250 clusters in Surgeon)
----------------------------------------------------------------------------------------------
                             |               Robust
             TotalCABGVolume |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-----------------------------+----------------------------------------------------------------
                ExperSurgery |   20.67973   5.518644     3.75   0.000     9.863381    31.49607
           ExperSurgery2_d10 |  -4.380554   1.198624    -3.65   0.000    -6.729813   -2.031295
     IsolShareTotalCABG_m100 |  -.3903946    .719192    -0.54   0.587    -1.799985    1.019196
HospTotalCABGVolumewithoutMD |   .0082275   .0171389     0.48   0.631     -.025364    .0418191
                             |
                        Year |
                       2001  |   -16.6394    13.6484    -1.22   0.223    -43.38979    10.11098
[2002-2012 omitted for space]
                       2013  |  -176.5981   32.40319    -5.45   0.000    -240.1072    -113.089
                             |
                       _cons |   209.5927    95.2555     2.20   0.028     22.89535    396.2901
-----------------------------+----------------------------------------------------------------
                     sigma_u |  192.38852
                     sigma_e |  149.25301
                         rho |  .62427839   (fraction of variance due to u_i)
----------------------------------------------------------------------------------------------
*/

* ==>Best to look at TotalRAMR, with year fixed effects and possibly controlling for share of Isolated CABGs


/* Below, fixed/random effects regressions to determine the effect of experience, etc. on TotalRAMR: */
* Takeaways:
* No age effects but clearer experience effects (Would this still hold with piecewise regression?).  To see, run 'xtreg TotalRAMR AgeSurgery c.AgeSurgery#c.AgeSurgery IsolShareTotalCABG i.Year if OtherHos==1&TotalCABGVolume >10, fe'
* Interesting increase in TotalRAMR in years 2005-2007 (shows up with FE but not so much with RE, which is what is shown below)
* The share of the total that is Isolated CABGs has an effect on TotalRAMR
* The Hospital's RAMR without the surgeon (RAMRwithoutMD) has quite an effect as well 


*  interact experience with volume (use FE or RE? RE probably best, since we want to knwo the effects of all regressors and not difference them out (since CABG weight matters?))
xtreg TotalRAMR  c.ExperSurgery_d10##c.TotalCABGVolume_d10 IsolShareTotalCABG_m100 RAMRwithoutMD i.Year if OtherHos==1&TotalCABGVolume >10, re vce(cluster Surgeon)
predict p 
graph twoway (scatter TotalRAMR  ExperSurgery) (scatter p ExperSurgery)  (qfit p ExperSurgery)  if  OtherHos==1&TotalCABGVolume>10
drop p
/*
Random-effects GLS regression                   Number of obs     =      2,340
Group variable: nSurgeon                        Number of groups  =        250

R-sq:                                           Obs per group:
     within  = 0.0402                                         min =          1
     between = 0.1547                                         avg =        9.4
     overall = 0.0892                                         max =         28

                                                Wald chi2(18)     =      90.82
corr(u_i, X)   = 0 (assumed)                    Prob > chi2       =     0.0000

                                                          (Std. Err. adjusted for 250 clusters in Surgeon)
----------------------------------------------------------------------------------------------------------
                                         |               Robust
                               TotalRAMR |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-----------------------------------------+----------------------------------------------------------------
                        ExperSurgery_d10 |   .1540102   .2566304     0.60   0.548    -.3489762    .6569966
                     TotalCABGVolume_d10 |   -.015331   .0097113    -1.58   0.114    -.0343647    .0037028
                                         |
c.ExperSurgery_d10#c.TotalCABGVolume_d10 |   .0031471   .0045537     0.69   0.490    -.0057781    .0120722
                                         |
                 IsolShareTotalCABG_m100 |   .0169021    .010004     1.69   0.091    -.0027054    .0365097
                           RAMRwithoutMD |   .3879399   .1542169     2.52   0.012     .0856804    .6901994
                                         |
                                    Year |
                                   2001  |  -.1623939   .1341343    -1.21   0.226    -.4252922    .1005045
[2002-2012 omitted for space]
                                   2012  |  -.6577689   .3118506    -2.11   0.035    -1.268985   -.0465529
                                   2013  |  -.6237401     .33436    -1.87   0.062    -1.279074    .0315935
                                         |
                                   _cons |    2.08825   .9906644     2.11   0.035      .146583    4.029916
-----------------------------------------+----------------------------------------------------------------
                                 sigma_u |  1.6246301
                                 sigma_e |    2.18048
                                     rho |  .35697228   (fraction of variance due to u_i)
----------------------------------------------------------------------------------------------------------
*/

* Including Experience^2 has some effect on predictions (U-shaped over experience)
xtreg TotalRAMR ExperSurgery2_d10 c.ExperSurgery_d10##c.TotalCABGVolume_d10  IsolShareTotalCABG_m100  RAMRwithoutMD i.Year if OtherHos==1&TotalCABGVolume >10, re vce(cluster Surgeon)
predict p
graph twoway (scatter TotalRAMR  ExperSurgery) (scatter p ExperSurgery) (qfit p ExperSurgery) if  OtherHos==1&TotalCABGVolume>10
drop p
/*
Random-effects GLS regression                   Number of obs     =      2,340
Group variable: nSurgeon                        Number of groups  =        250

R-sq:                                           Obs per group:
     within  = 0.0409                                         min =          1
     between = 0.1624                                         avg =        9.4
     overall = 0.0909                                         max =         28

                                                Wald chi2(19)     =      91.47
corr(u_i, X)   = 0 (assumed)                    Prob > chi2       =     0.0000

                                                          (Std. Err. adjusted for 250 clusters in Surgeon)
----------------------------------------------------------------------------------------------------------
                                         |               Robust
                               TotalRAMR |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-----------------------------------------+----------------------------------------------------------------
                       ExperSurgery2_d10 |   .0151745   .0107891     1.41   0.160    -.0059717    .0363207
                        ExperSurgery_d10 |   -.509661   .5376168    -0.95   0.343    -1.563371    .5440485
                     TotalCABGVolume_d10 |  -.0155064     .00958    -1.62   0.106    -.0342829    .0032701
                                         |
c.ExperSurgery_d10#c.TotalCABGVolume_d10 |    .003523   .0044956     0.78   0.433    -.0052883    .0123343
                                         |
                 IsolShareTotalCABG_m100 |   .0164248   .0100788     1.63   0.103    -.0033294    .0361789
                           RAMRwithoutMD |   .3840599   .1518933     2.53   0.011     .0863544    .6817653
                                         |
                                    Year |
                                   2001  |  -.1494912    .134206    -1.11   0.265    -.4125302    .1135478
[2002-2012 omitted for space]
                                   2013  |  -.6337468   .3345846    -1.89   0.058    -1.289521     .022027
                                         |
                                   _cons |   2.698527   1.090924     2.47   0.013     .5603556    4.836698
-----------------------------------------+----------------------------------------------------------------
                                 sigma_u |  1.6156521
                                 sigma_e |  2.1802124
                                     rho |  .35448846   (fraction of variance due to u_i)
----------------------------------------------------------------------------------------------------------

*/


* Adding hospital effects
xtreg TotalRAMR ExperSurgery2_d10 c.ExperSurgery_d10##c.TotalCABGVolume_d10  IsolShareTotalCABG_m100  RAMRwithoutMD i.Year i.cHospital if OtherHos==1&TotalCABGVolume >10, re vce(cluster Surgeon)
predict p
graph twoway (scatter TotalRAMR  ExperSurgery) (scatter p ExperSurgery)  (qfit p ExperSurgery) if  OtherHos==1&TotalCABGVolume>10
drop p
/* 
Random-effects GLS regression                   Number of obs     =      2,340
Group variable: nSurgeon                        Number of groups  =        250

R-sq:                                           Obs per group:
     within  = 0.1186                                         min =          1
     between = 0.0710                                         avg =        9.4
     overall = 0.0950                                         max =         28

                                                Wald chi2(60)     =     304.31
corr(u_i, X)   = 0 (assumed)                    Prob > chi2       =     0.0000

                                                          (Std. Err. adjusted for 250 clusters in Surgeon)
----------------------------------------------------------------------------------------------------------
                                         |               Robust
                               TotalRAMR |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-----------------------------------------+----------------------------------------------------------------
                       ExperSurgery2_d10 |   .0180084   .0111093     1.62   0.105    -.0037654    .0397821
                        ExperSurgery_d10 |  -.7338803    .554853    -1.32   0.186    -1.821372    .3536116
                     TotalCABGVolume_d10 |  -.0180723   .0093332    -1.94   0.053    -.0363651    .0002205
                                         |
c.ExperSurgery_d10#c.TotalCABGVolume_d10 |   .0052246    .004108     1.27   0.203    -.0028269     .013276
                                         |
                 IsolShareTotalCABG_m100 |   .0161673     .01008     1.60   0.109    -.0035892    .0359237
                           RAMRwithoutMD |   .1562533   .1604877     0.97   0.330    -.1582969    .4708035
                                         |
                                    Year |
                                   2001  |  -.1511464   .1402313    -1.08   0.281    -.4259947    .1237019
[2002-2012 omitted for space]
                                   2013  |  -.6836902   .3801662    -1.80   0.072    -1.428802    .0614219
                                         |
                               cHospital |
                            Arnot Ogden  |   2.450203   1.794294     1.37   0.172     -1.06655    5.966955
[hospitals omitted for space]
                               Winthrop  |   1.742826   1.503121     1.16   0.246    -1.203236    4.688889
                                         |
                                   _cons |   1.208147   1.967734     0.61   0.539     -2.64854    5.064834
-----------------------------------------+----------------------------------------------------------------
                                 sigma_u |  1.5942869
                                 sigma_e |  2.0590661
                                     rho |  .37480634   (fraction of variance due to u_i)
----------------------------------------------------------------------------------------------------------
*/

* Simple piecewise, not very different from above so not posting results from below commands.
/*
xtreg TotalRAMR  ExperSurgery TotalCABGVolume IsolShareTotalCABG  RAMRwithoutMD i.Year if OtherHos==1&TotalCABGVolume >10&ExperSurgery<11, re vce(cluster Surgeon)
predict pL11
xtreg TotalRAMR  ExperSurgery TotalCABGVolume IsolShareTotalCABG  RAMRwithoutMD i.Year if OtherHos==1&TotalCABGVolume >10&ExperSurgery>10, re vce(cluster Surgeon)
predict pG10
gen p = pL11 if ExperSurgery<11&ExperSurgery!=.
replace p = pG10 if ExperSurgery>10&ExperSurgery!=.
graph twoway (scatter TotalRAMR  ExperSurgery) (scatter p ExperSurgery)  (qfit p ExperSurgery) if  OtherHos==1&TotalCABGVolume>10
drop pL11 pG10 p
*/

* The share of isolated CABGs has an effect (negative) for those with more experience, but no effect for those with less experience
xtreg TotalRAMR  c.ExperSurgery_d10##c.TotalCABGVolume_d10 c.ExperSurgery_d10##c.IsolShareTotalCABG  RAMRwithoutMD i.Year i.cHospital if OtherHos==1&TotalCABGVolume >10, re vce(cluster Surgeon)
predict p
graph twoway (scatter TotalRAMR  IsolShareTotalCABG) (scatter p IsolShareTotalCABG) (qfit p IsolShareTotalCABG) if  OtherHos==1&TotalCABGVolume>10&ExperSurgery<20, name(LT20yrExp)
graph twoway (scatter TotalRAMR  IsolShareTotalCABG) (scatter p IsolShareTotalCABG) (qfit p IsolShareTotalCABG) if  OtherHos==1&TotalCABGVolume>10&ExperSurgery>=20, name(GEQ20yrExp)
graph combine LT20yrExp GEQ20yrExp
drop p
/* 
* Could similarly look at the following, which produces results with the same interpretation:
xtreg TotalRAMR  c.ExperSurgery_d10##c.TotalCABGVolume_d10  IsolShareTotalCABG_m100  RAMRwithoutMD i.Year i.cHospital if OtherHos==1&TotalCABGVolume >10&ExperSurgery<20, re vce(cluster Surgeon)
xtreg TotalRAMR  c.ExperSurgery_d10##c.TotalCABGVolume_d10  IsolShareTotalCABG_m100  RAMRwithoutMD i.Year i.cHospital if OtherHos==1&TotalCABGVolume >10&ExperSurgery>=20, re vce(cluster Surgeon)
* And from a slightly different angle, surgeons who have more experience by the time non-isolated CABGs become more common have higher TotalRAMRs when the share of isolated CABGs they perform is larger
xtreg TotalRAMR  c.ExperSurgery_d10##c.TotalCABGVolume_d10 c.Age2016##c.IsolShareTotalCABG RAMRwithoutMD  i.Year i.cHospital if OtherHos==1&TotalCABGVolume >10, re vce(cluster Surgeon)
*/
/*
. xtreg TotalRAMR  c.ExperSurgery_d10##c.TotalCABGVolume_d10 c.ExperSurgery_d10##c.IsolShareTotalCABG  RAMRwithoutMD i.Year 
> i.cHospital if OtherHos==1&TotalCABGVolume >10, re vce(cluster Surgeon)
note: ExperSurgery_d10 omitted because of collinearity

Random-effects GLS regression                   Number of obs     =      2,340
Group variable: nSurgeon                        Number of groups  =        250

R-sq:                                           Obs per group:
     within  = 0.1184                                         min =          1
     between = 0.0688                                         avg =        9.4
     overall = 0.0917                                         max =         28

                                                Wald chi2(60)     =     290.96
corr(u_i, X)   = 0 (assumed)                    Prob > chi2       =     0.0000

                                                          (Std. Err. adjusted for 250 clusters in Surgeon)
----------------------------------------------------------------------------------------------------------
                                         |               Robust
                               TotalRAMR |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-----------------------------------------+----------------------------------------------------------------
                        ExperSurgery_d10 |  -.3604041   .5548499    -0.65   0.516     -1.44789    .7270816
                     TotalCABGVolume_d10 |  -.0182864   .0093762    -1.95   0.051    -.0366634    .0000906
                                         |
c.ExperSurgery_d10#c.TotalCABGVolume_d10 |   .0048761   .0041574     1.17   0.241    -.0032722    .0130244
                                         |
                        ExperSurgery_d10 |          0  (omitted)
                      IsolShareTotalCABG |    .388099   1.921082     0.20   0.840    -3.377153    4.153351
                                         |
 c.ExperSurgery_d10#c.IsolShareTotalCABG |   .6206297    .749549     0.83   0.408    -.8484594    2.089719
                                         |
                           RAMRwithoutMD |   .1655597   .1623855     1.02   0.308    -.1527101    .4838295
                                         |
                                    Year |
                                   2001  |  -.1712289   .1405495    -1.22   0.223     -.446701    .1042431
[omitted for space]
                                   2013  |  -.6552765   .3833721    -1.71   0.087    -1.406672    .0961191
                                         |
                               cHospital |
                            Arnot Ogden  |   2.375171   1.821292     1.30   0.192    -1.194496    5.944838
[omitted for space]
                               Winthrop  |    1.73606   1.536863     1.13   0.259    -1.276136    4.748255
                                         |
                                   _cons |   1.361728   2.433487     0.56   0.576    -3.407819    6.131275
-----------------------------------------+----------------------------------------------------------------
                                 sigma_u |  1.6119526
                                 sigma_e |  2.0595697
                                     rho |  .37986962   (fraction of variance due to u_i)
----------------------------------------------------------------------------------------------------------

*/





/* Is it the case that age is not correlated with performance (as suggested from conversation with Dr. Galloway)? 
   If it's not correlated, is it because the volume changes so much with age (either as a choice of the surgeon or imposed)? */
   

/* Are there spillover effects across isolated versus total CABGs? */



/* Looking at total hospital volume to see if older surgeons at smaller hospitals can decrease work.
   Volume to hospital is endogenous but volume to surgeon is not. */

/* For surgeons who perform at more than one hospital (either within the same year or, especially, across years), is there a hospital effect? */



/*  [Couldn't read on paper:] Are othre in hospital pos[trel] co[rments] */


/* How many are retiring at each age?  How does the decrease in volume predict this exit? */



/* Do hospitals have a balance of surgeon ages? */


/* Age doesn't seem to affect RAMR, but indeed volume does.  However, for log(RAMR), volume increases RAMR.
What about different levels of volumes? */
