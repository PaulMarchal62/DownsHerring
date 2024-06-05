*************************************************************************************************;
*********************************** Produces map in S1 Fig **************************************;
*************************************************************************************************;

goptions reset=global htitle=2.3 htext=2.3 ftext=arial colors=(black) ftitle=arial;

libname icesarea 'C:\Paul\2021-\Data library\SAS map template';

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

%macro makemaps;

data nsgrid3;
  set nsgrid2;
       if ref_zone = 'FEEDING' then binary = 1;
  else if ref_zone = 'OTHER  ' then binary = 0;
  else if ref_zone = 'DOWNS  ' then binary = 2;
RUN;

data _c1;
  retain mincol minrow 1E18 maxcol maxrow maxval -1E18 ;
  set nsgrid3;
  col_ices = put(substr(upcase(compress(ref_ices,"/")),3,1),$top.)
		+input(substr(compress(ref_ices,"/"),4,1),1.)+0.5;
  row_ices = (input(substr(ref_ices,1,2),2.)+71)/2+0.25;
  step = 1.0*substr(ref_pixl,6,3);
  col = col_ices + (-3 + 2*(step - 4*floor(step/4)))*0.125;
  row = row_ices + (1 - 2*floor(step/4))*0.125;
  if col>maxcol and col ^=. then do;
                maxcol=col;
				call symput("maxx",maxcol);
              end; 
  if row>maxrow and row ^=. then do;
                maxrow=row;
				call symput("maxy",maxrow);
              end;
  if col<mincol and col ^=. then do;
                mincol=col;
				call symput("minx",mincol);
              end;
  if row<minrow and row ^=. then do;
                minrow=row;
				call symput("miny",minrow);
              end;
  if binary>maxval and binary ^= . then do;
                maxval=binary;
				call symput("maxval",put(maxval,12.));
              end;
RUN;

%let tal=10;
%let i =10;
%let mvplot = 10;
%let bvplot = 1;
%DO %WHILE (%eval(&maxval. / &i. ) > 0);
    %let mvplot = %eval(&i. );
    %let bvplot = %eval(&mvplot. / 10);
	%let i = %eval(&i + &tal.);
	%if  %eval(&i. / &tal.)=10 %then %do;
		%let tal=  %eval(&tal. * 10);
	%end;
%END;
%put &minx. &maxx. &miny. &maxy.;

data _c1;
  set _c1 _allsquares;
  if col >= &minx. and col <= &maxx. and row >= &miny. and row <= &maxy.; 
RUN;

data _anno1;                                 
  set icesarea.polygon_anno_tectac;
  if x < (&minx. - 0.125) and x^=. then x = (&minx. - 0.12499);
  if x > (&maxx. + 0.125) and x^=. then x = (&maxx. + 0.12499);
  if y < (&miny. - 0.125) and y^=. then y = (&miny. - 0.12499); 
  if y > (&maxy. + 0.125) and y^=. then y=  (&maxy. + 0.12499);
  if function="POLY" then color=/*"lightgrey"*/"cx666666";
  else if function="POLYCONT" then color="cx000000";
  when="a";
RUN;

data _anno2;
  X=-3; Y=63; function="MOVE"; XSYS="2"; YSYS="2"; style="MSOLID"; color="cx000000"; when="a";output;
  X=-3; Y=63.2; function="DRAW"; XSYS="2"; YSYS="2"; style="MSOLID"; color="cx000000"; when="a";output;
RUN;

data _anno;
  set _anno1 _anno2;
RUN;


data _Field (keep= col row x y);
  set _c1;
  retain plotXsiz 0.25;
  retain plotYsiz 0.25;
  x = col - PlotXsiz/2;
  y = row - PlotYsiz/2;
  output;
  x = x + plotXsiz;
  output;
  y = y + plotYsiz;
  output;
  x = x - PlotXsiz;
  output;
RUN;

goptions 	reset=all 
			colors=(/*lightgrey*/cxffffff lightgrey/*cxee4000*/ blue)
			ctext=black ftext=swissb; 

pattern1 value=msolid; 
footnote " ";

