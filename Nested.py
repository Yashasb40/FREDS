import streamlit as st
import mysql.connector

# Establishing a connection to the MySQL database
conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='maxwell@123',
    database='freds'
)
cursor = conn.cursor()

# Streamlit UI
st.title('MySQL Database Interaction')

# Generate unique keys for each text_input
create_account_key = 'create_account'
login_key = 'login'
send_thread_key = 'send_thread'
follow_key = 'follow'
stop_follow_key = 'stop_follow'

# Create Account Section
st.header('Create Account')
username = st.text_input('Username', key=create_account_key + '_username')
firstname = st.text_input('First Name', key=create_account_key + '_firstname')
lastname = st.text_input('Last Name', key=create_account_key + '_lastname')
birthdate = st.date_input('Birth Date', key=create_account_key + '_birthdate')
role = st.text_input('Role', key=create_account_key + '_role')
bio = st.text_area('Bio', key=create_account_key + '_bio')
password = st.text_input('Password', type='password', key=create_account_key + '_password')

if st.button('Create Account'):
    try:
        cursor.callproc('create_account', (username, firstname, lastname, birthdate, role, bio, password))
        conn.commit()
        st.success(f'Account created for {username}')
    except mysql.connector.Error as e:
        st.error(f'Error creating account: {e.msg}')

# Login Section
st.header('Login')
login_username = st.text_input('Username', key=login_key + '_username')
login_password = st.text_input('Password', type='password', key=login_key + '_password')

if st.button('Login'):
    try:
        cursor.callproc('login', (login_username, login_password))
        result = next(cursor.stored_results())
        status = result.fetchone()[0]
        st.success(status)
    except mysql.connector.Error as e:
        st.error(f'Login error: {e.msg}')

# Send Thread Section
st.header('Send Thread')
thread_content = st.text_area('Thread Content', key=send_thread_key + '_content')

if st.button('Send Thread'):
    try:
        cursor.callproc('send_thread', (thread_content,))
        conn.commit()
        st.success('Thread sent successfully.')
    except mysql.connector.Error as e:
        st.error(f'Error sending thread: {e.msg}')

# Follow Section
st.header('Follow')
following_username = st.text_input('Username to Follow', key=follow_key + '_username')

if st.button('Follow'):
    try:
        cursor.callproc('follow', (following_username,))
        conn.commit()
        st.success(f'You are now following {following_username}')
    except mysql.connector.Error as e:
        st.error(f'Error following user: {e.msg}')

# Stop Follow Section
st.header('Stop Follow')
stop_follow_username = st.text_input('Username to Stop Following', key=stop_follow_key + '_username')

if st.button('Stop Follow'):
    try:
        cursor.callproc('stop_follow', (stop_follow_username,))
        conn.commit()
        st.success(f'You stopped following {stop_follow_username}')
    except mysql.connector.Error as e:
        st.error(f'Error stopping follow: {e.msg}')

# Remember to close the connection
cursor.close()
conn.close()
