/*
Electricity production / consumption (1960 - 2012)

Data from kaggle.com
Krzysztof Kadowski, 2021-06-10
**/
--=============================================================================
--Data preparation
--=============================================================================

--All indocators for electricity
SELECT* FROM indicators i
WHERE lower(indicatorname) LIKE '%electr%'
ORDER BY indicatorname ;

--Indicators for production
SELECT DISTINCT indicatorname, indicatorcode 
FROM indicators i
WHERE lower(indicatorname) LIKE '%electricity prod%'
ORDER BY indicatorcode;

--Indicators for consumption
SELECT DISTINCT indicatorname, indicatorcode 
FROM indicators i
WHERE lower(indicatorname) LIKE '%electric power cons%'
ORDER BY indicatorcode;

/*
Indicators + codes: 
	Electric power consumption (kWh per capita)	EG.USE.ELEC.KH.PC
	
	Electricity production from coal sources (% of total)	EG.ELC.COAL.ZS
	Electricity production from oil, gas and coal sources (% of total)	EG.ELC.FOSL.ZS
	Electricity production from hydroelectric sources (% of total)	EG.ELC.HYRO.ZS
	Electricity production from natural gas sources (% of total)	EG.ELC.NGAS.ZS
	Electricity production from nuclear sources (% of total)	EG.ELC.NUCL.ZS
	Electricity production from oil sources (% of total)	EG.ELC.PETR.ZS
	Electricity production from renewable sources, excluding hydroelectric (kWh)	EG.ELC.RNWX.KH
	Electricity production from renewable sources, excluding hydroelectric (% of total)	EG.ELC.RNWX.ZS
*/

--Countries
SELECT * FROM country c;

-- World / Europe / Asia / another groups of countries - have a number in alpha2code code or letters: 
-- XC, EU, XE, XD, XR, XS, XJ, ZJ, XL XO, XM, XN, ZQ, XQ, XP, XU, OE,  ZG, ZF, XT

--Regions
SELECT * FROM country c, 
regexp_matches(alpha2code, '[0-9]');

--List of countries without stats of groups of countries
SELECT * FROM country c
WHERE c.alpha2code !~ '[%0-9%]' 
	AND c.alpha2code !~'[X%]' 
	AND c.alpha2code NOT IN ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF');
	
--Min and Max year
SELECT min(i."Year")
FROM indicators i; --1960

SELECT max(i."Year") 
FROM indicators i; --2013

--======================================================================
-- Cumulative statistics of electr. consumption per capita from records 
-- for regions: World / Europe / Asia / etc. 
--======================================================================

-- Electr. consumption in regions in years
DROP TABLE IF EXISTS region_electr_consumption;
CREATE TEMP TABLE region_electr_consumption
AS
	SELECT c.shortname AS Region, 
		i."Year",
		round(i.value::NUMERIC, 2) AS consumption,
		regexp_matches(alpha2code, '[0-9]')
	FROM indicators i
	JOIN country c ON i.countrycode = c.countrycode
	WHERE lower(i.indicatorname) LIKE '%electric power cons%'
	GROUP BY c.shortname, i."Year", i.value, regexp_matches(alpha2code, '[0-9]')
	ORDER BY 2;

SELECT * 
FROM region_electr_consumption;


--Average electr. consumption by regions 
SELECT Region,
	ROUND(avg(consumption)::NUMERIC,1) avg_consumption
FROM region_electr_consumption
GROUP BY Region
ORDER BY 2;


--Average electr. consumption by every 10 years 
DROP TABLE IF EXISTS ten_years;
CREATE TEMP TABLE ten_years
AS
	SELECT 	avg(i.value) filter (where i."Year" <1970) AS to_1970,
			avg(i.value) filter (where i."Year">=1970 and i."Year" <1980) AS to_1980,
			avg(i.value) filter (where i."Year">=1980 and i."Year" <1990) AS to_1990,
			avg(i.value) filter (where i."Year">=1990 and i."Year" <2000) AS to_2000,
			avg(i.value) filter (where i."Year">=2000 and i."Year" <2010) AS to_2010,
			avg(i.value) filter (where i."Year">=2010 and i."Year" <2013) AS to_2013
	FROM indicators i
	JOIN country c ON i.countrycode = c.countrycode
	WHERE lower(i.indicatorname) LIKE '%electric power cons%' 
		AND c.alpha2code !~ '[%0-9%]' 
		AND c.alpha2code !~'[X%]' 
		AND c.alpha2code NOT IN ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF');
