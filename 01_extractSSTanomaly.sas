****************************************************************************************************;
* - Imports monthly NOAA SST anomaly files from 1980 to 2021                                       *;
* - Average of Northern North Sea (CPR areas B2+C2) and of EEC-SNS separately                      *;
* - Merges files and exports into tsapel SAS library                                               *;
* - Produces Fig A.a in S2 Text                                                                    *;
****************************************************************************************************;

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

%macro import_ssta;
%let sstafile=;
%do year = 1980 %to 2021;
  %do month = 1 %to 12;
    %if (&month. < 10) %then %let month_ = 0&month.;
	%else %let month_ = &month.;
	%let sstafile= &sstafile. ssta&year.&month.;
    %put &year. &month. &month_.;
    data ssta&year.&month.;
      %let _EFIERR_ = 0;
      infile "C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\Temperature\ssta&year.&month_..csv" delimiter = ';' MISSOVER DSD lrecl=32767 firstobs=1 ;
        informat VAR001 best12.; informat VAR002 best12.; informat VAR003 best12.; informat VAR004 best12.; informat VAR005 best12.;
        informat VAR006 best12.; informat VAR007 best12.; informat VAR008 best12.; informat VAR009 best12.; informat VAR010 best12.;
        informat VAR011 best12.; informat VAR012 best12.; informat VAR013 best12.; informat VAR014 best12.; informat VAR015 best12.;
        informat VAR016 best12.; informat VAR017 best12.; informat VAR018 best12.; informat VAR019 best12.; informat VAR020 best12.;
        informat VAR021 best12.; informat VAR022 best12.; informat VAR023 best12.; informat VAR024 best12.; informat VAR025 best12.;
        informat VAR026 best12.; informat VAR027 best12.; informat VAR028 best12.; informat VAR029 best12.; informat VAR030 best12.;
        informat VAR031 best12.; informat VAR032 best12.; informat VAR033 best12.; informat VAR034 best12.; informat VAR035 best12.;
        informat VAR036 best12.; informat VAR037 best12.; informat VAR038 best12.; informat VAR039 best12.; informat VAR040 best12.;
        informat VAR041 best12.; informat VAR042 best12.; informat VAR043 best12.; informat VAR044 best12.; informat VAR045 best12.;
        informat VAR046 best12.; informat VAR047 best12.; informat VAR048 best12.; informat VAR049 best12.; informat VAR050 best12.;
        informat VAR051 best12.; informat VAR052 best12.; informat VAR053 best12.; informat VAR054 best12.; informat VAR055 best12.;
        informat VAR056 best12.; informat VAR057 best12.; informat VAR058 best12.; informat VAR059 best12.; informat VAR060 best12.;
        informat VAR061 best12.; informat VAR062 best12.; informat VAR063 best12.; informat VAR064 best12.; informat VAR065 best12.;
        informat VAR066 best12.; informat VAR067 best12.; informat VAR068 best12.; informat VAR069 best12.; informat VAR070 best12.;
        informat VAR071 best12.; informat VAR072 best12.; informat VAR073 best12.; informat VAR074 best12.; informat VAR075 best12.;
        informat VAR076 best12.; informat VAR077 best12.; informat VAR078 best12.; informat VAR079 best12.; informat VAR080 best12.;
        informat VAR081 best12.; informat VAR082 best12.; informat VAR083 best12.; informat VAR084 best12.; informat VAR085 best12.;
        informat VAR086 best12.; informat VAR087 best12.; informat VAR088 best12.; informat VAR089 best12.; informat;
        format VAR001 best32.; format VAR002 best12.; format VAR003 best12.; format VAR004 best12.; format VAR005 best12.;
        format VAR006 best12.; format VAR007 best12.; format VAR008 best12.; format VAR009 best12.; format VAR010 best12.;
        format VAR011 best12.; format VAR012 best12.; format VAR013 best12.; format VAR014 best12.; format VAR015 best12.;
        format VAR016 best12.; format VAR017 best12.; format VAR018 best12.; format VAR019 best12.; format VAR020 best12.;
        format VAR021 best12.; format VAR022 best12.; format VAR023 best12.; format VAR024 best12.; format VAR025 best12.;
        format VAR026 best12.; format VAR027 best12.; format VAR028 best12.; format VAR029 best12.; format VAR030 best12.;
        format VAR031 best12.; format VAR032 best12.; format VAR033 best12.; format VAR034 best12.; format VAR035 best12.;
        format VAR036 best12.; format VAR037 best12.; format VAR038 best12.; format VAR039 best12.; format VAR040 best12.;
        format VAR041 best12.; format VAR042 best12.; format VAR043 best12.; format VAR044 best12.; format VAR045 best12.;
        format VAR046 best12.; format VAR047 best12.; format VAR048 best12.; format VAR049 best12.; format VAR050 best12.;
        format VAR051 best12.; format VAR052 best12.; format VAR053 best12.; format VAR054 best12.; format VAR055 best12.;
        format VAR056 best12.; format VAR057 best12.; format VAR058 best12.; format VAR059 best12.; format VAR060 best12.;
        format VAR061 best12.; format VAR062 best12.; format VAR063 best12.; format VAR064 best12.; format VAR065 best12.;
        format VAR066 best12.; format VAR067 best12.; format VAR068 best12.; format VAR069 best12.; format VAR070 best12.;
        format VAR071 best12.; format VAR072 best12.; format VAR073 best12.; format VAR074 best12.; format VAR075 best12.;
        format VAR076 best12.; format VAR077 best12.; format VAR078 best12.; format VAR079 best12.; format VAR080 best12.;
        format VAR081 best12.; format VAR082 best12.; format VAR083 best12.; format VAR084 best12.; format VAR085 best12.;
        format VAR086 best12.; format VAR087 best12.; format VAR088 best12.; format VAR089 best12.;
        input VAR001 VAR002 VAR003 VAR004 VAR005 VAR006 VAR007 VAR008 VAR009 VAR010
              VAR011 VAR012 VAR013 VAR014 VAR015 VAR016 VAR017 VAR018 VAR019 VAR020
              VAR021 VAR022 VAR023 VAR024 VAR025 VAR026 VAR027 VAR028 VAR029 VAR030
              VAR031 VAR032 VAR033 VAR034 VAR035 VAR036 VAR037 VAR038 VAR039 VAR040
              VAR041 VAR042 VAR043 VAR044 VAR045 VAR046 VAR047 VAR048 VAR049 VAR050
              VAR051 VAR052 VAR053 VAR054 VAR055 VAR056 VAR057 VAR058 VAR059 VAR060
              VAR061 VAR062 VAR063 VAR064 VAR065 VAR066 VAR067 VAR068 VAR069 VAR070
              VAR071 VAR072 VAR073 VAR074 VAR075 VAR076 VAR077 VAR078 VAR079 VAR080
              VAR081 VAR082 VAR083 VAR084 VAR085 VAR086 VAR087 VAR088 VAR089;
      if _ERROR_ then call symputx('_EFIERR_',1);
      ref_year = &year.;
	  ref_month = &month.;
      if (_n_ <= 91) then longitude = 2*(_n_ - 1);
      else longitude = 2*(_n_ - 181);
    RUN;
  %end;
