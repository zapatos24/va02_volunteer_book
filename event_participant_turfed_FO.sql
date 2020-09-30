select *
from(
	 select *, today-14 as today14, today-30 as today30
		from(
  			select vanid, date, name, phone, status, recruited_by, 
      			   signup_date, getdate() as today
  			from public.va02_event_participants
        )
    ) as p
left outer join
(select vanid, organizer from public.region_assignment) as r
on p.vanid = r.vanid