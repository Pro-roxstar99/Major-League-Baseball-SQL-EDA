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