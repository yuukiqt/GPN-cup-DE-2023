with 
	ranked_products as (
		select
			st.store_region,
    		extract('YEAR' from s.sales_date) as sales_year,
    		extract('MONTH' from s.sales_date) as sales_month,
    		s.good_name,
    		sum(s.s_sum) AS total_sales,
    		row_number() over (partition by st.store_region, 
									extract('YEAR' from s.sales_date), 
									extract('MONTH' from s.sales_date) 
								order by sum(s.s_sum) desc) as rank
  		from sales s
  		join stores st on s.store_id = st.store_id
		group by
    		st.store_region,
    		extract('YEAR' from s.sales_date),
    		extract('MONTH' from s.sales_date),
    		s.good_name
	),
	total_sales_per_year as (
		select
    		st.store_region,
    		extract('YEAR' from s.sales_date) as sales_year,
    		sum(s.s_sum) as total_sales_in_region
  		from sales s
  		join stores st on s.store_id = st.store_id
		group by
    		st.store_region,
			extract('YEAR' from s.sales_date)
	),
	sales_per_month as (
  		select
    		st.store_region,
    		extract('YEAR' from s.sales_date) as sales_year,
    		extract('MONTH' from s.sales_date) as sales_month,
    		sum(s.s_sum) as total_sales_in_region
  		from sales s
  		join stores st on s.store_id = st.store_id
		group by
			st.store_region,
			extract('YEAR' from s.sales_date),
			extract('MONTH' from s.sales_date)
	),
	total_sales_per_product as (
		select
			s.good_name,
			sum(s.s_sum) as total_sales_across_network
		from sales s
		group by s.good_name
	)
select
	rp.store_region,
	rp.sales_month,
	rp.good_name,
	rp.total_sales,
	round((rp.total_sales / tspm.total_sales_in_region) * 100, 2) as percent_sales_in_region_per_year,
	round((rp.total_sales / tsp.total_sales_across_network) * 100, 2) as percent_sales_across_stores,
	round((rp.total_sales / sm.total_sales_in_region) * 100, 2) as percent_total_sales_in_region
from ranked_products rp
join total_sales_per_year tspm on 
	rp.store_region = tspm.store_region 
	and rp.sales_year = tspm.sales_year
join sales_per_month sm on 
	rp.store_region = sm.store_region 
	and rp.sales_month = sm.sales_month
join total_sales_per_product tsp on rp.good_name = tsp.good_name
where rp.rank <= 3
order by
	rp.store_region,
	rp.sales_month,
	rp.rank;
