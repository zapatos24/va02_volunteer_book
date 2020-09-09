-- cleaned event participants with today-14 and today-30
select p.vanid, p.date, p.name, p.phone, p.status, p.recruited_by, p.signup_date,
			 p.today14, p.today30, r.organizer, lr.last_recruit, ls.sched_bool,
       CASE WHEN r.organizer = 'Giordano, Peggy' and lr.last_recruit = 'Mackey, Erin' THEN lr.last_recruit
       			WHEN r.organizer is not null THEN r.organizer
            WHEN r.organizer is null and lr.last_recruit is not null THEN lr.last_recruit
            ELSE null
            END as proper_organizer
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
-- add turfed FO
left outer join

(
  select vanid, organizer from sandbox_va_2.region_assignment
) as r
on p.vanid = r.vanid


--
--add latest recruit
left outer join

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
-- add scheduled boolean
left outer join
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
-- add url for votebuilder: my campaign


--
-- add status for super_active, active, almost_active, drop_off


--
-- add flake status 

