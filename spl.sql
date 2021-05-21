/*
 * Przeprowadzimy wstepn¹ analizê wskaŸników z grupy Social Protection & Labour
 */
SELECT * 
  FROM series 
 WHERE topic LIKE 'Social Protection%';

SELECT DISTINCT topic 
  FROM series 
 WHERE topic LIKE 'Social Protection%';
--Grupa sk³ada siê z 5 podgrup, w których sk³ad wchodzi 148 ró¿nych wskaŸników

SELECT count(1) 
  FROM country;

 SELECT DISTINCT i."Year" 
   FROM indicators i 
  ORDER BY i."Year";
--Posiadamy dane dla 247 krajów/regionów z lat 1960-2015

SELECT i."Year",
	   count(1) 
  FROM indicators i 
 GROUP BY i."Year" 
 ORDER BY i."Year";
/*
 * Projekt zak³ada skupienie siê na sytuacji obecnej i niedawnych zmianach,
 * ograniczymy siê wiêc do lat 2005-2014. Dane z roku 2015 s¹ znacz¹co niepe³ne.
 */

/*
 * Przegl¹daj¹c listê wskaŸników najciekawsze dla naszej analizy wydaj¹ siê byæ nastêpuj¹ce:
 * SL.TLF.0714.ZS - Children in employment, total (% of children ages 7-14)
 * SM.POP.NETM - Net migration
 * SM.EMI.TERT.ZS - Emigration rate of tertiary educated (% of total tertiary educated population)
 * SL.UEM.LTRM.ZS - Long-term unemployment (% of total unemployment)
 * SL.UEM.TOTL.ZS - Unemployment, total (% of total labor force) (modeled ILO estimate)
 * SL.UEM.TOTL.NE.ZS - Unemployment, total (% of total labor force) (national estimate)
 * SL.SRV.EMPL.ZS - Employment in services (% of total employment)
 * per_sa_allsa.adq_pop_tot - Adequacy of social safety net programs (% of total welfare of beneficiary households)
 */
SELECT i.indicatorcode, i.indicatorname,
	   count(1), 
	   i."Year"
  FROM indicators AS i
 WHERE indicatorcode IN (SELECT s.seriescode
 						   FROM series AS s 
 						  WHERE s.topic LIKE 'Social Protection%')
   AND i."Year" BETWEEN 2005 AND 2014
   AND indicatorcode IN ('SL.TLF.0714.ZS', 'SM.POP.NETM', 'SM.EMI.TERT.ZS', 'SL.UEM.LTRM.ZS', 'SL.UEM.TOTL.ZS',
	  					 'SL.UEM.TOTL.NE.ZS', 'SL.SRV.EMPL.ZS', 'per_sa_allsa.adq_pop_tot')
 GROUP BY i.indicatorcode, i.indicatorname, i."Year"
 ORDER BY 3 DESC;
/*
 * We have very solid data on SL.UEM.TOTL.ZS and SL.UEM.TOTL.NE.ZS (Unemployment),
 * some missing data on SL.UEM.LTRM.ZS (long-term unemployment),
 * and little or on data on the rest of the above indicators.
 * We will also use the SL.TLF.0714.ZS (children in employment),
 * as most of the countries would have it close to 0 anyway.
 * SM.POP.NETM (migration) is a 5 year average and has data for lots of countries for this period.
 * 
 * We will continue with a focus on:
 * SL.TLF.0714.ZS - Children in employment, total (% of children ages 7-14)
 * SM.POP.NETM - Net migration
 * SL.UEM.TOTL.ZS - Unemployment, total (% of total labor force) (modeled ILO estimate)
 * SL.UEM.TOTL.NE.ZS - Unemployment, total (% of total labor force) (national estimate)
 */

/*
 * Starting with SL.TLF.0714.ZS - Children in employment, total (% of children ages 7-14)
 */
CREATE TEMP TABLE children_last AS
SELECT i.countryname,
	   i."Year",
	   i.value,
	   FIRST_VALUE(i.value) OVER 
	   		(PARTITION BY i.countryname ORDER BY i."Year" DESC) AS latest_value
  FROM indicators AS i
 WHERE i.indicatorcode = 'SL.TLF.0714.ZS'
   AND i."Year" BETWEEN 2005 and 2014
 ORDER BY 1, i."Year" DESC, i.value DESC;
