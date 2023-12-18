***************************************************************************************
**		Section 1. Inputting data sources											 **
**************************************************************************************;
%web_drop_table(WORK.acumen);


FILENAME REFFILE '/home/u63078235/sasuser.v94/cleaned_data.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.acumen;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.acumen; RUN;


%web_open_table(WORK.acumen);



***************************************************************************************
**		Section 2. Data Quality Check												 **
**************************************************************************************;
PROC FORMAT;
VALUE SexF
	0 = "Female"
	1 = "Male";
VALUE HospitalF
	0 = "No"
	1 = "Yes";
RUN;

/* Check for 12 Entries per employee_id */
PROC SQL;
    SELECT COUNT(*) AS num_less_12_entries
    FROM (SELECT employee_id
          FROM acumen
          WHERE health_score NE 10
          GROUP BY employee_id
          HAVING COUNT(*) < 12) AS less_12_entries;
QUIT;

/* Check for Unique employee_id and quarter Combinations */
PROC SQL;
    SELECT employee_id, quarter, COUNT(*) as count
    FROM acumen
    GROUP BY employee_id, quarter
    HAVING COUNT(*) > 1;
QUIT;

TITLE ""Frequency plot for Sex"";
PROC SGPLOT DATA=acumen;
    VBAR quarter / GROUP=sex GROUPDISPLAY=cluster;
    XAXIS LABEL='Quarter';
    YAXIS LABEL='Frequency';
    TITLE 'Sex Distribution Over Quarters';
RUN;
TITLE ""Frequency plot for Race"";
PROC SGPLOT DATA=acumen;
    VBAR quarter / GROUP=race GROUPDISPLAY=cluster;
    XAXIS LABEL='Quarter';
    YAXIS LABEL='Frequency';
    TITLE 'Race Distribution Over Quarters';
RUN;

TITLE "sex & race over quarter by employee_id";
PROC SQL;
    CREATE TABLE sex_changes AS
    SELECT employee_id, COUNT(DISTINCT sex) AS distinct_sex_count
    FROM acumen
    GROUP BY employee_id
    HAVING COUNT(DISTINCT sex) > 1;

    CREATE TABLE race_changes AS
    SELECT employee_id, COUNT(DISTINCT race) AS distinct_race_count
    FROM acumen
    GROUP BY employee_id
    HAVING COUNT(DISTINCT race) > 1;
QUIT;


***************************************************************************************
**		Section 3. Demographic Characteristics										 **
**************************************************************************************;
PROC SGPLOT DATA=acumen;
    SCATTER x=age y=health_score / GROUP=sex;
    XAXIS LABEL='Age';
    YAXIS LABEL='Health Score';
    TITLE 'Scatter Plot of Age vs Health Score';
    FORMAT sex SexF.;
    WHERE health_score NE 10;
RUN;

PROC SGPLOT DATA=acumen;
    VBOX health_score / CATEGORY=sex;
    XAXIS LABEL='Sex';
    YAXIS LABEL='Health Score';
    TITLE 'Health Score Distribution by Sex';
    FORMAT sex SexF.;
    WHERE health_score NE 10;
RUN;

PROC SGPLOT DATA=acumen;
    VBOX health_score / CATEGORY=race;
    XAXIS LABEL='Race';
    YAXIS LABEL='Health Score';
    TITLE 'Health Score Distribution by Race';
    WHERE health_score NE 10;
RUN;



***************************************************************************************
**		Section 4. Bivariate Analyses for Keys										 **
**************************************************************************************;
PROC SORT DATA=acumen;
  BY employee_id;
RUN;

PROC SGPLOT DATA=acumen;
    SCATTER x=salary y=health_score / GROUP=quarter MARKERATTRS=(symbol=circlefilled);
    XAXIS LABEL='Salary';
    YAXIS LABEL='Health Score';
    TITLE 'Scatter Plot of Salary vs Health Score by Quarter';
    WHERE health_score NE 10;
RUN;

proc sgpanel data=acumen;
  panelby quarter / columns=4 onepanel;
  scatter x=salary y=health_score / markerattrs=(symbol=circlefilled);
  rowaxis grid;
  colaxis grid;
  title 'Panelled Scatter Plot of Health Score by Quarter';
  WHERE health_score NE 10;
run;

PROC SGPLOT DATA=acumen;
    VBOX health_score / CATEGORY=quarter GROUP=quarter_hospital_visit;
    XAXIS LABEL='Quarter';
    YAXIS LABEL='Health Score';
    TITLE 'Health Score by Quarter and Hospital Visit';
    WHERE health_score NE 10;
    FORMAT quarter_hospital_visit HospitalF.;
RUN;


