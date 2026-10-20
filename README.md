# Support Bug Command Centre

A SQL-powered dashboard project designed to improve visibility between Customer Support and Engineering teams.

## Project Overview

This project demonstrates how support teams can track customer-reported bugs, identify engineering ownership gaps and prioritise issues requiring follow-up.

Built using **Snowflake SQL**, with a Streamlit dashboard for visualisation.

## What the SQL Does

1. Creates a Snowflake database and table for bug tracking.
2. Generates 100 fictional Jira-style support tickets.
3. Assigns ticket severity, engineering status, owners and dates.
4. Identifies overdue bugs, unassigned tickets and delayed engineering updates.
5. Creates reporting queries for three dashboard sections:
   - Executive Overview
   - Engineering Visibility
   - Support Action Centre

## Technology

- Snowflake
- SQL
- Streamlit
- Python

## Data

All 100 tickets are fictional and created for demonstration purposes. No real customer or company data is used.

## Project Status

SQL database and reporting logic complete. Streamlit dashboard built in Snowflake; application source code and screenshots will be added to this repository separately.
