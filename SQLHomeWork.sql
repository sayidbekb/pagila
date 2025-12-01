-- ***TASK 1***

-- Output the number of movies in each category, sorted descending.
select 
	c.name,
	count(film_id) AS num_of_movies
from film_category fc
join category c
using(category_id)
join film f
using(film_id)
group by c.name

order by num_of_movies desc;



-- ***TASK 2***

-- Output the 10 actors whose movies rented the most, sorted in descending order.

select 
	a.actor_id,
	concat(a.first_name, ' ', a.last_name) as actor_name,
	sum(rental_duration) as total_rental_duration
from film f
join film_actor fa using(film_id)
join actor a using(actor_id)
group by a.actor_id, actor_name
order by total_rental_duration desc
limit 10;



-- ***TASK 3***

-- Output the category of movies on which the most money was spent.


select 
	c.name,
	sum(f.replacement_cost) as total_cost
from film f
join film_category fc using(film_id)
join category c using(category_id)
group by c.name
order by total_cost desc
limit 1
;



-- ***TASK 4***

-- Print the names of movies that are not in the inventory. Write a query without using the IN operator.

select f.title
from film f
left join inventory i using(film_id)
where i.film_id is null;



-- ***TASK 5***

-- Output the top 3 actors who have appeared the most in movies 
-- in the “Children” category. If several actors have the same number of movies, 
-- output all of them.

with actor_film_category as
	(select *
	from film_category fc
	join category c
	using(category_id)
	join film_actor fa
	using(film_id)
	where c.name = 'Children'),

 appear_count_rank as
	(select 
		actor_id,
		count(actor_id) as appear_count,
		dense_rank() over (order by count(actor_id) desc) as dense_rank
	from actor_film_category
	group by actor_id
	order by appear_count desc)




select 
	concat(a.first_name, ' ', a.last_name) as top_actor,
	acr.appear_count
from actor a
join appear_count_rank acr
using(actor_id)
where dense_rank <= 3
order by acr.appear_count desc;



-- ***TASK 6***

-- Output cities with the number of active and inactive customers (active - customer.active = 1). 
--Sort by the number of inactive customers in descending order.

select 
	c.city,
	sum(c2.active) as active_customers, -- active = 1 → counts active customers
	sum(1 - c2.active) as inactive_customers -- inactive = 0 → counts active customers
	
from city c
join address a using(city_id)
join customer c2 using(address_id)
group by c.city
order by inactive_customers desc



-- ***TASK 7***

-- Output the category of movies that have the highest number of total rental hours in the city 
-- (customer.address_id in this city) and that start with the letter “a”. 
-- Do the same for cities that have a “-” in them. Write everything in one query.

with rental_hours as
	(select 
		case
			when c2.city like 'A%' then 'starts_with_a'
			when c2.city like '%-%' then 'has -'
		end as city_group_type,
		c.name as category,
		sum(EXTRACT(EPOCH FROM (return_date - rental_date)) / 3600) as total_rental_hours
	from rental
	join inventory i using(inventory_id)
	join film_category fc using(film_id)
	join category c using(category_id)
	join customer cu using(customer_id)
	join address a using(address_id)
	join city c2 using(city_id)
	where return_date is not null 
		and 
		(c2.city like 'A%' or 
		c2.city like '%-%')
	group by city_group_type, c.name)


select city_group_type, category, round(total_rental_hours, 3)
from (
	select 
		city_group_type,
		category,
		total_rental_hours,
		rank() over(partition by city_group_type order by total_rental_hours desc) as rank
	from rental_hours
	) ranked
where rank = 1;