/*
Table schema for importing the .csv files into the postgres database.

File series.csv as stored on kaggle contains a typo.
For this file please remove the \ character before importing
or change the escape character from the default \ to ~ in BDeaver.
*/

CREATE TABLE public.countrynotes (
	countrycode varchar(5) NULL,
	seriescode varchar(30) NULL,
	description text NULL
);

CREATE TABLE public.country (
	countrycode varchar(3) NULL,
	shortname varchar(46) NULL,
	tablename varchar(46) NULL,
	longname varchar(73) NULL,
	alpha2code varchar(2) NULL,
	currencyunit varchar(42) NULL,
	specialnotes varchar(1094) NULL,
	region varchar(26) NULL,
	incomegroup varchar(20) NULL,
	wb2code varchar(2) NULL,
	nationalaccountsbaseyear varchar(119) NULL,
	nationalaccountsreferenceyear varchar(7) NULL,
	snapricevaluation varchar(36) NULL,
	lendingcategory varchar(5) NULL,
	othergroups varchar(9) NULL,
	systemofnationalaccounts varchar(62) NULL,
	alternativeconversionfactor varchar(18) NULL,
	pppsurveyyear varchar(34) NULL,
	balanceofpaymentsmanualinuse varchar(44) NULL,
	externaldebtreportingstatus varchar(11) NULL,
	systemoftrade varchar(20) NULL,
	governmentaccountingconcept varchar(31) NULL,
	imfdatadisseminationstandard varchar(42) NULL,
	latestpopulationcensus varchar(61) NULL,
	latesthouseholdsurvey varchar(124) NULL,
	sourceofmostrecentincomeandexpendituredata varchar(90) NULL,
	vitalregistrationcomplete varchar(48) NULL,
	latestagriculturalcensus varchar(36) NULL,
	latestindustrialdata float8 NULL,
	latesttradedata float8 NULL,
	latestwaterwithdrawaldata float8 NULL
);

CREATE TABLE public.footnotes (
	countrycode varchar(5) NULL,
	seriescode varchar(30) NULL,
	"Year" varchar(6) NULL,
	description text NULL
);

CREATE TABLE public.indicators (
	countryname varchar(50) NULL,
	countrycode varchar(5) NULL,
	indicatorname varchar(250) NULL,
	indicatorcode varchar(30) NULL,
	"Year" int4 NULL,
	value float8 NULL
);

CREATE TABLE public.seriesnotes (
	seriescode varchar(30) NULL,
	"Year" varchar(6) NULL,
	description text NULL
);

CREATE TABLE public.series (
	seriescode text NULL,
	topic text NULL,
	indicatorname text NULL,
	shortdefinition text NULL,
	longdefinition text NULL,
	unitofmeasure text NULL,
	periodicity text NULL,
	baseperiod text NULL,
	othernotes text NULL,
	aggregationmethod text NULL,
	limitationsandexceptions text NULL,
	notesfromoriginalsource text NULL,
	generalcomments text NULL,
	"Source" text NULL,
	statisticalconceptandmethodology text NULL,
	developmentrelevance text NULL,
	relatedsourcelinks text NULL,
	otherweblinks text NULL,
	relatedindicators text NULL,
	licensetype text NULL
);
