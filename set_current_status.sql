DROP TABLE IF EXISTS sandbox_va_2.va02_event_p_currstat;

CREATE TABLE sandbox_va_2.va02_event_p_currstat
AS
  select mod.vanid,	mod.date,	mod.name,	mod.phone, mod.status,	mod.recruited_by,	mod.signup_date, 
  			 mod.today14,	mod.today30, mod.organizer, mod.last_recruit, mod.sched_bool, mod.cnt_comp_tot,	
  			 mod.cnt_flake, mod.cnt_comp_14, mod.cnt_comp_30, mod.proper_organizer, status.curr_status
  
  --start with modded participant list
  from sandbox_va_2.va02_event_p_mod as mod
  
  left outer join
  
  --join with current status on vanid
  (
    select *, 
           CASE WHEN latest_count.last_date >= dateadd(day, -13, getdate()) and 
                     latest_count.last_cnt_comp_14 >= 2 THEN 'super_active'
                WHEN latest_count.last_date >= dateadd(day, -29, getdate()) and 
                   latest_count.last_cnt_comp_30 >= 2 THEN 'active'
                WHEN latest_count.last_date >= dateadd(day, -29, getdate()) and 
                   latest_count.last_cnt_comp_30 = 1 THEN 'almost_active'
                ELSE 'drop_off'
                END as curr_status
    from
      (
      select distinct t.vanid,
      --latest date vol participated  
      last_value(t.date) over (
        partition by vanid
        order by t.date asc
        rows between unbounded preceding and unbounded following) as last_date,
        
      --latest completed number in last 14 days for latest date
      last_value(t.cnt_comp_14) over (
        partition by vanid
        order by t.date asc
        rows between unbounded preceding and unbounded following) as last_cnt_comp_14,
        
      --latest completed number in last 30 days for latest date
      last_value(t.cnt_comp_30) over (
        partition by vanid
        order by t.date asc
        rows between unbounded preceding and unbounded following) as last_cnt_comp_30
        
      from sandbox_va_2.va02_event_p_mod as t
      ) as latest_count
  ) as status
  on status.vanid = mod.vanid
  
  