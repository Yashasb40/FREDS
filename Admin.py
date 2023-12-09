import streamlit as st
import mysql.connector

class AdminPanel:
    def __init__(self):
        self.conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='maxwell@123',
            database='freds'
        )
        self.cursor = self.conn.cursor()

    def check_admin_role(self, username):
        try:
            self.cursor.execute("SELECT role FROM usersn WHERE username=%s", (username,))
            role = self.cursor.fetchone()

            if role and role[0] == 'admin':
                return True
        except Exception as e:
            print(f"Error checking admin role: {e}")
        return False

    def display_users_data(self):
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='maxwell@123',
            database='freds'
        )
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM usersn")
        users_data = cursor.fetchall()
        conn.close()
        return users_data

    def modify_user_data(self, user_id, new_username, new_password, new_role):
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='maxwell@123',
            database='freds'
        )
        cursor = conn.cursor()
        cursor.execute("UPDATE usersn SET username=%s, password=%s, role=%s WHERE user_id=%s", (new_username, new_password, new_role, user_id))
        conn.commit()
        conn.close()

    def delete_user_data(self, user_id):
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='maxwell@123',
            database='freds'
        )
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM usersn WHERE user_id=%s", (user_id,))
        user_exists = cursor.fetchone()

        if user_exists:
            cursor.execute("DELETE FROM usersn WHERE user_id=%s", (user_id,))
            conn.commit()
            conn.close()
            return True
        else:
            conn.close()
            return False

    def show_admin_panel(self):
        st.title("Admin Panel")

        username = st.text_input("Username")

        if self.check_admin_role(username):
            st.success("Logged in as Admin")

            st.subheader("Users' Data")
            users_data = self.display_users_data()
            st.table(users_data)

            st.subheader("Modify User Data")
            selected_user_id = st.number_input("Enter User ID to Modify", min_value=1)
            new_username = st.text_input("New Username")
            new_password = st.text_input("New Password", type="password")
            new_role = st.selectbox("New Role", ['admin', 'user'])
            modify_button = st.button("Modify")

            if modify_button:
                if self.modify_user_data(selected_user_id, new_username, new_password, new_role):
                    st.success("User Data Modified Successfully")
                else:
                    st.error("Failed to modify user data")

            st.subheader("Delete User")
            delete_user_id = st.number_input("Enter User ID to Delete", min_value=1)
            delete_button = st.button("Delete")

            if delete_button:
                if self.delete_user_data(delete_user_id):
                    st.success("User Deleted Successfully")
                else:
                    st.error("Failed to delete user")
        else:
            st.error("Access denied. You do not have admin privileges.")


def main():
    admin_panel = AdminPanel()
    admin_panel.show_admin_panel()

if __name__ == "__main__":
    main()
