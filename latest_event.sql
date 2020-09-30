select distinct vanid,
       last_value(date) over (
            partition by vanid
            order by date asc, time asc
            rows between unbounded preceding and unbounded following) as last_date,
       last_value(event) over (
            partition by vanid
            order by date asc, time asc
            rows between unbounded preceding and unbounded following) as last_event
from public.va02_event_participants
where status = 'Completed' and event not like '%Cancelled%'
order by vanid