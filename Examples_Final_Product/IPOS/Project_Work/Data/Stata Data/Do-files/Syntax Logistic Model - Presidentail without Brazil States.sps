

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


