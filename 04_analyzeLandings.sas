****************************************************************************************************;
* - Inputs tsapel.cpr1999_2021                                                                     *;
* - Calculates #trip duration, total landing and LPUE per year, per month and per vessel           *;
* - 7-month backwards shift to align with spawning season                                          *;
* - Performs harmonic GAMs with Tweedie distributions.                                             *;
* - Produces Fig 1                                                                                 *;
* - Output to 05_calcPhenMetricsSINC.nb for calculating phenological metrics                       *;
****************************************************************************************************;

goptions reset=global htitle=2.3 htext=2.3 ftext=arial colors=(black) ftitle=arial;

libname tsapel 'C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\SAS';

OPTIONS FMTSEARCH=(sasuser formats);

%global yearmin;
%global yearmax;
%global tripmax;
%let yearmin=1999;
%let yearmax=2021;
%let yearmax_=2024;
%let tripmax=2;
*%let maxdf=26;
%let maxdf=22;

proc format;
  value $top
   'C'=-30
   'D'=-20
   'E'=-10
   'F'=  0
   'G'= 10
   'H'= 20
;
RUN;

data cprvess01;
  set tsapel.cprvess1999_2021;
  landing = landing/1000;
  if (ref_year >= &yearmin. and ref_year <= &yearmax.);
  if tripdur <= &tripmax.;
  keep ref_vess ref_ft ref_year ref_month ref_day ref_date ref_ices gear vlength species tripdur landing imark;
RUN;

*proc freq data=cprvess01(where=(species='HER'));
*  tables tripdur;
*  weight landing;
*RUN;
*proc freq data=cprvess01(where=(species='HER'));
*  tables ref_year*ref_month;
*RUN;
proc freq data=cprvess01(where=(species='HER'));
  tables ref_ices;
  weight landing;
RUN;


proc sort data=cprvess01;
  by ref_ft species;
RUN;
proc means  data=cprvess01 noprint;
  by ref_ft;
  var tripdur imark;
  id ref_vess vlength ref_year ref_month ref_day ref_date;
  output out=cprvess02(drop=_type_ _freq_) max=;
RUN;
proc means data=cprvess01(where=(species='HER')) noprint;
  by ref_ft;
  var landing;
  output out=cprvess02_(drop=_type_ _freq_) sum=landing_her;
RUN;

data cprvess03;
  merge cprvess02 cprvess02_;
    by ref_ft;
  if landing_her = . then landing_her = 0;
  Pi = arcos(-1);
  ******** Try estimates with a 7-month backwards shift (or put in comments) **********;
  if ref_month >= 7 then do;
    ref_month = ref_month - 7;
    ref_year = ref_year;
  end;
  else do;
    ref_month = ref_month + 5;
    ref_year = ref_year - 1;
  end;
  if ref_year in (1998,2021) then delete;
  **************************************************************************************;
  xcos = cos(2*Pi*ref_month/12);
  xsin = sin(2*Pi*ref_month/12);
  xcos2 = cos(4*Pi*(ref_month)/12);
  xsin2 = sin(4*Pi*(ref_month)/12);
  xcos3 = cos(6*Pi*(ref_month)/12);
  xsin3 = sin(6*Pi*(ref_month)/12);
  xcos4 = cos(8*Pi*(ref_month)/12);
  xsin4 = sin(8*Pi*(ref_month)/12);
  xcos5 = cos(10*Pi*(ref_month)/12);
  xsin5 = sin(10*Pi*(ref_month)/12);
  lpue_her = landing_her/tripdur;
  yearmonth = ref_year + (ref_month)/12;
RUN;
proc sort data=cprvess03;
  by ref_year ref_month;
RUN;
*proc freq data=cprvess03;
*  tables ref_year*ref_month;
*  weight tripdur;
*RUN;

data cpr_landing_her;
  set cprvess03;
  var_name = 'LAND_HER';
  var_value = landing_her;
  keep ref_ft ref_vess vlength ref_year ref_month ref_day ref_date yearmonth tripdur xcos: xsin: var_name var_value;