--data for most countries come FROM only 1 or 2 periods, so we'll only look at the lastest

SELECT DISTINCT
	   countryname,
	   latest_value
  FROM children_last
 ORDER BY 2 DESC;
/*
 * We won't look much at the countries with low values, as some countries with probable very low scores have no data
 * (such as western european and other well developed countries).
 * 
 * Looking at the list we find the countries WHERE the most children have to work are African countries
 * Let's just look at the values for Africa only.
 */

SELECT DISTINCT
	   cl.countryname,
	   cl.latest_value,
	   c.region
  FROM children_last AS cl
  	   JOIN country AS c
  	   ON cl.countryname = c.tablename
 WHERE c.region LIKE '%Africa%'
 ORDER BY 2 DESC;
/*
 * Sub-Saharan states have generally very poor scores, but values range FROM 12.5 to 62,
 * so we can see some countries in the region managed to keep the children out of the workforce.
 */

/*
 * Let's now take a closer look at SM.POP.NETM - Net migration.
 */
SELECT i.countryname,
	   i."Year",
	   i.value
  FROM indicators AS i
 WHERE i.indicatorcode = 'SM.POP.NETM'
   AND i."Year" BETWEEN 2005 and 2014
 ORDER BY 1, 2 DESC, 3 DESC;

/*
 * We only have data for 2012 and 2007 (avearge FROM 5 years).
 * Let's see which country has the most imigration and emigration.
 * We will only look at the countries, not regions.
 */
SELECT i.countryname,
	   i."Year",
	   i.value
  FROM indicators AS i
	   JOIN country AS c
	   ON c.tablename = i.countryname 
	 	  AND c.region != ''
 WHERE i.indicatorcode = 'SM.POP.NETM'
   AND i."Year" = 2012
 ORDER BY 2 DESC, 3 DESC;

SELECT i.countryname,
	   i."Year",
	   i.value
  FROM indicators AS i
  	   JOIN country AS c
	   ON c.tablename = i.countryname 
	      AND c.region != ''
WHERE i.indicatorcode = 'SM.POP.NETM'
  AND i."Year" = 2012
ORDER BY 2 DESC, i.value ASC;

/*
 * The top of the list includes many well developed countries like USA, Germany and Canada.
 * The numbers might correspond to lots of emigrants FROM India and China seeking better job opportunities.
 * 
 * We can see also Turkey, Lebanon, Oman, which is probably connected with war in Syria and
 * lot's of emigrnats FROM there (top of the list).
 * 
 * Now we will calculated the greatest change in migration for both periods.
 */
CREATE TEMP TABLE migration_2012 AS
SELECT i.countryname,
	   i.value AS value_2012
  FROM indicators AS i
 	   JOIN country AS c
	   ON c.tablename = i.countryname 
	      AND c.region != ''
 WHERE i.indicatorcode = 'SM.POP.NETM'
   AND i."Year" = 2012;

CREATE TEMP TABLE migration_2007 AS
SELECT i.countryname,
	   i.value AS value_2007
  FROM indicators AS i
	   JOIN country AS c
	   ON c.tablename = i.countryname
	   	  AND c.region != ''
 WHERE i.indicatorcode = 'SM.POP.NETM'
   AND i."Year" = 2007;

SELECT m12.countryname,
	   m12.value_2012,
	   m07.value_2007,
	   m12.value_2012 - m07.value_2007 AS difference
  FROM migration_2012 AS m12
 	   JOIN migration_2007 AS m07 
   	   ON m12.countryname = m07.countryname
 ORDER BY ABS(m12.value_2012 - m07.value_2007) DESC;

/*
 * The biggest difference in these periods can be seen in Syria, UAE and Spain (all negative),
 * followed by Turkey, Bangladesh, Germany. The profile for each country is different.
 */

/*
 * The last 2 indicators are:
 * SL.UEM.TOTL.ZS - Unemployment, total (% of total labor force) (modeled ILO estimate) (ILO - International Labour Organization)
 * SL.UEM.TOTL.NE.ZS - Unemployment, total (% of total labor force) (national estimate)
 * 
 */