%end;

data ssta2;
  set &sstafile.;
RUN;

%mend;

options errors=0;
%import_ssta;
options errors=5;

**************************************** SST anomaly ************************************************;

data ssta3;
  set ssta2;
  array ssta_{1:89} var001-var089;
  do i=1 to 89;
	latitude = (i - 1)*2 - 88;
    ssta = ssta_{i};
	output;
  end;
  keep ref_year ref_month latitude longitude ssta;
RUN;

data ssta4;
  set ssta3;
       if (latitude >= 55 and latitude <= 61 and longitude >= -3 and longitude <= 3) then area="FEEDING " ; * based on B2+C2 CPR areas;
  else if (latitude >= 49 and latitude <= 53 and longitude >= -2 and longitude <= 5) then area="SPAWNING"; * based roughly on the distribution of fishing effort;
  else delete;
  yearmonth = ref_year + (ref_month-1)/12;
  refline = 0;
  *if ref_year >= 1999;
RUN;
proc sort data=ssta4;
  by area ref_year ref_month;
RUN;
proc means data=ssta4 noprint;
  var ssta;
  by area ref_year ref_month;
  id yearmonth refline;
  output out=ssta5 mean=;
RUN;
data ssta6;
  set ssta5;
  if ref_month in (4,5,6,7,8,9) then season =   "SPRING-SUMMER";
  else if ref_month in (10,11,12) then season = "AUTUMN-WINTER";
  else delete;