RUN;
data cpr_lpue_her;
  set cprvess03;
  var_name = 'LPUE_HER';
  var_value = lpue_her;
  keep ref_ft ref_vess vlength ref_year ref_month ref_day ref_date yearmonth tripdur xcos: xsin: var_name var_value;
RUN;
data cprvess04;
  set cpr_landing_her cpr_lpue_her;
  if var_name = 'LPUE_HER';
  ref_year_ = ref_year;
  ref_month_ = ref_month;
  ref_vlength = vlength*tripdur;
  *if vlength < 24;
RUN;
proc sort data=cprvess04;
  by var_name ref_year ref_month;
RUN;

symbol1 i=none v=dot color=blue  line=1 w=2 repeat=1;
proc gplot data=cprvess04;
  plot var_value*yearmonth / overlay nolegend;
RUN;
proc means data=cprvess04 noprint;
  var vlength;
  by var_name ref_year ref_month;
  id yearmonth;
  output out=cprvess04_(drop=_type_) mean=;
RUN;
proc gplot data=cprvess04_;
  plot vlength*yearmonth / overlay nolegend;
RUN;

proc sgplot data=cprvess04;
  vbox vlength / category=ref_month;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data;
  yaxis display=(nolabel) /*values=(0 to 80 by 20)*/ valueattrs=(size=12 weight=bold);
RUN;
proc sgplot data=cprvess04;
  vbox vlength / category=ref_year;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data;
  yaxis display=(nolabel) /*values=(0 to 80 by 20)*/ valueattrs=(size=12 weight=bold);
RUN;

ods graphics on;
proc gampl data=cprvess04 seed=12345 plots;
  model vlength = spline(ref_year ref_month) / dist=tweedie link=log;
  output out=vlength01 p=pred_hat lower=pred_p05 upper=pred_p95 residual=pred_res;
  *ods output ParameterEstimates=gamparms00 FitStatistics=gamfit00;
RUN;

data vlength02;
  merge cprvess04 vlength01;
  attrib ref_year label="Annual cycle";
  attrib ref_month label="Month";
RUN;

