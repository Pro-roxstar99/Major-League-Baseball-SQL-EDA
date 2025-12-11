use maven_advanced_sql;

select *
from players
limit 10;

select *
from salaries
limit 10;

select *
from schools
limit 10;

select *
from school_details
limit 10;

select s.*, sd.*
from schools s
inner join school_details sd
on s.schoolID = sd.schoolID
limit 10;


-- Starting with EDA and checking some data trends

select sal.yearID,
		sal.teamID,
        round(sum(sal.salary)/100000, 1) as current_year_salary_expenses,
        lag(round(sum(sal.salary)/100000, 1))
			over(partition by sal.teamID order by sal.yearID) as prev_year_salary_expenses,
            
		round(
        (sum(sal.salary) - lag(sum(sal.salary))
						over(partition by sal.teamID order by sal.yearID))/100000, 1) as difference_in_salary_spendings,
		
        round(
        (sum(sal.salary) - lag(sum(sal.salary))
						over(partition by sal.teamID order by sal.yearID))*100
        /
        (lag(sum(sal.salary)) over(partition by sal.teamID order by sal.yearID))
        ,1) as salary_yoy_growth_pct
        
from salaries as sal
group by 1,2
order by 2,1
limit 200;

-- PART I: SCHOOL ANALYSIS

-- TASK 1: View the schools and school details tables
select *
from schools
limit 10;

select *
from school_details
limit 10;

-- TASK 2: In each decade, how many schools were there that produced players?
select s.*, sd.*
from schools s
left join school_details sd
on s.schoolID = sd.schoolID;

select floor(s.yearID/10)*10 as decade,
		count(distinct sd.name_full) as num_of_schools
from schools s
left join school_details sd
on s.schoolID = sd.schoolID
group by floor(s.yearID/10)*10;

-- 3. What are the names of the top 5 schools that produced the most players?

with school_players_and_names as (
			select 
					s.schoolID as school_name,
                    count(distinct s.playerID) as num_of_players
            from schools s
            group by s.schoolID
),

top_ranking_schools as (
		select spn.school_name as name,
                dense_rank() over(order by spn.num_of_players desc) as school_rank
        from school_players_and_names spn
)

select trs.name, trs.school_rank
from top_ranking_schools trs
where school_rank <=5
order by school_rank;

-- 4. For each decade, what were the names of the top 3 schools that produced the most players?

with getting_decades as (
	select floor(s.yearID/10)*10 as decade,
				sd.name_full as school_name,
            count(s.playerID) as num_of_players
	from schools s
    left join school_details sd
    on s.schoolID = sd.schoolID
    group by floor(s.yearID/10)*10, sd.name_full
),
top_schools_decade as (
	select gd.decade,
			gd.school_name,
			dense_rank() over(partition by gd.decade order by gd.num_of_players desc, gd.school_name) as decade_ranker,
            gd.num_of_players
	from getting_decades gd
)
select tsd.*
from top_schools_decade tsd
where decade_ranker <= 3;


-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
select *
from salaries;

-- 2. Return the top 20% of teams in terms of average annual spending

with total_spending as (
		select s.teamID as team,
				sum(s.salary) as total_spend -- total amount the team is spending
        from salaries s
        group by s.teamID
),

top_20_ntile as (
		select tots.team as team_name,
				avg(tots.total_spend) as average_annual_spending,
                ntile(5) over(order by tots.total_spend desc, tots.team) as ranker
        from total_spending tots
        group by tots.team
)

select team_name, round(average_annual_spending/1000000000, 1) as annual_spending_in_billions
from top_20_ntile
where ranker = 1;


-- 3. For each team, show the cumulative sum of spending over the years

with total_sales as (
		select sal.yearID as year,
				sal.teamID as team,
				sum(sal.salary) as total_salary
		from salaries as sal
        group by  sal.yearID, sal.teamID
),

cumulative_sum as (
		select ts.year as year, ts.team as team,
					round(sum(ts.total_salary) over(partition by ts.team order by ts.year)/1000000000, 1) as cumulative_sum_of_spending
		from total_sales ts
)
select *
from cumulative_sum;



-- 4. Return the first year that each team's cumulative spending surpassed 1 billion

with total_sales as (
			select sal.yearID as year,
					sal.teamID as team,
                    sum(sal.salary) as total_salary_spending
            from salaries sal
            group by sal.yearID, sal.teamID
),

cumulative_sales as (
		select ts.year as year, ts.team as team,
				sum(ts.total_salary_spending) over(order by ts.total_salary_spending) as cumulative_salary_spending
		from total_sales ts
),

first_billion as (
		select cs.year as year, cs.team as team,
				cs.cumulative_salary_spending,
                row_number() over(partition by cs.team order by cs.cumulative_salary_spending) as billion_ranker
		from cumulative_sales cs
        where cs.cumulative_salary_spending > 1000000000
)

select *
from first_billion
where billion_ranker = 1
order by year, team;


-- PART III: PLAYER CAREER ANALYSIS
-- 1. View the players table and find the number of players in the table
select *
from players;

select count(distinct playerID) as num_of_players
from players;

-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.

with player_info as (
	select p.nameGiven as player_name,
			round(datediff(debut, concat(birthYear,"-",birthMonth,"-",birthDay))/365.25) as age_debut_year,
            round(datediff(finalGame, concat(birthYear,"-",birthMonth,"-",birthDay))/365.25) as age_final_year
    from players p
),

career_len as (
				select player_name,
						age_debut_year,
                        age_final_year,
                        abs(age_debut_year-age_final_year) as career_length
				from player_info
)

select *
from career_len;



-- 3. What team did each player play on for their starting and ending years?

select *
from players;

select *
from salaries;

select p.playerID, p.nameGiven as player_name, s1.teamID as debut_team, year(p.debut) as debut_year,
		s2.teamID as final_team, year(p.finalGame) as final_year
from players p
inner join salaries s1
on p.playerID = s1.playerID and year(p.debut) = s1.yearID
inner join salaries s2
on p.playerID = s2.playerID and year(p.finalGame) = s2.yearID;


-- 4. How many players started and ended on the same team and also played for over a decade?

