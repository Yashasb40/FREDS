
use freds;

CREATE TABLE usersn (
username    VARCHAR(20) NOT NULL ,
firstName    VARCHAR(20)NOT NULL,
lastName    VARCHAR(20)NOT NULL,
birthDate    DATE NOT NULL,
registery_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
bio        Varchar(64),
followers   INT  NOT NULL DEFAULT 0,
following   INT  NOT NULL DEFAULT 0,
password VARCHAR(128) NOT NULL ,

PRIMARY KEY (username)
);

CREATE TABLE thread(
threadid          INT AUTO_INCREMENT,
type            CHAR(1) NOT NULL CHECK ( type in ('T', 'C')) ,
username         VARCHAR(20) NOT NULL,
thread_content     VARCHAR(256) NOT NULL,
ref_id          INT,
timestamp_t     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
likes           INT NOT NULL DEFAULT 0,

PRIMARY KEY (threadid),
FOREIGN KEY (username) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (ref_id) REFERENCES thread(threadid)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE message(
 mess_id            INT AUTO_INCREMENT,
 type           CHAR(1) NOT NULL CHECK ( type in ('M', 'T')) ,
 s_id           VARCHAR(20) NOT NULL ,
 r_id           VARCHAR(20) NOT NULL ,
 content        VARCHAR(256),
 ref_id         INT ,
 timestamp_t     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

PRIMARY KEY (mess_id),
FOREIGN KEY (s_id) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (r_id) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (ref_id) REFERENCES thread(threadid)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE login_record(
  username      VARCHAR(20) NOT NULL ,
  timestamp_t     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

PRIMARY KEY (username, timestamp_t),
FOREIGN KEY (username) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE block(
username        VARCHAR(20),
blocked_user     VARCHAR(20),

PRIMARY KEY (username, blocked_user ),
FOREIGN KEY (username) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE ,
FOREIGN KEY (blocked_user) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE follow (
follower    VARCHAR(20) NOT NULL ,
following    VARCHAR(20) NOT NULL ,

PRIMARY KEY (follower, following),
FOREIGN KEY (follower) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE ,
FOREIGN KEY (following) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE likes (
username        VARCHAR(20),
threadid           INT,
timeStamp_l   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

PRIMARY KEY     (threadid, username),
FOREIGN KEY     (threadid) REFERENCES thread(threadid)
ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY     (username) REFERENCES usersn(username)
ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE community_group (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    group_name VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR(200),
    creator_username VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (creator_username) REFERENCES usersn(username)
);

CREATE TABLE group_members (
    group_id INT,
    username VARCHAR(20),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, username),
    FOREIGN KEY (group_id) REFERENCES community_group(group_id),
    FOREIGN KEY (username) REFERENCES usersn(username)
);

CREATE TABLE group_texts (
    text_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT,
    text_content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES community_group(group_id)
);

CREATE TABLE group_announcements (
    announcement_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT,
    announcement_content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES community_group(group_id)
);

CREATE TABLE group_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT,
    username VARCHAR(40),
    member_id VARCHAR(20),
    joined_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (group_id) REFERENCES community_group(group_id),
    FOREIGN KEY (member_id) REFERENCES usersn(username)
);