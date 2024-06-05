****************************************************************************************************;
* - Imports SINC phenological indicators output from Mathematica                                   *;
* - Merges with GAM output from 04_analyzeLandings.sas                                             *;
* - Exploring stats (cubic splines) and making graphs                                              *;
* - Produces Fig 2                                                                                 *;
* - Exporting GAM outputs and phenological indicators for ARIMAX analyses                          *;
****************************************************************************************************;

goptions reset=global htitle=2.3 htext=2.3 ftext=arial colors=(black) ftitle=arial;

libname tsapel 'C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\SAS';

OPTIONS FMTSEARCH=(sasuser formats);

%global yearmin;
%global yearmax;
%let yearmin=1999;
%let yearmax=2021;
%let yearmax_ = 2024;

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

******************** Imports SINC phenological indicators output from Mathematica ******************;

data cprvess10;
      %let _EFIERR_ = 0;
      infile 'C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\SAS Results\postmathematica_logbkC.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=1;
      informat ref_year best32. ;
      informat theta_pic best12. ;
      informat theta_med best12. ;
      informat theta_deb best12. ;
      informat theta_fin best12. ;
      informat delta best12. ;
	  informat theta_grav best12. ;
	  informat theta_deb05 best12. ;
	  informat theta_fin95 best12. ;
      format ref_year best12. ;
      format theta_pic best12. ;
      format theta_med best12. ;
      format theta_deb best12. ;
      format theta_fin best12. ;
      format delta best12. ;
	  format theta_grav best12. ;
	  format theta_deb05 best12. ;
	  format theta_fin95 best12. ;
      input ref_year theta_pic theta_med theta_deb theta_fin delta theta_grav theta_deb05 theta_fin95;
      if _ERROR_ then call symputx('_EFIERR_',1);
RUN;

axis1 color=black width=1 label=none major=(height=1 width=1) minor=none order=(&yearmin. to &yearmax_. by 5);
axis2 color=black label=(angle=90 'Spawning season phenology metrics (1)') value=("01OCT" "01NOV" "01DEC" "01JAN" "01FEB") width=1 major=(height=1 width=1) minor=none order=(3 to 7 by 1);
symbol1 i=join v=none color=blue   line=1 w=1 repeat=1;
symbol2 i=join v=none color=red    line=1 w=1 repeat=1;
symbol3 i=join v=none color=green  line=1 w=1 repeat=1;
proc gplot data=cprvess10;
  plot (theta_med theta_grav theta_pic)*ref_year / skipmiss overlay haxis=axis1 vaxis=axis2 legend;
RUN;

axis3 color=black label=(angle=90 'Spawning season phenology metrics (2)') value=("01SEP" "01OCT" "01NOV" "01DEC" "01JAN" "01FEB" "01MAR" "01APR") width=1 major=(height=1 width=1) minor=none order=(2 to 9 by 1);
symbol1 i=join v=none color=blue  line=1 w=1 repeat=1;
symbol2 i=join v=none color=green line=1 w=1 repeat=2;
symbol3 i=join v=none color=red   line=1 w=1 repeat=2;
proc gplot data=cprvess10;
  plot (theta_med theta_deb theta_fin theta_deb05 theta_fin95)*ref_year / skipmiss overlay haxis=axis1 vaxis=axis3 legend;
RUN;

proc sort data=cprvess10;
  by ref_year;
RUN;
data cprvess11;
  merge tsapel.gamoutput_logbk_shift1(where=(method = 'SINC')) cprvess10;
    by ref_year;
  delta_deb = theta_med - theta_deb;
  delta_fin = theta_fin - theta_med;
  ratio_deb = delta_deb/delta;
  ratio_fin = delta_fin/delta;
RUN;

************************ Exploring stats (simple mean and cubic splines) and making graphs ***************************;

proc means data=cprvess11 noprint;
  by method ref_year;
  var theta: delta: ratio:;
  output out=cprvess12(drop=_type_ _freq_) mean=;
RUN;
proc means data=cprvess12 noprint;
  by method;
  var theta: delta: ratio:;
  output out=cprvess12_(drop=_type_ _freq_)
         mean(theta_med)=theta_med_ mean(theta_deb)=theta_deb_ mean(theta_fin)=theta_fin_
         mean(delta)=delta_         mean(delta_deb)=delta_deb_ mean(delta_fin)=delta_fin_
                                    mean(ratio_deb)=ratio_deb_ mean(ratio_fin)=ratio_fin_;
RUN;
data cprvess13(where=(method='SINC'));
  merge cprvess12 cprvess12_;
    by method;
RUN;

proc loess data=cprvess13;
  model theta_med=ref_year;
  ods output OutputStatistics=sp_theta_med_;
RUN;
data sp_theta_med;
  set sp_theta_med_;
  sp_theta_med=pred;
  keep ref_year sp_theta_med;
