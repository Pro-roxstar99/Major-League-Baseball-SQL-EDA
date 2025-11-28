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