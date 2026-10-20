
-- STEP 1: Create the database and folder where all bug data will be stored.

CREATE DATABASE IF NOT EXISTS SUPPORT_BUG_DEMO;

CREATE SCHEMA IF NOT EXISTS
    SUPPORT_BUG_DEMO.ANALYTICS;

USE DATABASE SUPPORT_BUG_DEMO;
USE SCHEMA ANALYTICS;

-- Check that the correct database and folder are selected.
SELECT
    CURRENT_DATABASE() AS DATABASE_NAME,
    CURRENT_SCHEMA() AS SCHEMA_NAME;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 2: Create an empty table to store bug details, owners, dates and status.

CREATE TABLE IF NOT EXISTS BUG_TICKETS (
    TICKET_ID VARCHAR(20),
    TITLE VARCHAR(255),
    DESCRIPTION VARCHAR(2000),
    BUG_CATEGORY VARCHAR(100),
    PRODUCT_AREA VARCHAR(100),
    SEVERITY VARCHAR(20),
    ENGINEERING_STATUS VARCHAR(30),
    ASSIGNED_ENGINEER VARCHAR(100),
    SUPPORT_OWNER VARCHAR(100),
    DIFFICULTY VARCHAR(20),
    REPORTED_DATE DATE,
    LAST_UPDATED_DATE DATE,
    TARGET_RESOLUTION_DATE DATE,
    RESOLVED_DATE DATE,
    AFFECTED_CUSTOMERS INTEGER,
    WORKAROUND_AVAILABLE BOOLEAN,
    NEXT_ACTION VARCHAR(500)
);

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 3: Generate 100 fictional bugs with different priorities, owners and dates.

-- INSERT INTO BUG_TICKETS

-- -- Create 100 numbered records.
-- WITH NUMBERS AS (
--     SELECT SEQ4() + 1 AS N
--     FROM TABLE(GENERATOR(ROWCOUNT => 100))
-- ),

-- -- Assign each bug a priority, engineering status and reported date.
-- BASE AS (
--     SELECT
--         N,
--         CASE MOD(N, 6)
--             WHEN 0 THEN 'Critical'
--             WHEN 1 THEN 'High'
--             WHEN 2 THEN 'Medium'
--             WHEN 3 THEN 'Low'
--             WHEN 4 THEN 'High'
--             ELSE 'Medium'
--         END AS SEVERITY,
--         CASE
--             WHEN N <= 12 THEN 'Reported'
--             WHEN N <= 25 THEN 'Acknowledged'
--             WHEN N <= 40 THEN 'Planned'
--             WHEN N <= 65 THEN 'In Progress'
--             WHEN N <= 75 THEN 'Blocked'
--             ELSE 'Resolved'
--         END AS STATUS,
--         DATEADD(
--             DAY, -MOD(N * 7, 180),
--             CURRENT_DATE()
--         ) AS REPORTED_DATE
--     FROM NUMBERS
-- ),

-- -- Give each bug a fictional issue title and category.
-- DETAILS AS (
--     SELECT
--         *,
--         CASE MOD(N, 8)
--             WHEN 0 THEN 'Login authentication failure'
--             WHEN 1 THEN 'API response timeout'
--             WHEN 2 THEN 'Dashboard data mismatch'
--             WHEN 3 THEN 'File upload validation error'
--             WHEN 4 THEN 'User permissions not updating'
--             WHEN 5 THEN 'Notification delivery failure'
--             WHEN 6 THEN 'Report export formatting issue'
--             ELSE 'Integration sync failure'
--         END AS ISSUE_TITLE,
--         CASE MOD(N, 5)
--             WHEN 0 THEN 'Authentication'
--             WHEN 1 THEN 'API'
--             WHEN 2 THEN 'Reporting'
--             WHEN 3 THEN 'User Management'
--             ELSE 'Integrations'
--         END AS CATEGORY
--     FROM BASE
-- )

