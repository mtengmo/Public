

SET QUOTED_IDENTIFIER ON
GO
drop table [eventlog_forwardedevents]
CREATE TABLE [dbo].[eventlog_forwardedevents]
(
    [pk_id] int IDENTITY(1,1) PRIMARY KEY,
    [Id] [int] NULL,
    [LevelDisplayName] [nvarchar](max) NULL,
    [LogName] [nvarchar](255) NULL,
    [MachineName] [nvarchar](150) NULL,
    [Messages] [nvarchar](max) NULL,
    [ProviderName] [nvarchar](max) NULL,
    [RecordId] [bigint] NULL,
    [TaskDisplayName] [nvarchar](max) NULL,
    [TimeCreated] [datetime2](7) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
      

GO


-- Create Unique Clustered Index with IGNORE_DUPE_KEY=ON to avoid duplicates in sqlbulk imports
CREATE UNIQUE  INDEX [ixu_eventlog_forwardevents] ON [dbo].[eventlog_forwardedevents]
(
     [RecordID] ASC,
     [MachineName] ASC,
     [LogName] ASC
) WITH (IGNORE_DUP_KEY = ON)
GO

CREATE FULLTEXT CATALOG fulltextCatalog AS DEFAULT;
DROP FULLTEXT INDEX ON eventlog_forwardedevents;

CREATE FULLTEXT INDEX ON eventlog_forwardedevents(messages) 
KEY INDEX PK__eventlog__1543595ECC76ACC8






