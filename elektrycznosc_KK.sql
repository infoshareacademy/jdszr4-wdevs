-- Zadanie 1 - 

/*
 
 Wstępna analiza:
- najwięksi producenci energii elektrycznej,
- najwięksi zużywający energię elektryczną,
- najlepsi / najgorsi w produkcji vs. zużycie energii elektrycznej,
- przyrosty zużycia,
- przyrosty produkcji.

*/

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
-- najwięcej globalnie zużywa prądu: Norwegia, Islandia, Canada, Luxemburg
-- najmniej prądu globalnie zużywa: Haiti, Cambodia, Eritrea, Ethiopia, Benin 
--=============================================================================

-- sumaryczne zużycie prądu latami rosnąco
select i."Year" as rok,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
group by i."Year" 
order by 1;

-- sumaryczne zużycie prądu wartościami rosnąco
select i."Year" as rok,  sum(round(i.value::numeric, 1)) as zuzycie  
from indicators i
join country c on i.countrycode = c.countrycode
where lower(i.indicatorname) like '%electric power cons%'
group by i."Year" 
order by 2;

--=============================================================================
-- WNIOSEK 2: 
-- I latami i zużyciem konsumpcja globalna rośnie - nie było globalnego spadku zużycia prądu

--=============================================================================









