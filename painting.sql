#1)--------------Are there museuems without any paintings--------------------#
	select * from museum m
	where not exists (select w.museum_id from work w
					 where w.museum_id=m.museum_id);
                     
#how many without painting#
select count(*) from museum m
	where not exists (select w.museum_id from work w
					 where w.museum_id=m.museum_id);
                     
				
#2-------Identify the paintings whose asking price is less than 50% of its regular price------#
	select * 
	from product_size
	where sale_price < (regular_price*0.5);
    
    
#3---------Which canva size costs the most?-------------#
	SELECT cs.label AS canva, ps.sale_price
FROM (SELECT *,RANK() OVER (ORDER BY sale_price DESC) AS rnk
    FROM product_size) ps
JOIN canvas_size cs ON CAST(cs.size_id AS CHAR) = ps.size_id
WHERE ps.rnk = 1;


#4---------Delete duplicate records from work, product_size, subject and image_link tables----#
delete from work 
	where work_id not in (select work_id from 
    (select *,row_number() over() as rn
						from work ) a where a.rn>1);
    
    delete from product_size 
	where (work_id,size_id) not in (select work_id,size_id from 
    (select *,row_number() over() as rn
						from product_size ) a where a.rn>1);
                        
 delete from subject 
	where (work_id,subject) not in (select work_id,subject from 
    (select *,row_number() over() as rn
						from subject ) a where a.rn>1);                       
	
    
delete from image_link 
	where work_id not in (select work_id from 
    (select *,row_number() over() as rn
						from image_link ) a where a.rn>1);
                        
                        
#5----------Identify the museums with invalid city information in the given dataset----------#
	SELECT * 
FROM museum 
WHERE city REGEXP '^[0-9]';
                        
#6----------Fetch the top 10 most famous painting subject---------------#
	select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;
    
    
#7----Identify the museums which are open on both Sunday and Monday. Display museum name, city-----#
	select distinct m.name as museum_name, m.city, m.state,m.country
	from museum_hours mh 
	join museum m on m.museum_id=mh.museum_id
	where day='Sunday'
	and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');


#8------How many museums are open every single day------#
	select count(1)
	from (select museum_id, count(1)
		  from museum_hours
		  group by museum_id
		  having count(1) = 7) x;
                        
 #9-Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum---#
	select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;                       
                        
#10--Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)#
	select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;
    
#11--Display the 3 least popular canva sizes-----#
	select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cast(cs.size_id as char)= ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;
    

#12----Which museum has the most no of most popular painting style----#
	with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;

#13-----Identify the artists whose paintings are displayed in multiple countries-----#
	with cte as
		(select distinct a.full_name as artist
		, w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;

#14-----Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country
#If there are multiple value, seperate them with comma.
	with cte_country as 
			(select country, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by country),
		cte_city as
			(select city, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by city)
	select group_concat(distinct country.country,', ') as "country", group_concat(city.city,', ') as "city"
	from cte_country country
	cross join cte_city city
	where country.rnk = 1
	and city.rnk = 1;

#15-------Identify the artist and the museum where the most expensive and least expensive painting is placed. 
#Display the artist name, sale_price, painting name, museum name, museum city and canvas label
	with cte as 
		(select *
		, rank() over(order by sale_price desc) as rnk
		, rank() over(order by sale_price ) as rnk_asc
		from product_size )
	select w.name as painting
	, cte.sale_price
	, a.full_name as artist
	, m.name as museum, m.city
	, cz.label as canvas
	from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cz on cz.size_id = CAST(cte.size_id AS DECIMAL)
	where rnk=1 or rnk_asc=1;

#16--Which country has the 5th highest no of paintings?
	with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;

#17----Which are the 3 most popular and 3 least popular painting styles?
	with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;

#18----Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
	select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	









