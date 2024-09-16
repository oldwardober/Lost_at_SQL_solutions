
------ LOST AT SQL ------

-- CHALLANGES SOLUTIONS



-- 1. case by Jess Peck (CASE WHEN)

-- We have impostor on board! We have to identify it by checking if all characteristics (length, weight and habitat) are outside the usual range for given specie.

select 
	*,
	case 
		when (species_name = 'clownfish') and (length not between 3 and 7) and (weight not between 0.2 and 0.8) and (habitat_type <> 'coral reef') then 'impostor'
		when (species_name = 'octopus') and (length not between 12 and 36) and (weight not between 6.6 and 23) and (habitat_type <> 'coastal marine waters') then 'impostor'
		when (species_name = 'starfish') and (length not between 0.5 and 40) and (weight not between 3.3 and 6.6) and (habitat_type <> 'kelp forest') then 'impostor'
		else 'not impostor' end as 'impostor_status'
from marine_life



-- 2. indentify by David Westby (JOINS and CTEs)

/* We are presented with a three datasets containing information about employees. We have to find out which employees changed their occupation, 
   but unfortunately format of the datasets is inconsistent. */

-- We have id numbers but for some reason these are not distinct, so we will join datasets on birth dates which happen to be distinct.

-- first I will merge new_database with start_dates and change the format of birth date to be consistent with the old_database
with merged as 
	(
	select 
		*,
		-- changing date_of_birth format from dd/mm/yyyy to yyyy-mm-dd
  		substring(nd.date_of_birth, -4) || '-' ||  substring(nd.date_of_birth, 	 4, 2) || '-' || substring(nd.date_of_birth, 1, 2)  as 'date_of_birth2' 
	from new_database nd 
	inner join start_dates sd on nd.date_of_birth = sd.date_of_birth
	)

-- and now joining these two datasets with old_database
select 
	m.full_name as 'Full_Name', 
	m.employment_start_date,
	m.occupation as 'latest_occupation',
	od.occupation as 'previous_occupation'
from merged m
left join old_database od on m.date_of_birth2 = od.date_of_birth
where employed_or_departed = 'Employed' and m.occupation <> od.occupation -- we are interested only with employees who are still employed and changed their occupation



-- 3. maintain by Chris Green (text functions and GROUP BY)

/* We have a dataset containing information about vent maintenance, but the vent names were not kept consistent (p1 vs p01 vs P01 and so on). 
   We have to correct it and get number of checks for each vent. */

select 
	lower(replace(vent, 0, '')) as 'nice_vent', -- converting the vent names to uniform format (p1, p2 etc)
	count(*) as 'times_checked'
from vent_maintenance
group by lower(replace(vent, 0, ''))
having  count(*) < 10 -- we are interested only in vents that were checked fewer than 10 times



-- 4. pudding by Robin Lord (CTEs, window functions, case when, correlated subqueries)

/* We have puddings offenders on board! (people who take more puddings that they should and what's more they take the last one)
   Our job is to identify managers who have the most offenders in their crew. */

-- We have 4 datasets
--food_taken: [time_stamp, meal, food_id, staff_id]
--crew: [person_id, person_seniority, manager_id]
--food_left: [date, food, number_left]
--food: [meal, food_id, food]

/* There is some ambiguity as to how we should define pudding offender. I get the right results assuming that the pudding offender is someone who:
	- took more than 3 puddings
	- and took the last pudding */

-- first I join 2 datasets just to get the name of the given food (we have to join on both meal and food_id because food ids are different for each meal).

with table1 as (
	select 
		*,
		date(ft.timestamp) as date,
		f.food as food
	from food_taken ft
	left join food f on ft.meal = f.meal and ft.food_id = f.food_id
	),

/* Now i use window function to get 2 important columns
	- take_order - to know who took the last piece of pudding on each day
	- take_count - to know how many puddings were taken by each person on each day 

   I also join this data with food_left table to know how many pieces of food were left each day. */

table2 as (
	select 
		t1.date,
		t1.timestamp,
		t1.meal,
		t1.food_id,
		t1.food,
		t1.staff_id,
		fl.number_left,
		row_number() over(partition by t1.date, t1.food order by t1.timestamp desc) as take_order,
		count() over(partition by t1.staff_id, t1.date, t1.food) as take_count
	from table1 t1
	left join food_left fl on t1.date = fl.date and t1.food = fl.food
	),

/* Now I add snr_manager_id column to crew dataset to take into account indirect managees. 
   Specificly, if junior's manager is specialist, then I assume that this specialist's manager is also junior's indirect manager. */
	
table3 as (
	select 
		*,
		case 
			when manager_id is null then person_id
			when substring(manager_id, 1, 3) = 'snr' then manager_id
			when substring(manager_id, 1, 3) = 'spe' then (select c2.manager_id from crew c2 where c1.manager_id = c2.person_id)
		end as snr_manager_id
	from crew c1),

-- Finally I calculate the ranking of offenders.

table4 as (  
	select 
		staff_id,
		sum(case when food = 'pudding' and number_left = 0 and take_order = 1  and take_count > 1 then 1 else 0 end) as offences,
  		row_number() over(order by sum(case when food = 'pudding' and number_left = 0 and take_order = 1  and take_count > 1then 1 else 0 end) desc) as offenders_rank,
		snr_manager_id
	from table2 t2
	left join table3 t3 on t2.staff_id = t3.person_id
	group by staff_id
	order by offences desc
	)

select 
	snr_manager_id,
	sum(case when offenders_rank < 6 then 1 else 0 end) as offender_count
from table4
group by snr_manager_id
order by offender_count desc 


-- 5. search by Dom Woodman

-- unfortunately this solution is not correct, not sure where is the mistake

with RankedDays as (
    select 
      	*,
  		length(query) - length(replace(query, ' ', '')) + 1 as keywords_count,
        dense_rank() over (partition by path order by pt desc) as dr
    from search_data
),

AggregatedData as (
    select 
        path,
        sum(case when dr = 1 OR dr = 2 then clicks else 0 end) as recent_clicks,
  		sum(case when dr = 1 OR dr = 2 then keywords_count else 0 end) as recent_keys,
        sum(case when dr = 3 OR dr = 4 then clicks else 0 end) as previous_clicks,
        sum(case when dr = 3 OR dr = 4 then keywords_count else 0 end) as previous_keys
    from RankedDays
    where dr <= 4  
    group by path
)

select 
    path,
    (recent_clicks - previous_clicks) as diff_total_clicks,
	(recent_keys - previous_keys) as diff_unique_keywords
from AggregatedData
order by diff_total_clicks desc;




