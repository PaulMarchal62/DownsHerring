# DownsHerring
Contains 6 SAS programs and 1 Mathematica code that were used to run the analyses in PONE-D-24-09475. These were run sequentially starting from 00_... to 07_... Data that are publicly available are also provided. Some of the codes could be run with the data provided in the repository. For others (fisheries data), a data request should be sent. 

00_make_maps.sas : can be run without input data

01_extractSSTanomaly.sas : can be run with input data in the SSTa zip file

02_extractCPRzoo.sas : can be run with input data in CPRData_B2C2.csv

03_extractLandings.sas : To be run, this code requires fisheries data which are owned by the DGAMPA and for which access is restricted. A data request could be conveyed via the form that could be found: https://sih.ifremer.fr/Donnees/Demande-de-donnees. The requester should seek access to the CPR files and vessel characteristics for French vessels fiching in ICES Divisions 7d and 4c between 1999 and 2021. 

04_analyzeLandings.sas : This code should be run after the three previous ones. Data underpinning Fig 1 are provided in the repository (Fig 1.csv)




https://sih.ifremer.fr/Donnees/Demande-de-donnees