SELECT * FROM ten_years;


--Electr. consumption by countries
DROP TABLE IF EXISTS consumption_by_countires;
CREATE TEMP TABLE consumption_by_countires
AS
	SELECT c.shortname AS country, 
		i."Year" AS yearof,
		round(i.value::numeric, 1) AS consumption,
		lag(round(i.value::numeric, 1)) OVER (PARTITION BY c.shortname ORDER BY c.shortname, i."Year") consumption_prev
	FROM indicators i
	JOIN country c ON i.countrycode = c.countrycode
	WHERE lower(i.indicatorname) LIKE '%electric power cons%' 
		AND c.alpha2code !~ '[%0-9%]' 
		AND c.alpha2code !~'[X%]' 
		AND c.alpha2code NOT IN ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF') 
	GROUP BY country, yearof, consumption
	ORDER BY 1, 2;
SELECT * FROM consumption_by_countires;


-- Percentage increases in consumption by countries / years 
DROP TABLE IF EXISTS percent_increases;
CREATE TEMP TABLE percent_increases
AS
	SELECT country, 
		yearof,
		consumption,
		consumption_prev,
		round((consumption - consumption_prev)/ consumption_prev, 3)*100 AS percent_consumption_incr
	FROM consumption_by_countires;
SELECT * 
FROM percent_increases;


-- Country with the greatest increase in consumption 
SELECT country,
	yearof,
	percent_consumption_incr
FROM percent_increases
WHERE percent_consumption_incr = (SELECT max(percent_consumption_incr) FROM percent_increases);

-- Country with the largest negative consumption growth 
SELECT country,
	yearof,
	percent_consumption_incr
FROM percent_increases
WHERE percent_consumption_incr = (SELECT min(percent_consumption_incr) FROM percent_increases);

	

DROP TABLE IF EXISTS percentyle;
CREATE TEMP TABLE percentyle
AS
	SELECT	yearof,
		percentile_disc(0.95) WITHIN GROUP (ORDER BY percent_consumption_incr) q95,
		percentile_disc(0.5) WITHIN GROUP (ORDER BY percent_consumption_incr) q50,
		percentile_disc(0.05) WITHIN GROUP (ORDER BY percent_consumption_incr) q5
	FROM percent_increases
	GROUP BY 1;
SELECT * 
FROM percentyle;


DROP TABLE IF EXISTS high;
CREATE TEMP TABLE high
AS
	SELECT DISTINCT o.country,
		o.yearof,
		percent_consumption_incr,			
		CASE WHEN percent_consumption_incr >= q50 THEN 1 ELSE 0 END in_q50,
		CASE WHEN percent_consumption_incr >= q95 THEN 1 ELSE 0 END in_q95,
		CASE WHEN percent_consumption_incr <= q5 THEN 1 ELSE 0 END in_q5
	FROM percent_increases o
	CROSS JOIN percentyle;
SELECT * 
FROM high;

--Countries in 95%
SELECT o.country,
	   sum(o.in_q95) as sum_q95
FROM high o 
GROUP BY o.country
ORDER BY 2 DESC;

-- Countries in 5%
SELECT o.country,
	   sum(in_q5) AS sum_q5
FROM high o 
GROUP BY o.country
ORDER BY 2 DESC;


-- Annual electr. consumption no-group by country 
DROP TABLE IF EXISTS year_consumption_world;
CREATE TEMP TABLE year_consumption_world
AS
	SELECT i."Year" AS yearof,
		round(i.value::numeric, 1) AS year_consum,
		lag(round(i.value::numeric, 1)) OVER (PARTITION BY  i."Year") year_consum_prev
	FROM indicators i
	JOIN country c ON i.countrycode = c.countrycode
	WHERE lower(i.indicatorname) LIKE '%electric power cons%' 
		AND c.alpha2code !~ '[%0-9%]' 
		AND c.alpha2code !~'[X%]' 
		AND c.alpha2code NOT IN ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF') 
	GROUP BY yearof, year_consum
	ORDER BY 1;
