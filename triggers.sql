DELIMITER //

CREATE TRIGGER auto_like
AFTER INSERT
ON likes FOR EACH ROW
    BEGIN
        DECLARE id INT;
        SET id = NEW.threadid;
        UPDATE thread SET likes = likes + 1 WHERE threadid = id;
    END //


CREATE TRIGGER auto_follow
BEFORE INSERT
ON follow FOR EACH ROW
    BEGIN
        DECLARE follower_temp VARCHAR(20);
        DECLARE following_temp VARCHAR(20);
        SET follower_temp = NEW.follower;
        SET following_temp = NEW.following;
        UPDATE usersn SET following = usersn.following + 1 WHERE username = follower_temp;
        UPDATE usersn SET followers = followers + 1 WHERE username = following_temp;
    end //


CREATE TRIGGER auto_stop_follow
BEFORE DELETE
ON follow FOR EACH ROW
    BEGIN
        DECLARE follower_temp VARCHAR(20);
        DECLARE following_temp VARCHAR(20);
        SET follower_temp = OLD.follower;
        SET following_temp = OLD.following;
        UPDATE usersn SET following = usersn.following - 1 WHERE username = follower_temp;
        UPDATE usersn SET followers = followers - 1 WHERE username = following_temp;
    end //


CREATE TRIGGER auto_login
AFTER INSERT
ON usersn FOR EACH ROW
    BEGIN
        INSERT INTO login_record(USERNAME, TIMESTAMP_T) VALUES (NEW.username, CURRENT_TIMESTAMP);
    end //
