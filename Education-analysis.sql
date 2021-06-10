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