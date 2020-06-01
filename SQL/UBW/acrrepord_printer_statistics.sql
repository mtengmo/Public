
select report_name, orderno, client, date_started, description, printer, user_id, CASE 
    WHEN ing_status = 0 THEN 'Normal'
    WHEN ing_status = 2 THEN 'No rows'
	WHEN ing_status = 3 THEN 'Functional Errors'
	WHEN ing_status = 4 THEN 'Technical Errors'
    ELSE 'Unknown error' End as ing_status_desc
from acrrepord
where printer != 'default'
    and printer not like 'fil%'
    and date_started > getdate()-30
order by agrtid desc


select Distinct(description), client, user_id, count(*) as antal
from acrrepord
where printer != 'default'
    and printer not like 'fil%'
group by client,description, user_id
order by antal desc



select Distinct(description), client, user_id, count(*) as antal
, CASE 
    WHEN ing_status = 0 THEN 'Normal'
    WHEN ing_status = 2 THEN 'No rows'
	WHEN ing_status = 3 THEN 'Functional Errors'
	WHEN ing_status = 4 THEN 'Technical Errors'
    ELSE 'Unknown error' End as ing_status_desc
from acrrepord
where printer != 'default'
    and printer not like 'fil%'
group by client,description, user_id,ing_status
order by antal desc
