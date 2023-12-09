import streamlit as st
import mysql.connector
import datetime
import base64


st.set_page_config(initial_sidebar_state="collapsed")
connection = mysql.connector.connect(host='localhost', user="root", password="maxwell@123", db='freds')
cursor = connection.cursor()


custom_css = """
    <style>
        body {
            background-color: #FFB6C1;
            font-family: Arial, sans-serif;
        }
        .stApp {
            background-color: transparent !important;
        }
        .stExpander {
            background-color: rgba(255, 255, 255, 0.9)
            border-radius: 10px;
        }
    </style>
"""

st.markdown(custom_css, unsafe_allow_html=True)

result_log = ''
col1, col2 = st.columns(2)
st.session_state['cursor'] = cursor
st.session_state['connection'] = connection
st.session_state['login'] = 'None'
st.session_state['expand'] = False

with col1:
    with st.expander("Login", expanded=st.session_state['expand']):
        arguments = []
        
        userName = st.text_input("Enter your username", key='login1')
        arguments.append(userName)

        password = st.text_input("Enter your password", key='login2', type="password")
        arguments.append(password)

        login = st.button("Login")
        if login:
            try:
                cursor.callproc('login', arguments)
                for i in cursor.stored_results():
                    result_log = i.fetchone()[0]

                if 'invalid' not in result_log:
                    st.success(result_log)
                    st.session_state['login'] = userName
                    st.session_state['expand'] = False
                    connection.commit()
                else:
                    st.warning(result_log)
                    connection.rollback()
            except mysql.connector.Error as e:
                st.error(f"An error occurred during login: {e}")

if st.session_state['login'] == "admin":
    from loginrec import logrec
    with st.expander("Show login records"):
        logrec()

if result_log == "Login successfully.":
    st.title("Welcome to Freds: " + userName)

def create_account(username, firstname, lastname, birthdate, role, bio, password):
    try:
        if len([arg for arg in (username, firstname, lastname, birthdate, role, bio, password) if arg is not None]) != 7:
            return "Error: Incorrect number of arguments provided."

        cursor.callproc('create_account', (username, firstname, lastname, birthdate, role, bio, password))

        connection.commit()

        cursor.close()

        return "Account created successfully!"
    
    except mysql.connector.Error as e:
        return f"MySQL Error: {e.msg}"

st.title("Create User Account")

username = st.text_input("Username")
firstname = st.text_input("First Name")
lastname = st.text_input("Last Name")
birthdate = st.date_input("Birthdate")
role = st.text_input("Role")
bio = st.text_input("Bio")
password = st.text_input("Password", type="password")

if st.button("Create Account"):
    result = create_account(username, firstname, lastname, birthdate, role, bio, password)
    st.write(result)

st.title('Freds')