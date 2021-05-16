/*
TEMAT: Analiza zużycia / produkcji energii elektrycznej.
	
Zakres lat: 1960 - 2012
**/
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

/*
 Zakres wskaźników:
	- Electric power consumption (kWh per capita)
	- Electricity production from coal sources (% of total)
	- Electricity production from oil, gas and coal sources (% of total)
	- Electricity production from hydroelectric sources (% of total)
	- Electricity production from nuclear sources (% of total)
	- Electricity production from renewable sources, excluding hydroelectric (% of total)
*/
--=============================================================================

-- Sprawdzenie kto bierze udział w notowaniach
select * from country c;

-- Zauważam, że w rekordach ukrywają się zbiorcze statystyki World/ Europa itd.
-- Można je zindentyfikować przez pole alpha2code, które zawiera wtedy cyfrę.
-- Są też stowarzyszenia i frupy krajów:
-- XC, EU, XE, XD, XR, XS, XJ, ZJ, XL XO, XM, XN, ZQ, XQ, XP, XU, OE,  ZG, ZF, XT
-- niektóre dane w kWh inne w %

--regiony
select * from country c, 
regexp_matches(alpha2code, '[0-9]');

--kraje
select * from country c
where c.alpha2code !~ '[%0-9%]' 
		and c.alpha2code !~'[X%]' 
		and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF');


--=================================================================================

-- Wyciągam dla orientacji statystyki zbiorcze z rekordów dla regionów: World/ Europa itd.

-- Średnie zużycie energi elekt. w regionach / świat
select c.shortname as Region, 
		round(avg(i.value)::numeric, 0) as zuzycie_regiony,
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

--średnie zuzycie z podzialem na 10 lat
select min(i."Year") from indicators i; --1960
select max(i."Year") from indicators i; --2013

drop table dziesiatki;
create temp table dziesiatki
as
	select 	avg(round(i.value::numeric, 1)) filter (where i."Year" <1970) as zuzycie_do1970,
			avg(round(i.value::numeric, 1)) filter (where i."Year">=1970 and i."Year" <1980) as zuzycie_do1980,
			avg(round(i.value::numeric, 1)) filter (where i."Year">=1980 and i."Year" <1990) as zuzycie_do1990,
			avg(round(i.value::numeric, 1)) filter (where i."Year">=1990 and i."Year" <2000) as zuzycie_do2000,
			avg(round(i.value::numeric, 1)) filter (where i."Year">=2000 and i."Year" <2010) as zuzycie_do2010,
			avg(round(i.value::numeric, 1)) filter (where i."Year">=2010 and i."Year" <2013) as zuzycie_do2013
	from indicators i
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%electric power cons%' 
								and c.alpha2code !~ '[%0-9%]' 
								and c.alpha2code !~'[X%]' 
								and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF');
select * from dziesiatki;


--=============
-- WNIOSEK 1: Największe średnie globalne zużycie w latach 2000-2010, najmniejsze w latach 1960-1970


--=====================================================================================

-- Właściwe statystyki - Zużycie energii elektrycznej

--=====================================================================================

-- Tab. pomocnicza
drop table zuzycie_krajami;
create temp table zuzycie_krajami
as
	select c.shortname as kraj, 
			i."Year" as rok,
			round(i.value::numeric, 1) as zuzycie,
			lag(round(i.value::numeric, 1)) over (partition by c.shortname order by c.shortname, i."Year") zuzycie_prev
	from indicators i
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%electric power cons%' 
								and c.alpha2code !~ '[%0-9%]' 
								and c.alpha2code !~'[X%]' 
								and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF') 
	group by kraj, rok, zuzycie
	order by 1, 2;
select * from zuzycie_krajami;

-- Przyrosty zuzycia procentowe krajami/latami
drop table przyrosty_procentowe;
create temp table przyrosty_procentowe
as
	select kraj, 
			rok,
			zuzycie,
			zuzycie_prev,
			round((zuzycie - zuzycie_prev)/ zuzycie_prev, 3)*100 as procentowy_wzost_zuzycia
	from zuzycie_krajami;
