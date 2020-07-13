create view [dbo].[te_aagsesshist_summary]
as
    (
    select
        DATEADD( minute, ( DATEDIFF( minute, 0, DATEADD( second, ( 15 * 60 ) / 2, c.login_time ) ) / 15 ) * 15, 0 ) as datelist
	  , COUNT(c.login_time) as cntr_value
	  , status
    --,status
    from dbo.aagsesshist c
    where 1=1
        and c.login_time > GETDATE()-35
        and c.status = 'n'
        and c.system_name != ' '
    group by DATEADD( minute, ( DATEDIFF( minute, 0, DATEADD( second, ( 15 * 60 ) / 2, c.login_time ) ) / 15 ) * 15, 0 ),status --, t.datelist
)
GO