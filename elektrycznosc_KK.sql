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
-- Sprawdzenie kodów związanych z elektrycznością

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


-- Sprawdzenie kto bierze udział w notowaniach
select * from country c;

-- Zauważam, że w rekordach ukrywają się zbiorcze statystyki World/ Europa itd.
-- Można je zindentyfikować przez pole alpha2code, które zawiera wtedy cyfrę.
-- Są też stowarzyszenia i frupy krajów:
-- XC, EU, XE, XD, XR, XS, XJ, ZJ, XL XO, XM, XN, ZQ, XQ, XP, XU, OE,  ZG, ZF, XT

select * from country c, 
regexp_matches(alpha2code, '[0-9]');

select * from country c
where c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF');


--=================================================================================
-- Wyciągam statystyki zbiorcze z rekordów dla regionów: World/ Europa itd.

-- Sumaryczne zużycie energi elekt. w regionach / świat
select c.shortname as Region, 
		round(sum(i.value)::numeric, 0) as zuzycie_regiony,
		regexp_matches(alpha2code, '[0-9]')
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
group by c.shortname, regexp_matches(alpha2code, '[0-9]')
order by 1 desc;


-- Sumaryczna produkcja energi elekt. w regionach / świat
select c.shortname as Region, 
		round(sum(i.value)::numeric, 0) as produkcja_regiony,
		regexp_matches(alpha2code, '[0-9]')
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%'
group by c.shortname, regexp_matches(alpha2code, '[0-9]')
order by 1 desc;

-- Sumaryczna produkcja energi elekt. w regionach / świat z podziałem na źródło

select c.shortname as Region, 
		i.indicatorname zrodlo,
		round(sum(i.value)::numeric, 0) as produkcja_regiony_zrodlami,
		regexp_matches(alpha2code, '[0-9]')
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%'
group by c.shortname, i.indicatorname, regexp_matches(alpha2code, '[0-9]')
order by 1 desc;

--=======================================================================================
-- Statystyki krajami bez regionów

-- zuzycie prądu krajami, latami
select c.shortname as Kraj, 
		i."Year" as Rok, 
		round(i.value::numeric, 1) as zuzycie
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
order by c.shortname, i."Year" ;

-- sumaryczne zuzycie prądu krajami
select c.shortname as Kraj,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
group by c.shortname 
order by c.shortname;

-- sumaryczne zuzycie prądu krajami od największych
select c.shortname as Kraj,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
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
where lower(i.indicatorname) like '%electric power cons%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
group by i."Year" 
order by 1;

-- sumaryczne zużycie prądu wartościami rosnąco(per capita) 
select i."Year" as rok,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
group by i."Year" 
order by 2;

--=============================================================================
-- WNIOSEK 2: 
-- I latami i zużyciem konsumpcja globalna (per capita) rośnie 
-- - nie było globalnego spadku zużycia prądu
--=============================================================================

-- pordukcja z różnych źródeł krajami i latami
drop table prod_roczna_krajami;

create temp table prod_roczna_krajami
as
select i."Year" as rok, 
		c.shortname as Country, 
		sum(round(i.value::numeric, 1)) as produkcja  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%' 
								and lower(i.indicatorname) not like '%kwh%'
								and c.alpha2code !~ '[%0-9%]' 
								and c.alpha2code !~'[X%]' 
								and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')						
group by  i."Year" , c.shortname
order by (1,2); 

select * from prod_roczna_krajami;

-- produkcja roczna krajami rodzaje
drop table prod_roczna_krajami_zrodla;

create temp table prod_roczna_krajami_zrodla
as
select i."Year" as rok, 
		c.shortname as Country, 
		i.indicatorname as Zrodlo,
		sum(round(i.value::numeric, 1)) as produkcja  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electricity prod%' 
								and lower(i.indicatorname) not like '%kwh%'
								and c.alpha2code !~ '[%0-9%]' 
								and c.alpha2code !~'[X%]' 
								and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
group by  i."Year" , c.shortname, i.indicatorname
order by (1,2,3); 

select * from prod_roczna_krajami_zrodla;

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
where lower(i.indicatorname) like '%from coal sources (% of total)%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
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
	where lower(i.indicatorname) like '%from coal sources (% of total)%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
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
where lower(i.indicatorname) like '%hydroelectric sources%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
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
	where lower(i.indicatorname) like '%hydroelectric sources%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
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
where lower(i.indicatorname) like '%nuclear sources%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
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
	where lower(i.indicatorname) like '%nuclear sources%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
	group by c.shortname
	having ( sum(round(i.value::numeric, 1)) =0 )
	order by (2) desc; 

select * from atom;

select count(*) from atom;
--=============================================================================
-- WNIOSEK 8: 
-- 110 krajów nie używa ele. atom. do produkcji elektr.
--=============================================================================

-- =====================================================
-- Statystylo średnich / mody


create temp table sr_zuzycie
as
	select c.shortname as Kraj,  sum(round(i.value::numeric, 1)) as zuzycie  
	from indicators i
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%electric power cons%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
	group by c.shortname 
	order by 2 desc;

-- wyznaczanie średniego i mody zużycia 
select round(avg(zuzycie),1) as srednie_zuzycie,
	   mode() within group (order by zuzycie) as moda_zuzycia
from sr_zuzycie;

-- wyznaczanie średniej i mody produkcji
drop table sr_prod;
create temp table sr_prod
as
	select c.shortname as Kraj,  sum(round(i.value::numeric, 1)) as produkcja  
	from indicators i
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%electricity production%' and c.alpha2code !~ '[%0-9%]' and c.alpha2code !~'[X%]' and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF')
	group by c.shortname 
	order by 2 desc;

select round(avg(produkcja),1) as srednia_produkcja,
	   mode() within group (order by produkcja) as moda_produkcji
from sr_prod;

-- to be continued...