select * from przyrosty_procentowe;

-- Kraj z największym przyrostem zuzycia
select kraj,
		rok,
		procentowy_wzost_zuzycia as maksymalny_wzrost
from przyrosty_procentowe
where procentowy_wzost_zuzycia = (select max(procentowy_wzost_zuzycia) from przyrosty_procentowe);

-- Kraj z największym ujemnym przyrostem zuzycia
select kraj,
		rok,
		procentowy_wzost_zuzycia as minimalny_wzrost
from przyrosty_procentowe
where procentowy_wzost_zuzycia = (select min(procentowy_wzost_zuzycia) from przyrosty_procentowe);


--=============
-- WNIOSEK 2: Kraj z najwększym przyrostem zyżycia: Bahrain w 1984 roku - (173.7%)
--			  Kraj z najwększym spadkiem zyżycia: Angola w 1976 roku - (-56%)	

drop table percentyle;
create temp table percentyle
as
	select	rok,
			percentile_disc(0.95) within group (order by procentowy_wzost_zuzycia) q95,
			percentile_disc(0.5) within group (order by procentowy_wzost_zuzycia) q50,
			percentile_disc(0.05) within group (order by procentowy_wzost_zuzycia) q5
	from przyrosty_procentowe
	group by 1;
select * from percentyle;

drop table naj;
create temp table naj
as
	select  distinct o.kraj,
			o.rok,
			procentowy_wzost_zuzycia			
			case when procentowy_wzost_zuzycia >= q50 then 1 else 0 end czy_w_q50,
			case when procentowy_wzost_zuzycia >= q95 then 1 else 0 end czy_w_q95,
			case when procentowy_wzost_zuzycia <= q5 then 1 else 0 end czy_w_q5
	from przyrosty_procentowe o
	cross join percentyle;

select * from naj;

select o.kraj,
	   sum(o.czy_w_q95) as suma95
from naj o 
group by o.kraj
order by 2 desc;

--=============
-- WNIOSEK 3: Kraje, które najwięcej razy mieściły się w 95% wielkości wzrostów: Indonesia (23), Vietnam(22), Korea(20)


select o.kraj,
	   sum(o.czy_w_q5) as suma5
from naj o 
group by o.kraj
order by 2 desc;

--=============
-- WNIOSEK 4: Kraje, które najwięcej razy mieściły się w 5% wielkości wzrostów: Switzerland(46), United Kingdom(44), Canada(41), United States(39), Zambia(38!)


	
-- zuzycie roczne bez podziału na kraje
drop table zuzycie_roczne_swiat;
create temp table zuzycie_roczne_swiat
as
	select 	i."Year" as rok,
			round(i.value::numeric, 1) as zuzycie_roczne,
			lag(round(i.value::numeric, 1)) over (partition by  i."Year") zuzycie_prev_roczne
	from indicators i
	join country c on i.countrycode = c.countrycode
	where lower(i.indicatorname) like '%electric power cons%' 
								and c.alpha2code !~ '[%0-9%]' 
								and c.alpha2code !~'[X%]' 
								and c.alpha2code not in ('EU', 'ZJ', 'ZQ', 'OE', 'ZG', 'ZF') 
	group by rok, zuzycie_roczne
	order by 1;


drop table srednie;
create temp table  srednie 
as
	select rok, 
		round(avg(zuzycie_roczne)::numeric, 2) avg_zuzycie_roczne,
		round(avg(zuzycie_prev_roczne)::numeric, 2) avg_zuzycie_prev_roczne		
	from zuzycie_roczne_swiat 
	group by rok;
select * from srednie;

select rok,
		round((avg_zuzycie_roczne - avg_zuzycie_prev_roczne)/avg_zuzycie_prev_roczne,2)*100 as zuzycie_roczne_procentowe
from srednie
order by 2 desc;


--=============
-- WNIOSEK 5: Największe przyrosty średniego zużycia globalnie były w 1965, 1961, 1962 i 1968










