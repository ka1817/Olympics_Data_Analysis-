SELECT * FROM public.olympics_history
SELECT * FROM public.olympics_history
SELECT * FROM public.olympics_history
select * from o_h
--How many olympics games have been held?
--using with clause
with gamess as (SELECT distinct games FROM public.olympics_history
order by games)
select count(games) as total_olympic_games from gamess
--using sub query
select count(games) as total_olympic_games from (SELECT distinct games FROM public.olympics_history
order by games) as x
--list down all olympics games held so far
select distinct year,season,city from olympics_history
order by year,season,city
--Mention the total no of nations who participated in each olympics game?
with all_countries as (SELECT games,region FROM public.olympics_history
join o_h on o_h.noc=olympics_history.noc
group by olympics_history.games,o_h.region) 
select games,count(region) from all_countries
group by games
order by games;
--Which year saw the highest and lowest no of countries participating in olympics
with all_countries as
              (select games, nr.region
              from olympics_history oh
              join o_h nr ON nr.noc=oh.noc
              group by games, nr.region),
          tot_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)
      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;
--Which nation has participated in all of the olympic games
with tot_games as
              (select count(distinct games) as total_games
              from olympics_history),
          countries as
              (select games, nr.region as country
              from olympics_history oh
              join o_h nr ON nr.noc=oh.noc
              group by games, nr.region),
          countries_participated as
              (select country, count(1) as total_participated_games
              from countries
              group by country)
      select cp.*
      from countries_participated cp
      join tot_games tg on tg.total_games = cp.total_participated_games
      order by 1;
--Identify the sport which was played in all summer olympics.
with t1 as
          	(select count(distinct games) as total_games
          	from olympics_history where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from olympics_history where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select *
      from t3
      join t1 on t1.total_games = t3.no_of_games;
--Which Sports were just played only once in the olympics.
with t1 as
          	(select distinct games, sport
          	from olympics_history),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where t2.no_of_games = 1
      order by t1.sport;

--Fetch the total no of sports played in each olympic games.
with t1 as
      	(select distinct games, sport
      	from olympics_history),
        t2 as
      	(select games, count(1) as no_of_sports
      	from t1
      	group by games)
      select * from t2
      order by no_of_sports desc;
--Fetch oldest athletes to win a gold medal
with temp as
            (select name,sex,cast(case when age = 'NA' then '0' else age end as int) as age
              ,team,games,city,sport, event, medal
            from olympics_history),
        ranking as
            (select *, rank() over(order by age desc) as rnk
            from temp
            where medal='Gold')
    select *
    from ranking
    where rnk = 1;
--Find the Ratio of male and female athletes participated in all olympic games.
 with t1 as
        	(select sex, count(1) as cnt
        	from olympics_history
        	group by sex),
        t2 as
        	(select *, row_number() over(order by cnt) as rn
        	 from t1),
        min_cnt as
        	(select cnt from t2	where rn = 1),
        max_cnt as
        	(select cnt from t2	where rn = 2)
    select concat('1 : ', round(max_cnt.cnt::decimal/min_cnt.cnt, 2)) as ratio
    from min_cnt, max_cnt;
--Fetch the top 5 athletes who have won the most gold medals.
with a as (SELECT name,team,case when medal='Gold' then 1 else 0 end as total_medals FROM public.olympics_history
where medal='Gold')
select name,team,sum(total_medals) from a
group by name,team
order by sum desc
limit 5

 with t1 as
            (select name, team, count(1) as total_gold_medals
            from olympics_history
            where medal = 'Gold'
            group by name, team
            order by total_gold_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)
    select name, team, total_gold_medals
    from t2
    where rnk <= 5;
--Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as
            (select name, team, count(1) as total_medals
            from olympics_history
            where medal in ('Gold', 'Silver', 'Bronze')
            group by name, team
            order by total_medals desc),
        t2 as
            (select *, dense_rank() over (order by total_medals desc) as rnk
            from t1)
    select name, team, total_medals
    from t2
    where rnk <= 5;
--Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with tot as (select region,count(medal) as total_medals from olympics_history as os
join o_h on os.noc=o_h.noc
where medal in ('Gold', 'Silver', 'Bronze')
group by region
order by total_medals desc),
     ra as (select *,rank() over(order by total_medals desc) as rnk from tot)
select * from ra
where rnk<=5
--List down total gold, silver and bronze medals won by each country.
with a as (select region,case when medal='Gold' then 1 else 0 end as gold,
              case when medal='Silver' then 1 else 0 end as silver,
              case when medal='Bronze' then 1 else 0 end as Bronze from olympics_history as os
join o_h on os.noc=o_h.noc),
     b as (select region,sum(gold) as gold,sum(silver) as silver,sum(bronze) as bronze from a
group by region
order by gold,silver,bronze desc)
select region, max(gold) over(order by gold desc),silver,bronze from b
--List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
with a as (SELECT games,region,case when medal='Gold' then 1 else 0 end as gold,
              case when medal='Silver' then 1 else 0 end as silver,
              case when medal='Bronze' then 1 else 0 end as Bronze from olympics_history as os
join o_h on os.noc=o_h.noc),
          b as (select games,region,sum(gold) as gold,sum(silver) as silver,sum(bronze) as bronze from a
group by games,region
order by gold,silver,bronze desc)
select * from b
order by games,region
--Which countries have never won gold medal but have won silver/bronze medals?
with a as (select region,cast(case when medal='Gold' then 1 else 0 end as int) as gold,
	          cast(case when medal='Silver' then 1 else 0 end as int) as silver,
	          cast(case when medal='Bronze' then 1 else 0 end as int) as bronze from olympics_history os
join o_h on o_h.noc=os.noc),
      b as (select region,sum(gold) as gold,sum(silver) as silver,sum(bronze) as bronze from a
           group by region)
select * from b
where gold=0 and (silver > 0 or bronze > 0)
order by bronze desc
--in which Sport/event, India has won highest medals.
with a as (SELECT team,sport,sum(case when medal='NA' then 0 else 1 end) as total_medals  FROM public.olympics_history
where team='India'
group by team,sport
order by total_medals desc
limit 1)
select sport,total_medals from a
--Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
select team,sport,games,sum(case when medal='NA' then 0 else 1 end) as total_medals 
from olympics_history
where team='India' and sport='Hockey'
group by team,sport,games
order by total_medals desc
--Get the total number of medals won by each country:
select o_h.region,sum(case when medal='NA' then 0 else 1 end) total_medals from olympics_history os
join o_h on o_h.noc=os.noc
where medal <> 'NA'
group by o_h.region
order by total_medals desc
--Find the top 5 athletes with the most medals
with a as (select name,sum(case when medal='NA' then 0 else 1 end) total_medals
from olympics_history
where medal <> 'NA'
group by name
order by total_medals desc
limit 10)
select *,dense_rank() over(order by total_medals desc)
from a
--Find the country with the highest average medal count per event
with a as (select o_h.region,games,sum(case when medal='NA' then 0 else 1 end) total_medals from olympics_history os
join o_h on o_h.noc=os.noc
group by  o_h.region,games)
select region,avg(total_medals) as avg_total_medals from a
group by region
order by avg_total_medals desc
--Find the athlete who has participated in the most number of distinct sports
SELECT
    Name,
    COUNT(DISTINCT Sport) AS sports_count
FROM
    olympics_history
GROUP BY
    Name
ORDER BY
    sports_count DESC
LIMIT 1;
--Calculate the average age of athletes who won gold medals, grouped by their gender,
--and find the gender with the highest average age
select sex,sum(cast(age as int)) as avg_age from olympics_history
where age <> 'NA' and medal='Gold'
group by sex
ORDER BY
    avg_age DESC
LIMIT 1;
--Find the top 3 athletes with the highest number of medals in each Olympic year
WITH ranked_athletes AS (
    SELECT
        Year,
        Name,
        COUNT(Medal) AS medal_count,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(Medal) DESC) AS rank
    FROM
        olympics_history
    WHERE
        Medal IS NOT NULL
    GROUP BY
        Year, Name
)
SELECT
    Year,
    Name,
    medal_count,rank
