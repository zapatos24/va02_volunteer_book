select distinct vanid,
       last_value(recruited_by) over (
            partition by vanid
            order by date asc, time asc
            rows between unbounded preceding and unbounded following) as last_recruit
from public.va02_event_participants
where recruited_by is not null
order by vanid