import streamlit as st
import mysql.connector

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'maxwell@123',
    'database': 'freds'
}

conn = mysql.connector.connect(**db_config)
cursor = conn.cursor()

def fetch_group_texts_announcements(group_id):
    try:
        cursor.execute("SELECT text_content FROM group_texts WHERE group_id = %s", (group_id,))
        texts = cursor.fetchall()

        cursor.execute("SELECT announcement_content FROM group_announcements WHERE group_id = %s", (group_id,))
        announcements = cursor.fetchall()

        conn.commit()
        return texts, announcements

    except mysql.connector.Error as err:
        st.error(f"Error: {err.msg}")

    finally:
        cursor.close()
        conn.close()

def count_users_in_group(group_id):
    query = "CALL count_users_in_group(%s, @user_count)"
    cursor.execute(query, (group_id,))
    cursor.execute("SELECT @user_count")
    user_count = cursor.fetchone()[0]
    return user_count

def main():
    st.title("Community Group Texts and Announcements")

    group_id = st.number_input("Enter Group ID", min_value=1)

    if st.button("Fetch Texts and Announcements"):
        if group_id:
            texts, announcements = fetch_group_texts_announcements(group_id)
            if texts:
                st.subheader("Texts:")
                for text in texts:
                    st.write(text[0])
            else:
                st.warning("No texts available for this group.")

            if announcements:
                st.subheader("Announcements:")
                for announcement in announcements:
                    st.write(announcement[0])
            else:
                st.warning("No announcements available for this group.")
        else:
            st.warning("Please enter a valid Group ID.")

selected_option = st.selectbox('Choose an action:', ('Count', 'Count Users in Group'))

if selected_option == 'Count Users in Group':
    group_id = st.number_input('Enter Group ID:', min_value=1)
    if st.button('Count Users'):
        user_count = count_users_in_group(group_id)
        st.write(f'Total users in group {group_id}: {user_count}')

if __name__ == '__main__':
    main()