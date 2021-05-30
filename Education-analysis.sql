/*1)	Gross intake ratio in first grade of primary education, female (% of relevant age group)*/
create temp table Gross_intake_1grade_female
as
select 	distinct i.countryname
,		i."Year" 
,		i.value
,		round(lag(i.value) over (partition by i.countryname order by i."Year")::numeric,2) previous_year
,		round(((i.value - lag(i.value) over (partition by i.countryname order by i."Year"))/
		lag(i.value) over (partition by i.countryname order by i."Year"))::numeric,2) YoY_value
from indicators i
join country c on i.countrycode = c.countrycode 
where c.region is not null and c.region <> '' and indicatorcode = 'SE.PRM.GINT.FE.ZS'
group by i.countryname, i."Year", i.value;

select * from Gross_intake_1grade_female;

/*2)	Gross intake ratio in first grade of primary education, male (% of relevant age group)*/
create temp table Gross_intake_1grade_male
as
select 	distinct i.countryname
,		i."Year" 
,		i.value
,		round(lag(i.value) over (partition by i.countryname order by i."Year")::numeric,2) previous_year
,		round(((i.value - lag(i.value) over (partition by i.countryname order by i."Year"))/
lag(i.value) over (partition by i.countryname order by i."Year"))::numeric,2) YoY_value
from indicators i
join country c on i.countrycode = c.countrycode 
where c.region is not null and c.region <> '' and indicatorcode = 'SE.PRM.GINT.MA.ZS'
group by i.countryname, i."Year", i.value;

select * from Gross_intake_1grade_male;

/*3)	Gross intake ratio in first grade of primary education, total (% of relevant age group)
 * Porównanie wartoœci dla kobiet, mê¿czyzn oraz dla kobiet i mê¿czyzn ³¹cznie.
 * WskaŸnik reprezentuje stosunek osób przyjêtych do pierwszej klasy szko³y podstawowej do grupy dzieci w wieku szkolnym, 
 * które powinny rozpocz¹æ edukacjê w danym roku.
 */ 
create temp table Gross_intake_1grade_total
as
select 	distinct i.countryname
,		i."Year" 
,		i.value
,		round(lag(i.value) over (partition by i.countryname order by i."Year")::numeric,2) previous_year
,		round(((i.value - lag(i.value) over (partition by i.countryname order by i."Year"))/
lag(i.value) over (partition by i.countryname order by i."Year"))::numeric,2) YoY_value
from indicators i
join country c on i.countrycode = c.countrycode 
where c.region is not null and c.region <> '' and indicatorcode = 'SE.PRM.GINT.ZS'
group by i.countryname, i."Year", i.value;


select * from Gross_intake_1grade_female;
select * from Gross_intake_1grade_male;
select * from Gross_intake_1grade_total;

select 
		f.countryname 
,		f."Year"
,		round(f.value::numeric,2) as female
,		round(m.value::numeric,2) as male
,		round(t.value::numeric,2) as total_f_m
from Gross_intake_1grade_female f
join Gross_intake_1grade_male m on f.countryname = m.countryname and f."Year" = m."Year"
join Gross_intake_1grade_total t on f.countryname = t.countryname and f."Year" = t."Year";



/* Dekady
 * Poniewa¿ dla niektórych lat i krajów posiadane dane s¹ niekompletne, postanowiono dokonaæ analizy w dekadach
 */

create table decades
as
select distinct i."Year"
,		concat((i."Year"/10),'0') as decade_start_date
,		concat((i."Year"/10)::varchar,'0')::numeric + 9 as decade_end_date
,		substring(cast(i."Year" as varchar),3,1) as decade
,		substring(cast(i."Year" as varchar),1,2)::numeric + 1 as century
from indicators i
order by i."Year";

select * from decades;

/* Gender gaps per dekada
 * Pokazuje ró¿nicê miêdzy przyjêciem do szko³y podstawowej kobiet i mê¿czyzn per rok i dekada.*/

create temp table Gender_gaps
as
select 
		c.region
,		f.countryname 
,		d.century
,		d.decade
,		f."Year"
,		f.value as female
,		m.value as male
,		m.value - f.value as gender_gap
from Gross_intake_1grade_female f
join Gross_intake_1grade_male m on f.countryname = m.countryname and f."Year" = m."Year"
join Gross_intake_1grade_total t on f.countryname = t.countryname and f."Year" = t."Year"
join country c on f.countryname = c.tablename
join decades d on f."Year" = d."Year"
group by c.region
,		f.countryname 
,		d.century 
,		d.decade 
,		f."Year"
,		f.value
,		m.value
order by f.countryname, d.century, d.decade;


