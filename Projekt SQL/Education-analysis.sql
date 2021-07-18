/*1)	Gross intake ratio in first grade of primary education, female (% of relevant age group)*/
CREATE TEMP TABLE Gross_intake_1grade_female AS
SELECT DISTINCT i.countryname,
  i."Year",
  i.value,
  round(LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year")::NUMERIC, 2) previous_year,
  round(((i.value - LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))/ LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))::NUMERIC, 2) YoY_value
FROM
  indicators i
JOIN country c ON 
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.GINT.FE.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;

SELECT
  *
FROM Gross_intake_1grade_female;

/*2)	Gross intake ratio in first grade of primary education, male (% of relevant age group)*/
CREATE TEMP TABLE Gross_intake_1grade_male AS
SELECT
  DISTINCT i.countryname,
  i."Year",
  i.value,
  round(LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year")::NUMERIC, 2) previous_year,
  round(((i.value - LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))/ LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))::NUMERIC, 2) YoY_value
FROM
  indicators i
JOIN country c ON
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.GINT.MA.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;

SELECT
  *
FROM
  Gross_intake_1grade_male;

/*3)	Gross intake ratio in first grade of primary education, total (% of relevant age group)
 * Porównanie wartoœci dla kobiet, mê¿czyzn oraz dla kobiet i mê¿czyzn ³¹cznie.
 * WskaŸnik reprezentuje stosunek osób przyjêtych do pierwszej klasy szko³y podstawowej do grupy dzieci w wieku szkolnym, 
 * które powinny rozpocz¹æ edukacjê w danym roku.
 */ 
CREATE TEMP TABLE Gross_intake_1grade_total AS
SELECT
  DISTINCT i.countryname,
  i."Year",
  i.value,
  round(LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year")::NUMERIC, 2) previous_year,
  round(((i.value - LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))/ LAG(i.value) OVER (PARTITION BY i.countryname ORDER BY i."Year"))::NUMERIC, 2) YoY_value
FROM
  indicators i
JOIN country c ON
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.GINT.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;


SELECT
  *
FROM
  Gross_intake_1grade_female;

SELECT
  *
FROM
  Gross_intake_1grade_male;

SELECT
  *
FROM
  Gross_intake_1grade_total;

SELECT
  f.countryname,
  f."Year",
  round(f.value::NUMERIC, 2) AS female,
  round(m.value::NUMERIC, 2) AS male,
  round(t.value::NUMERIC, 2) AS total_f_m
FROM
  Gross_intake_1grade_female f
JOIN Gross_intake_1grade_male m ON
  f.countryname = m.countryname
  AND f."Year" = m."Year"
JOIN Gross_intake_1grade_total t ON
  f.countryname = t.countryname
  AND f."Year" = t."Year";



/* Dekady
 * Poniewa¿ dla niektórych lat i krajów posiadane dane s¹ niekompletne, postanowiono dokonaæ analizy w dekadach
 */

CREATE TABLE decades AS
SELECT
  DISTINCT i."Year",
  concat((i."Year" / 10), '0') AS decade_start_date,
  concat((i."Year" / 10)::varchar, '0')::NUMERIC + 9 AS decade_end_date,
  substring(CAST(i."Year" AS varchar), 3, 1) AS decade,
  substring(CAST(i."Year" AS varchar), 1, 2)::NUMERIC + 1 AS century
FROM
  indicators i
ORDER BY
  i."Year";

SELECT
  *
FROM
  decades;

/* Gender gaps per dekada
 * Pokazuje ró¿nicê miêdzy przyjêciem do szko³y podstawowej kobiet i mê¿czyzn per rok i dekada.*/

CREATE TEMP TABLE Gender_gaps AS
SELECT
  c.region,
  f.countryname,
  d.century,
  d.decade,
  f."Year",
  f.value AS female,
  m.value AS male,
  m.value - f.value AS gender_gap
FROM
  Gross_intake_1grade_female f
JOIN Gross_intake_1grade_male m ON
  f.countryname = m.countryname
  AND f."Year" = m."Year"
JOIN Gross_intake_1grade_total t ON
  f.countryname = t.countryname
  AND f."Year" = t."Year"
JOIN country c ON
  f.countryname = c.tablename
