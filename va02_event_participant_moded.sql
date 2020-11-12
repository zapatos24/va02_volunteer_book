DROP TABLE IF EXISTS sandbox_va_2.va02_event_p_mod;

CREATE TABLE sandbox_va_2.va02_event_p_mod
AS
-- cleaned event participants with today-14 and today-30
select p.vanid, p.date, p.name, 
  		 CASE WHEN charindex(',', p.name) != 0 THEN left(p.name, charindex(',', p.name)-1)
       			ELSE p.name
            END as last_name, 
  		 CASE WHEN charindex(',', p.name) != 0 THEN right(p.name, len(p.name) - charindex(',', p.name))
       			ELSE p.name
            END as first_name,
       p.phone, p.cell_phone, p.status, p.recruited_by, p.signup_date,
			 p.today14, p.today30, r.organizer, lr.last_recruit, ls.sched_bool, comp.cnt_comp_tot,
       flk.cnt_flake, comp_14.cnt_comp_14, comp_30.cnt_comp_30,
  		 -- create column for proper organizer when deciding between recruited by and turfed FO
       CASE WHEN r.organizer = 'Giordano, Peggy' and lr.last_recruit = 'Mackey, Erin' THEN lr.last_recruit
       			WHEN r.organizer is not null THEN r.organizer
            WHEN r.organizer is null and lr.last_recruit is not null THEN lr.last_recruit
            ELSE 'Not Assigned'
            END as proper_organizer

from(
	 select *, trunc(today-14) as today14, 
  				trunc(today-30) as today30
	 from(
  	select d.vanid, d.event, d.date, d.time, d.name, d.phone, d.cell_phone, d.status, 
     			 d.recruited_by, d.signup_date, getdate() as today
  	from sandbox_va_2.va02_event_participants as d
    where d.event not ilike '_Cancelled%' and
     			d.event not ilike '%1:1%' and
     			d.role != 'Textbanker'
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
  select distinct recruit_sub.vanid,
         last_value(recruit_sub.recruited_by) over (
              partition by vanid
              order by recruit_sub.date asc, recruit_sub.time asc
              rows between unbounded preceding and unbounded following) as last_recruit
  from sandbox_va_2.va02_event_participants as recruit_sub
  where recruit_sub.recruited_by is not null and
  			recruit_sub.role != 'Textbanker'
  order by recruit_sub.vanid
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
      select distinct sched_sub.vanid, 
                 last_value(sched_sub.date) over (
                    partition by vanid
                    order by sched_sub.date asc, sched_sub.time asc
                    rows between unbounded preceding and unbounded following) as last_shift
      from sandbox_va_2.va02_event_participants as sched_sub
      where sched_sub.status != 'Cancelled' and 
      			sched_sub.status != 'Declined' and
      			sched_sub.role != 'Textbanker'
    )
  
) as ls
on p.vanid = ls.vanid


-- add total completed shifts
left outer join
  (
    select vanid, COUNT(name) as cnt_comp_tot
    from sandbox_va_2.va02_event_participants
    where status = 'Completed' and 
    			event not ilike '_Cancelled%' and
    			event not ilike '%1:1%' and
    			role != 'Textbanker'
    group by vanid
  ) as comp
on p.vanid = comp.vanid


-- add total declined/no show shifts
left outer join
  (
    select vanid, COUNT(name) as cnt_flake
    from sandbox_va_2.va02_event_participants
    where status = 'Declined' or status = 'No Show' and 
    			event not ilike '_Cancelled%' and
    			event not ilike '%1:1%' and
    			role != 'Textbanker'
    group by vanid
  ) as flk
on p.vanid = flk.vanid
  

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
         where sub1.event not ilike '_Cancelled%' and 
    					 sub1.event not ilike '%1:1%' and
         			 sub1.status = 'Completed' and
         			 sub1.role != 'Textbanker'
         group by 1,2
       ) as t1
       join 
       (
         select sub2.vanid, sub2.date, count(sub2.event) as count_t2
         from sandbox_va_2.va02_event_participants as sub2
         where sub2.event not ilike '_Cancelled%' and 
    					 sub2.event not ilike '%1:1%' and
         			 sub2.status = 'Completed' and
         			 sub2.role != 'Textbanker'
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
         where sub1.event not ilike '_Cancelled%' and
    					 sub1.event not ilike '%1:1%' and
         			 sub1.status = 'Completed' and
         			 sub1.role != 'Textbanker'
         group by 1,2
       ) as t1
       join 
       (
         select sub2.vanid, sub2.date, count(sub2.event) as count_t2
         from sandbox_va_2.va02_event_participants as sub2
         where sub2.event not ilike '_Cancelled%' and 
    					 sub2.event not ilike '%1:1%' and
         			 sub2.status = 'Completed' and
         			 sub2.role != 'Textbanker'
         group by 1,2
       ) as t2
       on t1.vanid = t2.vanid and t2.date between dateadd(day, -29, t1.date) and t1.date
    ) as act
    group by 1,2
    order by 1,2
  ) as comp_30
  on p.vanid = comp_30.vanid and p.date = comp_30.date

