with
	both_in_check as (
		select 
			extract('MONTH' from s1.sales_date) as month, 
			coalesce(sum(s1.s_sum) + sum(s2.s_sum), 0) as both
		from sales s1
		join sales s2 on s1.check_num = s2.check_num
		where s1.good_name = 'товар01' and s2.good_name = 'товар02'
		group by extract('MONTH' from s1.sales_date)
	),
	without_tovar02_in_check as (
		select 
			extract('MONTH' from s1.sales_date) as month, 
			coalesce(sum(s1.s_sum), 0) as only_tovar01_sum
		from sales s1
		left join sales s2 on 
			s1.check_num = s2.check_num 
			and s2.good_name = 'товар02'
		where s1.good_name = 'товар01' and s2.check_num is null
		group by extract('MONTH' from s1.sales_date)
	),
	without_tovar01_in_check as (
		select 
			extract('MONTH' from s1.sales_date) as month, 
			coalesce(sum(s1.s_sum), 0) as only_tovar02_sum
		from sales s1
		left join sales s2 on 
			s1.check_num = s2.check_num 
			and s2.good_name = 'товар01'
		where s1.good_name = 'товар02' and s2.check_num is null
		group by extract('MONTH' from s1.sales_date)
	),
	without_both_in_check as (
		select 
			extract('MONTH' from s1.sales_date) as month, 
			coalesce(sum(s1.s_sum), 0) as never_both
		from sales s1
		left join sales s2 on 
			s1.check_num = s2.check_num 
			and (s2.good_name = 'товар01' or s2.good_name = 'товар02')
		where 
			s1.good_name not in ('товар01', 'товар02') 
			and s2.check_num is null
		group by extract('MONTH' from s1.sales_date)
	),
	months as (
		select generate_series(1,12) as month
	)
select 
	m.month as month,
	coalesce(b.both, 0)as sold_both,
	coalesce(wt2.only_tovar01_sum, 0) as only_tovar01_sum,
	coalesce(wt1.only_tovar02_sum, 0) as only_tovar01_sum,
	coalesce(wb.never_both, 0) as without_both
from months m
left join both_in_check b on m.month = b.month
left join without_tovar02_in_check wt2 on m.month = wt2.month
left join without_tovar01_in_check wt1 on m.month = wt1.month
left join without_both_in_check wb on m.month = wb.month
order by m.month
