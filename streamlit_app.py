
import streamlit as st
import pandas as pd

# STEP 1: Set the dashboard title and layout.
st.set_page_config(
    page_title="Support Bug Command Centre",
    page_icon="📊",
    layout="wide"
)

# STEP 2: Load the fictional bug data from Snowflake.
@st.cache_data(show_spinner="Loading bug data...")
def load_data():
    session = st.connection("snowflake").session()
    return session.sql("""
        SELECT *
        FROM SUPPORT_BUG_DEMO.ANALYTICS.VW_BUG_DASHBOARD
    """).to_pandas()

df = load_data()

# STEP 3: Prepare dates and numbers for the charts.
for column in [
    "REPORTED_DATE",
    "LAST_UPDATED_DATE",
    "TARGET_RESOLUTION_DATE",
    "RESOLVED_DATE"
]:
    df[column] = pd.to_datetime(df[column])

df["AFFECTED_CUSTOMERS"] = pd.to_numeric(
    df["AFFECTED_CUSTOMERS"]
)

# STEP 4: Create navigation between the three pages.
st.sidebar.title("📊 Bug Command Centre")
page = st.sidebar.radio(
    "Select dashboard",
    [
        "Executive Overview",
        "Engineering Visibility",
        "Support Action Centre"
    ]
)

st.sidebar.divider()
st.sidebar.caption("Demo data: 100 fictional Jira-style tickets")
st.sidebar.caption("Source: Snowflake | ANALYTICS")

# PAGE 1: EXECUTIVE OVERVIEW
if page == "Executive Overview":

    st.title("Executive Overview")
    st.caption("Overall health of the customer-reported bug backlog")

    total = len(df)
    open_bugs = df[df["IS_OPEN"]]
    resolved = df[df["ENGINEERING_STATUS"] == "Resolved"]

    high_priority = open_bugs[
        open_bugs["SEVERITY"].isin(["Critical", "High"])
    ]

    in_progress = df[
        df["ENGINEERING_STATUS"] == "In Progress"
    ]

    awaiting = df[
        df["ENGINEERING_STATUS"] == "Reported"
    ]

    # Show six headline bug metrics.
    c1, c2, c3 = st.columns(3)
    c1.metric("Total Bugs", total)
    c2.metric("Open Bugs", len(open_bugs))
    c3.metric("Critical / High Open", len(high_priority))

    c4, c5, c6 = st.columns(3)
    c4.metric("In Progress", len(in_progress))
    c5.metric("Resolved", len(resolved))
    c6.metric("Awaiting Acknowledgement", len(awaiting))

    st.divider()

    # Show bug status and severity charts.
    left, right = st.columns(2)

    with left:
        st.subheader("Bugs by Engineering Status")
        status_counts = df["ENGINEERING_STATUS"].value_counts()
        st.bar_chart(status_counts)

    with right:
        st.subheader("Bugs by Severity")
        severity_counts = df["SEVERITY"].value_counts()
        st.bar_chart(severity_counts)

    # Show product categories and weekly trends.
    left, right = st.columns(2)

    with left:
        st.subheader("Bugs by Category")
        st.bar_chart(df["BUG_CATEGORY"].value_counts())

    with right:
        st.subheader("Weekly Reported vs Resolved")

        reported = (
            df.groupby(
                pd.Grouper(key="REPORTED_DATE", freq="W")
            ).size().rename("Reported")
        )

        resolved_weekly = (
            df[df["RESOLVED_DATE"].notna()]
            .groupby(
                pd.Grouper(key="RESOLVED_DATE", freq="W")
            ).size().rename("Resolved")
        )

        weekly = pd.concat(
            [reported, resolved_weekly], axis=1
        ).fillna(0)

        st.line_chart(weekly)

    # Generate a summary using actual ticket numbers.
    st.subheader("Executive Summary")
    st.info(
        f"Engineering is currently working on "
        f"{len(in_progress)} bugs. "
        f"{len(high_priority)} critical or high-priority "
        f"bugs remain open, and {len(awaiting)} bugs "
        f"are awaiting acknowledgement."
    )

