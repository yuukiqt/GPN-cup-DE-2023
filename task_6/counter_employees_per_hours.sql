-- append values to work day in [mon - fri]
-- cuz currently we have only weekends days on db
insert into store_acs (store_id, employee_id, event_ts, event_type)
values
    (1, 1, '2023-11-06 09:00:30', '1'),     
    (1, 2, '2023-11-06 09:30:51', '1'),     
    (1, 1, '2023-11-06 12:13:00', '-1'),    
    (1, 2, '2023-11-06 17:20:00', '-1'),   
    (1, 1, '2023-11-06 18:30:30', '1'),
    (1, 1, '2023-11-06 21:00:00', '-1'),
    (2, 3, '2023-11-06 10:15:00', '1'),   
    (2, 3, '2023-11-06 14:21:20', '-1'), 
    (2, 4, '2023-11-06 13:30:05', '1'),  
    (2, 4, '2023-11-06 19:37:00', '-1'),
    (2, 3, '2023-11-06 20:41:00', '1'),
    (2, 3, '2023-11-06 21:10:00', '-1'),
	(1, 1, '2023-11-05 09:00:30', '1'); -- for test weekend day
    

with 
	hours as (
    	select generate_series(9, 21) as hour --generate hours series [9:21]
	),
	entry_events as (   -- get all entry events // where event_type = 1
	    select
	        store_id,
	        extract('HOUR' from event_ts) as hour,
	        count(*) as entry_count
	    from
	        store_acs
	    where
	        event_ts::date = to_date('2023-11-06', 'YYYY-MM-DD') and event_type = '1'
	    group by
	        store_id, 
	        extract('HOUR' from event_ts)
	),
	exit_events as (   -- get all exit events // where event_type = -1
	    select
	        store_id,
	        extract('HOUR' from event_ts) as hour,
	        count(*) as exit_count
	    from
	        store_acs
	    where
	        event_ts::date = to_date('2023-11-06', 'YYYY-MM-DD') AND event_type = '-1'
	    group by
	        store_id, 
	        extract('HOUR' from event_ts)
	)
select
    h.hour,
    s.store_id,
    coalesce(sum(ee.entry_count) over (partition by s.store_id order by h.hour), 0) -
    coalesce(sum(ex.exit_count) over (partition by s.store_id order by h.hour), 0) AS count_employees
from
    hours h
cross join
    (select distinct store_id from store_acs) s
left join
    entry_events ee on h.hour = ee.hour and s.store_id = ee.store_id
left join
    exit_events ex on h.hour = ex.hour and s.store_id = ex.store_id
WHERE
    EXTRACT(DOW FROM DATE '2023-11-06') NOT IN (0, 6) -- if its weekends we get empty report
order by
    h.hour,
    s.store_id;
