DROP TABLE IF EXISTS sandbox_va_2.va02_event_p_currstat;

CREATE TABLE sandbox_va_2.va02_event_p_currstat
AS
  select mod.vanid,	mod.date,	mod.name,	mod.last_name, mod.first_name,
  			 mod.phone, mod.cell_phone, mod.status,	mod.recruited_by,	mod.signup_date, 
  			 mod.today14,	mod.today30, mod.organizer, mod.last_recruit, mod.sched_bool, mod.cnt_comp_tot,	
  			 mod.cnt_flake, mod.cnt_comp_14, mod.cnt_comp_30, mod.proper_organizer,
         
    		 CASE WHEN latest_count.curr_date_comp_14 >= 2 THEN 'super_active'
   			 WHEN latest_count.curr_date_comp_30 >= 2 THEN 'active'
 			   WHEN latest_count.curr_date_comp_30 = 1 THEN 'almost_active'
 			   ELSE 'drop_off'
 			   END as curr_status
  
  --start with modded participant list
  from sandbox_va_2.va02_event_p_mod as mod
  
  left outer join
  
  (--table of vanid and how many completed shifts in last 14 days
    select sub1.vanid, sub1.curr_date_comp_14, sub2.curr_date_comp_30
    from
    (
      select t1.vanid, count(t1.status) as curr_date_comp_14
      from sandbox_va_2.va02_event_p_mod as t1
      where t1.date between date_trunc('day', dateadd(day, -13, getdate())) and 
      											date_trunc('day', getdate()) and
      			t1.status = 'Completed'
      group by 1
    ) as sub1

    left outer join

    (--table of vanid and how many completed shifts in last 30 days
      select t2.vanid, count(t2.status) as curr_date_comp_30
      from sandbox_va_2.va02_event_p_mod as t2
      where t2.date between date_trunc('day', dateadd(day, -29, getdate())) and 
      										  date_trunc('day', getdate()) and
      			t2.status = 'Completed'
      group by 1
    ) as sub2 
    on sub1.vanid = sub2.vanid

  ) as latest_count
	on latest_count.vanid = mod.vanid
  
  