-- -- Fill in the remaining ticket details and save all 100 bugs.
-- SELECT
--     'BUG-' || (1000 + N),
--     ISSUE_TITLE || ' - Case ' || N,
--     'Synthetic customer-reported issue: '
--         || ISSUE_TITLE
--         || '. Requires engineering investigation.',
--     CATEGORY,
--     CASE MOD(N, 4)
--         WHEN 0 THEN 'Web Application'
--         WHEN 1 THEN 'Mobile Application'
--         WHEN 2 THEN 'Admin Portal'
--         ELSE 'Public API'
--     END,
--     SEVERITY,
--     STATUS,
--     CASE
--         WHEN STATUS = 'Reported' OR MOD(N, 11) = 0
--             THEN NULL
--         ELSE
--             CASE MOD(N, 5)
--                 WHEN 0 THEN 'Alex Morgan'
--                 WHEN 1 THEN 'Priya Shah'
--                 WHEN 2 THEN 'Daniel Lee'
--                 WHEN 3 THEN 'Emma Wilson'
--                 ELSE 'James Patel'
--             END
--     END,
--     CASE MOD(N, 3)
--         WHEN 0 THEN 'Support Team A'
--         WHEN 1 THEN 'Support Team B'
--         ELSE 'Support Team C'
--     END,
--     CASE MOD(N, 3)
--         WHEN 0 THEN 'Easy'
--         WHEN 1 THEN 'Medium'
--         ELSE 'Hard'
--     END,
--     REPORTED_DATE,
--     DATEADD(
--         DAY,
--         LEAST(
--             MOD(N * 3, 15),
--             DATEDIFF(DAY, REPORTED_DATE, CURRENT_DATE())
--         ),
--         REPORTED_DATE
--     ),
--     DATEADD(DAY, 7 + MOD(N, 21), REPORTED_DATE),
--     CASE
--         WHEN STATUS = 'Resolved'
--             THEN DATEADD(
--                 DAY,
--                 LEAST(
--                     3 + MOD(N, 12),
--                     DATEDIFF(
--                         DAY, REPORTED_DATE, CURRENT_DATE()
--                     )
--                 ),
--                 REPORTED_DATE
--             )
--         ELSE NULL
--     END,
--     1 + MOD(N * 13, 75),
--     MOD(N, 3) = 0,
--     CASE STATUS
--         WHEN 'Reported'
--             THEN 'Request engineering acknowledgement'
--         WHEN 'Acknowledged'
--             THEN 'Confirm investigation timeline'
--         WHEN 'Planned'
--             THEN 'Confirm sprint allocation'
--         WHEN 'In Progress'
--             THEN 'Request progress update'
--         WHEN 'Blocked'
--             THEN 'Escalate blocker to engineering lead'
--         ELSE 'Confirm resolution with customer'
--     END
-- FROM DETAILS;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 4: Display the first 10 bugs to check the data.

SELECT * FROM BUG_TICKETS LIMIT 10;

-- Count total, open, resolved, critical and unassigned bugs.
SELECT
    COUNT(*) AS TOTAL_TICKETS,
    COUNT(DISTINCT TICKET_ID) AS UNIQUE_TICKETS,
    COUNT_IF(ENGINEERING_STATUS != 'Resolved')
        AS OPEN_BUGS,
    COUNT_IF(ENGINEERING_STATUS = 'Resolved')
        AS RESOLVED_BUGS,
    COUNT_IF(SEVERITY = 'Critical')
        AS CRITICAL_BUGS,
    COUNT_IF(ASSIGNED_ENGINEER IS NULL
        AND ENGINEERING_STATUS != 'Resolved')
        AS UNASSIGNED_OPEN_BUGS
FROM BUG_TICKETS;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 5: Correct resolved bugs where the last update is earlier than resolution.

UPDATE BUG_TICKETS
SET LAST_UPDATED_DATE = RESOLVED_DATE
WHERE ENGINEERING_STATUS = 'Resolved'
  AND LAST_UPDATED_DATE < RESOLVED_DATE;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 6: Create a reusable view that automatically flags bugs needing attention.

