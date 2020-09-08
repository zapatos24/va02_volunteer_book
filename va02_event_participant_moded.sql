-- cleaned event participants with today-14 and today-30
select p.vanid, p.date, p.name, p.phone, p.status, p.recruited_by, p.signup_date,
			 p.today14, p.today30, r.organizer, lr.last_recruit, ls.sched_bool
from(
	 select *, trunc(today-14) as today14, 
  				trunc(today-30) as today30
		from(
  			select vanid, date, name, phone, status, recruited_by, 
      			   signup_date, getdate() as today
  			from sandbox_va_2.va02_event_participants
        )
    ) as p

--
left outer join
-- add turfed FO

(
  select vanid, organizer from sandbox_va_2.region_assignment
) as r
on p.vanid = r.vanid

--
left outer join
--add latest recruit

(
  select distinct vanid,
         last_value(recruited_by) over (
              partition by vanid
              order by date asc, time asc
              rows between unbounded preceding and unbounded following) as last_recruit
  from sandbox_va_2.va02_event_participants
  where recruited_by is not null
  order by vanid
) as lr
on p.vanid = lr.vanid

--
left outer join
-- add scheduled boolean
(
  select vanid,
  		 CASE WHEN last_shift > getdate() THEN 'True'
  		 ELSE 'False'
  		 END as sched_bool
  from
    (--get the latest date a person has been shifted
      select distinct vanid, 
                 last_value(date) over (
                    partition by vanid
                    order by date asc, time asc
                    rows between unbounded preceding and unbounded following) as last_shift
      from sandbox_va_2.va02_event_participants
      where status != 'Cancelled' and status != 'Declined'
    )
  
) as ls
on p.vanid = ls.vanid

--
left outer join
-- add url for votebuilder: my campaign


