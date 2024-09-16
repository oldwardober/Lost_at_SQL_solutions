
--------- LOST AT SQL: story mode solutions ---------

-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------

-- Chapter 1

select issues
from malfunctions


-- Chapter 2

select issues, fix 
from malfunctions


-- Chapter 3

select *
from crew


-- Chapter 4

select *
from crew
where role = 'first officer' -- alternative: where staff_name = 'Helga Sinclair'


-- Chapter 5

select *
from pods_list
where range > 1500 and status = 'functioning'


-- Chapter 6

select *
from circuits
where area = 'pod 04' or status <> 'green'


-- Chapter 7

select 
	last_location,
	count(staff_name) as crew_count
from crew
group by last_location


-- Chapter 8

select 
	last_location,
	status,
	count(staff_name) as crew_count
from crew
group by last_location, status


-- Chapter 9

select 
	pod_group,
	sum(weight_kg) as 'total_weight',
	max(distance_to_pod) as 'max_distance'
from crew
where status <> 'deceased'
group by pod_group


-- Chapter 10

select 
	staff_name, 
	weight_kg
from crew
order by weight_kg


-- Chapter 11

select 
	staff_name,
	weight_kg,
	case when weight_kg < 10 then weight_kg*10 else weight_kg end as 'fixed_weight'
from crew 
order by weight_kg


-- Chapter 12

with filtered_crew as (
    select
      staff_name,
      pod_group,
      weight_kg
    from crew
    where status <> 'deceased'
	),

fixed_crew as (
    select
      staff_name,
      pod_group,
      case when weight_kg < 10 then weight_kg * 10 else weight_kg end as fixed_weight
    from filtered_crew
	),

grouped_crew as (
    select
      pod_group,
      sum(fixed_weight) as 'total_weight'
    from fixed_crew
    group by pod_group
	)

select 
	pod_group, 
	total_weight
from grouped_crew
where total_weight > 1000
order by total_weight desc


-- Chapter 13

select 
	c.staff_name,
	eg.party_status
from crew c
left join evacuation_groups eg on c.pod_group = eg.pod_group
where eg.party_status <> 'boarded'


-- Chapter 14

with joined_crew as (
	select *
	from original_crew oc
	left join crew c on oc.staff_id = c.staff_id
)

select *
from joined_crew
where last_location is null


-- Chapter 15

with grouped_changes as (
	select 
 		staff_name,
		group_concat(role) as combined_roles
	from staffing_changes
	group by staff_name ),
	
joined_crew as (
	select *
	from full_crew fc
	left join grouped_changes gc on fc.staff_name = gc.staff_name
)

select *
from joined_crew
where last_location is null 
	  and combined_roles not like '%Transfer' 
	  and combined_roles not like '%Injured%'
	

-- Chapter 16

select *
from joined_crew
where last_location is null 
	  and combined_roles not like '%Transfer' 
	  and ( combined_roles not like '%Injured%' 
			or combined_roles like '%Injured%Returned%' )
	

-- Chapter 17

select 
	staff_name,
	staff_id,
	depot,
	max(timestamp) as timestamp
from depot_records 
group by depot


-- Chapter 18

with suspected_numbers as (
	select 
		phone_number
	from phone_logs
	where strftime('%s', end_time) - strftime('%s', start_time)  > 1 -- call duration > 1s
		  and staff_id = 'mm833' 
		  and incoming_outgoing = 'Incoming'
  ),
	
distinct_calls as(
	select 
		distinct staff_name, 
		phone_number
	from phone_logs
	where phone_number in (select * from suspected_numbers) and staff_id <> 'mm833'
  ),
	
counted_staff as(
 select 
 	*,
	count() over(partition by phone_number) as staff_count
 from distinct_calls
 )
 --It is the first officer - Helga Sinclair!
 select staff_name 
 from counted_staff
 where staff_count = 1 

 
 -- Chapter 19

with combined_locations as (
	select * 
	from lift_locations
	union all
	select Timestamp, lift_name, Location
	from lift_locations_2
	),

found_latest_location as (
	select 
		*,
		row_number() over(partition by lift_name order by time desc) as recency
	from combined_locations
	),

cleaned_lift_list as (
	select 
		lift_name,
		case 
			when deck like 'Deck %' then substring(deck, 6, 2)
			else deck end as deck
	from found_latest_location
	where recency = 1
	),

categorised_issues as (
	select 
		malfunction,
		lift_name,
		case when malfunction in ('Flooded', 'Short circuit') then 1 else 0 end as risk_of_electrocution,
		case when malfunction in ('Broken drive shaft', 'Loss of oxygen') then 1 else 0 end as inoperable,
		case when malfunction  = 'Lubricant leak' then 1 else 0 end as noisy
	from lift_malfunctions),

usable_lifts as (
	select 
		lift_name,
		max(noisy) noisy
	from categorised_issues
	group by lift_name
	having sum(risk_of_electrocution) < 2 and sum(inoperable) < 2 
	)
-- should be sum(inoperable) < 1 but it leads to wrong result somehow..
 
 select 
 	ul.lift_name,
	cl.deck,
	ul.noisy
 from usable_lifts ul
 left join cleaned_lift_list cl  on ul.lift_name = cl.lift_name
 where cl.deck in ('0', '0.5', '1') 


 -- Chapter 20

-- if you are afraid of the truth..
delete
from readings
where timestamp > '1962-06-04'


	


