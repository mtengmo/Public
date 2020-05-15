-- before Unit4 Businessworld M7, msg filesuffix was flagged as text/plain in docarchive.
-- because of that preview in web doesn´t work

begin tran
select
    *
into adsfileinfo
from
    adsfileinfo
select
    *
into adspage
from
    adspage
select
    *
into adsdocument
from
    adsdocument
CREATE TABLE [adsfileinfo_audit_20200514]
(
    file_guid uniqueidentifier,
    old_mime_type VARCHAR (255),
    new_mime_type VARCHAR (255),
    ModificationDate DATETIME
);

CREATE TABLE [adsdocument_audit_20200514]
(
    doc_guid uniqueidentifier,
    old_mime_type VARCHAR (255),
    new_mime_type VARCHAR (255),
    ModificationDate DATETIME
);

update
    adsdocument
set
    mime_type = 'application/vnd.ms-outlook' 
	output [deleted].doc_guid,
    [deleted].mime_type,
    [inserted].mime_type,
    GETUTCDATE() INTO adsdocument_audit_20200514
from
    adsfileinfo a,
    adspage d,
    adsdocument c
where
    a.file_suffix = 'msg'
    and a.mime_type = 'text/plain'
    and a.file_guid = d.file_guid
    and c.doc_guid = d.doc_guid



update
    adsfileinfo
set
    mime_type = 'application/vnd.ms-outlook'
	output [deleted].file_guid,
    [deleted].mime_type,
    [inserted].mime_type,
    GETUTCDATE() INTO [adsfileinfo_audit_20200514]
where
    file_suffix = 'msg'
    and mime_type = 'text/plain'




select *
from adsdocument_audit_20200514
select *
from [adsfileinfo_audit_20200514]


--rollback