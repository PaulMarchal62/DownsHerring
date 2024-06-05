****************************************************************************************************;
* - Imports and merges CPR input files for 1999-2021, selects 7D+4C, pelagic trawls and species    *;
* - Imports and merges vessel characteristics for 1999-2021                                        *;
* - Merges files and exports into tsapel SAS library                                               *;
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

%let yearmin=1999;
%let yearmax=2021;

%macro import_cpr;

**************************************************************************************************;
*** Imports and merges CPR input files for 1999-2021, selects 7D+4C, pelagic trawls and species **;
**************************************************************************************************;

%do year = &yearmin. %to 2008;
data cpr&year.;
  %let _EFIERR_ = 0;
  infile "C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\CPR\cpr&year..txt" MISSOVER DSD lrecl=32767 firstobs=2;
  input
    @1 NAV_NUM $12.
    @13 ANNEE_MAREE_DAT_SEQ 4.
    @17 MOIS_MAREE_DAT_SEQ 2.
    @19 JOUR_MAREE_DAT_SEQ 2.
    @21 LIE_LIEU_COD $5.
    @26 LIE_TLIEU_COD $1.
    @27 SECTEUR $9.
    @36 RECTANGLE $9.
    @45 ENGIN 3.
    @48 ESPECE 6.
    @54 PRODUCTION 9.
    @63 TEMPS_DE_PECHE $7.
    @70 NOMBRE_OPERATION 6.
    @76 MAREE_DUREE 5.
    @81 NOMBRE_ENGIN 3.
    @84 MAILLAGE 5.
    @89 DIMENSION 9.
    @98 ANNEE_MAREE_DAT_RET 4.
    @102 MOIS_MAREE_DAT_RET 2.
    @104 JOUR_MAREE_DAT_RET 2.
    @106 TPENG 7.;
  if _ERROR_ then call symput('_EFIERR_',1);
       if ESPECE = 3502 then species = 'HER';
  else if ESPECE = 3409 then species = 'HOM';
  else if ESPECE = 3705 then species = 'MAC';
  else if ESPECE = 3504 then species = 'PIL';
                        else delete;
  if ENGIN in (932,935,942,945) then gear = 'XTM';
                                else delete;
  if substr(SECTEUR,1,5) in ('S007D','S004C');
  drop ENGIN ESPECE;
RUN;
%end;

%do year = 2009 %to &yearmax.;
data cpr&year.;
  %let _EFIERR_ = 0;
  infile "C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\CPR\cpr&year..txt" MISSOVER DSD lrecl=32767 firstobs=2;
  input
    @1 NAV_NUM $12.
    @13 ANNEE_MAREE_DAT_SEQ 4.
    @17 MOIS_MAREE_DAT_SEQ 2.
    @19 JOUR_MAREE_DAT_SEQ 2.
    @21 LIE_LIEU_COD $5.
    @26 LIE_TLIEU_COD $1.
    @27 SECTEUR $9.
    @36 RECTANGLE $9.
    @45 ENGIN $3.
    @48 species $3.
    @51 PRODUCTION 9.
    @60 TEMPS_DE_PECHE $7.
    @67 NOMBRE_OPERATION 6.
    @73 MAREE_DUREE 5.
    @78 NOMBRE_ENGIN 3.
    @81 MAILLAGE 5.
    @86 DIMENSION 9.
    @95 ANNEE_MAREE_DAT_RET 4.
    @99 MOIS_MAREE_DAT_RET 2.
    @101 JOUR_MAREE_DAT_RET 2.
    @103 TPENG 7.;
  if _ERROR_ then call symput('_EFIERR_',1);
  if species in ('HER','HOM','MAC','PIL');
  if ENGIN in ('OTM','PTM') then gear = 'XTM';
                            else delete;
*  if substr(SECTEUR,1,5) in ('S007D');
  if substr(SECTEUR,1,5) in ('S007D','S004C');
  drop ENGIN;
RUN;
%end;

%mend;

%import_cpr;

data cprall;
  set cpr1999 cpr2000 cpr2001 cpr2002 cpr2003 cpr2004 cpr2005 cpr2006 cpr2007 cpr2008 cpr2009 cpr2010
      cpr2011 cpr2012 cpr2013 cpr2014 cpr2015 cpr2016 cpr2017 cpr2018 cpr2019 cpr2020 cpr2021;
  ref_ft = compress(NAV_NUM||ANNEE_MAREE_DAT_RET||MOIS_MAREE_DAT_RET||JOUR_MAREE_DAT_RET);
  ref_vess = NAV_NUM;
  ref_year = ANNEE_MAREE_DAT_RET;
  ref_month = MOIS_MAREE_DAT_RET;
  ref_day = JOUR_MAREE_DAT_RET;
  ref_date = MDY(ref_month,ref_day,ref_year);
  ref_ices = substr(RECTANGLE,2,4);
  tripdur = ref_date - MDY(MOIS_MAREE_DAT_SEQ,JOUR_MAREE_DAT_SEQ,ANNEE_MAREE_DAT_SEQ) + 1;
  tripdur2 = 1 + int(MAREE_DUREE/24);
  diffdur = tripdur - tripdur2;
  if (tripdur <= 0) then tripdur = tripdur2;
  landing = PRODUCTION;
  imark = 1;
  keep ref_vess ref_ft ref_year ref_month ref_day ref_date ref_ices gear species tripdur landing imark;
