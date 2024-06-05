*****************************************************************************************************;
* - Inputs CPR plankton data corresponding to either period                                         *;
* - Extracts and prepares data for visualisation, monthly aggregation and analyses                  *;
* - Produces Figs A.b-d and Fig B in S2 Text                                                        *;
*****************************************************************************************************;

goptions reset=global htitle=2.3 htext=2.3 ftext=arial colors=(black) ftitle=arial;

libname tsapel 'C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\SAS';

OPTIONS FMTSEARCH=(sasuser formats);

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

%global yearmin;
%global yearmax;
%let yearmin=1980;
%let yearmax=2020;
%let yearmax_=2025;

************ Extracts and prepares data for visualisation, monthly aggregation and analyses **********;

data cpkr01;
  %let _EFIERR_ = 0;
  infile 'C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\Zooplancton\CPkR\CPRData_B2C2.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
  informat Year best32. ;
  informat Month best32. ;
  informat Number_Samples best32. ;
  informat Calanus_finmarchicus best32. ;
  informat Calanus_helgolandicus best32. ;
  informat Temora_longicornis best32. ;
  format Year best12. ;
  format Month best12. ;
  format Number_Samples best12. ;
  format Calanus_finmarchicus best12. ;
  format Calanus_helgolandicus best12. ;
  format Temora_longicornis best12. ;
  input Year Month Number_Samples Calanus_finmarchicus Calanus_helgolandicus Temora_longicornis ;
  if _ERROR_ then call symputx('_EFIERR_',1);
RUN;
data cpkr02;
  set cpkr01;
  ab_calfin = Calanus_finmarchicus;
  ab_calhel = Calanus_helgolandicus;
  ab_temora = Temora_longicornis;
  ref_year = Year;
  if ref_year >= &yearmin.;
  if Month in (4,5,6,7,8,9);
  season = 'SPRING-SUMMER';
  keep season ref_year ab:;
RUN;
proc sort data=cpkr02;
  by ref_year;
RUN;
proc means data=cpkr02 noprint;
  var ab:;
  by ref_year;
  id season;
  output out=cpkr03(drop=_type_ _freq_) mean=;
RUN;

proc means data=cpkr03 noprint;
  var ab:;
  id season;
  output out=cpkr03_(drop=_type_ _freq_) mean(ab_calfin)=ab_calfin_ mean(ab_calhel)=ab_calhel_ mean(ab_temora)=ab_temora_;
RUN;
data cpkr04;
  merge cpkr03 cpkr03_;
    by season;
RUN;
proc loess data=cpkr04;
  model ab_calfin=ref_year;
  ods output OutputStatistics=cpkr04_ab_calfin_;
RUN;
data cpkr04_ab_calfin;
  set cpkr04_ab_calfin_;
  sp_ab_calfin=pred;
  keep ref_year sp_ab_calfin;
RUN;
proc loess data=cpkr04;
  model ab_calhel=ref_year;
  ods output OutputStatistics=cpkr04_ab_calhel_;
RUN;
data cpkr04_ab_calhel;
  set cpkr04_ab_calhel_;
  sp_ab_calhel=pred;
  keep ref_year sp_ab_calhel;
RUN;
proc loess data=cpkr04;
  model ab_temora=ref_year;
  ods output OutputStatistics=cpkr04_ab_temora_;
RUN;
data cpkr04_ab_temora;
  set cpkr04_ab_temora_;
  sp_ab_temora=pred;
  keep ref_year sp_ab_temora;
RUN;
data cpkr06;
  merge cpkr04 cpkr04_ab_calfin cpkr04_ab_calhel cpkr04_ab_temora;
    by ref_year;
RUN;

symbol1 i=join v=circle color=black line=33 h=1 w=1 repeat=1;
symbol2 i=join v=none   color=black line=33 h=2 w=2 repeat=1;
symbol3 i=join v=none   color=black line=1  h=2 w=2 repeat=1;
axis10 color=black label=('Year') width=1 major=(height=1 width=1) minor=none order=(&yearmin. to &yearmax_. by 5);
axis11 color=black label=none width=1 major=(height=1 width=1) minor=none order=(0 to 30 by 10);
axis12 color=black label=none width=1 major=(height=1 width=1) minor=none order=(0 to 30 by 10);
axis13 color=black label=none width=1 major=(height=1 width=1) minor=none order=(0 to 300 by 100);
title '(b) Abundance - Calanus finmarchicus';
proc gplot data=cpkr06;
  plot (ab_calfin ab_calfin_ sp_ab_calfin)*ref_year / skipmiss overlay haxis=axis10 vaxis=axis11 nolegend;
RUN;
title '(c) Abundance - Calanus helgolandicus';
proc gplot data=cpkr06;
  plot (ab_calhel ab_calhel_ sp_ab_calhel)*ref_year / skipmiss overlay haxis=axis10 vaxis=axis12 nolegend;
RUN;
title '(d) Abundance - Temora longicornis';
proc gplot data=cpkr06;
  plot (ab_temora ab_temora_ sp_ab_temora)*ref_year / skipmiss overlay haxis=axis10 vaxis=axis13 nolegend;
RUN;
title;

******************************** Exporting filtered CPkR zooplanktonic abundances ****************************************;

data tsapel.cpkrzoo2&yearmin.;
  set cpkr03;
  if ref_year >= 1999;
RUN;

********************************* Investigating monthly patterns in Calanus spp. *****************************************;

data cpkr05;
  set cpkr01;
  ab_calfin = Calanus_finmarchicus;
  ab_calhel = Calanus_helgolandicus;
  ab_temora = Temora_longicornis;
       if month=1  then ref_month="JAN";
  else if month=2  then ref_month="FEB";
  else if month=3  then ref_month="MAR";
  else if month=4  then ref_month="APR";
  else if month=5  then ref_month="MAY";
  else if month=6  then ref_month="JUN";
  else if month=7  then ref_month="JUL";
  else if month=8  then ref_month="AUG";
  else if month=9  then ref_month="SEP";
  else if month=10 then ref_month="OCT";
  else if month=11 then ref_month="NOV";
  else if month=12 then ref_month="DEC";
  if Year >= &yearmin.;
  keep year month ref_month ab:;
RUN;
proc sort data=cpkr05;
  by month year;
RUN;
title height=2 "(a) Monthly counts of Calanus finmarchicus";
proc sgplot data=cpkr05;
  vbox ab_calfin / category=ref_month;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data;
  yaxis display=(nolabel) values=(0 to 80 by 20) valueattrs=(size=12 weight=bold);
RUN;
title height=2 "(b) Monthly counts of Calanus helgolandicus";
proc sgplot data=cpkr05;
  vbox ab_calhel / category=ref_month;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data;
  yaxis display=(nolabel) values=(0 to 80 by 20) valueattrs=(size=12 weight=bold);
RUN;
title height=2 "(c) Monthly counts of Temora longicornis";
proc sgplot data=cpkr05;
  vbox ab_temora / category=ref_month;
  xaxis display=(nolabel) valueattrs=(size=12 weight=bold) discreteorder=data;
  yaxis display=(nolabel) values=(0 to 500 by 100) valueattrs=(size=12 weight=bold);
RUN;
