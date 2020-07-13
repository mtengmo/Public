USE [DB_P_AGRESSO]
GO

/****** Object:  View [dbo].[te_agresso_baseline]    Script Date: 2020-07-10 13:49:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER   view [dbo].[te_agresso_baseline]
as

    with
        cte_datelist (datelist)
        as
        (
            SELECT distinct(DATEADD( minute, ( DATEDIFF( minute, 0, DATEADD( second, ( 15 * 60 ) / 2, t.datelist ) ) / 15 ) * 15, 0 ))
            from dbo.[Get_DateList_uft]('MINUTE', dateadd(hour, datediff(hour, 0, getdate()-30), 0),NULL) t

        )

                    SELECT
            'Agresso Reports_baseline' as cntr_name
, 'spline' as type
, t.datelist
, avg(c.cntr_value)  as cntr_value
, c.ing_status
        --  ,COUNT(c.datelist) Instances

        FROM [dbo].te_acrrepord_summary c
  CROSS APPLY (
  select distinct(dateadd(hour, datediff(hour, 0, datelist), 0)) as datelist
            from cte_datelist
   ) t

        where 1=1
            and c.ing_status = 0


            and DATENAME(dw, c.datelist ) = DATENAME(dw, t.datelist ) -- week
            and DATEPART(hh, c.datelist) = DATEPART(hh, t.datelist)

        -- and DATEPART(dw, c.datelist) = 3
        -- and DATEPART(hh, c.datelist) = 23
        GROUP BY c.ing_status,DATENAME(dw, c.datelist ), DATEPART(dw, c.datelist), DATEPART(hh, c.datelist),t.datelist
        --order by datelist
    union all
        SELECT
            'Agresso Reports' as cntr_name
, 'area' as type
, t.datelist
, c.cntr_value
, c.ing_status
        from te_acrrepord_summary c
  CROSS APPLY (
  select datelist
            from cte_datelist
   ) t
        where 1=1
            and c.ing_status = 0
            and c.datelist = t.datelist
        group by t.DateList, c.ing_status,c.cntr_value
    --order by t.datelist, ctrl_name
    UNION ALL

        SELECT
            'Agresso logons_baseline' as cntr_name
, 'spline' as type
, t.datelist
, avg(c.cntr_value)  as cntr_value

--  ,COUNT(c.datelist) Instances
, null as ing_status
        FROM [dbo].[te_aagsesshist_summary] c
  CROSS APPLY (
  select distinct(dateadd(hour, datediff(hour, 0, datelist), 0)) as datelist
            from cte_datelist
   ) t

        where 1=1


            and DATENAME(dw, c.datelist ) = DATENAME(dw, t.datelist ) -- week
            and DATEPART(hh, c.datelist) = DATEPART(hh, t.datelist)

        -- and DATEPART(dw, c.datelist) = 3
        -- and DATEPART(hh, c.datelist) = 23
        GROUP BY DATENAME(dw, c.datelist ), DATEPART(dw, c.datelist), DATEPART(hh, c.datelist),t.datelist
    --order by datelist
    union all
        SELECT
            'Agresso logons' as cntr_name
, 'area' as type
, t.datelist
, c.cntr_value
, null as ing_status
        from [te_aagsesshist_summary] c
  CROSS APPLY (
  select datelist
            from cte_datelist
   ) t
        where 1=1
            and c.datelist = t.datelist
        group by t.DateList, c.status,c.cntr_value

GO


