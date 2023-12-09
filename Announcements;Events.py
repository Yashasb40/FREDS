import streamlit as st
import mysql.connector

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'maxwell@123',
    'database': 'freds'
}

def post_text(group_id, text_content):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        cursor.execute("INSERT INTO group_texts (group_id, text_content) VALUES (%s, %s)", (group_id, text_content))
        conn.commit()
        st.success("Text posted successfully.")

    except mysql.connector.Error as err:
        st.error(f"Error: {err.msg}")

    finally:
        cursor.close()
        conn.close()

def post_announcement(group_id, announcement_content):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()

        cursor.execute("INSERT INTO group_announcements (group_id, announcement_content) VALUES (%s, %s)", (group_id, announcement_content))
        conn.commit()
        st.success("Announcement posted successfully.")

    except mysql.connector.Error as err:
        st.error(f"Error: {err.msg}")

    finally:
        cursor.close()
        conn.close()

def main():
    st.title("Post Texts and Announcements for Community Groups")

    group_id = st.number_input("Enter Group ID", min_value=1)
    text_content = st.text_area("Enter Text")
    announcement_content = st.text_area("Enter Announcement")

    if st.button("Post Text"):
        if group_id and text_content:
            post_text(group_id, text_content)
        else:
            st.warning("Please enter valid Group ID and Text content.")

    if st.button("Post Announcement"):
        if group_id and announcement_content:
            post_announcement(group_id, announcement_content)
        else:
            st.warning("Please enter valid Group ID and Announcement content.")

if __name__ == '__main__':
    main()