select * from gender_gaps gp;
/*where gp.gender_gap = gp.min_gender_gap or gp.gender_gap = gp.max_gender_gap*/

-----------------------
/*Podzia³ w dekadach*/
/*select distinct
		gp.region
,		gp.countryname
,		gp.century
,		gp.decade
,		min(gp.gender_gap) over (partition by gp.decade, gp.countryname)
,		max(gp.gender_gap) over (partition by gp.decade, gp.countryname)
from gender_gaps gp
order by gp.countryname, gp.century, gp.decade;

select * from gender_gaps;*/

-----------------------------
/*Pokazuje œredni¹, min oraz max gender gap per kraj oraz dekadê*/

create temp table gender_gaps_basic_measures
as
select distinct
		gp.region
,		gp.countryname
,		gp.century
,		gp.decade
,		avg(gp.gender_gap) over (partition by gp.decade, gp.countryname) as avg_gap_country_and_decade
,		min(gp.gender_gap) over (partition by gp.decade, gp.countryname) as min_gap_country_and_decade
,		max(gp.gender_gap) over (partition by gp.decade, gp.countryname) as max_gap_country_and_decade
from gender_gaps gp
order by gp.region, gp.century, gp.decade;

select * from gender_gaps_basic_measures

select 
		gpm.region