proc template;
   define statgraph surface2;
      begingraph /*/ designwidth=defaultDesignHeight*/;
	     entrytitle "Predicted vessel length (m)";
         layout overlay /
           xaxisopts=(offsetmin=0 offsetmax=0 linearopts=(thresholdmin=0 thresholdmax=0)
             linearopts=(tickvaluepriority=true minorticks=true
             tickvaluelist=(1999 2004 2009 2014 2019)
             tickdisplaylist=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20")))
           yaxisopts=(offsetmin=0 offsetmax=0 linearopts=(viewmax=12 thresholdmin=0 thresholdmax=0)
             linearopts=(tickvaluepriority=true minorticks=true
             tickvaluelist=(0 2 4 6 8 10)
             tickdisplaylist=("JUL" "SEP" "NOV" "JAN" "MAR" "MAY")));
           contourplotparm z=pred_hat y=ref_month x=ref_year /
             gridded=TRUE contourtype=fill nhint=10 nlevels=10 name="Contour";
		   continuouslegend "Contour";
         endlayout;
      endgraph;
   end;
RUN;
proc sgrender data=vlength02 template=surface2;
RUN;

proc means data=vlength02 noprint;
  var pred_hat;
  by ref_year;
  output out=vlength02_(drop=_type_) mean=;
RUN;
proc sgplot data=vlength02_;
  vbox pred_hat / category=ref_year;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data;
  yaxis display=(nolabel) /*values=(0 to 80 by 20)*/ valueattrs=(size=12 weight=bold);
RUN;

proc sort data=vlength02 out=vlength03;
  by ref_month;
RUN;
proc means data=vlength03 noprint;
  var pred_hat;
  by ref_month;
  output out=vlength03_(drop=_type_) mean=;
RUN;
proc sgplot data=vlength03_;
  vbox pred_hat / category=ref_month;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data;
  yaxis display=(nolabel) /*values=(0 to 80 by 20)*/ valueattrs=(size=12 weight=bold);
RUN;

proc sort data=vlength02 out=vlength04;
  by ref_year ref_month;
RUN;
proc means data=vlength04 noprint;
  var pred_hat wlength;
  by ref_year ref_month;
  output out=vlength04_(drop=_type_) mean=;
RUN;
data vlength05;
  set vlength04_;
  wlength = pred_hat*(ref_month);
RUN;
proc means data=vlength05 noprint;
  by ref_year;
  var pred_hat wlength;
  output out=vlength05_ sum=;
RUN;
data vlength06;
  set vlength05_;
  vlength_grav = wlength/pred_hat;
  keep ref_year vlength_grav;
RUN;
proc sgplot data=vlength06;
  vbox vlength_grav / category=ref_year;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25");
  yaxis display=(nolabel) values=(4 to 8 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("OCT" "NOV" "DEC" "JAN" "FEB");
RUN;

*********** GAM and plot applying simple sine wave, with or without annual interactions *************;

proc gampl data=cprvess04 seed=12345; *SIN0;
  model var_value = param(vlength) param(xcos) param(xsin) / dist=Tweedie link=log;
  output out=cprvess050 p=pred_hat lower=pred_p05 upper=pred_p95 residual=pred_res;
  ods output ParameterEstimates=gamparms00 FitStatistics=gamfit00;
RUN;
data gamparms00;
  set gamparms00;
  method = 'SIN0';
RUN;
data gamfit00;
  set gamfit00;
  method = 'SIN0';
RUN;
ods graphics on;
proc gampl data=cprvess04 seed=12345 plots; *SINW;
  class ref_year;
  model var_value = param(vlength) param(xcos) param(xsin) spline(ref_year_/maxdf=&maxdf.) / dist=Tweedie link=log;
  output out=cprvess05w p=pred_hat lower=pred_p05 upper=pred_p95 residual=pred_res;
  ods output ParameterEstimates=gamparms01w FitStatistics=gamfit01w NObs=gamobs01w;
RUN;
ods graphics off;
ods graphics on;
proc gampl data=cprvess04 seed=12345 plots; *SINX;
  class ref_year;
  model var_value = param(vlength) param(xcos*ref_year) param(xsin*ref_year) / dist=Tweedie link=log;
  output out=cprvess05x p=pred_hat lower=pred_p05 upper=pred_p95 residual=pred_res;
  ods output ParameterEstimates=gamparms01x FitStatistics=gamfit01x NObs=gamobs01x;
RUN;
ods graphics off;
ods graphics on;
proc gampl data=cprvess04 seed=12345 plots; *SINA: 1st Fourier harmonic;
  class ref_year;
  model var_value = param(xcos*ref_year) param(xsin*ref_year) spline(ref_year_/ maxdf=&maxdf.) / dist=Tweedie link=log;
  output out=cprvess05a p=pred_hat lower=pred_p05 upper=pred_p95 residual=pred_res;
  ods output ParameterEstimates=gamparms01a FitStatistics=gamfit01a NObs=gamobs01a;
RUN;
ods graphics off;
*ods graphics on;
*proc gampl data=cprvess04 plots; *SINB: 2nd Fourier harmonic; * DID not converge after 200 iterations; 
*  class ref_year;
*  model var_value = param(xcos*ref_year) param(xsin*ref_year) param(xcos2*ref_year) param(xsin2*ref_year)
*        param(vlength) spline(ref_year_/maxdf=&maxdf.) / dist=Tweedie link=log;
*  output out=cprvess05b p=pred_hat lower=pred_p05 upper=pred_p95 residual=pred_res;
*  ods output ParameterEstimates=gamparms01b FitStatistics=gamfit01b NObs=gamobs01b;
*RUN;
*ods graphics off;
ods graphics on;
proc gampl data=cprvess04 seed=12345 plots; *SINC: 3rd Fourier harmonic;
  class ref_year;
  model var_value = param(xcos*ref_year) param(xsin*ref_year) param(xcos2*ref_year) param(xsin2*ref_year)
                    param(xcos3*ref_year) param(xsin3*ref_year)
                    spline(ref_year_/ maxdf=&maxdf.) / dist=Tweedie link=log;
  output out=cprvess05c p=pred_hat lower=pred_p05 upper=pred_p95 residual=pred_res;
  ods output ParameterEstimates=gamparms01c FitStatistics=gamfit01c NObs=gamobs01c;
RUN;
ods graphics off;

quit;
*************************************************************************************************************;

data gamfit02w;
  set gamfit01w;
  method = 'SINW';
RUN;
data gamfit02x;
  set gamfit01x;
  method = 'SINX';
RUN;
data gamfit02a;
  set gamfit01a;
  method = 'SINA';
RUN;
data gamfit02c;
  set gamfit01c;
  method = 'SINC';
RUN;
data gamfit02;
  set gamfit02w gamfit02x gamfit02a gamfit02c;
  if substr(description,1,4) = 'AIC ';
  AIC = Value;
  keep method AIC;
RUN;
proc sort data=gamfit02;
  by method;
RUN;
data gamobs02w;
  set gamobs01w;
  method = 'SINW';
RUN;
data gamobs02x;
  set gamobs01x;
  method = 'SINX';
RUN;
data gamobs02a;
  set gamobs01a;
  method = 'SINA';
RUN;
data gamobs02c;
  set gamobs01c;
  method = 'SINC';
RUN;
data gamobs02;
  set gamobs02w gamobs02x gamobs02a gamobs02c;
  if label = 'Number of Observations Read';
  nbobs = N;
  keep method nbobs;
RUN;
proc sort data=gamobs02;
  by method;
RUN;
data gammodel01;
  merge gamobs02 gamfit02;
    by method;
RUN;

data cprvess060;
  merge cprvess04 cprvess050;
  ref_dat = MDY(ref_month,01,ref_year);
  method = 'SIN0';
RUN;
data cprvess06w;
  merge cprvess04 cprvess05w;
  ref_dat = MDY(ref_month,01,ref_year);
  method = 'SINW';
RUN;
data cprvess06x;
  merge cprvess04 cprvess05x;
  ref_dat = MDY(ref_month,01,ref_year);
  method = 'SINX';
RUN;
data cprvess06a;
  merge cprvess04 cprvess05a;
  ref_dat = MDY(ref_month,01,ref_year);
  method = 'SINA';
RUN;
data cprvess06c;
  merge cprvess04 cprvess05c;
  ref_dat = MDY(ref_month,01,ref_year);
  method = 'SINC';
RUN;
data cprvess06;
  set cprvess06w cprvess06x cprvess06a cprvess06c;
  ref_dat = MDY(ref_month,01,ref_year);
RUN;
proc sort data=cprvess06;
  by method ref_year ref_month;
RUN;

data gamparms02w;
  set gamparms01w;
  method = 'SINW';
RUN;
data gamparms02x;
  set gamparms01x;
  method = 'SINX';
RUN;
data gamparms02a;
  set gamparms01a;
  method = 'SINA';
RUN;
data gamparms02c;
  set gamparms01c;
  method = 'SINC';
RUN;
data gamparms02;
  set gamparms02w gamparms02x gamparms02a gamparms02c;
RUN;

data gamparms03 gamparms04 gamparms05 gamparms06 gamparms07 gamparms08;
  set gamparms02;
  if effect ^in ('Intercept','Dispersion','Power','vlength');
  if method in ('SINA','SINC');
  keep method ref_year parameter estimate stderr;
  if substr(parameter,1,5) = 'xcos*' then output gamparms03;
  else if substr(parameter,1,5) = 'xsin*' then output gamparms04;
  else if substr(parameter,1,5) = 'xcos2' then output gamparms05;
  else if substr(parameter,1,5) = 'xsin2' then output gamparms06;
  else if substr(parameter,1,5) = 'xcos3' then output gamparms07;
  else if substr(parameter,1,5) = 'xsin3' then output gamparms08;
  keep method ref_year parameter estimate stderr;
RUN;
data gamparms03_;
  set gamparms03;
  betac = estimate;
  sigmac = stderr;
  keep method ref_year betac sigmac;
RUN;
proc sort data=gamparms03_;
  by method ref_year;
RUN;
data gamparms04_;
  set gamparms04;
  betas = estimate;
  sigmas = stderr;
  keep method ref_year betas sigmas;
RUN;
proc sort data=gamparms04_;
  by method ref_year;
RUN;
data gamparms05_;
  set gamparms05;
  betac2 = estimate;
  sigmac2 = stderr;
  keep method ref_year betac2 sigmac2;
RUN;
data gamparms06_;
  set gamparms06;
  betas2 = estimate;
  sigmas2 = stderr;
  keep method ref_year betas2 sigmas2;
RUN;
data gamparms07_;
  set gamparms07;
  betac3 = estimate;
  sigmac3 = stderr;
  keep method ref_year betac3 sigmac3;
RUN;
data gamparms08_;
  set gamparms08;
  betas3 = estimate;
  sigmas3 = stderr;
  keep method ref_year betas3 sigmas3;
RUN;
data cprvess07;
  merge cprvess06 gamparms03_ gamparms04_ gamparms05_ gamparms06_ gamparms07_ gamparms08_;
    by method ref_year;
  yearmonth = ref_year + (ref_month)/12;
RUN;
proc sort data=cprvess07;
  by method ref_year ref_month;
RUN;

************************ Exporting GAM model performance statistics and outputs **********************;

data tsapel.gamoutput_logbk_shift1;
  set cprvess07;
  ref_period = "&yearmin.-&yearmax.";
RUN;
data tsapel.gammodel_logbk_shift;
  set gamparms02;
RUN;
data tsapel.gamfit_logbk_shift;
  set gammodel01;
RUN;

data stat1;
  set tsapel.gammodel_logbk_shift;
  sortpar = substr(parameter,1,5);
  if substr(parameter,1,1) = "x";
  keep method sortpar estimate;
RUN;
proc sort data=stat1;
  by method sortpar;
RUN;
proc means data=stat1 noprint;
  var estimate;
  by method sortpar;
  output out=tsapel.outstatlogbk min=minpar max=maxpar;
RUN;

***********************************************************************************************************************;
*** Keep to avoid running GAMPL with spline(year,month) and a lot of df which takes a long time, suppress otherwise ***;
*data cprvess07;
*  set tsapel.gamoutput_logbk_shift1;
*RUN;
***********************************************************************************************************************;
***********************************************************************************************************************;

********************************************** Making general graphs **************************************************;

proc template;
   define statgraph surface;
      begingraph /*/ designwidth=defaultDesignHeight*/;
	     entrytitle "Predicted landing ber annual cycle et per month";
         layout overlay /
           xaxisopts=(offsetmin=0 offsetmax=0 linearopts=(thresholdmin=0 thresholdmax=0))
           yaxisopts=(offsetmin=0 offsetmax=0 linearopts=(viewmax=12 thresholdmin=0 thresholdmax=0));
           contourplotparm z=pred_hat y=ref_month_ x=ref_year_ /
             gridded=TRUE contourtype=fill nhint=20 nlevels=20 name="Contour";
		   continuouslegend "Contour" / title="Predicted landings";
         endlayout;
      endgraph;
   end;
RUN;
proc sgrender data=cprvess07(where=(method='SINC')) template=surface;
RUN;

axis1 color=black width=1 label=none major=(height=1 width=1) minor=none order=(&yearmin. to &yearmax_. by 5);
axis2 color=black label=(angle=90 'Herring landings') width=1 major=(height=1 width=1) minor=none order=(0 to 20 by 5);
axis21 color=none label=none width=1 major=none minor=none value=none order=(0 to 20 by 5);

symbol1   i=none v=dot color=blue  h=1 w=1 l=1  repeat=1;
symbol2   i=join v=none color=red   h=1 w=2 l=1  repeat=1;
symbol3   i=join v=none color=red  h=1 w=1 l=33  repeat=2;
proc gplot data=cprvess07;
  plot (var_value pred_hat pred_p05 pred_p95)*yearmonth / overlay haxis=axis1 nolegend;
  by method;
RUN;

proc means data=cprvess07 noprint;
  by method ref_year ref_month;
  var var_value;
  id pred_hat pred_p05 pred_p95 ref_dat yearmonth xcos: xsin: betac: betas: sigmac: sigmas:;
  output out=cprvess08(drop=_type_ _freq_) mean=var_med p5=var_p05 p95=var_p95;
RUN;

symbol1 i=join v=none color=black line=1 w=1 repeat=3;
symbol2 i=join v=none color=red line=1 w=2 repeat=1;
pattern1 color=white value=mempty;
pattern2 color=ligr value=msolid;
pattern3 color=ligr value=msolid;
title "SINA";
proc gplot data=cprvess08(where=(method='SINA'));
  plot (var_p05 var_p95)*yearmonth / skipmiss areas=2 overlay haxis=axis1 vaxis=axis2 nolegend;
  plot2 (var_med pred_hat)*yearmonth / skipmiss overlay vaxis=axis21 nolegend;
RUN;
title "SINC";
proc gplot data=cprvess08(where=(method='SINC'));
  plot (var_p05 var_p95)*yearmonth / skipmiss areas=2 overlay haxis=axis1 vaxis=axis2 nolegend;
  plot2 (var_med pred_hat)*yearmonth / skipmiss overlay vaxis=axis21 nolegend;
RUN;
title;

******************************* Initial explorations - in comment for final printing **********************************;
/*
data focus1;
  set cprvess08;
       if (ref_year >= 1999 and ref_year < 2005) then hexade = '1999-2004';
  else if (ref_year >= 2005 and ref_year < 2011) then hexade = '2005-2010';
  else if (ref_year >= 2011 and ref_year < 2017) then hexade = '2011-2016';
  else if (ref_year >= 2017 and ref_year < 2023) then hexade = '2017-2022';
  else delete; 
  if method in ('SINA','SINC');
  keep hexade ref_year ref_month method yearmonth var_med pred_hat; 
RUN;
data focus2;
  set focus1;
  landings = pred_hat;
       if method = 'SINA' then series = "Fourier 1st order ";
  else if method = 'SINC' then series = "Fourier 3rd order ";
  keep hexade ref_year ref_month method series yearmonth landings;
RUN;
data focus3;
  set focus1;
  landings = var_med;
  if method = 'SINA';
  series = "Observations         ";
  keep hexade ref_year ref_month series yearmonth landings;
RUN;
data focus4;
  set focus2 focus3;
  if method = '' then method = 'OBSE';
RUN;
proc sort data=focus4;
  by hexade ref_year ref_month series;
RUN;

axis11 color=black width=1 label=none value=("JUL99" "JUL00" "JUL01" "JUL02" "JUL03" "JUL04" "JUL05") major=(height=1 width=1) minor=none order=(1999 to 2005 by 1);
axis12 color=black width=1 label=none value=("JUL05" "JUL06" "JUL07" "JUL08" "JUL09" "JUL10" "JUL11") major=(height=1 width=1) minor=none order=(2005 to 2011 by 1);
axis13 color=black width=1 label=none value=("JUL11" "JUL12" "JUL13" "JUL14" "JUL15" "JUL16" "JUL17") major=(height=1 width=1) minor=none order=(2011 to 2017 by 1);
axis14 color=black width=1 label=none value=("JUL17" "JUL18" "JUL19" "JUL20" "JUL21" "     " "     ") major=(height=1 width=1) minor=none order=(2017 to 2023 by 1);
axis31 color=black label=(angle=90 'Herring daily landings') width=1 major=(height=1 width=1) minor=none order=(0 to 60 by 20);

symbol1 i=join v=none color=blue  line=1 w=1 repeat=1;
symbol2 i=join v=none color=red   line=1 w=1 repeat=1;
symbol3 i=none v=dot  color=black  line=33 w=2 repeat=1;

title '(a)';
proc gplot data=focus4(where=(method in ('SINA','SINC','OBSE') and hexade=('1999-2004')));
  plot landings*yearmonth=series / skipmiss overlay nolegend haxis=axis11 vaxis=axis31;
RUN;
title '(b)';
proc gplot data=focus4(where=(method in ('SINA','SINC','OBSE') and hexade=('2005-2010')));
  plot landings*yearmonth=series / skipmiss overlay nolegend haxis=axis12 vaxis=axis31;
RUN;
title '(c)';
proc gplot data=focus4(where=(method in ('SINA','SINC','OBSE') and hexade=('2011-2016')));
  plot landings*yearmonth=series / skipmiss overlay nolegend haxis=axis13 vaxis=axis31;
RUN;
title '(d)';
proc gplot data=focus4(where=(method in ('SINA','SINC','OBSE') and hexade=('2017-2022')));
  plot landings*yearmonth=series / skipmiss overlay nolegend haxis=axis14 vaxis=axis31;
RUN;
title;
*/
***********************************************************************************************************************;

********************************* For final printing only - put in comments otherwise *********************************;
data focus1;
  set cprvess08;
       if (ref_year >= 1999 and ref_year < 2011) then hexade = '1999-2010';
  else if (ref_year >= 2011 and ref_year < 2023) then hexade = '2011-2022';
  else delete; 
  if method in ('SINA','SINC');
  keep hexade ref_year ref_month method yearmonth var_med pred_hat; 
RUN;
data focus2;
  set focus1;
  landings = pred_hat;
       if method = 'SINA' then series = "Fourier 1st order ";
  else if method = 'SINC' then series = "Fourier 3rd order ";
  keep hexade ref_year ref_month method series yearmonth landings;
RUN;
data focus3;
  set focus1;
  landings = var_med;
  if method = 'SINA';
  series = "Observations         ";
  keep hexade ref_year ref_month series yearmonth landings;
RUN;
data focus4;
  set focus2 focus3;
  if method = '' then method = 'OBSE';
RUN;
proc sort data=focus4;
  by hexade ref_year ref_month series;
RUN;

axis11 color=black width=1 label=none value=("JUL99" "JUL01" "JUL03" "JUL05" "JUL07" "JUL09" "JUL11") major=(height=1 width=1) minor=none order=(1999 to 2011 by 2);
axis12 color=black width=1 label=none value=("JUL11" "JUL13" "JUL15" "JUL17" "JUL19" "JUL21" "     ") major=(height=1 width=1) minor=none order=(2011 to 2023 by 2);
axis31 color=black label=(angle=90 'Herring daily landings') width=1 major=(height=1 width=1) minor=none order=(0 to 60 by 20);

symbol1 i=join v=none color=blue  line=1 w=1 repeat=1;
symbol2 i=join v=none color=red   line=1 w=1 repeat=1;
symbol3 i=none v=dot  color=black  line=33 w=2 repeat=1;

options printerpath=tiff nodate;
ods _all_ close;
ods printer;
title '(a)';
proc gplot data=focus4(where=(method in ('SINA','SINC','OBSE') and hexade=('1999-2010')));
  plot landings*yearmonth=series / skipmiss overlay nolegend haxis=axis11 vaxis=axis31;
RUN;
ods printer close;
ods printer;
title '(b)';
proc gplot data=focus4(where=(method in ('SINA','SINC','OBSE') and hexade=('2011-2022')));
  plot landings*yearmonth=series / skipmiss overlay nolegend haxis=axis12 vaxis=axis31;
RUN;
title;
ods printer close;

********************************************************************************************************************;


data focus5;
  set focus4;
  wland = landings*(ref_month);
RUN;
proc sort data=focus5;
  by series ref_year descending landings;
RUN;
data focus5_;
  set focus5;
    by series ref_year;
  if first.ref_year;
  theta_lmax = ref_month;
  keep series ref_year theta_lmax;
RUN;
proc means data=focus5 noprint;
  by series ref_year;
  var landings wland;
  output out=focus6 sum=;
RUN;
data focus7;
  merge focus5_ focus6;
    by series ref_year;
  theta_grav = wland/landings;
  keep series ref_year theta_lmax theta_grav;
RUN;
quit;

axis3 color=black label=(angle=90 'Spawning season center of gravity') value=("01NOV" "01DEC" "01JAN") width=1 major=(height=1 width=1) minor=none order=(4 to 6 by 1);
symbol1 i=join v=none color=blue line=1 w=1 repeat=1;
symbol2 i=join v=none color=red  line=1 w=1 repeat=1;
symbol3 i=none v=dot color=black  line=1 w=1 repeat=1;
proc gplot data=focus7;
  plot theta_lmax*ref_year=series / skipmiss overlay haxis=axis1;
RUN;
proc gplot data=focus7;
  plot theta_grav*ref_year=series / skipmiss overlay haxis=axis1 vaxis=axis3 nolegend;
RUN;

************************************************************************************************;

******* Calculating peak and amplitude from sine wave GAM model outputs, with SINA model *******;

proc means data=cprvess07 noprint;
  by method ref_year ref_month;
  var var_value;
  id pred_hat pred_p05 pred_p95 ref_dat yearmonth xcos xsin betac betas sigmac sigmas;
  output out=cprvess08(drop=_type_ _freq_) mean=var_med p5=var_p05 p95=var_p95;
RUN;

proc sort data=cprvess08(where=(method='SINA')) out=cprvess09;
  by ref_year descending var_med;
RUN;

data cprvess09_SINA1;
  set cprvess09(where=(method='SINA'));
    by method ref_year;
  if first.ref_year;
  Pi = arcos(-1);
  thetap = atan(abs(betas/betac));
  if      (betac > 0 and betas >= 0) then theta_pic = 12*thetap/(2*Pi);
  else if (betac < 0 and betas >= 0) then theta_pic = 12*(Pi-thetap)/(2*Pi);
  else if (betac > 0 and betas <  0) then theta_pic = 12*(2*Pi-thetap)/(2*Pi);
  *else if (betac < 0 and betas <  0) then theta_pic = 12*(Pi-thetap)/(2*Pi);
  else if (betac < 0 and betas <  0) then theta_pic = 12*(Pi+thetap)/(2*Pi);
  alpha = sqrt(betas**2 + betac**2);
  theta_med = theta_pic;
  theta_deb = theta_pic - (6/Pi)*arcos((-1+sqrt(1+4*alpha**2))/(2*alpha));
  theta_fin = theta_pic + (6/Pi)*arcos((-1+sqrt(1+4*alpha**2))/(2*alpha));
  delta = theta_fin - theta_deb;
  keep method ref_year theta: delta alpha;
RUN;
data cprvess09_SINA2;
  merge cprvess09_SINA1 focus7(where=(series='Observations'));
    by ref_year;
RUN;
data tsapel.cprvess09_SINA;
  set cprvess09_SINA2;
  drop thetap alpha series theta_lmax;
RUN;


************* Exporting SINC outputs for phenological indicators analyzis with Mathematica **********;

proc sort data=cprvess08(where=(method='SINC')) out=cprvess08_SINC;
  by ref_year method ref_month;
RUN;
data focus8;
  set focus7;
  if series='Observations';
  keep ref_year theta_lmax theta_grav;
RUN;
data cprvess09_SINC;
  merge cprvess08_SINC focus8;
    by ref_year;
  keep ref_year ref_month yearmonth pred_hat theta_grav;
RUN;
PROC EXPORT DATA=cprvess09_SINC OUTFILE= "C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\SAS Results\premathematica_logbkC.csv" 
        DBMS=CSV REPLACE;
RUN;
