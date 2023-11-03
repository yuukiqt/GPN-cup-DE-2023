-- createdb gpn -O shouji -W 1234

create table stores(
	store_id int primary key,
	store_name varchar(50),
	store_region varchar(50));
	
create table sales(
	check_num int,
	sales_date date,
	store_id int,
	good_name varchar(50),
	s_count int,
	s_sum decimal(18,2), -- best practice for price
	primary key (check_num, sales_date, store_id));
alter table sales add foreign key (store_id) references stores(store_id);


create table store_acs(
	store_id int,
	employee_id int,
	event_ts timestamp,
	event_type char(2)); -- seems bad (1,-1) => 2symb // but can use (1,0) => char(1)
alter table store_acs add foreign key (store_id) references stores(store_id);

-- generate data for stores
with recursive
	store_names(store_id, store_name) as 
	(
		select 1, 'Магазин01'
		union all
		select
			store_id + 1,
			case
				when store_id between 1 and 8 then 'Магазин0' || store_id + 1
				else 'Магазин' || store_id + 1
			end as store_name
		from store_names
		where store_id < 3 -- count of creating store rows
	),
	region_names(region_id, region_name) as 
	(
		select 1, 'Регион01'
		union all
		select 
	  		region_id + 1,
	  		case
	  			when region_id between 1 and 8 then 'Регион0' || region_id + 1
	  			else 'Регион' || region_id + 1
	  		end as region_name
	  	from region_names
	  	where region_id < 5  -- count of creating region rows
	)
insert into stores(store_id, store_name, store_region)
(
	select
		ROW_NUMBER() OVER () as store_id, -- using window func for create seq
		store_name,
		region_name
	from region_names, store_names
);

-- generate data for sales
with recursive 
	product_names(product_id, product_name) as
	(
		select 1, 'товар01'
		union all
		select
			product_id + 1,
			case 
				when product_id between 1 and 8 then 'товар0' || product_id + 1
				else 'товар' || product_id + 1
			end as product_name
		from product_names
		where product_id < 20 -- count of creating product rows
	),
	date_range AS (
		SELECT 
			(CURRENT_DATE - INTERVAL '3 months')::date AS sales_date  -- get date 3 month ago, format ['YYYY-MM-DD']
		UNION ALL
		SELECT (sales_date + INTERVAL '1 day')::date
		FROM date_range
		WHERE sales_date < CURRENT_DATE
)
insert into sales(check_num, sales_date, store_id, good_name, s_count, s_sum)
(SELECT
	ROW_NUMBER() OVER () as check_num,
	dr.sales_date,
	s.store_id,
	pn.product_name,
	FLOOR(RANDOM() * 12) + 5 as s_count,  -- generate random count range(5,16)
	((FLOOR(RANDOM() * 100) + 1)* 1.33)::decimal(18,2) as s_sum  -- generate random sum range(1.33,133.00)
from date_range dr
cross join stores s
cross join product_names pn
left join sales sa
on dr.sales_date = sa.sales_date
	and s.store_id = sa.store_id
	and pn.product_name = sa.good_name
where sa.check_num is null);

-- fill store_acs
insert into store_acs (store_id, employee_id, event_ts, event_type)
VALUES
    (1, 1, '2023-11-02 09:00:30', '1'),     
    (1, 2, '2023-11-02 09:30:51', '1'),     
    (1, 1, '2023-11-02 12:13:00', '-1'),    
    (1, 2, '2023-11-02 17:20:00', '-1'),   
    (1, 1, '2023-11-02 18:30:30', '1'),
    (1, 1, '2023-11-02 21:00:00', '-1'),
    (2, 3, '2023-11-02 10:15:00', '1'),   
    (2, 3, '2023-11-02 14:21:20', '-1'), 
    (2, 4, '2023-11-02 13:30:05', '1'),  
    (2, 4, '2023-11-02 19:37:00', '-1'),
    (2, 3, '2023-11-02 20:41:00', '1'),
    (2, 4, '2023-11-02 20:33:00', '1');

