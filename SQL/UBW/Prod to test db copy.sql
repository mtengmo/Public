// Draft copy prod to test
sp_changedbowner 'agrtest'


declare @LastExtractDate varchar(255)
select top 1
	@LastExtractDate=format([last_update],'yyyy-MM-dd')
from acrrepord
order by last_update desc
update acrclient
	set client_name = '*TEST* ' + @LastExtractDate + ' ' + client_name



declare @newhostname varchar(255) = 'prodhostname'

declare @oldhostname varchar(255)
select top 1
	@oldhostname=trim(server_name)
from aagserverqueue
where status = 'n'
order by last_update desc

update aagserverqueue
set server_name = replace(server_name, @oldhostname, @newhostname) 
where status = 'n'
select *
from aagserverqueue
where status = 'n'


declare @newwebhostname varchar(255) = 'agrtest.domain.se'
declare @oldwebhostname varchar(255)
select top 1
	@oldwebhostname=trim(host)
from aagserviceuri
where status = 'n'
order by last_update desc

update aagserviceuri
 set host = replace(host, @oldwebhostname, @newwebhostname)
 where status = 'n'

select *
from aagserviceuri




update agladdress
  set e_mail = replace(e_mail, '@', '!')
  where e_mail != ''