,		gpm.countryname
,		gpm.century
,		gpm.decade
,		gpm.avg_gap_country_and_decade
,		(select min(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm)
,		(select max(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm)
from gender_gaps_basic_measures gpm
where gpm.avg_gap_country_and_decade = (select min(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm)
		or gpm.avg_gap_country_and_decade = (select max(gpm.avg_gap_country_and_decade) from gender_gaps_basic_measures gpm);

/* Na przestrzeni lat, najwiêksza dysproporcja ze wzglêdu na p³eæ wyst¹pi³a w Bhutanie oraz Lesotho w latach 70tych ubieg³ego wieku.
 * W Buthanie przyjêto do pierwszej klasy o 64 pkt procentowe wiêcej ch³opców ni¿ dziewczynech, 
 * podczas gdy w Lesotho o 20 pkt procentowych wiêcej dziewczynek ni¿ ch³opców.
 */


/*Pokazuje œredni¹ gender gap per kraj oraz wiek*/

create temp table gender_gaps_basic_measures2
as
select distinct
		gp.region
,		gp.countryname
,		gp.century
,		gp.decade
,		avg(gp.gender_gap) over (partition by gp.decade, gp.countryname) as avg_gap_country_and_decade
from gender_gaps gp
order by gp.region, gp.century, gp.decade;

select * from gender_gaps_basic_measures2;

/*ranking per century i decade - top 3
 * Pokazuje ranking per kraj i dekada w obrêbie regionu - wartoœæ bezwzglêdna - im bli¿ej zera tym kraj bardziej rozwiniêty */
create temp table ranking_top_3
as
select gpm2.region, gpm2.countryname, gpm2.century, gpm2.decade, abs(gpm2.avg_gap_country_and_decade) as wartosc_bezwzgledna
,	dense_rank() over(partition by gpm2.region, gpm2.century, gpm2.decade order by abs(gpm2.avg_gap_country_and_decade))  as ranking
,	count(*) over (partition by gpm2.countryname) liczba_wystapien
from gender_gaps_basic_measures2 gpm2;

select * from ranking_top_3;

select *
from ranking_top_3 r3
where r3.ranking <= 3;

-----------------------------------
/*sytuacja krajów dla których mamy dane conajmniej dla 3 dekad*/

select 
		r3.region
,		r3.countryname
,		r3.countryname
,		r3.century
,		r3.decade
,		r3.wartosc_bezwzgledna
,		r3.ranking
from ranking_top_3 r3
where r3.liczba_wystapien >= '3'
group by r3.region, r3.countryname, r3.century, r3.decade, r3.wartosc_bezwzgledna, r3.ranking, r3.liczba_wystapien
order by r3.region, r3.countryname, r3.century, r3.decade;

--Punkty
/*select 
		r3.region
,		r3.countryname
,		r3.century
,		r3.decade
,		r3.wartosc_bezwzgledna
,		r3.ranking
,		avg(r3.ranking) over (partition by r3.countryname, r3.century)
from ranking_top_3 r3
where r3.liczba_wystapien >= '3'
group by r3.region, r3.countryname, r3.century, r3.decade, r3.wartosc_bezwzgledna, r3.ranking, r3.liczba_wystapien
order by r3.region, r3.countryname, r3.century, r3.decade;*/


/* Analiza poni¿ej pokazuje ruchy w rankingu na przestrzeni dwóch ostatnich wieków - wielkoœæ gender gap. 
 * Pokazuje wzmocnienie lub os³abienie danego kraju w obrêbie regionu.
 * Ranking nie bie¿e pod uwagê ró¿nic w wielkoœci populacji w poszczególnych krajach*/
 /* Tabela Punkty_20 pokazuje œrednie miejsce w rankinu w 20 wieku per kraj w regionie - dla wykazania tendencji*/

create temp table Punkty_20
as
select distinct
		r3.region
,		r3.countryname
,		r3.century
,		avg(r3.ranking) over (partition by r3.countryname, r3.century) as avg_ranking_20_century
from ranking_top_3 r3
where r3.liczba_wystapien >= '3' and r3.century = 20
group by r3.region, r3.countryname, r3.century, r3.ranking
order by r3.region, r3.countryname, r3.century;

select * from Punkty_20;

/*Tabela Punkty_21 pokazuje œrednie miejsce w rankinu w 21 wieku per kraj w regionie - dla wykazania tendencji*/
create temp table Punkty_21
as
select distinct
		r3.region
,		r3.countryname
,		r3.century
,		avg(r3.ranking) over (partition by r3.countryname, r3.century) as avg_ranking_21_century
from ranking_top_3 r3
where r3.liczba_wystapien >= '3' and r3.century = 21
group by r3.region, r3.countryname, r3.century, r3.ranking
order by r3.region, r3.countryname, r3.century;

select 
	p20.region
,	p20.countryname
,	round(p20.avg_ranking_20_century,2) as century_20
,	round(p21.avg_ranking_21_century,2) as century_21
,	round((p20.avg_ranking_20_century - p21.avg_ranking_21_century),2) as progress
from Punkty_20 p20
join punkty_21 p21 on p20.countryname = p21.countryname
order by p20.region, round((p20.avg_ranking_20_century - p21.avg_ranking_21_century),2);

/* East Asia & Pacific: najwiêkszy spadek wyst¹pi³ w Malezji, 
 * w miarê podobne tempo rozmowu maj¹ Tajlandia, Tonga, Mongolia, Myanmar oraz Filipiny.
 * Japonia zarówno w 20 wieku jak i w 21 sta³a na czele rankingu.
 * Najwiêkszy skok w przód natomiast wyst¹pi³ na Wyspach Marshalla.
 * 
 * Europe & Central Asia: najwiêkszy spadek wyst¹pi³ w Gruzji, W³oszech oraz na Cyprze.
 * Najwiêkszy wzrost natomiast na Bia³orusi i w Irlandii.
 * Nale¿y jednak zauwa¿yæ, ¿e w Europie ró¿nice pomiêdzy dostêpem do edukacji wœród kobie i mê¿czyzn s¹ nieznaczne.
 * 
 * Latin America & Caribbean: Najwiêkszy spadek wyst¹pi³ w Kolumbii, z pierwszej dziesi¹tki w 20 wieku spad³a w okolice 29 pozycji.
 * Podobny spadek odnotowano w Nikaragui, nieco mniejszu na Dominikania, St.Lucia, Trinidad i Tobago.
 * Najwiêkszy wzrost wyst¹pi³ na Dominice, w Arubii i Meksyku.
 * 
 * Middle East & North Africa: Najwiêkszy spadek wyst¹pi³ w Katarze, z okolic 5 miejsca spad³ w okolice 13.
 * Spadek w rankingu odnotowano równie¿ na Malcie i w Libanie.
 * Najwiêkszy progres odnotowano w Iranie, Maroku oraz Tunezji.
 * 
 * North America: Trudno mówiæ o wzrostach i spadkach. Na przestrzeni wieków sytuacja nie zmienila siê zbytnio.
 * 
 * South Asia: Najwiêkszy spadek wyst¹pi³ w Afganistanie, z œrednio czwartego miejsca spad³ w okolice 7-8. Butan natomiast z okolic 4 wskoczy³ na 2.
 * 
 * Sub-Saharan Africa: Najwiêkszy spadek odnotowano w Suazi, Nigerze i Kamerunie. Najwiêkszy wzrost z Gambii, Ugandzie i Ghanie. 
*/
----------------------------------------------------------