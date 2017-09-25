/***************************************************************************************/
/* Kaggle Dataset - Human Resources Analytics */

/***************************************************************************************/

libname hr "I:\SAS Projects\Human Resources Analytics";

PROC IMPORT DATAFILE="I:\SAS Projects\Human Resources Analytics\HR.csv"
	OUT=hr.data 
	DBMS=CSV 
	REPLACE;	
	GETNAMES=yes;
	GUESSINGROWS=15000;
RUN;

/*proc contents data=clinic._all_nods;run; 
	_all_ requests listing of all files in the library 
	nods suppresses detailed info about each file */

/*to view descriptor information of the datafile, use varnum to show logical position in the dataset*/
PROC CONTENTS DATA=hr.data varnum;RUN;

/*display first 10 obs*/
PROC PRINT DATA=hr.data(FIRSTOBS=1 OBS=10);RUN;

PROC FORMAT; 
	value $deptfmt 
	'IT'='IT'
	'RandD'='RandD'
	'accounting'='Accounting'
	'hr'='HR'
	'management'='Management'
	'marketing'='Marketing'
	'product_mng'='Product_Mng'
	'sales'='Sales'
	'support'='Support'
	'technical'='Technical';
RUN;
	
/*recoding*/
DATA hr.datav1;
	SET hr.data (RENAME=(sales=dept left=left_company Work_accident=work_accident average_montly_hours=average_monthly_hours));

	IF salary="low" THEN nsalary=1;
	ELSE IF salary='medium' THEN nsalary=2;
	ELSE IF salary='high' THEN nsalary=3;

	length dept $10;
	format dept $deptfmt.;
RUN;
PROC PRINT DATA=hr.datav1(FIRSTOBS=13000 OBS=13010);
	ID DEPT;
RUN;

PROC SORT DATA=hr.datav1 out=work.datav1; 
	BY left_company salary;
RUN;

*can use proc summary w/ print option to produce similar output;
PROC MEANS DATA=work.datav1 maxdec=2;
	VAR satisfaction_level last_evaluation number_project average_monthly_hours time_spend_company nsalary;
	BY left_company salary;
RUN;
*Mean satisfaction for those already left the company=0.44 (work longer hours on ave=207.42)
*Mean for those still with the company=0.67 (work shorter hours on ave=199.06);

PROC FREQ DATA=work.datav1; 
	TABLES left_company*dept*salary/ NOFREQ NOROW NOPERCENT;
RUN;

*first logit analysis;
PROC LOGISTIC DESCENDING DATA=work.datav1; 
	MODEL left_company = satisfaction_level last_evaluation average_monthly_hours time_spend_company nsalary/ LINK=LOGIT RSQ STB;
	OUTPUT P=pred OUT=output1;
RUN;
/**Max rescaled R-square=0.2585, AIC=16466.691, SC=16474.306**/

*second logit analysis;
PROC LOGISTIC DESCENDING DATA=work.datav1; 
	MODEL left_company = satisfaction_level time_spend_company nsalary/ LINK=LOGIT RSQ STB;
	OUTPUT P=pred OUT=output2;
RUN;
/**Max rescaled R-square=0.2572, AIC=16466.691, SC=16474.306**/
*Dropping last_evaluation(insignificant) or average_monthly_hours do not improve max rescaled R-squared,AIC,SC;

DATA work.predict1; 
	SET output1;
	*ypred11 = 0.9220 -3.7082*(satisfaction_level) + 0.0556*(last_evaluation) + 0.00154*(average_monthly_hours)+0.1978*(time_spend_company)
			 -0.7027*(nsalary);
	*scenario - average satisfaction & evaluation, ave.200 hours workin, 3.5 years in the company and low salary;
	ypred11 = 0.9220 -3.7082*(0.5) + 0.0556*(0.5) + 0.00154*(200)+0.1978*(3.5)-0.7027*(1);
	ypred1 = exp(ypred11)/(1+exp(ypred11));
RUN;

PROC PRINT DATA=work.predict1(FIRSTOBS=1 OBS=1);
	VAR ypred1;
RUN;
*Predicted probability of this individual leaving the company (using pred11 scenario) = 0.35281;

