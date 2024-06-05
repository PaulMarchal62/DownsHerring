****************************************************************************************************;
* - Inputs tsapel.gamoutput_logbk_shift2, tsapel.ssta, tsapel.cpkrzoo                              *;
* - Tests autocorrelation within and collinearities across environmental variables                 *;
* - Model phenological metrics vs. environmental variables using ARMAX models                      *;
* - Produces Fig 3                                                                                 *;
****************************************************************************************************;

goptions reset=global htitle=2.3 htext=2.3 ftext=arial colors=(black) ftitle=arial;

libname tsapel 'C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\SAS';

OPTIONS FMTSEARCH=(sasuser formats);

%global Pi;
%global tripdur;
%global yearmin;
%global yearmax;
%let Pi=3.141593;
%let tripdur=2;
%let yearmin=1999;
%let yearmax=2020;
%let yearmax_=2024;

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

******************* Imports herring logbook and sold landing files and merge them *******************;

data signal01;
  set tsapel.gamoutput_logbk_shift2;
  theta0 = theta_med;
  theta1 = theta_deb;
  theta2 = theta_fin;
  theta3 = theta_deb05;
  theta4 = theta_fin95;
  delta_0595 = theta4 - theta3;
  drop theta_med theta_deb theta_fin theta_deb05 theta_fin95;
RUN;
proc sort data=signal01;
  by ref_year;
RUN;
proc means data=signal01 noprint;
  by ref_year;
  var theta: delta:;
  output out=signal02(drop=_type_ _freq_) mean=;
RUN;

****************** Imports NOAA SST anomaly file and merges with fisheries data **********************;

proc sort data=tsapel.ssta2 out=signal03;
  by ref_year;
RUN;
data signal04;
  merge signal02 signal03;
    by ref_year;
  if ref_year >= &yearmin. and ref_year <= &yearmax.;
RUN;

************** Imports CPR zooplankton file and merges with fisheries+SST anomaly data ****************;

data signal05;
  set tsapel.cpkrzoo21985;
  if ref_year >= &yearmin. and ref_year <= &yearmax.;
RUN;

data signal06;
  merge signal04 signal05;
    by ref_year;
  ref_date = mdy(01,01,ref_year);
  label theta_grav = "Spawning gravity center";
  label theta0     = "Spawning peak timing";
  label delta      = "Spawning season duration";
  label delta_0595 = "Spawning season duration (5%-95%)";
  label theta1     = "Spawning season beginning";
  label theta2     = "Spawning season ending";
  label theta3     = "Spawning season beginning at 5%";
  label theta4     = "Spawning season ending at 95%";
  label ref_year = "Year";
RUN;

data tsapel.prearima2_withshift;
  set signal06;
RUN;

***************** Calculated correlation to compare phenological indices across data sources **********;

ods graphics on;
proc corr data=signal06(where=(ref_year <= 2020)) pearson plots=matrix(histogram);
   var theta_grav theta0 theta1 theta2 theta3 theta4 delta;
RUN;
ods graphics off;

************************* Testing for colinearity between SSTa, CALf and Calh ***********************;

ods graphics on;
title 'Measures of correlation between herring phenology, SSTa and Calanus densities';
proc corr data=signal06(where=(ref_year <= 2020)) pearson plots=matrix(histogram);
   var ref_year ssta_: ab_:;
RUN;
ods graphics off;
title;

************************ Exploring auto-correlation in explanatory variables ************************;

ods graphics on;
proc arima data=signal06;
  identify var=ssta;
RUN; 
ods graphics off;
ods graphics on;
proc arima data=signal06;
  identify var=ab_calfin;
  estimate;
RUN; 
ods graphics off;
ods graphics on;
proc arima data=signal06;
  identify var=ab_calhel;
  estimate;
RUN; 
ods graphics off;
ods graphics on;
proc arima data=signal06;
  identify var=ab_temora;
  estimate;
RUN;
ods graphics off;
ods graphics on;
proc arima data=signal06;
  identify var=ssta_spwn_auwi;
RUN; 
ods graphics off;

********************* Exploring cross-correlation between explanatory variables ********************;