RUN;
proc sort data=ssta6;
  by area season ref_year;
RUN;
proc means data=ssta6 noprint;
  var ssta refline; 
  by area season ref_year;
  output out=ssta7 mean= p5(ssta)=ssta_p05 p95(ssta)=ssta_p95;
RUN;

axis1 color=black label=('Year') width=1 major=(height=1 width=1) minor=none order=(1980 to 2025 by 5);
axis2 color=black label=none width=1 major=(height=1 width=1) minor=none order=(-1 to 2 by 1);

symbol1   i=join v=circle color=blue  h=1 w=1 l=1  repeat=1;
symbol2   i=join v=none color=blue  h=2 w=2 l=33  repeat=1;

title '(a) SST anomaly';
proc gplot data=ssta7(where=(area="FEEDING " and season='SPRING-SUMMER'));
  plot (ssta refline)*ref_year / overlay haxis=axis1 vaxis=axis2;
RUN;

data feed_spsu feed_auwi spwn_spsu spwn_auwi;
  set ssta7;
  if (area = "FEEDING " and season = "SPRING-SUMMER") then output  feed_spsu;
  if (area = "FEEDING " and season = "AUTUMN-WINTER") then output  feed_auwi;
  if (area = "SPAWNING" and season = "SPRING-SUMMER") then output  spwn_spsu;
  if (area = "SPAWNING" and season = "AUTUMN-WINTER") then output  spwn_auwi;
RUN;
data feed_spsu;
  set feed_spsu;
  ssta_feed_spsu = ssta;
  keep ref_year refline ssta ssta_feed_spsu;
RUN;
data feed_auwi;
  set feed_auwi;
  ssta_feed_auwi = ssta;
  keep ref_year ssta_feed_auwi;
RUN;
data spwn_spsu;
  set spwn_spsu;
  ssta_spwn_spsu = ssta;
  keep ref_year ssta_spwn_spsu;
RUN;
data spwn_auwi;
  set spwn_auwi;
  ssta_spwn_auwi = ssta;
  keep ref_year ssta_spwn_auwi;
RUN;
data ssta8;
  merge feed_spsu feed_auwi spwn_spsu spwn_auwi;
    by ref_year;
RUN;

proc loess data=ssta8;
  model ssta_feed_spsu=ref_year;
  ods output OutputStatistics=ssta8_feed_spsu_;
RUN;
data ssta8_feed_spsu;
  set ssta8_feed_spsu_;
  pred_feed_spsu=pred;
  keep ref_year pred_feed_spsu;
RUN;
proc loess data=ssta8;
  model ssta_spwn_auwi=ref_year;
  ods output OutputStatistics=ssta8_spwn_auwi_;
RUN;
data ssta8_spwn_auwi;
  set ssta8_spwn_auwi_;
  pred_spwn_auwi=pred;
  keep ref_year pred_spwn_auwi;
RUN;
data ssta9;
  merge ssta8 ssta8_feed_spsu ssta8_spwn_auwi;
    by ref_year;
RUN;

symbol1 i=join v=circle color=blue  h=1 w=1 l=33 repeat=1;
symbol2 i=join v=none   color=blue  h=2 w=2 l=1  repeat=1;
symbol3 i=join v=circle color=red   h=1 w=1 l=33 repeat=1;
symbol4 i=join v=none   color=red   h=2 w=2 l=1  repeat=1;
symbol5 i=join v=none   color=black h=2 w=2 l=33 repeat=1;
title '(a) SST anomaly';
proc gplot data=ssta9;
  plot (ssta_feed_spsu pred_feed_spsu ssta_spwn_auwi pred_spwn_auwi refline)*ref_year / overlay haxis=axis1 vaxis=axis2 nolegend;
RUN;
proc gplot data=ssta9;
  plot (ssta_feed_spsu pred_feed_spsu ssta_spwn_auwi pred_spwn_auwi refline)*ref_year / overlay haxis=axis1 vaxis=axis2 legend;
RUN;

data tsapel.ssta2;
  set ssta8;
  if ref_year >= 1999;
  keep ref_year ssta:;
RUN;