# PAGE 2: ENGINEERING VISIBILITY
elif page == "Engineering Visibility":

    st.title("Engineering Visibility")
    st.caption("Track ownership, progress and planned work")

    open_df = df[df["IS_OPEN"]].copy()

    # Add filters for engineer, severity, status and difficulty.
    f1, f2, f3, f4 = st.columns(4)

    with f1:
        engineer = st.selectbox(
            "Engineer",
            ["All"] + sorted(
                open_df["ASSIGNED_ENGINEER"]
                .dropna().unique().tolist()
            ) + ["Unassigned"]
        )

    with f2:
        severity = st.selectbox(
            "Severity",
            ["All", "Critical", "High", "Medium", "Low"]
        )

    with f3:
        status = st.selectbox(
            "Status",
            ["All"] + sorted(
                open_df["ENGINEERING_STATUS"].unique().tolist()
            )
        )

    with f4:
        difficulty = st.selectbox(
            "Difficulty",
            ["All", "Easy", "Medium", "Hard"]
        )

    # Apply selected filters.
    filtered = open_df.copy()

    if engineer == "Unassigned":
        filtered = filtered[
            filtered["ASSIGNED_ENGINEER"].isna()
        ]
    elif engineer != "All":
        filtered = filtered[
            filtered["ASSIGNED_ENGINEER"] == engineer
        ]

    if severity != "All":
        filtered = filtered[
            filtered["SEVERITY"] == severity
        ]

    if status != "All":
        filtered = filtered[
            filtered["ENGINEERING_STATUS"] == status
        ]

    if difficulty != "All":
        filtered = filtered[
            filtered["DIFFICULTY"] == difficulty
        ]

    # Display engineering workload metrics.
    c1, c2, c3, c4 = st.columns(4)

    c1.metric("Matching Bugs", len(filtered))
    c2.metric(
        "Unassigned",
        filtered["ASSIGNED_ENGINEER"].isna().sum()
    )
    c3.metric(
        "Blocked",
        (filtered["ENGINEERING_STATUS"] == "Blocked").sum()
    )
    c4.metric(
        "Planned",
        (filtered["ENGINEERING_STATUS"] == "Planned").sum()
    )

    st.divider()

    # Show ownership and difficulty charts.
    left, right = st.columns(2)

    with left:
        st.subheader("Bugs by Engineer")
        owners = filtered["ASSIGNED_ENGINEER"].fillna(
            "Unassigned"
        )
        st.bar_chart(owners.value_counts())

    with right:
        st.subheader("Bugs by Difficulty")
        st.bar_chart(filtered["DIFFICULTY"].value_counts())

    # Display a searchable ticket table.
    st.subheader("Engineering Ticket Tracker")

    search = st.text_input("Search ticket ID, title or description")

    if search:
        mask = (
            filtered["TICKET_ID"].str.contains(
                search, case=False, na=False, regex=False
            )
            | filtered["TITLE"].str.contains(
                search, case=False, na=False, regex=False
            )
            | filtered["DESCRIPTION"].str.contains(
                search, case=False, na=False, regex=False
            )
        )
        filtered = filtered[mask]

    st.dataframe(
        filtered[[
            "TICKET_ID",
            "TITLE",
            "SEVERITY",
            "ENGINEERING_STATUS",
            "DIFFICULTY",
            "ASSIGNED_ENGINEER",
            "REPORTED_DATE",
            "LAST_UPDATED_DATE",
            "NEXT_ACTION"
        ]],
        use_container_width=True,
        hide_index=True
    )

# PAGE 3: SUPPORT ACTION CENTRE
else:

    st.title("Support Action Centre")
    st.caption("Identify customer-impacting issues requiring follow-up")

    open_df = df[df["IS_OPEN"]].copy()

    # Identify bugs requiring support attention.
    attention = open_df[
        (open_df["IS_OVERDUE"])
        | (open_df["NEEDS_UPDATE"])
        | (open_df["NEEDS_ACKNOWLEDGEMENT"])
        | (open_df["IS_UNASSIGNED"])
        | (open_df["ENGINEERING_STATUS"] == "Blocked")
        | (open_df["AFFECTED_CUSTOMERS"] >= 50)
    ].copy()

    # Show the number of bugs requiring different actions.
    c1, c2, c3, c4 = st.columns(4)

    c1.metric("Needs Attention", len(attention))
    c2.metric("Overdue", int(open_df["IS_OVERDUE"].sum()))
    c3.metric(
        "No Recent Update",
        int(open_df["NEEDS_UPDATE"].sum())
    )
    c4.metric(
        "Awaiting Acknowledgement",
        int(open_df["NEEDS_ACKNOWLEDGEMENT"].sum())
    )

    st.divider()

    # Explain why each ticket needs attention.
    def attention_reason(row):
        if (
            row["SEVERITY"] in ["Critical", "High"]
            and row["IS_UNASSIGNED"]
        ):
            return "High priority without engineer"
        if row["NEEDS_ACKNOWLEDGEMENT"]:
            return "Acknowledgement overdue"
        if row["IS_OVERDUE"]:
            return "Target date missed"
        if row["NEEDS_UPDATE"]:
            return "No recent update"
        if row["ENGINEERING_STATUS"] == "Blocked":
            return "Engineering blocker"
        return "Review customer impact"

    attention["ATTENTION_REASON"] = attention.apply(
        attention_reason, axis=1
    )

    # Sort critical bugs first, then by customer impact.
    priority_order = {
        "Critical": 1,
        "High": 2,
        "Medium": 3,
        "Low": 4
    }

    attention["PRIORITY_ORDER"] = (
        attention["SEVERITY"].map(priority_order)
    )

    attention = attention.sort_values(
        ["PRIORITY_ORDER", "AFFECTED_CUSTOMERS"],
        ascending=[True, False]
    )

    # Display the support follow-up list.
    st.subheader("Prioritised Follow-Up List")

    st.dataframe(
        attention[[
            "TICKET_ID",
            "TITLE",
            "SEVERITY",
            "ENGINEERING_STATUS",
            "ASSIGNED_ENGINEER",
            "AFFECTED_CUSTOMERS",
            "AGE_DAYS",
            "ATTENTION_REASON",
            "NEXT_ACTION"
        ]],
        use_container_width=True,
        hide_index=True
    )

    # Create a daily summary from the ticket data.
    st.subheader("Daily Support Summary")

    st.info(
        f"{len(attention)} open bugs currently need "
        f"support attention. "
        f"{int(open_df['IS_OVERDUE'].sum())} are overdue, "
        f"{int(open_df['NEEDS_UPDATE'].sum())} have no "
        f"recent updates, and "
        f"{int(open_df['IS_UNASSIGNED'].sum())} "
        f"have no assigned engineer."
    )

# Show a footer on every page.
st.divider()
st.caption(
    "Support Bug Command Centre | Fictional demonstration data | "
    "Built with Snowflake SQL and Streamlit"
)