select * from zuzycie_roczne_swiat


DROP TABLE IF EXISTS avg_year;
CREATE TEMP TABLE avg_year 
AS
	SELECT yearof, 
		round(avg(year_consum)::numeric, 2) avg_year_consum,
		round(avg(year_consum_prev)::numeric, 2) avg_year_consum_prev		
	FROM year_consumption_world
	GROUP BY yearof;
SELECT * 
FROM avg_year;

-- The largest increases in average consumption globally 
SELECT yearof,
		round((avg_year_consum - avg_year_consum_prev)/avg_year_consum_prev,4)*100 as percet_avg_year_consum
FROM avg_year
ORDER BY 2 DESC;



-- IN PROGRESS.............

--============================================================
-- Produkcja elektryczności

-- W końcu zrobiłem crosstaba...Zamiast długich nazw użyłem kodów.

select distinct indicatorname, indicatorcode from indicators i
where lower(indicatorname) like '%electricity prod%'
order by indicatorcode;

select i."Year" as rok, 
		c.shortname as Country, 
		i.indicatorname  as indicator_name,
		i.indicatorcode as icode,
		sum(round(i.value::numeric, 1)) as produkcja 
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%'
group by  i."Year" , c.shortname, i.indicatorname, i.indicatorcode 
order by (1,2); 

-- odpaliłem rozszerzenia dla crosstaba
CREATE extension tablefunc;

-- utworzyłem sobie tabelę tyczmaczsową z danymi, które mnie interesują 
drop table if exists dane;

create temp table dane
as
select  c.shortname as country, 
		i.indicatorname  as indicator_name, 
		i.indicatorcode as icode,
		sum(round(i.value::numeric, 1)) produkcja
from indicators i 
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%' and lower(i.indicatorcode) like '%zs' and i.value <>0
group by c.shortname, i.indicatorname, i.indicatorcode 
order by (1,2); 

select country, 
		icode, 
		produkcja
from dane 
where icode like '%ZS'
order by 1,2;

 
SELECT * 
FROM crosstab('select country, 
						icode, 
						sum(produkcja) as suma 
				from dane 
				group by country, icode
				order by 1,2 ')
as final_result(
	country varchar(200),
	"EG.ELC.COAL.ZS" numeric,
	"EG.ELC.FOSL.ZS" numeric,
	"EG.ELC.HYRO.ZS" numeric,
	"EG.ELC.NGAS.ZS" numeric,
	"EG.ELC.NUCL.ZS" numeric,
	"EG.ELC.PETR.ZS" numeric,
	"EG.ELC.RNWX.ZS" numeric);
	

-- Produkcja roczna bez podziału na kraje
drop table if exists produkcja_roczna_swiat;
create temp table produkcja_roczna_swiat
as
	select 	i."Year" as rok,
			round(i.value::numeric, 1) as produkcja_roczna,
			lag(round(i.value::numeric, 1)) over (partition by  i."Year") produkcja_prev_roczna
	from indicators i
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%electricity prod%' and lower(i.indicatorcode) like '%zs' and i.value <>0
	group by rok, produkcja_roczna
	order by 1;
select * from produkcja_roczna_swiat;

drop table if exists srednia;
create temp table  srednia
as
	select rok, 
		round(avg(produkcja_roczna)::numeric, 2) avg_produkcja_roczna,
		round(avg(produkcja_prev_roczna)::numeric, 2) avg_produkcja_prev_roczna		
	from produkcja_roczna_swiat 
	group by rok;
select * from srednia;

select rok,
		round((avg_produkcja_roczna - avg_produkcja_prev_roczna)/avg_produkcja_prev_roczna,4)*100 as produkcja_roczna_procentowa
from srednia
order by 2 desc;







-- to be continued...

--======================================================================
-- Cumulative statistics of electr. production in % of total from records 
-- for regions: World / Europe / Asia / etc. 
--======================================================================

select c.shortname as Region, 
		i.indicatorname zrodlo,
		round(sum(i.value)::numeric, 0) as produkcja_regiony_zrodlami,
		regexp_matches(alpha2code, '[0-9]')
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%'
group by c.shortname, i.indicatorname, regexp_matches(alpha2code, '[0-9]')
order by 1 desc;