CREATE OR REPLACE VIEW VW_BUG_DASHBOARD AS
SELECT
    *,

    -- Identify bugs that are still open.
    ENGINEERING_STATUS != 'Resolved'
        AS IS_OPEN,

    -- Identify open bugs that have missed their target date.
    ENGINEERING_STATUS != 'Resolved'
        AND TARGET_RESOLUTION_DATE < CURRENT_DATE()
        AS IS_OVERDUE,

    -- Identify open bugs with no update in over 7 days.
    ENGINEERING_STATUS != 'Resolved'
        AND LAST_UPDATED_DATE <
            DATEADD(DAY, -7, CURRENT_DATE())
        AS NEEDS_UPDATE,

    -- Identify bugs waiting over 3 days for engineering acknowledgement.
    ENGINEERING_STATUS = 'Reported'
        AND REPORTED_DATE <
            DATEADD(DAY, -3, CURRENT_DATE())
        AS NEEDS_ACKNOWLEDGEMENT,

    -- Identify open bugs without an assigned engineer.
    ENGINEERING_STATUS != 'Resolved'
        AND ASSIGNED_ENGINEER IS NULL
        AS IS_UNASSIGNED,

    -- Calculate how many days each bug has been or was open.
    DATEDIFF(
        DAY, REPORTED_DATE,
        COALESCE(RESOLVED_DATE, CURRENT_DATE())
    ) AS AGE_DAYS

FROM BUG_TICKETS;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 7: Executive Overview - Show the main bug numbers for leadership.

SELECT
    COUNT(*) AS TOTAL_BUGS,
    COUNT_IF(IS_OPEN) AS OPEN_BUGS,
    COUNT_IF(
        IS_OPEN AND SEVERITY IN ('Critical', 'High')
    ) AS HIGH_PRIORITY_OPEN,
    COUNT_IF(ENGINEERING_STATUS = 'In Progress')
        AS IN_PROGRESS,
    COUNT_IF(ENGINEERING_STATUS = 'Resolved')
        AS RESOLVED,
    COUNT_IF(ENGINEERING_STATUS = 'Reported')
        AS AWAITING_ACKNOWLEDGEMENT
FROM VW_BUG_DASHBOARD;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 8: Engineering Visibility - Show who owns open bugs and their status, difficulty and priority.

SELECT
    ENGINEERING_STATUS,
    ASSIGNED_ENGINEER,
    DIFFICULTY,
    SEVERITY,
    COUNT(*) AS TICKET_COUNT
FROM VW_BUG_DASHBOARD
WHERE IS_OPEN
GROUP BY 1, 2, 3, 4
ORDER BY TICKET_COUNT DESC;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 9: Support Action Centre - Find bugs needing follow-up and rank them by priority.

SELECT
    TICKET_ID,
    TITLE,
    SEVERITY,
    ENGINEERING_STATUS,
    ASSIGNED_ENGINEER,
    AFFECTED_CUSTOMERS,
    AGE_DAYS,

    -- Explain why each bug needs attention.
    CASE
        WHEN SEVERITY IN ('Critical', 'High')
             AND IS_UNASSIGNED
            THEN 'High priority without engineer'
        WHEN NEEDS_ACKNOWLEDGEMENT
            THEN 'Engineering acknowledgement overdue'
        WHEN IS_OVERDUE
            THEN 'Target resolution date missed'
        WHEN NEEDS_UPDATE
            THEN 'No recent engineering update'
        WHEN ENGINEERING_STATUS = 'Blocked'
            THEN 'Engineering blocker'
        ELSE 'Review customer impact'
    END AS ATTENTION_REASON,
    NEXT_ACTION

FROM VW_BUG_DASHBOARD

-- Include only open bugs with risks, delays or high customer impact.
WHERE IS_OPEN
  AND (
      IS_OVERDUE
      OR NEEDS_UPDATE
      OR NEEDS_ACKNOWLEDGEMENT
      OR IS_UNASSIGNED
      OR ENGINEERING_STATUS = 'Blocked'
      OR AFFECTED_CUSTOMERS >= 50
  )

-- Show critical bugs first, followed by bugs affecting more customers.
ORDER BY
    CASE SEVERITY
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        ELSE 4
    END,
    AFFECTED_CUSTOMERS DESC;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- STEP 10: Count bugs by engineering status for a dashboard bar chart.

SELECT
    ENGINEERING_STATUS,
    COUNT(*) AS NUMBER_OF_BUGS
FROM VW_BUG_DASHBOARD
GROUP BY ENGINEERING_STATUS
ORDER BY NUMBER_OF_BUGS DESC;