JOIN decades d ON
  f."Year" = d."Year"
GROUP BY
  c.region,
  f.countryname,
  d.century,
  d.decade,
  f."Year",
  f.value,
  m.value
ORDER BY
  f.countryname,
  d.century,
  d.decade;


SELECT
  *
FROM
  gender_gaps gp;
/*where gp.gender_gap = gp.min_gender_gap or gp.gender_gap = gp.max_gender_gap*/


/*Pokazuje œredni¹, min oraz max gender gap per kraj oraz dekadê*/

CREATE TEMP TABLE gender_gaps_basic_measures AS
SELECT
  DISTINCT gp.region,
  gp.countryname,
  gp.century,
  gp.decade,
  avg(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS avg_gap_country_and_decade,
  min(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS min_gap_country_and_decade,
  max(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS max_gap_country_and_decade
FROM
  gender_gaps gp
ORDER BY
  gp.region,
  gp.century,
  gp.decade;

SELECT
  *
FROM
  gender_gaps_basic_measures;

SELECT
  gpm.region,
  gpm.countryname,
  gpm.century,
  gpm.decade,
  gpm.avg_gap_country_and_decade,
  (
    SELECT
      min(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  ) ,
  (
    SELECT
      max(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  )
FROM
  gender_gaps_basic_measures gpm
WHERE
  gpm.avg_gap_country_and_decade = (
    SELECT
      min(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  )
  OR gpm.avg_gap_country_and_decade = (
    SELECT
      max(gpm.avg_gap_country_and_decade)
    FROM
      gender_gaps_basic_measures gpm
  );

/* Na przestrzeni lat, najwiêksza dysproporcja ze wzglêdu na p³eæ wyst¹pi³a w Bhutanie oraz Lesotho w latach 70tych ubieg³ego wieku.
 * W Buthanie przyjêto do pierwszej klasy o 64 pkt procentowe wiêcej ch³opców ni¿ dziewczynech, 
 * podczas gdy w Lesotho o 20 pkt procentowych wiêcej dziewczynek ni¿ ch³opców.
 */


/*Pokazuje œredni¹ gender gap per kraj oraz wiek*/

CREATE TEMP TABLE gender_gaps_basic_measures2 AS
SELECT
  DISTINCT gp.region,
  gp.countryname,
  gp.century,
  gp.decade,
  avg(gp.gender_gap) OVER (
    PARTITION BY gp.decade,
    gp.countryname
  ) AS avg_gap_country_and_decade
FROM
  gender_gaps gp
ORDER BY
  gp.region,
  gp.century,
  gp.decade;

SELECT
  *
FROM
  gender_gaps_basic_measures2;

/*ranking per century i decade - top 3
 * Pokazuje ranking per kraj i dekada w obrêbie regionu - wartoœæ bezwzglêdna - im bli¿ej zera tym kraj bardziej rozwiniêty */
CREATE TEMP TABLE ranking_top_3 AS
SELECT
  gpm2.region,
  gpm2.countryname,
  gpm2.century,
  gpm2.decade,
  abs(gpm2.avg_gap_country_and_decade) AS wartosc_bezwzgledna,
  DENSE_RANK() OVER(
    PARTITION BY gpm2.region,
    gpm2.century,
    gpm2.decade
  ORDER BY
    abs(gpm2.avg_gap_country_and_decade)
  ) AS ranking,
  count(*) OVER (
    PARTITION BY gpm2.countryname
  ) liczba_wystapien
FROM
  gender_gaps_basic_measures2 gpm2;

SELECT
  *
FROM
  ranking_top_3;

SELECT
  *
FROM
  ranking_top_3 r3
WHERE
  r3.ranking <= 3;

-----------------------------------
/*sytuacja krajów dla których mamy dane conajmniej dla 3 dekad*/

SELECT
  r3.region,
  r3.countryname,
  r3.countryname,
  r3.century,
  r3.decade,
  r3.wartosc_bezwzgledna,
  r3.ranking
FROM
  ranking_top_3 r3
WHERE
  r3.liczba_wystapien >= '3'
GROUP BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.decade,
  r3.wartosc_bezwzgledna,
  r3.ranking,
  r3.liczba_wystapien
ORDER BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.decade;

/* Analiza poni¿ej pokazuje ruchy w rankingu na przestrzeni dwóch ostatnich wieków - wielkoœæ gender gap. 
 * Pokazuje wzmocnienie lub os³abienie danego kraju w obrêbie regionu.
 * Ranking nie bie¿e pod uwagê ró¿nic w wielkoœci populacji w poszczególnych krajach*/
 /* Tabela Punkty_20 pokazuje œrednie miejsce w rankinu w 20 wieku per kraj w regionie - dla wykazania tendencji*/

CREATE TEMP TABLE Punkty_20 AS
SELECT
  DISTINCT r3.region,
  r3.countryname,
  r3.century,
  avg(r3.ranking) OVER (
    PARTITION BY r3.countryname,
    r3.century
  ) AS avg_ranking_20_century
FROM
  ranking_top_3 r3
WHERE
  r3.liczba_wystapien >= '3'
  AND r3.century = 20
GROUP BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.ranking
ORDER BY
  r3.region,
  r3.countryname,
  r3.century;

SELECT
  *
FROM
  Punkty_20;

/*Tabela Punkty_21 pokazuje œrednie miejsce w rankinu w 21 wieku per kraj w regionie - dla wykazania tendencji*/
CREATE TEMP TABLE Punkty_21 AS
SELECT
  DISTINCT r3.region,
  r3.countryname,
  r3.century,
  avg(r3.ranking) OVER (
    PARTITION BY r3.countryname,
    r3.century
  ) AS avg_ranking_21_century
FROM
  ranking_top_3 r3
WHERE
  r3.liczba_wystapien >= '3'
  AND r3.century = 21
GROUP BY
  r3.region,
  r3.countryname,
  r3.century,
  r3.ranking
ORDER BY
  r3.region,
  r3.countryname,
  r3.century;

SELECT
  p20.region,
  p20.countryname,
  round(p20.avg_ranking_20_century, 2) AS century_20,
  round(p21.avg_ranking_21_century, 2) AS century_21,
  round((p20.avg_ranking_20_century - p21.avg_ranking_21_century), 2) AS progress
FROM
  Punkty_20 p20
JOIN punkty_21 p21 ON
  p20.countryname = p21.countryname
ORDER BY
  p20.region,
  round((p20.avg_ranking_20_century - p21.avg_ranking_21_century), 2);

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
 
 /*4)	Net intake rate in grade 1, female (% of official school-age population)*/
DROP TABLE Net_intake_1grade_female;

CREATE TEMP TABLE Net_intake_1grade_female AS
SELECT DISTINCT 
  i.countryname,
  i."Year",
  i.value
FROM
  indicators i
JOIN country c ON
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.NINT.FE.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;

SELECT 
  *
FROM
  Net_intake_1grade_female;

/*5)	Net intake rate in grade 1, male (% of official school-age population)*/
DROP TABLE Net_intake_1grade_male;

CREATE TEMP TABLE Net_intake_1grade_male AS
SELECT
  DISTINCT i.countryname,
  i."Year",
  i.value
FROM
  indicators i
JOIN country c ON
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.NINT.MA.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;

SELECT
  *
FROM
  Net_intake_1grade_male;

/*6)	Net intake rate in grade 1 (% of official school-age population)*/
DROP TABLE Net_intake_1grade_total;

CREATE TEMP TABLE Net_intake_1grade_total AS
SELECT
  DISTINCT i.countryname,
  i."Year",
  i.value
FROM
  indicators i
JOIN country c ON
  i.countrycode = c.countrycode
WHERE
  c.region IS NOT NULL
  AND c.region <> ''
  AND indicatorcode = 'SE.PRM.NINT.ZS'
GROUP BY
  i.countryname,
  i."Year",
  i.value;


SELECT
	*
FROM
	Net_intake_1grade_female;

SELECT
	*
FROM
	Net_intake_1grade_male;

SELECT
	*
FROM
	Net_intake_1grade_total;

/*Ogóle zestawienie Net intake to 1st grade*/

DROP TABLE IF EXISTS net_overview;

CREATE TEMP TABLE net_overview AS
SELECT
  c.region AS region,
  f.countryname AS country,
  d.century AS century,
  d.decade AS decade,
  f."Year" AS year,
  f.value AS female,
  m.value AS male,
  t.value AS total
FROM
  Net_intake_1grade_female f
JOIN Net_intake_1grade_male m ON
  f.countryname = m.countryname
  AND f."Year" = m."Year"
JOIN Net_intake_1grade_total t ON
  f.countryname = t.countryname
  AND f."Year" = t."Year"
JOIN country c ON
  f.countryname = c.tablename
JOIN decades d ON
  f."Year" = d."Year";

SELECT
	*
FROM
	net_overview;

/*Wartoœci minimalne*/

SELECT
  n.region,
  n.country,
  n.century,
  n.decade,
  n.YEAR,
  female AS min_female,
  male AS min_male,
  total AS min_total
FROM
  net_overview n
WHERE
  n.female = (
    SELECT
      min(n.female)
    FROM
      net_overview n
  )
  OR n.male = (
    SELECT
      min(n.male)
    FROM
      net_overview n
  )
  OR n.total = (
    SELECT
      min(n.total)
    FROM
      net_overview n
  )
GROUP BY
  n.region,
  n.country,
  n.century,
  n.decade,
  n.YEAR,
  n.female,
  n.male,
  n.total;
  
/*Wartoœci maksymalne*/

SELECT
  n.region,
  n.country,
  n.century,
  n.decade,
  n.YEAR,
  female AS max_female,
  male AS max_male,
  total AS max_total
FROM
  net_overview n
WHERE
  n.female = (
    SELECT
      max(n.female)
    FROM
      net_overview n
  )
  OR n.male = (
    SELECT
      max(n.male)
    FROM
      net_overview n
  )
  OR n.total = (
    SELECT
      max(n.total)
    FROM
      net_overview n
  )
GROUP BY
  n.region,
  n.country,
  n.century,
  n.decade,
  n.YEAR,
  n.female,
  n.male,
  n.total;

SELECT * FROM net_overview;

-----------------------------------
/*total net intake per century - ranking
 * ktore kraje najwiêkszy intake, ktore najmniejszy*/

CREATE TEMP TABLE avg_intake_total AS
SELECT
  c.region,
  f.countryname,
  d.century,
  d.decade,
  f."Year",
  t.value AS net_intake_total,
  avg(t.value) OVER (
    PARTITION BY d.decade,
    f.countryname
  ) AS avg_net_intake_total_decade
FROM
  Net_intake_1grade_female f
JOIN Net_intake_1grade_male m ON
  f.countryname = m.countryname
  AND f."Year" = m."Year"
JOIN Net_intake_1grade_total t ON
  f.countryname = t.countryname
  AND f."Year" = t."Year"
JOIN country c ON
  f.countryname = c.tablename
JOIN decades d ON
  t."Year" = d."Year"
GROUP BY
  c.region,
  f."Year",
  f.countryname,
  t.value,
  d.century,
  d.decade
ORDER BY
  c.region,
  d.century,
  d.decade;

SELECT
  *
FROM
  avg_intake_total;

CREATE TEMP TABLE worst_best_decade AS
SELECT
  a.region,
  a.countryname,
  a.century,
  a.decade,
  a.avg_net_intake_total_decade,
  DENSE_RANK() OVER(
    PARTITION BY a.region,
    a.century,
    a.decade
  ORDER BY
    a.avg_net_intake_total_decade DESC
  ) AS ranking ,
  DENSE_RANK() OVER(
    PARTITION BY a.region,
    a.century,
    a.decade
  ORDER BY
    a.avg_net_intake_total_decade
  ) AS reverse_ranking
FROM
  avg_intake_total a
GROUP BY
  a.region,
  a.countryname,
  a.avg_net_intake_total_decade,
  a.century,
  a.decade
ORDER BY
  a.region,
  a.century,
  a.decade;

SELECT
	*
FROM
	worst_best_decade w
WHERE
	ranking = 1
	OR reverse_ranking = 1;


/* 7)	Progression to secondary school, total (%)*/
DROP TABLE IF EXISTS progression_to_secondary_school_total;

CREATE TEMP TABLE progression_to_secondary_school_total AS
SELECT
	DISTINCT i.countryname,
	c.region,
	d.century,
	d.decade,
	i."Year",
	i.value
FROM
	indicators i
JOIN country c ON
	i.countrycode = c.countrycode
JOIN decades d ON
	i."Year" = d."Year"
WHERE
	c.region IS NOT NULL
	AND c.region <> ''
	AND indicatorcode = 'SE.SEC.PROG.ZS'
GROUP BY
	c.region,
	i.countryname,
	i."Year",
	i.value,
	d.century,
	d.decade
ORDER BY
	c.region,
	d.century,
	d.decade;

SELECT
	*
FROM
	progression_to_secondary_school_total;


DROP TABLE IF EXISTS progression_secondary_t;

CREATE TEMP TABLE progression_secondary_t AS
SELECT
	p.region,
	p.countryname,
	p.century,
	p.decade,
	p."Year",
	p.value AS progression_total,
	avg(p.value) OVER (
		PARTITION BY p.decade,
		p.countryname
	) AS avg_progression_total_decade
FROM
	progression_to_secondary_school_total p
GROUP BY
	p.region,
	p."Year",
	p.countryname,
	p.value,
	p.century,
	p.decade
ORDER BY
	p.region,
	p.countryname,
	p.century,
	p.decade;

SELECT
	*
FROM
	progression_secondary_t;

DROP TABLE IF EXISTS d_7;

CREATE TEMP TABLE d_7 AS
SELECT
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade AS d_7
FROM
	progression_secondary_t ps
WHERE
	ps.decade = '7'
GROUP BY
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade;


DROP TABLE IF EXISTS d_8;

CREATE TEMP TABLE d_8 AS
SELECT
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade AS d_8
FROM
	progression_secondary_t ps
WHERE
	ps.decade = '8'
GROUP BY
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade;

DROP TABLE IF EXISTS d_9;
CREATE TEMP TABLE d_9 AS
SELECT
	ps.region,
	ps.countryname,	
	ps.avg_progression_total_decade AS d_9
FROM
	progression_secondary_t ps
WHERE
	ps.decade = '9'
GROUP BY
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade;
		
DROP TABLE IF EXISTS d_0;

CREATE TEMP TABLE d_0 AS
SELECT
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade AS d_0
FROM
	progression_secondary_t ps
WHERE
	ps.decade = '0'
GROUP BY
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade;

DROP TABLE IF EXISTS d_1;

CREATE TEMP TABLE d_1 AS
SELECT
	ps.region,
	ps.countryname,	
	ps.avg_progression_total_decade AS d_1
FROM
	progression_secondary_t ps
WHERE
	ps.decade = '1'
GROUP BY
	ps.region,
	ps.countryname,
	ps.avg_progression_total_decade;

SELECT * FROM d_7;
SELECT * FROM d_8;
SELECT * FROM d_9;
SELECT * FROM d_0;
SELECT * FROM d_1;

SELECT
	c.region,
	c.shortname AS countryname,
	d_7,
	d_8,
	d_9,
	d_0,
	d_1,
	round((d_1-d_7)::numeric,2) AS progress
FROM
	country c
LEFT JOIN d_7 ON
	c.shortname = d_7.countryname
LEFT JOIN d_8 ON
	c.shortname = d_8.countryname
LEFT JOIN d_9 ON
	c.shortname = d_9.countryname
LEFT JOIN d_0 ON
	c.shortname = d_0.countryname
LEFT JOIN d_1 ON
	c.shortname = d_1.countryname
WHERE
	c.region IS NOT NULL
	AND c.region <> ''
	AND d_7 IS NOT NULL 
	AND d_1 IS NOT NULL 
ORDER BY
	c.region,
	c.shortname;

/* 8) Education: Inputs
 * Government expenditure on education, total (% of GDP)*/
DROP TABLE IF EXISTS expenditures;

CREATE TEMP TABLE expenditures AS
SELECT
	i.countryname,
	c.region,
	d.century,
	d.decade,
	i."Year",
	i.value AS expenditures
FROM
	indicators i
JOIN country c ON
	i.countrycode = c.countrycode
JOIN decades d ON
	i."Year" = d."Year"
WHERE
	c.region IS NOT NULL
	AND c.region <> ''
	AND indicatorcode = 'SE.XPD.TOTL.GD.ZS'
GROUP BY
	c.region,
	i.countryname,
	i."Year",
	i.value,
	d.century,
	d.decade
ORDER BY
	c.region,
	d.century,
	d.decade;

SELECT * FROM expenditures;

DROP TABLE IF EXISTS expenditures_avg_decade;

CREATE TEMP TABLE expenditures_avg_decade AS
SELECT
	e.region,
	e.countryname,
	e.century,
	e.decade,
	e."Year",
	avg(e.expenditures) OVER (
		PARTITION BY e.decade,
		e.countryname
	) AS avg_expenditures_decade
FROM
	expenditures e
GROUP BY
	e.region,
	e."Year",
	e.countryname,
	e.expenditures,
	e.century,
	e.decade
ORDER BY
	e.region,
	e.countryname,
	e.century,
	e.decade;

SELECT
	DISTINCT ea.region,
	ea.countryname,
	ea.century,
	ea.decade,
	ea.avg_expenditures_decade
FROM
	expenditures_avg_decade ea
ORDER BY
	ea.region,
	ea.countryname,
	ea.century,
	ea.decade;



DROP TABLE IF EXISTS e_7;

CREATE TEMP TABLE e_7 AS
SELECT
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade AS e_7
FROM
	expenditures_avg_decade ea
WHERE
	ea.decade = '7'
GROUP BY
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade;

SELECT * FROM e_7;

DROP TABLE IF EXISTS e_8;

CREATE TEMP TABLE e_8 AS
SELECT
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade AS e_8
FROM
	expenditures_avg_decade ea
WHERE
	ea.decade = '8'
GROUP BY
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade;

CREATE TEMP TABLE e_9 AS
SELECT
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade AS e_9
FROM
	expenditures_avg_decade ea
WHERE
	ea.decade = '9'
GROUP BY
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade;

SELECT * FROM e_9;

CREATE TEMP TABLE e_0 AS
SELECT
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade AS e_0
FROM
	expenditures_avg_decade ea
WHERE
	ea.decade = '0'
GROUP BY
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade;

SELECT * FROM e_0;

CREATE TEMP TABLE e_1 AS
SELECT
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade AS e_1
FROM
	expenditures_avg_decade ea
WHERE
	ea.decade = '1'
GROUP BY
	ea.region,
	ea.countryname,
	ea.avg_expenditures_decade;

SELECT * FROM e_1;

SELECT
	c.region,
	c.shortname AS countryname,
	e_7,
	e_8,
	e_9,
	e_0,
	e_1,
	round((e_1-e_7)::NUMERIC,2) AS progress
FROM
	country c
LEFT JOIN e_7 ON
	c.shortname = e_7.countryname
LEFT JOIN e_8 ON
	c.shortname = e_8.countryname
LEFT JOIN e_9 ON
	c.shortname = e_9.countryname
LEFT JOIN e_0 ON
	c.shortname = e_0.countryname
LEFT JOIN e_1 ON
	c.shortname = e_1.countryname
WHERE
	c.region IS NOT NULL
	AND c.region <> ''
	AND e_7 IS NOT NULL 
	AND e_1 IS NOT NULL 
ORDER BY
	c.region,
	c.shortname;

/*9)Education: Outcomes
 * Literacy rate, adult total (% of people ages 15 and above)*/

DROP TABLE IF EXISTS literacy;

CREATE TEMP TABLE literacy AS
SELECT
	c.region,	
	i.countryname,
	d.century,
	d.decade,
	i."Year",
	i.value AS literacy
FROM
	indicators i
JOIN country c ON
	i.countrycode = c.countrycode
JOIN decades d ON
	i."Year" = d."Year"
WHERE
	c.region IS NOT NULL
	AND c.region <> ''
	AND indicatorcode = 'SE.ADT.LITR.ZS'
GROUP BY
	c.region,
	i.countryname,
	i."Year",
	i.value,
	d.century,
	d.decade
ORDER BY
	c.region,
	d.century,
	d.decade,
	i.countryname;

SELECT * FROM literacy;

DROP TABLE IF EXISTS literacy_avg_decade;

CREATE TEMP TABLE literacy_avg_decade AS
SELECT
	l.region,
	l.countryname,
	l.century,
	l.decade,
	l."Year",
	avg(l.literacy) OVER (
		PARTITION BY l.decade,
		l.countryname
	) AS avg_literacy_decade
FROM
	literacy l
GROUP BY
	l.region,
	l."Year",
	l.countryname,
	l.literacy,
	l.century,
	l.decade
ORDER BY
	l.region,
	l.countryname,
	l.century,
	l.decade;

SELECT
	DISTINCT la.region,
	la.countryname,
	la.century,
	la.decade,
	la.avg_literacy_decade
FROM
	literacy_avg_decade la
ORDER BY
	la.region,
	la.countryname,
	la.century,
	la.decade;


DROP TABLE IF EXISTS l_7;

CREATE TEMP TABLE l_7 AS
SELECT
	la.region,
	la.countryname,
	la.avg_literacy_decade AS l_7
FROM
	literacy_avg_decade la
WHERE
	la.decade = '7'
GROUP BY
	la.region,
	la.countryname,
	la.avg_literacy_decade;

SELECT * FROM l_7;

DROP TABLE IF EXISTS l_8;

CREATE TEMP TABLE l_8 AS
SELECT
	la.region,
	la.countryname,
	la.avg_literacy_decade AS l_8
FROM
	literacy_avg_decade la
WHERE
	la.decade = '8'
GROUP BY
	la.region,
	la.countryname,
	la.avg_literacy_decade;

CREATE TEMP TABLE l_9 AS
SELECT
	la.region,
	la.countryname,
	la.avg_literacy_decade AS l_9
FROM
	literacy_avg_decade la
WHERE
	la.decade = '9'
GROUP BY
	la.region,
	la.countryname,
	la.avg_literacy_decade;

SELECT * FROM l_9;
DROP TABLE l_0;
CREATE TEMP TABLE l_0 AS
SELECT
	la.region,
	la.countryname,
	la.avg_literacy_decade AS l_0
FROM
	literacy_avg_decade la
WHERE
	la.decade = '0'
GROUP BY
	la.region,
	la.countryname,
	la.avg_literacy_decade;

SELECT * FROM e_0;

CREATE TEMP TABLE l_1 AS
SELECT
	la.region,
	la.countryname,
	la.avg_literacy_decade AS l_1
FROM
	literacy_avg_decade la
WHERE
	la.decade = '1'
GROUP BY
	la.region,
	la.countryname,
	la.avg_literacy_decade;

SELECT * FROM l_1;

CREATE TEMP TABLE literacy_overview AS
SELECT
	c.region,
	c.shortname AS countryname,
	l_7,
	l_8,
	l_9,
	l_0,
	l_1,
	round((l_1-l_9)::NUMERIC, 2) AS progress
FROM
	country c
LEFT JOIN l_7 ON
	c.shortname = l_7.countryname
LEFT JOIN l_8 ON
	c.shortname = l_8.countryname
LEFT JOIN l_9 ON
	c.shortname = l_9.countryname
LEFT JOIN l_0 ON
	c.shortname = l_0.countryname
LEFT JOIN l_1 ON
	c.shortname = l_1.countryname
WHERE
	c.region IS NOT NULL
	AND c.region <> ''
	AND l_9 IS NOT NULL
	AND l_1 IS NOT NULL
ORDER BY
	c.region,
	c.shortname;

SELECT * FROM literacy_overview;

SELECT 
lo.region,
lo.countryname,
lo.l_9,
lo.l_1,
lo.progress,
dense_rank() OVER (ORDER BY lo.progress desc)
FROM literacy_overview lo;


SELECT
	CORR(lo.l_9, e_9.e_9) AS Corr_literacy_expenditures_decade_9
FROM
	literacy_overview lo
LEFT JOIN e_9 ON
	lo.countryname = e_9.countryname;
	
	
SELECT
	CORR(lo.l_1, e_1.e_1) AS Corr_literacy_expenditures_decade_1
FROM
	literacy_overview lo
LEFT JOIN e_1 ON
	lo.countryname = e_1.countryname;


 
 