import streamlit as st
import mysql.connector
import pandas as pd
connection = st.session_state['connection'] 
cursor = st.session_state['cursor']
cursor1 = st.session_state['cursor']


def show_comm(n):
    arguments = []
    arguments.append(n)
    cursor.callproc('get_comments_of_thread', arguments)
    result = ''
    for i in cursor.stored_results():
        result = i.fetchall()
        df = pd.DataFrame(result)
        is_empty(df)
        st.write(df.to_markdown())
def comm(msg,n):
        arguments = []
        arguments.append(n)
        arguments.append(msg)
        cursor.callproc('comments', arguments)
        result = ''
        for i in cursor.stored_results():
            result = i.fetchone()[0]
        st.success(result)
        connection.commit()
def fr_act():
    cursor.callproc('get_following_activity')
    resultfr = ''
    j = 0
    for i in cursor.stored_results():
        resultfr = i.fetchall()
        df = pd.DataFrame(resultfr)
    is_empty(df)
    for idx, activity in enumerate(resultfr):
        st.title(activity[2])
        st.header(activity[3])
        
        comment_key = f"comments_{j}"
        like_key = f"like_{j}"
        reply_msg = st.text_input("Comment on this", key=comment_key)
        
        col1, col2 = st.columns(2)
        with col1:
            if st.button("Like", key=like_key):
                like(activity[0])
        with col2:
            if st.button("Comments", key=f"comment_button_{j}"):
                comm(reply_msg, activity[0])
        
        j += 1
        st.write("---")


    
def like(n):
    arguments = []
    thread_id = n
    arguments.append(thread_id)
    cursor.callproc('liking', arguments)
    result = ''
    for i in cursor.stored_results():
        result = i.fetchone()[0]
    st.success(result)
    connection.commit()

def is_empty(df):
    if df.empty:
        st.write('Empty table')

def thread():
    arguments = []
    result = st.text_input("Enter your thread ")
    thread = st.button("Thread")
    
    if thread:
        if(st.session_state['login']!='None'):
            arguments = [result]
            cursor.callproc('send_thread', arguments)
            for i in cursor.stored_results():
                result = i.fetchone()[0]
            st.write(result)
            connection.commit()

if(st.session_state['login'] == 'None'):
    st.write("Please login first to access this feature!")
    
else:
    thread()
    cursor.execute("Select threadid from thread where username='%s' and type='T'"%(st.session_state['login']))
    data = cursor.fetchall()
    # data=data[::-1] 
    with st.expander("Show My threads"):
        cursor.callproc('get_own_threads')
        result_thread = ''
        for i in cursor.stored_results():
            result_thread = i.fetchall()
            df = pd.DataFrame(result_thread,columns=['Thread','Time'])
            
            is_empty(df)
        if df.empty:
            st.write("Empty set")
        else:
            df['threadid'] = data
            st.write(df)
            
        
        # st.write(df.to_markdown())
    with st.expander("Show thread and replies"):
        arguments = []
        # print('')
        # thread_id = int(input())
        # st.write(data)
        if df.empty:
            st.write("Empty")
        else:
            for i in data:
                # arguments.append(i)
                cursor.callproc('get_comments_of_thread', i)
                result = ''
            for i in cursor.stored_results():
                result = i.fetchall()
                
            df3 = pd.DataFrame(result)

            st.dataframe(df3)
            # final = pd.merge(df,df3)

    with st.expander("Show all the threads"):
        cursor.execute("Select * from thread where username != '%s' and type='T'"%(st.session_state['login']))
        threads=cursor.fetchall()
        j=0
        
        for i in threads:
            st.title(i[2])
            st.header(i[3])
            reply_msg=st.text_input("Comment on this",key="%sj+1"%(j))
            col1,col2=st.columns(2)
            with col1:
                if(st.button("Like",key="1%s"%(j))):
                    like(i[0])
            with col2:
                if(st.button("Comments",key="2%s"%(j))):
                    comm(reply_msg,i[0])
            j+=1
            st.write("---")
    with st.expander("See what your friends are saying, %s"%(st.session_state['login'])):
        fr_act()
            
            