ods graphics on;
proc arima data=signal06;
  identify var=ssta_spwn_auwi crosscorr=(ssta);
  estimate input=(ssta);
RUN; 
ods graphics off;

ods graphics on;
proc arima data=signal06;
  identify var=ab_calfin crosscorr=(ssta ssta_spwn_auwi ab_calhel ab_temora);
  estimate input=(ab_calhel);
RUN; 
ods graphics off;
ods graphics on;
proc arima data=signal06;
  identify var=ab_calhel crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_temora);
  estimate input=(ab_calfin);
RUN; 
ods graphics off;
ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel);
  estimate input=(ssta);
RUN; 
ods graphics off;

*****************************************************************************************************;
************************************* Fit ARIMAX models *********************************************;
*****************************************************************************************************;


************************* Fitting ARIMAX model for spawning peak timing and forecasting ******************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=theta0 crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate input=(ab_calfin); * means: y(t) = mu + Z1z(t-1) + eps(t);
  forecast id=ref_date interval=year lead=0 out=tsa_theta_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_theta_withexpl;
  set tsa_theta_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season duration (25%-75%) and forecasting ******************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=delta crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate p=1 input=(ab_calhel, 1 $ ssta_spwn_auwi);
  forecast id=ref_date interval=year lead=0 out=tsa_delta_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_delta_withexpl;
  set tsa_delta_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season beginning (25%) and forecasting ******************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=theta1 crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate input=(ab_calfin);
  forecast id=ref_date interval=year lead=0 out=tsa_theta1_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_theta1_withexpl;
  set tsa_theta1_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season ending (75%) and forecasting ********************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=theta2 crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate input=(ab_calfin, 1 $ ssta_spwn_auwi);
  forecast id=ref_date interval=year lead=0 out=tsa_theta2_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_theta2_withexpl;
  set tsa_theta2_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season beginning (5%) and forecasting ******************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=theta3 crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate input=(ab_calfin);
  forecast id=ref_date interval=year lead=0 out=tsa_theta3_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_theta3_withexpl;
  set tsa_theta3_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season ending (95%) and forecasting ********************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=theta4 crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate input=(ab_calfin); * Note: (1 $ ssta_spwn_auwi) close to be significant at 5%;
  forecast id=ref_date interval=year lead=0 out=tsa_theta4_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_theta4_withexpl;
  set tsa_theta4_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season duration (5%-95%) and forecasting ******************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=delta_0595 crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate p=1 input=(1 $ ssta_spwn_auwi);
  forecast id=ref_date interval=year lead=0 out=tsa_delta0595_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_delta0595_withexpl;
  set tsa_delta0595_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season duration (25%-50%) and forecasting ******************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=delta_deb crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  estimate q=1 input=(ab_calhel, 1 $ ssta_spwn_auwi);
  forecast id=ref_date interval=year lead=0 out=tsa_delta2550_withexpl_;
RUN; 
ods graphics off;
quit;
data tsa_delta2550_withexpl;
  set tsa_delta2550_withexpl_;
  ref_year = year(ref_date);
  label ref_year = "Year";
  label forecast = "ARIMAX estimate";
RUN;

*********************** Fitting ARIMAX model for spawning season duration (50%-75%) and forecasting ******************;

ods graphics on;
proc arima data=signal06;
  identify var=ab_temora crosscorr=(ssta);
  estimate input=(ssta); *1999-2020 series;
  identify var=delta_fin crosscorr=(ssta ssta_spwn_auwi ab_calfin ab_calhel ab_temora);
  *estimate q=1 input=(ab_calhel, 1 $ ssta_spwn_auwi);
  *forecast id=ref_date interval=year lead=0 out=tsa_delta5075_withexpl_;
RUN; 
ods graphics off;
quit;
*data tsa_delta5075_withexpl;
*  set tsa_delta5075_withexpl_;
*  ref_year = year(ref_date);
*  label ref_year = "Year";
*  label forecast = "ARIMAX estimate";
*RUN;


***************************************** Make graphs *********************************************;

