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