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