axis1 color=black label=('Year') width=1 major=(height=1 width=1) minor=none order=(&yearmin. to &yearmax_. by 5);
axis2 color=black label=(angle=90 'Spawning peak timing') width=1 major=(height=1 width=1) minor=none order=(4 to 7 by 1);
axis3 color=black label=(angle=90 'Spawning duration') width=1 major=(height=1 width=1) minor=none order=(0 to 5 by 1);

symbol1 i=join v=none color=black line=1 w=1 repeat=2;
symbol2 i=join v=none color=blue line=1 h=1 w=1 repeat=1;
symbol3 i=join v=none color=red  line=1 h=2 w=2 repeat=1;
pattern1 color=white value=mempty;
pattern2 color=ligr value=msolid;
pattern3 color=ligr value=msolid;

symbol1 i=join v=none color=blue  h=2 w=2 l=1  repeat=1;
symbol2 i=join v=none color=red   h=2 w=2 l=1  repeat=1;

******************************************* For preliminary runs ******************************************************;
/*
title height=2 "(a) Downs herring spawning season peak";
proc sgplot data=tsa_theta_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta0 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(4 to 7 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("NOV" "DEC" "JAN" "FEB");
RUN;
title height=2 "(b) Downs herring spawning season start";
proc sgplot data=tsa_theta1_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta1 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(3 to 6 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("OCT" "NOV" "DEC" "JAN");
RUN;
title height=2 "(c) Downs herring spawning season end";
proc sgplot data=tsa_theta2_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta2 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(5 to 8 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("DEC" "JAN" "FEB" "MAR");
RUN;
title height=2 "(d) Downs herring spawning season duration";
proc sgplot data=tsa_delta_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=delta / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(0 to 4 by 1) valueattrs=(size=12 weight=bold);
RUN;

title height=2 "Downs herring spawning season start (5%)";
proc sgplot data=tsa_theta3_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta3 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(2 to 5 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("SEP" "OCT" "NOV" "DEC");
RUN;
title height=2 "Downs herring spawning season end (95%)";
proc sgplot data=tsa_theta4_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta4 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(5 to 9 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("DEC" "JAN" "FEB" "MAR" "APR");
RUN;
title height=2 "Downs herring spawning season duration (5%-95%)";
proc sgplot data=tsa_delta0595_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=delta_0595 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(2 to 6 by 1) valueattrs=(size=12 weight=bold);
RUN;
title height=2 "Downs herring spawning season duration (25%-50%)";
proc sgplot data=tsa_delta2550_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=delta_deb / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(0 to 2 by 1) valueattrs=(size=12 weight=bold);
RUN;


title;
*/
*********************************************************************************************************************;

*********************************************** For final print only; ***********************************************;
options printerpath=tiff nodate;
ods _all_ close;
ods printer;
title height=2 "(a) Downs herring spawning season peak";
proc sgplot data=tsa_theta_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta0 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(4 to 7 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("NOV" "DEC" "JAN" "FEB");
RUN;
ods printer close;
ods printer;
title height=2 "(b) Downs herring spawning season start";
proc sgplot data=tsa_theta1_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta1 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(3 to 6 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("OCT" "NOV" "DEC" "JAN");
RUN;
ods printer close;
ods printer;
title height=2 "(c) Downs herring spawning season end";
proc sgplot data=tsa_theta2_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=theta2 / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(5 to 8 by 1) valueattrs=(size=12 weight=bold) valuesdisplay=("DEC" "JAN" "FEB" "MAR");
RUN;
ods printer close;
ods printer;
title height=2 "(d) Downs herring spawning season duration";
proc sgplot data=tsa_delta_withexpl noautolegend;
   band Upper=u95 Lower=l95 x=ref_year
      / LegendLabel="95% Confidence Limits";
   scatter x=ref_year y=delta / markerattrs=(symbol=CircleFilled color=blue);
   series x=ref_year y=forecast / lineattrs=(color=red);
   xaxis display=(nolabel) values=(&yearmin. to &yearmax_. by 5) valueattrs=(size=12 weight=bold) valuesdisplay=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "2024/25"); 
   yaxis display=(nolabel) values=(0 to 4 by 1) valueattrs=(size=12 weight=bold);
RUN;
title;
ods printer close;
*********************************************************************************************************************;

