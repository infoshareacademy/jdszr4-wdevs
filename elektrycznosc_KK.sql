-- Zadanie 1 - 

/*
 
 Wstępna analiza:
- najwięksi producenci energii elektrycznej,
- najwięksi zużywający energię elektryczną,
- najlepsi / najgorsi w produkcji vs. zużycie energii elektrycznej,
- przyrosty zużycia,
- przyrosty produkcji.

*/
--=============================================================================
-- Sprawdzenie kodów 

-- jakie kody związane z elektrycznością
select * from indicators i
where lower(indicatorname) like '%electr%'
order by indicatorname ;

-- jakie kody produkcji elektryczności
select distinct indicatorname, indicatorcode from indicators i
where lower(indicatorname) like '%electricity prod%'
order by indicatorcode;

-- jakie kody konsumpcji elektryczności
select distinct indicatorname, indicatorcode from indicators i
where lower(indicatorname) like '%electric power cons%'
order by indicatorcode;
--=============================================================================


-- zuzycie prądu krajami, latami
select c.shortname as Kraj, i."Year" as Rok, round(i.value::numeric, 1) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
order by c.shortname, i."Year" ;

-- sumaryczne zuzycie prądu krajami
select c.shortname as Kraj,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
group by c.shortname 
order by c.shortname;

-- sumaryczne zuzycie prądu krajami od największych
select c.shortname as Kraj,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
group by c.shortname 
order by 2 desc;

--=============================================================================
-- WNIOSEK 1: 
-- najwięcej globalnie zużywa prądu (per capita): Norwegia, Islandia, Canada, Luxemburg
-- najmniej prądu globalnie (per capita) zużywa: Haiti, Cambodia, Eritrea, Ethiopia, Benin 
--=============================================================================

-- sumaryczne zużycie prądu latami rosnąco (per capita)
select i."Year" as rok,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
group by i."Year" 
order by 1;

-- sumaryczne zużycie prądu wartościami rosnąco(per capita) 
select i."Year" as rok,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
group by i."Year" 
order by 2;

--=============================================================================
-- WNIOSEK 2: 
-- I latami i zużyciem konsumpcja globalna (per capita) rośnie 
-- - nie było globalnego spadku zużycia prądu
--=============================================================================

select i."Year" as rok, 
		c.shortname as Country, 
		i.indicatorname  as indicator_name, 
		sum(round(i.value::numeric, 1)) as produkcja  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%'
group by  i."Year" , c.shortname, i.indicatorname
order by (1,2); 


/*
Electricity production from coal sources (% of total)
Electricity production from oil, gas and coal sources (% of total)
Electricity production from hydroelectric sources (% of total)
Electricity production from natural gas sources (% of total)
Electricity production from nuclear sources (% of total)
Electricity production from oil sources (% of total)
Electricity production from renewable sources, excluding hydroelectric (kWh)
Electricity production from renewable sources, excluding hydroelectric (% of total)
 */

-- produkcja elek. z węgla  krajami
select  c.shortname as country, 
		sum(round(i.value::numeric, 1)) as produkcja_wegiel
from indicators i 
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%from coal sources (% of total)%'
group by c.shortname
order by (2) desc; 

--=============================================================================
-- WNIOSEK 3: 
-- Niestety Polska, Australia i Afryka północna przodują w prod. elek. z węgla
--=============================================================================

-- ile krajów nie produkuje z węgla
drop table wegiel;

create temp table wegiel
as
	select  c.shortname as country, 
			sum(round(i.value::numeric, 1)) as produkcja_wegiel
	from indicators i 
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%from coal sources (% of total)%'
	group by c.shortname
	having ( sum(round(i.value::numeric, 1)) =0 )
	order by (2) desc; 

select * from wegiel;

select count(*) from wegiel;
--=============================================================================
-- WNIOSEK 4: 
-- 55 krajów nie używa węgla do produkcji elektr.
--=============================================================================


-- produkcja elek. z elektr. wodnych krajami
select  c.shortname as country, 
		sum(round(i.value::numeric, 1)) as produkcja_hydro
from indicators i 
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%hydroelectric sources%'
group by c.shortname
order by (2) desc; 

--=============================================================================
-- WNIOSEK 5: 
-- W produkcji hydro przodują Norway, Iceland, Dem. Rep. Congo
--=============================================================================

-- ile krajów nie produkuje z hydro
drop table hydro;

create temp table hydro
as
	select  c.shortname as country, 
			sum(round(i.value::numeric, 1)) as produkcja_hydro
	from indicators i 
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%hydroelectric sources%'
	group by c.shortname
	having ( sum(round(i.value::numeric, 1)) =0 )
	order by (2) desc; 

select * from hydro;

select count(*) from hydro;
--=============================================================================
-- WNIOSEK 6: 
-- 17 krajów nie używa hydro do produkcji elektr.
--=============================================================================



-- produkcja elek. z ele. atom. krajami
select  c.shortname as country, 
		sum(round(i.value::numeric, 1)) as produkcja_atom
from indicators i 
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%nuclear sources%'
group by c.shortname
order by (2) desc; 

--=============================================================================
-- WNIOSEK 7: 
-- W produkcji ele. atom. przodują France, Belgium, Slovak Republic
--=============================================================================

-- ile krajów nie produkuje z ele. atom.
drop table atom;

create temp table atom
as
	select  c.shortname as country, 
			sum(round(i.value::numeric, 1)) as produkcja_atom
	from indicators i 
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%nuclear sources%'
	group by c.shortname
	having ( sum(round(i.value::numeric, 1)) =0 )
	order by (2) desc; 

select * from atom;

select count(*) from atom;
--=============================================================================
-- WNIOSEK 8: 
-- 110 krajów nie używa ele. atom. do produkcji elektr.
--=============================================================================


-- to be continued...