FROM
    ranked_athletes
WHERE
    rank <= 3
ORDER BY
    Year, rank;

--Find the top 3 athletes with the most medals won in each sport
with a as (select name,sport,count(case when medal='NA' then 0 else 1 end) as total_medals
from olympics_history
group by name,sport
order by total_medals desc),
       b as (select *,row_number() over(partition by sport order by a.total_medals desc) as rnk from a)
select * from b
where rnk<=3
order by sport,total_medals desc
--Calculate the average age of athletes who won medals each year, and rank these years by average age.
b as 
WITH Filtered_Age AS (
    SELECT Year, Age
    FROM olympics_history
    WHERE Medal IS NOT NULL
      AND Age ~ '^[0-9]+$'  -- This regex checks if Age contains only numeric values
),
Avg_Age_Per_Year AS (
    SELECT Year, AVG(CAST(Age AS INT)) AS Average_Age
    FROM Filtered_Age
    GROUP BY Year
)
select *,rank() over(order by average_age) from Avg_Age_Per_Year

--Find athletes who participated in more events than the average number of events per athlete
WITH Event_Count_Per_Athlete AS (
    SELECT Name, COUNT(*) AS Event_Count
    FROM olympics_history
    GROUP BY Name
),
Avg_Event_Count AS (
    SELECT AVG(Event_Count) AS Avg_Count
    FROM Event_Count_Per_Athlete
),
Athletes_Above_Avg AS (
    SELECT Name
    FROM Event_Count_Per_Athlete
    WHERE Event_Count > (SELECT Avg_Count FROM Avg_Event_Count)
)
SELECT a.Name, a.Sport, a.Event
FROM olympics_history a
JOIN Athletes_Above_Avg aa ON a.Name = aa.Name;



