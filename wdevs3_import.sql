CREATE TABLE public.countrynotes_csv (
	countrycode varchar(5) NULL,
	seriescode varchar(30) NULL,
	description text NULL
);
CREATE TABLE public.country_csv (
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
CREATE TABLE public.footnotes_csv (
	countrycode varchar(5) NULL,
	seriescode varchar(30) NULL,
	"Year" varchar(6) NULL,
	description text NULL
);
CREATE TABLE public.indicators_csv (
	countryname varchar(50) NULL,
	countrycode varchar(5) NULL,
	indicatorname varchar(250) NULL,
	indicatorcode varchar(30) NULL,
	"Year" int4 NULL,
	value float8 NULL
);
CREATE TABLE public.seriesnotes_csv (
	seriescode varchar(30) NULL,
	"Year" varchar(6) NULL,
	description text NULL
);
CREATE TABLE public.series_csv (
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




--Import

select distinct * from indicators_csv ic2 
where lower(indicatorname) like '%imports%';


--Import metali

drop table zsumowane_wartosci_import; 
--zsumowanie waro�ci i �rednia importu dla wszystkich kraj�w i region�w
create temp table zsumowane_wartosci_import
as
select 	ic2.countryname
,		ic2.indicatorname
,		ic2.value 
,		sum(ic2.value) over (partition by countryname) suma_import_metali
, 		avg(ic2.value) over (partition by countryname) srednia_import_metali
,		lag(ic2.value) over (partition by countryname order by "Year") poprzedni_rok_metali
,		ic2."Year" 
from indicators_csv ic2
where indicatorname like 'Ores and metals imports%' 
group by ic2.value , ic2.countryname, ic2.indicatorname, ic2."Year" 
;
select  * from zsumowane_wartosci_import;

--Przyrost ilo�ciowy importu

select  distinct countryname 
,		suma_import_metali
from zsumowane_wartosci_import
order by suma_import_metali desc ;

-- Ilo�ciowo top 10 (Japonia, Belgia, Indie, Niemcy, W�ochy, Norwegia, Korea po�udniowa, Wielka Brytania, Finladia, Turcja)

--Procentowy przyrost importu
create temp table Zmiana_proc_import_metali
as
select  countryname
, 		sum((value/poprzedni_rok_metali)*100) zmiana_proc
,		"Year" 
from zsumowane_wartosci_import
group by countryname, poprzedni_rok, "Year"
order by countryname, "Year"
;

select distinct countryname
,				sum(zmiana_proc) over (partition by countryname) zmiana_proc_40
from zmiana_proc_import_metali
order by zmiana_proc_40 desc
;

--W tej tabeli mo�emy zobaczy� �e najwi�kszy przyrost procentowy zaobserwowa� Nepal dalej Senegal, Paragwaj, Islandia, W�gry, Tunezja, Turcja i Ekwador


--Fuel imports

create temp table zsumowane_wartosci_importu_paliw
as
select 	ic2.countryname
,		ic2.indicatorname
,		ic2.value 
,		sum(ic2.value) over (partition by countryname) suma_import_paliw
, 		avg(ic2.value) over (partition by countryname) srednia_import_paliw
,		lag(ic2.value) over (partition by countryname order by "Year") poprzedni_rok_paliw
,		ic2."Year" 
from indicators_csv ic2
where indicatorname like 'Fuel imports%' 
group by ic2.value , ic2.countryname, ic2.indicatorname, ic2."Year" 
;

select * 
from zsumowane_wartosci_importu_paliw;


select  distinct countryname 
,		suma_import_paliw
from zsumowane_wartosci_importu_paliw
order by suma_import_paliw desc ;

--Top 10 (Japonia, Bahamy, Indie, Brazylia, Trynidad i Tobago, Jamaika, Pakistan, Singapur, Korea po�udniowa, Bahrain)


create temp table Zmiana_proc_import_paliw
as
select  countryname
, 		sum((value/poprzedni_rok_paliw)*100) zmiana_proc
,		"Year" 
from zsumowane_wartosci_importu_paliw
group by countryname, poprzedni_rok_paliw, "Year"
order by countryname, "Year"
;

select distinct countryname
,				sum(zmiana_proc) over (partition by countryname) zmiana_proc_40
from zmiana_proc_import_paliw
order by zmiana_proc_40 desc;

--procentowo najwi�ksze zmiany mo�na zaobserowa� u Seszeli, Arabi Saudyjskiej, Bahrainu, Nigerii, Barbados, Trynidad i tobago, Nepal, Gwinea r�wnikowa
--zmiany

