


*COMPUTE vote.govt=NUMBER(vote.govt.cand,F3.1).

COMPUTE vote.govt=vote.govt.cand.
COMPUTE vote.diff=vote.govt.cand - max(vote.cand1,vote.cand2,vote.cand3,vote.cand4).
EXECUTE.



RECODE GovApproval (0 thru 39.99999=1) (40 thru 54.99999=2) (55 thru Highest=3) (ELSE=SYSMIS) INTO 
    scenario.
EXECUTE.

val labels
scenario
1 "Change [0-40)"
2 "Middle [40-54)"
3 "Continuity [55-100]".

RECODE Sucessornewcandidatefromthepartyinofficerunning (1=0) (0=1) (ELSE=SYSMIS) INTO candidate.
EXECUTE.

val labels
candidate
1 'Incumbent'
0 'Sucessor'.

recode ElectionType  ('' = 4) ('Chancellor' = 4) ('Parliamentary' = 2) ('President' = 1) ('Presidential' = 1) ('Governor' =1) ('Presidential/Legislative' = 1) ('Prime Minister' = 3) ('Prime Ministers' = 3) into election.type.
exec.

val labels
election.type
1 'Presidential'
2 'Parliamentary'
3 'Prime Minister'
4 'Other/Unkown'.

recode election.type (1=1) (else = 2) into presidential.
exec.

val labels
presidential
1 'Presidential' 
2 'Not Presidential'.

recode region ('' = 7) ('Africa' = 7) ('Asia' = 6) ('Caribbean' = 5) ('Central America' = 5) ('Europe' = 3) ('Middle East' = 6) ('North America' = 1) ('SEA/Pacific' = 4) ('South America' = 2) into region_.
exec.

val labels
region_
1 'North America'
2 'South America'
3 'Europe'
4 'SEA/Pacific'
5 'Central America / Caribean'
6 'Asia / Middle East'
7 'Africa / Unkown'.

recode GovernmentLevel ('' = 3) ('National' = 1) ('State' = 2)  into Gov.Level.
exec.

val labels
Gov.Level
1 'National'
2 'State'
3 'Unkown',

*convertendo ExcellentGood para approval

compute ExcellentGood.orig = GovApproval.
IF (ExcellentGood = 1) GovApproval = 7.992076 +  1.146371 * GovApproval.
EXEC.


* retirando eleicoes suspeitas

compute SUSPICIOUS = 0.
if ((scenario = 2) and (Result_depGovernmentinofficewon=0) and (candidate=1))  SUSPICIOUS = 1.
exec.

compute brazil_state = 0.
if ((Gov.Level = 2) and (Country = "Brasil"))  brazil_state = 1.
exec.


**** removing suspicious cases


LOGISTIC REGRESSION VARIABLES Result_depGovernmentinofficewon
  /SELECT=SUSPICIOUS EQ 0
  /METHOD=ENTER GovApproval candidate 
  /SAVE=PRED
  /CRITERIA=PIN(.05) POUT(.10) ITERATE(20) CUT(.5).

LOGISTIC REGRESSION VARIABLES Result_depGovernmentinofficewon
  /SELECT=brazil_state EQ 0
  /METHOD=ENTER GovApproval candidate 
  /SAVE=PRED
  /CRITERIA=PIN(.05) POUT(.10) ITERATE(20) CUT(.5).


*****


* Custom Tables.
CTABLES
  /VLABELS VARIABLES=presidential candidate Result_depGovernmentinofficewon scenario DISPLAY=DEFAULT    
  /TABLE presidential [C] > candidate [C] > Result_depGovernmentinofficewon [S][MEAN F40.2] BY 
    scenario [C]
  /CATEGORIES VARIABLES=presidential ORDER=A KEY=VALUE EMPTY=EXCLUDE TOTAL=YES POSITION=AFTER
  /CATEGORIES VARIABLES=candidate scenario ORDER=A KEY=VALUE EMPTY=INCLUDE.


* Custom Tables.
CTABLES
  /VLABELS VARIABLES=presidential candidate vote.diff DISPLAY=DEFAULT    
  /TABLE presidential [C] > candidate [C] > vote.diff [S][MEAN F40.2] BY 
    scenario [C]
  /CATEGORIES VARIABLES=presidential ORDER=A KEY=VALUE EMPTY=EXCLUDE TOTAL=YES POSITION=AFTER
  /CATEGORIES VARIABLES=candidate scenario ORDER=A KEY=VALUE EMPTY=INCLUDE TOTAL=YES POSITION=AFTER.



LOGISTIC REGRESSION VARIABLES Result_depGovernmentinofficewon
  /METHOD=ENTER candidate GovApproval 
  /SAVE=PRED
  /CRITERIA=PIN(.05) POUT(.10) ITERATE(20) CUT(.5).


RECODE PRE_1 (0 thru 0.499999=0) (0.5 thru 1=1) INTO Prediction.
COMPUTE ERROR = ABS(Result_depGovernmentinofficewon - Prediction).
EXECUTE.


* Custom Tables.
CTABLES
  /VLABELS VARIABLES=presidential Result_depGovernmentinofficewon Prediction DISPLAY=DEFAULT
  /TABLE presidential > Result_depGovernmentinofficewon [COUNT F40.0] BY Prediction
  /CATEGORIES VARIABLES=presidential ORDER=A KEY=VALUE EMPTY=INCLUDE
  /CATEGORIES VARIABLES=Result_depGovernmentinofficewon Prediction ORDER=A KEY=VALUE EMPTY=EXCLUDE.


