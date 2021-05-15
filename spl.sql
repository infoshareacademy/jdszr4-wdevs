/*
 * Przeprowadzimy wstepn¹ analizê wskaŸników z grupy Social Protection & Labour
 */
select * from series where topic like 'Social Protection%';
select distinct topic from series where topic like 'Social Protection%';
--Grupa sk³ada siê z 5 podgrup, w których sk³ad wchodzi 148 ró¿nych wskaŸników

select count(1) from country;
select distinct i."Year" from indicators i order by i."Year";
--Posiadamy dane dla 247 krajów/regionów z lat 1960-2015

select i."Year", count(1) from indicators i group by i."Year" order by i."Year";
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
select i.indicatorcode, i.indicatorname, count(1), i."Year"
from indicators i
where indicatorcode in (select s.seriescode from series s where topic like 'Social Protection%')
	  and (i."Year" between 2005 and 2014)
	  and (indicatorcode in ('SL.TLF.0714.ZS', 'SM.POP.NETM', 'SM.EMI.TERT.ZS', 'SL.UEM.LTRM.ZS', 'SL.UEM.TOTL.ZS',
	  						 'SL.UEM.TOTL.NE.ZS', 'SL.SRV.EMPL.ZS', 'per_sa_allsa.adq_pop_tot'))
group by i.indicatorcode, i.indicatorname, i."Year"
order by 3 desc;
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
create temp table children_last
as
select i.countryname
,	   i."Year"
,	   i.value
,	   first_value(i.value) over (partition by i.countryname order by i."Year" desc) latest_value
from indicators i
where i.indicatorcode = 'SL.TLF.0714.ZS'
  and (i."Year" between 2005 and 2014)
order by 1,i."Year" desc, i.value desc;
--data for most countries come from only 1 or 2 periods, so we'll only look at the lastest

select distinct countryname, latest_value
from children_last
order by 2 desc;
/*
 * We won't look much at the countries with low values, as some countries with probable very low scores have no data
 * (such as western european and other well developed countries).
 * 
 * Looking at the list we find the countries where the most children have to work are African countries
 * Let's just look at the values for Africa only.
 */

select distinct cl.countryname, cl.latest_value, c.region
from children_last cl
join country c on cl.countryname = c.tablename
where c.region like '%Africa%'
order by 2 desc;
/*
 * Sub-Saharan states have generally very poor scores, but values range from 12.5 to 62,
 * so we can see some countries in the region managed to keep the children out of the workforce.
 */

/*
 * Let's now take a closer look at SM.POP.NETM - Net migration.
 */
select i.countryname
,	   i."Year"
,	   i.value
from indicators i
where i.indicatorcode = 'SM.POP.NETM'
  and (i."Year" between 2005 and 2014)
order by 1, 2 desc, i.value desc;

/*
 * We only have data for 2012 and 2007 (avearge from 5 years).
 * Let's see which country has the most imigration and emigration.
 * We will only look at the countries, not regions.
 */
select i.countryname
,	   i."Year"
,	   i.value
from indicators i
join country c
on c.tablename = i.countryname and c.region != ''
where i.indicatorcode = 'SM.POP.NETM'
  and (i."Year" = 2012)
order by 2 desc, i.value desc;

select i.countryname
,	   i."Year"
,	   i.value
from indicators i
join country c
on c.tablename = i.countryname and c.region != ''
where i.indicatorcode = 'SM.POP.NETM'
  and (i."Year" = 2012)
order by 2 desc, i.value asc;

/*
 * The top of the list includes many well developed countries like USA, Germany and Canada.
 * The numbers might correspond to lots of emigrants from India and China seeking better job opportunities.
 * 
 * We can see also Turkey, Lebanon, Oman, which is probably connected with war in Syria and
 * lot's of emigrnats from there (top of the list).
 * 
 * Now we will calculated the greatest change in migration for both periods.
 */
create temp table migration_2012 as
select i.countryname
,	   i.value value_2012
from indicators i
join country c
on c.tablename = i.countryname and c.region != ''
where i.indicatorcode = 'SM.POP.NETM'
  and (i."Year" = 2012);

create temp table migration_2007 as
select i.countryname
,	   i.value value_2007
from indicators i
join country c
on c.tablename = i.countryname and c.region != ''
where i.indicatorcode = 'SM.POP.NETM'
  and (i."Year" = 2007);

select  m12.countryname
,		m12.value_2012
,		m07.value_2007
,		m12.value_2012 - m07.value_2007 difference
from migration_2012 m12 join migration_2007 m07 on m12.countryname=m07.countryname
order by abs(m12.value_2012 - m07.value_2007) desc;

/*
 * The biggest difference in these periods can be seen in Syria, UAE and Spain (all negative),
 * followed by Turkey, Bangladesh, Germany. The profile for each country is different.
 */

