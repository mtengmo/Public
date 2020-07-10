
-- http://services.agresso.com/events/
CREATE or ALTER view [dbo].[eventlog_forwardedevents_desc]
as
    (
    select
        [pk_id],
        [Id],
        [LevelDisplayName],
        [LogName],
        [MachineName],
        [Messages],
        [ProviderName],
        [RecordId],
        [TaskDisplayName],
        [TimeCreated],
        case
                when id = 2003 then 'The service was not able to connect to the database. This message is logged just once during startup. The service will continue to re-try the operation until success.'
                when id = 2004 then 'The service has successfully connected to the database.'
                when id = 2007 then 'Database connection was lost. This message is logged whenever the database connection is lost after a successfully connect.'
                when id = 2008 then 'Database connection was restored. This message is logged whenever the database connection is restored after beeing lost.'
                when id = 2034 then 'Error in configuration. General message.'
                when id = 2064 then 'Missing database configuration.'
                when id = 2066 then 'General event id related to database configuration and initialization.'
                when id = 3000 then 'Error when loading authentication assembly or authenticator'
                when id = 3001 then 'Warning when loading authenticator'
                when id = 3002 then 'Authentication information message'
                when id = 3003 then 'User authentication failed. Raised when a user is unable to log into the system using the selected authenticator. The reason can be read from the details of the event and the error code. Username and password related reasons: * User with specified username does not exist (IllegalUser) * Wrong password (WrongPassword) * Expired password (ExpiredPassword) User account related reasons: * User has no roled (NoRole) * User does not have access to client (IllegalClient) * User is disabled and does not have access on this date (Disabled) * User is not active, Status is not N. (NotActive) * User account is locked. (LockedOut) * User does not have access yet today (TooEarly) * User does not have access anymore today (TooLate) * Access to the system is restricted (RESTRICT_LOGIN_ROLE) and the user is not a member of this role (SystemAccessRestricted) * User has not provided a client and is not set up with a default one (NoClient) Windows authentication reasons: * Windows user is not mapped to an Agresso user (NotMapped). * Authentication using windows user and password failed. ([win error no])'
                when id = 3004 then 'User authentication succeded'
                when id = 3005 then 'User logged out of the system or a users session ended.'
                when id = 3007 then 'Unable to use integrated windows authenticator because the users windows credentials is not available to the system.'
                else cast(id as varchar(max))
				end as eventid_desc
    from
        eventlog_forwardedevents
    )