proc gmap map=_Field data=_c1;
  id col row;
  choro binary /	midpoints=(0.0 to 2.0 by 1.0) 
				ctext=lightgrey/*cx000000*/
				nolegend
				cempty=cx000000
				coutline=same/*lightgrey*//*cx808080*/
				ysize=100 cm 
				xsize=10 cm 
				annotate=_anno ;
RUN;
quit;


/*
goptions 	reset=all 
			colors=(cx1040ff cx1040cc cx2040bb cx3040aa cx504090 cx904040 
					cxaa4030 cxbb4020 cxcc4010 cxdd4000 cxee4000 )
			ctext=black ftext=swissb; 

legend1 	down=2 
			position= (bottom center outside) 
			shape=bar(0.5cm, 0.4 cm) 
			value=(	justify=left height=0.4cm font=swissb color=gray00) 
			label=(	justify=right height=0.4cm font=swissb color=cx000000 "Feeding grounds" 
					position=(left) );

pattern1 value=msolid; 
footnote " ";

proc gmap map=_Field data=_c1;
  id col row;
  choro binary /	midpoints=(0.0 to 1.0 by 0.1) 
				ctext=cx000000
				legend=legend1
				cempty=cx000000 
				coutline=cx000000 
				ysize=100 cm 
				xsize=10 cm 
				annotate=_anno ;
RUN;
quit;
*/
%mend;


*****************************************************************************************************;
*                           Do the spatial plots and export underpinning data                       *;
*****************************************************************************************************;

data nsgrid1;
  %let _EFIERR_ = 0;
  infile 'C:\Paul\2021-\Data library\SAS map template\EC-NS_Land_Sea.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
  informat ref_pixl $8. ;
  informat Land_Sea_OffZone $1. ;
  format ref_pixl $8. ;
  format Land_Sea_OffZone $1. ;
  input ref_pixl $ Land_Sea_OffZone $ ;
  if _ERROR_ then call symputx('_EFIERR_',1);
RUN;

data nsgrid2;
  set nsgrid1;
  ref_ices = substr(ref_pixl,1,4);
  col_ices = put(substr(upcase(compress(ref_ices,"/")),3,1),$top.)
		+input(substr(compress(ref_ices,"/"),4,1),1.)+0.5;
  row_ices = (input(substr(ref_ices,1,2),2.)+71)/2+0.25;
  step = 1.0*substr(ref_pixl,6,3);
  col = col_ices + (-3 + 2*(step - 4*floor(step/4)))*0.125;
  row = row_ices + (1 - 2*floor(step/4))*0.125;
  *if Land_Sea_OffZone = 'S';
  if (row >= 55 and row <= 61 and col >= -3 and col <= 3) then ref_zone = 'FEEDING'; * based on Cushing & Bridger (1966) and focusing on 4a-b;
                                                          else ref_zone = 'OTHER  ';
  *if ref_pixl in
  *  (                                 '29F0_003', IJMS paper!!
  *   '29F1_000','29F1_001','29F1_002','29F1_003','29F1_004','29F1_005','29F1_006','29F1_007',
  *                         '30F1_002','30F1_003',           '30F1_005','30F1_006','30F1_007',
  *                                                                     '31F1_006','31F1_007')
  *  then ref_zone = 'DOWNS  ';
  if ref_ices in ('27E8','27E9','27F0',
                  '28E8','28E9','28F0','28F1',
                  '29E8','29E9','29F0','29F1',
                  '30E8','30E9','30F0','30F1',
                                '31F0','31F1','31F2',
                                       '32F1','32F2',
                                       '33F1','33F2','33F3','33F4'
                                              '34F2',
                                       '35F1')
    then ref_zone = 'DOWNS  ';
  keep ref_zone ref_ices ref_pixl col row;
RUN;

proc sort data=nsgrid2;
  by ref_ices ref_pixl;
RUN;

data _allsquares;
  do col = -2.875 to 8.875 by 0.25;
    do row = 48.625 to 62.375 by 0.25;
    	output;
 	end; 
  end;
RUN;

%makemaps;