RUN;
proc loess data=cprvess13;
  model theta_deb=ref_year;
  ods output OutputStatistics=sp_theta_deb_;
RUN;
data sp_theta_deb;
  set sp_theta_deb_;
  sp_theta_deb=pred;
  keep ref_year sp_theta_deb;
RUN;
proc loess data=cprvess13;
  model theta_fin=ref_year;
  ods output OutputStatistics=sp_theta_fin_;
RUN;
data sp_theta_fin;
  set sp_theta_fin_;
  sp_theta_fin=pred;
  keep ref_year sp_theta_fin;
RUN;
proc loess data=cprvess13;
  model delta=ref_year;
  ods output OutputStatistics=sp_delta_;
RUN;
data sp_delta;
  set sp_delta_;
  sp_delta=pred;
  keep ref_year sp_delta;
RUN;
proc loess data=cprvess13;
  model delta_deb=ref_year;
  ods output OutputStatistics=sp_delta_deb_;
RUN;
data sp_delta_deb;
  set sp_delta_deb_;
  sp_delta_deb=pred;
  keep ref_year sp_delta_deb;
RUN;
proc loess data=cprvess13;
  model delta_fin=ref_year;
  ods output OutputStatistics=sp_delta_fin_;
RUN;
data sp_delta_fin;
  set sp_delta_fin_;
  sp_delta_fin=pred;
  keep ref_year sp_delta_fin;
RUN;
data cprvess14;
  merge cprvess13 sp_theta_med sp_theta_deb sp_theta_fin sp_delta sp_delta_deb sp_delta_fin;
    by ref_year;
RUN;

symbol1 i=none v=circle color=blue h=1 w=1 repeat=1;
symbol2 i=join v=none color=blue line=33 h=2 w=2 repeat=1;
symbol3 i=join v=none color=blue line=1  h=2 w=2 repeat=1;
symbol4 i=none v=circle color=red h=1 w=1 repeat=1;
symbol5 i=join v=none color=red line=33 h=2 w=2 repeat=1;
symbol6 i=join v=none color=red line=1  h=2 w=2 repeat=1;
symbol7 i=none v=circle color=green h=1 w=1 repeat=1;
symbol8 i=join v=none color=green line=33 h=2 w=2 repeat=1;
symbol9 i=join v=none color=green line=1  h=2 w=2 repeat=1;
axis40 color=black width=1 label=none value=("1999/00" "2004/05" "2009/10" "2014/15" "2019/20" "") major=(height=1 width=1) minor=none order=(&yearmin. to &yearmax_. by 5);
axis41 color=black label=(angle=90 'Month') value=("OCT" "NOV" "DEC" "JAN" "FEB") width=1 major=(height=1 width=1) minor=none order=(3 to 7 by 1);

**************************************** For preliminary runs only **************************************************;
/*
title '(a) Spawning season phenology';
proc gplot data=cprvess14;
  plot (theta_med theta_med_ sp_theta_med theta_deb theta_deb_ sp_theta_deb theta_fin theta_fin_ sp_theta_fin)*ref_year / skipmiss overlay haxis=axis40 vaxis=axis41 nolegend;
RUN;
title '(b) Spawning season duration metrics';
axis42 color=black label=(angle=90 'Duration (months)') width=1 value=('0' '1' '2' '3') major=(height=1 width=1) minor=none order=(0 to 3 by 1);
proc gplot data=cprvess14;
  plot (delta delta_ sp_delta delta_deb delta_deb_ sp_delta_deb delta_fin delta_fin_ sp_delta_fin)*ref_year / skipmiss overlay haxis=axis40 vaxis=axis42 nolegend;
RUN;
*/
**********************************************************************************************************************;

********************************************** For final printing only ***********************************************;
options printerpath=tiff nodate;
ods _all_ close;
ods printer;
title '(a) Spawning season phenology';
proc gplot data=cprvess14;
  plot (theta_med theta_med_ sp_theta_med theta_deb theta_deb_ sp_theta_deb theta_fin theta_fin_ sp_theta_fin)*ref_year / skipmiss overlay haxis=axis40 vaxis=axis41 nolegend;
RUN;
ods printer close;
ods printer;
title '(b) Spawning season duration metrics';
axis42 color=black label=(angle=90 'Duration (months)') width=1 value=('0' '1' '2' '3') major=(height=1 width=1) minor=none order=(0 to 3 by 1);
proc gplot data=cprvess14;
  plot (delta delta_ sp_delta delta_deb delta_deb_ sp_delta_deb delta_fin delta_fin_ sp_delta_fin)*ref_year / skipmiss overlay haxis=axis40 vaxis=axis42 nolegend;
RUN;
ods printer close;
*************************************************************************************************************************;

************************ Exporting GAM outputs and phenological indicators for ARIMAX analyses **********************;

data tsapel.gamoutput_logbk_shift2;
  set cprvess11;
  ref_period = "&yearmin.-&yearmax.";
RUN;
