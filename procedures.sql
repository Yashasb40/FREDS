DELIMITER //

CREATE PROCEDURE create_account(
    IN p_username VARCHAR(20),
    IN p_firstname VARCHAR(20),
    IN p_lastname VARCHAR(20),
    IN p_birthdate DATE,
    IN p_role VARCHAR(20),
    IN p_bio VARCHAR(64),
    IN p_password VARCHAR(128)
    	
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SELECT 'Sorry, this username is already taken.' AS message;
    END;

    INSERT INTO usersn(username, firstName, lastName, birthDate, role, bio, password)
    VALUES (p_username, p_firstname, p_lastname, p_birthdate, p_role, p_bio, SHA2(p_password, 512));
    SELECT CONCAT('Successful! Welcome to       ', p_username, '') AS message;
    COMMIT;
END //

CALL freds.create_account('username', 'firstname', 'lastname', 'birthdate', 'role', 'bio', 'password');

CREATE PROCEDURE login(
    IN p_username VARCHAR(20),
    IN p_password VARCHAR(128)
)
BEGIN
    DECLARE status VARCHAR(5);

    SET status = (SELECT CASE WHEN EXISTS (
            SELECT *
            FROM usersn
            WHERE username = p_username AND password = SHA2(p_password, 512)
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF status = 'True' THEN
        INSERT INTO login_record(username)
        VALUES (p_username);
        SELECT 'Login successfully.' AS 'status';
    ELSE
        SELECT 'Invalid username or password, please try again.' AS 'status';
    END IF;
END //

CREATE PROCEDURE find_subject(
    OUT person VARCHAR(20)
)
BEGIN
    SELECT username
    INTO person
    FROM login_record
    ORDER BY timestamp_t DESC
    LIMIT 1;
END //

CREATE PROCEDURE user_logins()
BEGIN
    SELECT *
    FROM login_record
    ORDER BY timestamp_t DESC;
END //

CREATE PROCEDURE send_thread(
    IN p_content VARCHAR(256)
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL find_subject(person);
    INSERT INTO thread(type, username, thread_content, timestamp_t)
    VALUES ('T', person, p_content, NOW());
    SELECT 'Successful, new thread was sent.' AS mess;
END //

CREATE PROCEDURE get_own_threads()
BEGIN
    DECLARE person VARCHAR(20);
    CALL find_subject(person);
    SELECT thread_content, timestamp_t
    FROM thread
    WHERE type = 'T' AND username = person;
END //

CREATE PROCEDURE get_own_threads_and_replies()
BEGIN
    DECLARE person VARCHAR(20);
    CALL find_subject(person);
    SELECT thread.type, thread.thread_content, t.thread_content AS reference_content, t.username AS reference_username, thread.timestamp_t
    FROM thread
    LEFT JOIN thread AS t ON thread.ref_id = t.threadid
    WHERE thread.username = person
    ORDER BY thread.timestamp_t DESC;
END //

CREATE PROCEDURE follow(
    IN p_following VARCHAR(20)
)
BEGIN
    DECLARE person VARCHAR(20);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SELECT 'There is no such username.' AS message;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SELECT CONCAT('You are already following ', p_following, '') AS message;
    END;

    CALL find_subject(person);

    INSERT INTO follow(follower, following)
    VALUES (person, p_following);

    SELECT CONCAT('Successful! you are now following ', p_following, '') AS message;
END //

CREATE PROCEDURE stop_follow(
    IN p_following VARCHAR(20)
)
BEGIN
    DECLARE status VARCHAR(6);
    DECLARE person VARCHAR(20);

    CALL find_subject(person);

    SET status = (SELECT CASE WHEN EXISTS (
            SELECT *
            FROM follow
            WHERE follower = person AND following = p_following
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF status = 'True' THEN
        DELETE FROM follow
        WHERE follower = person AND following = p_following;
        SELECT CONCAT('Successful! you are now unfollowing ', p_following, '') AS message;
    ELSE
        IF EXISTS (
            SELECT *
            FROM usersn
            WHERE usersn.username = p_following
        ) THEN
            SELECT CONCAT('You are not now following ', p_following, '') AS message;
        ELSE
            SELECT 'There is no such username.' AS message;
        END IF;
    END IF;
END //

CREATE PROCEDURE block(
    IN p_blockeduser VARCHAR(20)
)
BEGIN
    DECLARE person VARCHAR(20);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SELECT 'There is no such username.' AS message;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SELECT CONCAT('You are already blocking ', p_blockeduser, '') AS message;
    END;

    CALL find_subject(person);
    INSERT INTO block(username, blocked_user)
    VALUES (person, p_blockeduser);
    SELECT CONCAT('Successful! you are now blocking ', p_blockeduser, '') AS message;
END //

CREATE PROCEDURE stop_block(
    IN p_blockeduser VARCHAR(20)
)
BEGIN
    DECLARE status VARCHAR(6);
    DECLARE person VARCHAR(20);

    CALL find_subject(person);

    SET status = (SELECT CASE WHEN EXISTS (
            SELECT *
            FROM block
            WHERE username = person AND blocked_user = p_blockeduser
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF status = 'True' THEN
        DELETE FROM block
        WHERE username = person AND blocked_user = p_blockeduser;
        SELECT CONCAT('Successful! you are now unblocking ', p_blockeduser, '') AS message;
    ELSE
        IF EXISTS (
            SELECT *
            FROM usersn
            WHERE usersn.username = p_blockeduser
        ) THEN
            SELECT CONCAT('You are not now blocking ', p_blockeduser, '') AS message;
        ELSE
            SELECT 'There is no such username.' AS message;
        END IF;

    END IF;
END //

CREATE PROCEDURE get_following_activity()
BEGIN
    DECLARE person VARCHAR(20);
    CALL find_subject(person);

    SELECT y.type, y.username, y.thread_content, y.cc AS reference_content, y.us AS reference_username, y.timestamp_t
    FROM follow, (
        SELECT thread.threadid, thread.type, thread.username, thread.thread_content, thread.ref_id, thread.timestamp_t, thread.likes, t.thread_content AS cc, t.username AS us
        FROM thread
        LEFT JOIN thread AS t ON thread.ref_id = t.threadid
    ) AS y
    WHERE follow.following = y.username AND follow.follower = person AND y.username NOT IN (
        SELECT block.username
        FROM block
        WHERE blocked_user = person
    )
    ORDER BY y.timestamp_t DESC;
END //

CREATE PROCEDURE get_user_activity(
    IN p_username VARCHAR(20)
)
BEGIN
    DECLARE person VARCHAR(20);

    IF NOT EXISTS (
        SELECT *
        FROM usersn
        WHERE usersn.username = p_username
    ) THEN
        SELECT 'There is no such username.' AS message;
    ELSE
        CALL find_subject(person);
        SELECT thread.type, thread.thread_content, t.thread_content AS reference_content, t.username AS reference_username, thread.timestamp_t
        FROM thread
        LEFT JOIN thread AS t ON thread.ref_id = t.threadid
        WHERE thread.username = p_username AND NOT EXISTS (
                SELECT *
                FROM block
                WHERE block.username = p_username AND blocked_user = person
            )
        ORDER BY thread.timestamp_t DESC;
    END IF;
END //

CREATE PROCEDURE comments(
    IN p_threadid INT,
    IN p_comment_content VARCHAR(256)
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status VARCHAR(5);

    CALL find_subject(person);

    SET status = (SELECT CASE WHEN EXISTS (
            SELECT *
            FROM thread
            WHERE thread.threadid = p_threadid AND thread.username NOT IN (
                    SELECT block.username
                    FROM block
                    WHERE blocked_user = person
                )
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF status = 'True' THEN
        INSERT INTO thread(type, username, thread_content, ref_id, timestamp_t)
        VALUES ('C', person, p_comment_content, p_threadid, NOW());
        SELECT 'New comment added.' AS message;
    ELSE
        IF NOT EXISTS (
            SELECT *
            FROM thread AS tt
            WHERE tt.threadid = p_threadid
        ) THEN
            SELECT 'There is no such thread.' AS message;
        ELSE
            SELECT 'Sorry, you cant add comment because the thread sender is blocking you.' AS 'message';
        END IF;
    END IF;
END //

CREATE PROCEDURE get_comments_of_thread(
    IN p_threadid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL find_subject(person);

    IF NOT EXISTS (
            SELECT *
            FROM thread AS tt
            WHERE tt.threadid = p_threadid
    ) THEN
        SELECT 'There is no such thread.' AS message;
    ELSE
        SELECT thread.username, thread.thread_content
        FROM thread
        WHERE NOT EXISTS (
                SELECT *
                FROM block, thread AS t
                WHERE t.threadid = p_threadid AND t.username = block.username AND block.blocked_user = person
            ) AND thread.type = 'C' AND thread.ref_id = p_threadid AND thread.username NOT IN (
                SELECT block.username
                FROM block
                WHERE blocked_user = person
            )
        ORDER BY thread.timestamp_t DESC;
    END IF;
END //

CREATE PROCEDURE liking(
    IN p_threadid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status VARCHAR(5);
    DECLARE status2 VARCHAR(6);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        SELECT 'There is no such thread.' AS message;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SELECT CONCAT('You are already liking thread with threadid = ', p_threadid, '') AS message;
    END;

    SET status2 = (SELECT CASE WHEN EXISTS (
            SELECT *
            FROM thread AS tt
            WHERE tt.threadid = p_threadid
    )
    THEN 'True'
    ELSE 'False'
    END AS status);

    CALL find_subject(person);
    SET status = (
        SELECT CASE WHEN EXISTS (
                SELECT *
                FROM thread
                WHERE thread.threadid = p_threadid AND thread.username NOT IN (
                        SELECT block.username
                        FROM block
                        WHERE blocked_user = person
                    )
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF status = 'True' AND status2 = 'True' THEN
        INSERT INTO likes(username, threadid)
        VALUES (person, p_threadid);
        SELECT 'Successful!' AS mess;
    ELSEIF status2 = 'False' THEN
        SELECT 'There is no such thread.' AS mess;
    ELSE
        SELECT 'You cant like this thread because sender is blocking you.' AS 'message';
    END IF;
END //

CREATE PROCEDURE number_of_likes(
    IN p_threadid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL find_subject(person);

    IF NOT EXISTS (
            SELECT *
            FROM thread AS tt
            WHERE tt.threadid = p_threadid
    ) THEN
        SELECT 'There is no such thread.' AS mess;
    ELSE
        SELECT CASE WHEN EXISTS (
                SELECT *
                FROM thread
                WHERE thread.threadid = p_threadid AND thread.username IN (
                        SELECT block.username
                        FROM block
                        WHERE blocked_user = person
                    )
        )
        THEN 0
        ELSE (
            SELECT COUNT(*)
            FROM likes
            WHERE threadid = p_threadid
        )
        END AS number_of_like;
    END IF;
END //

CREATE PROCEDURE list_of_liking(
    IN p_threadid INT
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    IF NOT EXISTS(
            SELECT *
            FROM thread as tt
            WHERE tt.threadid = p_threadid
            ) THEN
                SELECT 'There is no such thread.' AS mess;
    ELSE

        SELECT likes.username
        FROM likes
        WHERE NOT EXISTS(
            SELECT *
            FROM block, thread AS t
            WHERE t.threadid = p_threadid AND t.username = block.username
            ) AND likes.threadid = p_threadid AND likes.username NOT IN (
                SELECT block.username
                FROM block
                WHERE blocked_user = person
                );
    end if ;
end //

CREATE PROCEDURE get_popular_threads()
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);
    SELECT *
    FROM thread
    WHERE username NOT IN (
            SELECT block.username
            FROM block
            WHERE blocked_user = person
        )
    ORDER BY likes DESC ;
end //

CREATE PROCEDURE direct_text_message(
    IN  p_username VARCHAR(20),
    IN  p_text  VARCHAR(256)
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status VARCHAR(5);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'There is no such username.' AS message;
    END;

    CALL find_subject(p_username, person);

    SET status = (
        SELECT CASE WHEN NOT EXISTS (
            SELECT *
            FROM block
            WHERE username = p_username AND blocked_user = person
        )
        THEN 'True'
        ELSE 'False'
        END AS status
    );

    IF status = 'True' THEN
        INSERT INTO message(type, s_id, r_id, content)
        VALUES ('M', person, p_username, p_text);
        SELECT 'Successful!' AS mess;
    ELSE
        SELECT CONCAT('Sorry, you can''t send a message because ', person, ' is blocking ', p_username, '.') AS mess;
    END IF;
END //

CREATE PROCEDURE direct_thread_message(
    IN  p_username VARCHAR(20),
    IN  p_threadid  INT
)
BEGIN
    DECLARE person VARCHAR(20);
    DECLARE status1 VARCHAR(5);
    DECLARE status2 VARCHAR(5);

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
	SELECT 'Either there is no such thread or such a user' AS mess;
    END;

    CALL  find_subject(person);

    SET status1 = (
        SELECT CASE WHEN NOT EXISTS(
        SELECT *
        FROM block
        WHERE block.username = p_username AND block.blocked_user = person
    )
    THEN 'True'
    ELSE 'False'
    END AS status);

    SET status2 = (
        SELECT CASE WHEN NOT EXISTS(
        SELECT *
        FROM  thread
        WHERE thread.threadid = p_threadid AND thread.username IN (
            SELECT block.username
            FROM block
            WHERE blocked_user = person
            )
        )
        THEN 'True'
        ELSE 'False'
        END AS status);

    IF (status1 = 'True' and status2 = 'True') THEN
        INSERT INTO message(type, s_id, r_id, ref_id)
        VALUES ('T', person, p_username, p_threadid);
        SELECT 'Successful!' AS mess;
    ELSEIF status1 = 'True' THEN
        SELECT CONCAT('Sorry, you cant send message because ',p_username,' is blocking you.') AS mess;
    ELSE
        SELECT CONCAT('Sorry, you cant send message because thread sender is blocking you.') AS mess;
    end if;

end //

CREATE PROCEDURE get_a_user_messages(
    IN p_username VARCHAR(20)
)
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    IF NOT EXISTS(
            SELECT *
            FROM usersn
            WHERE usersn.username = p_username
            ) THEN
                SELECT 'There is no such username.' AS message;
    ELSE

        SELECT message.type, message.content, thread.thread_content
        FROM message LEFT JOIN thread ON message.ref_id = thread.threadid
        WHERE r_id = person AND s_id = p_username AND (NOT message.type = 'T' OR
            thread.username NOT IN (
            SELECT block.username
            FROM block
            WHERE blocked_user = person
            ))
        ORDER BY message.timestamp_t DESC ;
    end if;
end //

CREATE PROCEDURE list_of_message_sender()
BEGIN
    DECLARE person VARCHAR(20);
    CALL  find_subject(person);

    SELECT message.type, message.s_id, message.content, thread.thread_content
    FROM message LEFT JOIN thread ON message.ref_id = thread.threadid
    WHERE r_id = person AND (NOT message.type = 'T' OR
        thread.username NOT IN (
        SELECT block.username
        FROM block
        WHERE blocked_user = person
        ))
    ORDER BY message.timestamp_t DESC ;
end //

CREATE PROCEDURE create_community_group(
    IN p_group_name VARCHAR(50),
    IN p_description VARCHAR(200),
    IN p_creator_username VARCHAR(20)
)
BEGIN
    DECLARE group_id INT;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        SELECT 'Sorry, this group name is already taken.' AS message;
    END;

    INSERT INTO community_group(group_name, description, creator_username)
    VALUES (p_group_name, p_description, p_creator_username);

    SET group_id = LAST_INSERT_ID();

    INSERT INTO group_members(group_id, username)
    VALUES (group_id, p_creator_username);

    SELECT CONCAT('Successful! Community group "', p_group_name, '" created.') AS message;
END //

CREATE PROCEDURE alogin(
    IN admin_username VARCHAR(20),
    IN admin_password VARCHAR(128)
)
BEGIN
    DECLARE admin_role VARCHAR(10);

        SET admin_role = (
        SELECT CASE
            WHEN EXISTS (
                SELECT * FROM admin WHERE admin_username = p_admin_username AND admin_password = SHA2(p_admin_password, 512)
            )
            THEN 'Admin'
            ELSE 'Invalid'
        END
    );
	IF admin_role = 'Admin' THEN
			SELECT 'Admin login successful.' AS 'status';
			SET @admin_logged_in = 1;
		ELSE
			SELECT 'Invalid admin username or password, please try again.' AS 'status';
		END IF;
	END //

DELIMITER //

CREATE PROCEDURE view_all_users()
BEGIN
    SELECT * FROM usersn;
END //

drop procedure view_all_users;

CREATE PROCEDURE delete_user(IN p_username VARCHAR(20))
BEGIN
    IF @admin_logged_in = 1 THEN
        DELETE FROM usersn WHERE username = p_username;
        user_id= user_id-1;
    ELSE
        SELECT 'Permission denied. Admin access required.' AS status;
    END IF;
END //

CREATE PROCEDURE modify_user(
    IN p_username VARCHAR(20),
    IN p_new_firstname VARCHAR(20),
    IN p_new_lastname VARCHAR(20),
    IN p_new_birthdate DATE,
    IN p_new_bio VARCHAR(64)
)
BEGIN
    IF @admin_logged_in = 1 THEN
        UPDATE usersn
        SET firstName = p_new_firstname,
            lastName = p_new_lastname,
            birthDate = p_new_birthdate,
            bio = p_new_bio
        WHERE username = p_username;
    ELSE
        SELECT 'Permission denied. Admin access required.' AS status;
    END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE join_community_group(
    IN p_group_id INT,
    IN p_username VARCHAR(255)
)
BEGIN
    DECLARE user_identifier VARCHAR(255);
    DECLARE message VARCHAR(255);

    SELECT username INTO user_identifier FROM usersn WHERE username = p_username;

    IF user_identifier IS NOT NULL THEN
        IF NOT EXISTS (SELECT * FROM group_members WHERE group_id = p_group_id AND member_id = user_identifier) THEN
            INSERT INTO group_members (group_id, member_id) VALUES (p_group_id, user_identifier);
            SET message = CONCAT('User "', p_username, '" joined the group successfully.');
        ELSE
            SET message = CONCAT('User "', p_username, '" is already a member of this group.');
        END IF;
    ELSE
        SET message = CONCAT('User "', p_username, '" does not exist.');
    END IF;

    SELECT message AS 'Result';
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE count_users_in_group(
    IN p_group_id INT,
    OUT user_count INT
)
BEGIN
    SELECT COUNT(*) INTO user_count
    FROM group_members
    WHERE group_id = p_group_id;
END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE main_nested_procedure()
BEGIN
    CALL create_account('username', 'firstname', 'lastname', 'birthdate', 'role', 'bio', 'password');
    CALL login('username', 'password');
    CALL send_thread('content');
    CALL follow('following_username');
    CALL stop_follow('following_username');
END //

DELIMITER ;