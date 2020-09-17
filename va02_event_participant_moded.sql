DROP TABLE IF EXISTS sandbox_va_2.va02_event_p_mod;

CREATE TABLE sandbox_va_2.va02_event_p_mod
AS
(
-- cleaned event participants with today-14 and today-30
select p.vanid, p.date, p.name, p.phone, p.status, p.recruited_by, p.signup_date,
			 p.today14, p.today30, r.organizer, lr.last_recruit, ls.sched_bool, comp.cnt_comp_tot,
       flk.cnt_flake, comp_14.cnt_comp_14, comp_30.cnt_comp_30,
       CASE WHEN r.organizer = 'Giordano, Peggy' and lr.last_recruit = 'Mackey, Erin' THEN lr.last_recruit
       			WHEN r.organizer is not null THEN r.organizer
            WHEN r.organizer is null and lr.last_recruit is not null THEN lr.last_recruit
            ELSE null
            END as proper_organizer
from(
	 select *, trunc(today-14) as today14, 
  				trunc(today-30) as today30
	 from(
  	select d.vanid, d.event, d.date, d.time, d.name, d.phone, d.status, d.recruited_by, 
      		 d.signup_date, getdate() as today
  	from sandbox_va_2.va02_event_participants as d
    where event not ilike '_Cancelled%'
       )
    ) as p


-- add turfed FO
left outer join
(
  select vanid, organizer from sandbox_va_2.region_assignment
) as r
on p.vanid = r.vanid


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


-- add total completed shifts
left outer join
  (
    select vanid, COUNT(name) as cnt_comp_tot
    from sandbox_va_2.va02_event_participants
    where status = 'Completed' and event not ilike '_Cancelled%'
    group by vanid
  ) as comp
on p.vanid = comp.vanid


-- add total declined/no show shifts
left outer join
  (
    select vanid, COUNT(name) as cnt_flake
    from sandbox_va_2.va02_event_participants
    where status = 'Declined' or status = 'No Show' and event not ilike '_Cancelled%'
    group by vanid
  ) as flk
on p.vanid = flk.vanid


-- add url for votebuilder: my campaign



-- add status for super_active, active, almost_active, drop_off

-- count how many completed shifts over 14 day rolling window for each van id 
left outer join
  (
    select act.vanid, act.date, sum(act.count_t2) as cnt_comp_14
    from
    (
       select t1.vanid, t1.date, t2.count_t2
       from
       (
         select sub1.vanid, sub1.date, count(sub1.event) as count_t1
         from sandbox_va_2.va02_event_participants as sub1
         where sub1.event not ilike '_Cancelled%' and sub1.status = 'Completed'
         group by 1,2
       ) as t1
       join 
       (
         select sub2.vanid, sub2.date, count(sub2.event) as count_t2
         from sandbox_va_2.va02_event_participants as sub2
         where event not ilike '_Cancelled%' and sub2.status = 'Completed'
         group by 1,2
       ) as t2
       on t1.vanid = t2.vanid and t2.date between dateadd(day, -13, t1.date) and t1.date
    ) as act
    group by 1,2
    order by 1,2
  ) as comp_14
  on p.vanid = comp_14.vanid and p.date = comp_14.date

-- count how many completed shifts over 30 day rolling window for each van id
left outer join
  (
    select act.vanid, act.date, sum(act.count_t2) as cnt_comp_30
    from
    (
       select t1.vanid, t1.date, t2.count_t2
       from
       (
         select sub1.vanid, sub1.date, count(sub1.event) as count_t1
         from sandbox_va_2.va02_event_participants as sub1
         where sub1.event not ilike '_Cancelled%' and sub1.status = 'Completed'
         group by 1,2
       ) as t1
       join 
       (
         select sub2.vanid, sub2.date, count(sub2.event) as count_t2
         from sandbox_va_2.va02_event_participants as sub2
         where event not ilike '_Cancelled%' and sub2.status = 'Completed'
         group by 1,2
       ) as t2
       on t1.vanid = t2.vanid and t2.date between dateadd(day, -29, t1.date) and t1.date
    ) as act
    group by 1,2
    order by 1,2
  ) as comp_30
  on p.vanid = comp_30.vanid and p.date = comp_30.date
  
  
-- add flake status 
)