CREATE TEMP TABLE unemployement_ilo AS
SELECT i.countryname,
	   i."Year",
	   i.value
  FROM indicators AS i
  	   JOIN country AS c
	   ON c.tablename = i.countryname
	      AND c.region != ''
	      AND i."Year" BETWEEN 2005 AND 2014
 WHERE i.indicatorcode = 'SL.UEM.TOTL.NE.ZS';

CREATE TEMP TABLE unemployement_nat AS
SELECT i.countryname,
	   i."Year",
	   i.value
  FROM indicators AS i
	   JOIN country AS c
	   ON c.tablename = i.countryname
	   	  AND c.region != ''
	   	  AND i."Year" BETWEEN 2005 AND 2014
 WHERE i.indicatorcode = 'SL.UEM.TOTL.ZS';

DROP TABLE unemployment_calculations;
CREATE TEMP TABLE unemployment_calculations AS
SELECT ui.countryname,
	   ui."Year",
	   ROUND(ui.value::numeric, 1) AS value_ilo,
	   ROUND(un.value::numeric, 1) AS value_national,
	   ROUND((ui.value - un.value)::numeric, 1) AS difference,
	   FIRST_VALUE(ui."Year") OVER 
	   		(PARTITION BY ui.countryname ORDER BY ui."Year" DESC) AS year_earliest,
	   FIRST_VALUE(ROUND(ui.value::numeric, 1)) OVER 
	   		(PARTITION BY ui.countryname ORDER by ui."Year" DESC) AS value_earliest,
	   FIRST_VALUE(ui."Year") OVER 
	   		(PARTITION BY ui.countryname ORDER BY ui."Year" ASC) AS year_latest,
	   FIRST_VALUE(ROUND(ui.value::numeric, 1)) OVER 
	   		(PARTITION BY ui.countryname ORDER BY ui."Year" ASC) AS value_latest
  FROM unemployement_ilo AS ui
	   JOIN unemployement_nat AS un
	   ON ui.countryname = un.countryname
	  	  AND ui."Year" = un."Year";

/*
 * After creating helping tables, we can check the current best and worst in terms of unemployment.
 */
SELECT uc.countryname,
	   uc.year_earliest,
	   uc.value_earliest
  FROM unemployment_calculations AS uc
 GROUP BY 1,2,3
 ORDER BY 3 DESC;
/*
 * The worst cases are some African and Mediterrean countries.
 */

/*
 * Here we compare the change of unemplyement in years 2005-2014 (limited to available data).
 * African countries are leading here, HAVING the most room for improvement.
 * Among the worst are Greece and Spain, hit by an economic crisis.
 */
SELECT uc.countryname,
	   CASE
	   WHEN (uc.year_earliest - uc.year_latest) != 0 THEN
			ROUND(100 * (uc.value_earliest - uc.value_latest) / uc.value_latest / (uc.year_earliest - uc.year_latest), 0)
	   ELSE NULL 
	   END AS change_perc_per_year,
	   CASE 
	   WHEN (uc.year_earliest - uc.year_latest) != 0 THEN
	   		ROUND((uc.value_earliest - uc.value_latest) / (uc.year_earliest - uc.year_latest), 1)
	   ELSE NULL
	   END AS change_abs_per_year
  FROM unemployment_calculations AS uc
 GROUP BY 1,2,3
 ORDER BY 3 ASC;

/*
 * Let's also check if the national reported value is similar to the ILO calculated value.
 */
SELECT uc.countryname,
	   ROUND(AVG(uc.value_ilo)::numeric, 0) AS ilo_avg,
	   ROUND(AVG(uc.value_national)::numeric, 0) AS national_avg,
	   ROUND(AVG(uc.difference)::numeric, 0) AS difference_avg
  FROM unemployment_calculations AS uc
 GROUP BY 1
HAVING ROUND(AVG(uc.difference)::numeric, 0) > 1 
	OR ROUND(AVG(uc.difference)::numeric, 0) < -1
 ORDER BY 4 DESC;
/*
 * Most of the countries report similiar values to that of ILO, with some African
 * countries being the least honest.
 */

