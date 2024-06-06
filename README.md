# DownsHerring
Contains 6 SAS programs and 1 Mathematica code that were used to run the analyses in PONE-D-24-09475. These were run sequentially starting from 00_... to 07_... Data that are publicly available are also provided. Some of the codes could be run with the data provided in the repository. For others (fisheries data), a data request should be sent. 

00_make_maps.sas : this SAS code can be run without input data;

01_extractSSTanomaly.sas : this SAS code can be run with input data in the SSTa zip file;

02_extractCPRzoo.sas : this SAS code can be run with input data in CPRData_B2C2.csv;

03_extractLandings.sas : to be run, this SAS code requires fisheries data which are owned by the DGAMPA and for which access is restricted. A data request could be conveyed via the form : https://sih.ifremer.fr/Donnees/Demande-de-donnees. The requester should seek access to the CPR files and vessel characteristics for French vessels fishing in ICES Divisions 7d and 4c between 1999 and 2021;

04_analyzeLandings.sas : this SAS code should be run after the three previous ones and it produces Fig 1. Data underpinning Fig 1 are provided in the repository (Fig 1.csv). The file premathematica_logbkC.csv is also produced and it is made available in this repository to be input in 05_calcPhenMetricsSINC.nb;

05_calcPhenMetricsSINC.nb : this Mathematica code can be run with input data in premathematica_logbkC.csv and it outputs postmathematica_logbkC.csv (also available in this repository);

06_plotPhenMetrics.sas : this SAS code should be run after the five previous ones and it produces Fig 2. Data underpinning Fig 2 are provided in the repository (Fig 2.csv).

07_analyzePhenMetrics.sas : this SAS code should be run after the six previous ones and it produces Fig 3. Data underpinning Fig 3 are provided in the repository (Fig 3.csv). The "Fit ARIMAX Section" part of the code could be run as a stand-alone piece by using the signal06.sas7bdat SAS data file as input to allow exploring various ARMAX parameterizations.
