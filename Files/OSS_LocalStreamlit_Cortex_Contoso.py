from typing import Any, Dict, List, Optional

import pandas as pd
import requests
import snowflake.connector
import streamlit as st

import time

# ---> CONFIGURE THESE VALUES

HOST = "YourDemoAccount.snowflakecomputing.com"
Val_user = "YourUserID"
Val_pw = "YourPW"

# <--- CONFIGURE THESE VALUES



DATABASE = "cortex_demos"
SCHEMA = "contoso"
STAGE = "analyst_stage"
FILE = "ContosoDemo.yaml"


if "CONN" not in st.session_state or st.session_state.CONN is None:
    st.session_state.CONN = snowflake.connector.connect(
        user=Val_user,
        password=Val_pw,
        account=HOST,
        host=HOST,
        port=443,
        warehouse="DEMO_WH",
        role="ACCOUNTADMIN",
    )


def send_message() -> Dict[str, Any]:
    """Calls the REST API and returns the response."""
    request_body = {
        "messages": st.session_state.messages,
        "semantic_model_file": f"@{DATABASE}.{SCHEMA}.{STAGE}/{FILE}",
    }
    resp = requests.post(
        url=f"https://{HOST}/api/v2/cortex/analyst/message",
        json=request_body,
        headers={
            "Authorization": f'Snowflake Token="{st.session_state.CONN.rest.token}"',
            "Content-Type": "application/json",
        },
    )
    request_id = resp.headers.get("X-Snowflake-Request-Id")
    if resp.status_code < 400:
        return {**resp.json(), "request_id": request_id}  # type: ignore[arg-type]
    else:
        st.session_state.messages.pop()
        raise Exception(
            f"Failed request (id: {request_id}) with status {resp.status_code}: {resp.content}"
        )


def process_message(prompt: str) -> None:
    """Processes a message and adds the response to the chat."""
    st.session_state.messages.append(
        {"role": "user", "content": [{"type": "text", "text": prompt}]}
    )
    with st.chat_message("user"):
        st.markdown(prompt)
    with st.chat_message("assistant"):
        with st.spinner("Generating response..."):
            start = time.time()
            
            response = send_message()

            end = time.time()
            elapsed_time = str(round((end - start),1)) + " secs"  # time in seconds

            request_id = response["request_id"]
            content = response["message"]["content"]
            st.session_state.messages.append(
                {"role": "analyst", "content": content, "request_id": request_id}
            )
            display_content(content=content, request_id=request_id, elapsed_time = elapsed_time)   # type: ignore[arg-type]


def display_content(
    content: List[Dict[str, str]],
    request_id: Optional[str] = None,
    elapsed_time: Optional[str] = None,
    message_index: Optional[int] = None,
) -> None:
    """Displays a content item for a message."""
    message_index = message_index or len(st.session_state.messages)
    if request_id:
        with st.expander("Request ID", expanded=False):
            st.markdown(request_id)
            st.markdown(elapsed_time)
    for item in content:
        if item["type"] == "text":
            st.markdown(item["text"])
        elif item["type"] == "suggestions":
            with st.expander("Suggestions", expanded=True):
                for suggestion_index, suggestion in enumerate(item["suggestions"]):
                    if st.button(suggestion, key=f"{message_index}_{suggestion_index}"):
                        st.session_state.active_suggestion = suggestion
        elif item["type"] == "sql":
            with st.expander("SQL Query", expanded=False):
                st.code(item["statement"], language="sql")
            with st.expander("Results", expanded=True):
                with st.spinner("Running SQL..."):

                    sql_api = item["statement"]
                    #sql_api =  "SELECT * FROM (" + sql_api.replace(";", "") + ") limit 20"
                    sql_api =  sql_api.replace(";", "") 
                    df = pd.read_sql(sql_api, st.session_state.CONN)


                    #st.markdown(sql_api)
                    
                    sql_new = f'''SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2','summarize & itemize top insights from the following json data in less than 150 words. Data: '  ||
                                        (
                                            SELECT array_agg( object_construct(*))::string as Output from
                                                    ( {sql_api}  )
                                        )
                                        ) as Insights'''
                    DataSummary = pd.read_sql(sql_new, st.session_state.CONN)
                    
                    DataSummaryText = str(DataSummary.iat[0, 0])

                    #df = pd.read_sql(item["statement"], st.session_state.CONN)
                    if len(df.index) > 0:
                        st.markdown(DataSummaryText)
                    if len(df.index) > 1:
                        data_tab, line_tab, bar_tab = st.tabs(
                            ["Data", "Line Chart", "Bar Chart"]
                        )
                        data_tab.dataframe(df)
                        if len(df.columns) > 1:
                            df = df.set_index(df.columns[0])
                        with line_tab:
                            st.line_chart(df)
                        with bar_tab:
                            st.bar_chart(df)
                    else:
                        st.dataframe(df)


def show_conversation_history() -> None:
    for message_index, message in enumerate(st.session_state.messages):
        chat_role = "assistant" if message["role"] == "analyst" else "user"
        with st.chat_message(chat_role):
            display_content(
                content=message["content"],
                request_id=message.get("request_id"),
                message_index=message_index,
            )

st.title("Cortex Analyst")
st.markdown(f"Semantic Model: `{FILE}`")

if st.button("Reset conversation") or "messages" not in st.session_state:
    st.session_state.messages = []
    st.session_state.suggestions = []
    st.session_state.active_suggestion = None

show_conversation_history()

if user_input := st.chat_input("What is your question?"):
    process_message(prompt=user_input)

if st.session_state.active_suggestion:
    process_message(prompt=st.session_state.active_suggestion)
    st.session_state.active_suggestion = None
