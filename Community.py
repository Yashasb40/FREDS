import streamlit as st
import mysql.connector

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'maxwell@123',
    'database': 'freds'
}

def create_community_group(group_name, description, creator_username):
    cursor = None
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        cursor.callproc('create_community_group', (group_name, description, creator_username))

        for result in cursor.stored_results():
            message = result.fetchone()[0]

        st.success(message)
        conn.commit()

    except mysql.connector.Error as err:
        st.error(f"Error: {err.msg}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def join_community_group(group_id, username):
    cursor = None
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        cursor.callproc('join_community_group', (group_id, username))

        for result in cursor.stored_results():
            message = result.fetchone()[0]

        st.success(message)
        conn.commit()

    except mysql.connector.Error as err:
        st.error(f"Error: {err.msg}")

    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def main():
    st.title("Community Group Creation")

    group_name = st.text_input("Enter Group Name")
    description = st.text_input("Enter Description")
    creator_username = st.text_input("Enter Creator's Username")

    if st.button("Create Group"):
        if group_name and description and creator_username:
            create_community_group(group_name, description, creator_username)
        else:
            st.warning("Please fill in all the fields.")

    st.title("Join a Community Group")

    group_id = st.text_input("Enter Group ID")
    user_to_join = st.text_input("Enter Your Username")

    if st.button("Join Group"):
        if group_id and user_to_join:
            join_community_group(group_id, user_to_join)
        else:
            st.warning("Please fill in all the fields.")
            
if __name__ == '__main__':
    main()