RUN;
proc sort data=cprall;
  by ref_year ref_vess;
RUN;

****************************************************************************************************;
********************* Imports and merges vessel characteristics for 1999-2021 **********************;
****************************************************************************************************;

%macro import_vess;
%do year = &yearmin. %to &yearmax.;
data vess&year.;
  ref_year_ = "&year.";
  infile "C:\Paul\2021-\Projets structurants\DS AMII FORESEA\Work\TSA Herring\Data\Vessels\Vessels&year..txt" delimiter = ';' MISSOVER DSD lrecl=32767 firstobs=2 ;
  informat NAVS_COD $8. ;
  informat DEB_FPC $12. ;
  informat FIN_FPC $12. ;
  informat MAT_COQUE $8. ;
  informat LONGUEUR_PP best32. ;
  informat LONGUEUR_HT best32. ;
  informat LARGEUR $1. ;
  informat NAVP_JAUGE_BR best32. ;
  informat NAVP_JAUGE_GT best32. ;
  informat NAVP_PUISSANCE_AD best32. ;
  informat NAVP_PUISSANCE_T best32. ;
  informat IND_RADIO $6. ;
  informat CODE_ARMATEUR $1. ;
  informat QUARTIER_ARM $1. ;
  informat DEBUT_ARM $1. ;
  informat FIN_ARM $1. ;
  informat CODE_FAO $5. ;
  informat NOM_FRANCAIS $71. ;
  informat NOM_ANGLAIS $25. ;
  informat NUM_ORDRE best32. ;
  informat SEG_COD $5. ;
  informat LIB_SEGMENT $23. ;
  informat LIB_SECTEUR $1. ;
  informat LIB_ESPECE $1. ;
  informat DEB_SEGMENT $12. ;
  informat FIN_SEGMENT $12. ;
  format NAVS_COD $8. ;
  format DEB_FPC $12. ;
  format FIN_FPC $12. ;
  format MAT_COQUE $8. ;
  format LONGUEUR_PP best12. ;
  format LONGUEUR_HT best12. ;
  format LARGEUR $1. ;
  format NAVP_JAUGE_BR best12. ;
  format NAVP_JAUGE_GT best12. ;
  format NAVP_PUISSANCE_AD best12. ;
  format NAVP_PUISSANCE_T best12. ;
  format IND_RADIO $6. ;
  format CODE_ARMATEUR $1. ;
  format QUARTIER_ARM $1. ;
  format DEBUT_ARM $1. ;
  format FIN_ARM $1. ;
  format CODE_FAO $5. ;
  format NOM_FRANCAIS $71. ;
  format NOM_ANGLAIS $25. ;
  format NUM_ORDRE best12. ;
  format SEG_COD $5. ;
  format LIB_SEGMENT $23. ;
  format LIB_SECTEUR $1. ;
  format LIB_ESPECE $1. ;
  format DEB_SEGMENT $12. ;
  format FIN_SEGMENT $12. ;
  input NAVS_COD $ DEB_FPC $ FIN_FPC $ MAT_COQUE $ LONGUEUR_PP LONGUEUR_HT LARGEUR $ NAVP_JAUGE_BR NAVP_JAUGE_GT
        NAVP_PUISSANCE_AD NAVP_PUISSANCE_T IND_RADIO $ CODE_ARMATEUR $ QUARTIER_ARM $ DEBUT_ARM $ FIN_ARM $
        CODE_FAO $ NOM_FRANCAIS $ NOM_ANGLAIS $ NUM_ORDRE SEG_COD $ LIB_SEGMENT $ LIB_SECTEUR $ LIB_ESPECE $
        DEB_SEGMENT $ FIN_SEGMENT $;
RUN;
%end;
%mend;

%import_vess;

data vessall;
  set vess1999 vess2000 vess2001 vess2002 vess2003 vess2004 vess2005 vess2006 vess2007 vess2008 vess2009 vess2010
      vess2011 vess2012 vess2013 vess2014 vess2015 vess2016 vess2017 vess2018 vess2019 vess2020 vess2021;
  ref_vess = NAVS_COD;
  vlength = LONGUEUR_HT/100; * Convert cm in m;
  ref_year = 1.0*ref_year_;
  keep ref_year ref_vess vlength;
RUN;

proc sort data=vessall;
  by ref_year ref_vess;
RUN;

proc means data=vessall noprint;
  by ref_year ref_vess;
  var vlength;
  output out=tsapel.vessall(drop= _type_ _freq_) mean=;
RUN;

symbol1 i=none v=dot color=blue  line=1 w=2 repeat=1;
proc gplot data=tsapel.vessall;
  plot vlength*ref_year / overlay nolegend;
RUN;


****************************************************************************************************;
******************** Merges files and exports into tsapel SAS library ******************************;
****************************************************************************************************;

data tsapel.cprvess1999_2021;
  merge tsapel.vessall cprall;
    by ref_year ref_vess;
  if imark = 1;
RUN;

