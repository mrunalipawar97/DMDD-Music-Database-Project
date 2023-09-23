Set SERVEROUTPUT ON;
create or replace PROCEDURE DROP_VIEWS IS
V_COUNTER NUMBER := 0;
CURRENT_USER VARCHAR(20);
EX_INCORRECT_USER EXCEPTION;
EX_VIEW_NOT_FOUND EXCEPTION;
BEGIN
    SELECT USER INTO CURRENT_USER FROM DUAL;
    DBMS_OUTPUT.PUT_LINE('user selected');
    IF (CURRENT_USER <> 'APPADMIN_NUMUSIC') THEN
        RAISE EX_INCORRECT_USER;
    END IF;
    
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_POPULAR_SONGS';   
    IF V_COUNTER > 0 THEN  
    EXECUTE IMMEDIATE 'DROP view VW_POPULAR_SONGS CASCADE CONSTRAINTS';
      DBMS_OUTPUT.PUT_LINE('view popular songs dropped');
    ELSE
    RAISE EX_VIEW_NOT_FOUND;
    END IF;
  
   SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_SONGS_WITH_LYRICS_IN_LANGUAGE';   
   IF V_COUNTER > 0 THEN  
   EXECUTE IMMEDIATE 'DROP view VW_SONGS_WITH_LYRICS_IN_LANGUAGE CASCADE CONSTRAINTS'; 
   DBMS_OUTPUT.PUT_LINE('view songs lyrics dropped');
   ELSE
    RAISE EX_VIEW_NOT_FOUND;
   END IF;
   
   SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS';   
  IF V_COUNTER > 0 THEN    
  EXECUTE IMMEDIATE 'DROP view VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS CASCADE CONSTRAINTS';  
  DBMS_OUTPUT.PUT_LINE('view USER SUBS dropped');
  ELSE
    RAISE EX_VIEW_NOT_FOUND;
   END IF;
   
   SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_POPULAR_ARTISTS';   
  IF V_COUNTER > 0 THEN   
  EXECUTE IMMEDIATE 'DROP view VW_POPULAR_ARTISTS CASCADE CONSTRAINTS'; 
  DBMS_OUTPUT.PUT_LINE('view POPULAR ARTISTS dropped');
  ELSE
    RAISE EX_VIEW_NOT_FOUND;
   END IF;
   
   SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_AUTO_SUBS';   
  IF V_COUNTER > 0 THEN  
  EXECUTE IMMEDIATE 'DROP view VW_AUTO_SUBS CASCADE CONSTRAINTS';  
  DBMS_OUTPUT.PUT_LINE('view AUTO SUBS dropped');
  ELSE
    RAISE EX_VIEW_NOT_FOUND;
   END IF;
   
   SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_USER_FAVOURITE_SONGS';   
   IF V_COUNTER > 0 THEN  
   EXECUTE IMMEDIATE 'DROP view VW_USER_FAVOURITE_SONGS CASCADE CONSTRAINTS'; 
   DBMS_OUTPUT.PUT_LINE('view USER FAV dropped');
   ELSE
    RAISE EX_VIEW_NOT_FOUND;
   END IF;
   
   SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_SONGS_BY_ALBUM';   
   IF V_COUNTER > 0 THEN  
   EXECUTE IMMEDIATE 'DROP view VW_SONGS_BY_ALBUM CASCADE CONSTRAINTS';  
       DBMS_OUTPUT.PUT_LINE('view SONGS BY ALBUM dropped');
       ELSE
    RAISE EX_VIEW_NOT_FOUND;
   END IF;
    
   SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_ALBUM_DETAILS';   
   IF V_COUNTER > 0 THEN    
   EXECUTE IMMEDIATE 'DROP view VW_ALBUM_DETAILS CASCADE CONSTRAINTS'; 
    DBMS_OUTPUT.PUT_LINE('view ALBUM DETAILS dropped');
    ELSE
    RAISE EX_VIEW_NOT_FOUND;
   END IF;
   
  SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_PLAYLIST_SONGS';   
  IF V_COUNTER > 0 THEN     
  EXECUTE IMMEDIATE 'DROP view VW_PLAYLIST_SONGS CASCADE CONSTRAINTS'; 
  DBMS_OUTPUT.PUT_LINE('view PLAYLIST SONGS dropped');
  ELSE
    RAISE EX_VIEW_NOT_FOUND;
  END IF;
   
 SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_TOP_RATED_SONGS';   
  IF V_COUNTER > 0 THEN   
  EXECUTE IMMEDIATE 'DROP view VW_TOP_RATED_SONGS CASCADE CONSTRAINTS';  
  DBMS_OUTPUT.PUT_LINE('view top rated songs dropped');
  ELSE
    RAISE EX_VIEW_NOT_FOUND;
  END IF;  
COMMIT;
    
EXCEPTION
    WHEN EX_INCORRECT_USER THEN
        DBMS_OUTPUT.PUT_LINE('YOU CANNOT PERFORM THIS ACTION, PLEASE CONTACT ADMIN');
    WHEN EX_VIEW_NOT_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('VIEW DOESNT EXIST');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    ROLLBACK;
END;
/

--procedure to create views
CREATE OR REPLACE PROCEDURE CREATEVIEWS IS
    V_COUNTER NUMBER := 1;
    CURRENT_USER VARCHAR(20);
    EX_INCORRECT_USER EXCEPTION;
    EX_FAILED_TO_CREATE_TABLE EXCEPTION;
    
BEGIN
    SELECT USER INTO CURRENT_USER FROM DUAL;
    IF (CURRENT_USER <> 'APPADMIN_NUMUSIC') THEN
        RAISE EX_INCORRECT_USER;
    END IF;
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_POPULAR_SONGS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
   CREATE VIEW VW_POPULAR_SONGS AS
    SELECT s.song_id, s.song_name, s.song_release_date, COUNT(d.song_id) AS download_count
    FROM Songs s
    JOIN Download d ON s.song_id = d.song_id
    GROUP BY s.song_id, s.song_name, s.song_release_date
    ORDER BY download_count DESC';
      DBMS_OUTPUT.PUT_LINE('view popular songs created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
-- A view to show all the songs in a specific playlist
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_PLAYLIST_SONGS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
    CREATE VIEW VW_PLAYLIST_SONGS AS
    SELECT ps.playlist_id, ps.playlist_name, s.song_name, s.song_release_date
    FROM Playlist ps
    JOIN Songs_Playlist sp ON ps.playlist_id = sp.playlist_id
    JOIN Songs s ON sp.song_id = s.song_id
    order by ps.playlist_id';
     DBMS_OUTPUT.PUT_LINE('view playlist songs created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
    -- A view to show album details
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_ALBUM_DETAILS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
    CREATE VIEW VW_ALBUM_DETAILS AS
    SELECT a.album_id, a.album_name, a.album_release_date, ar.artist_name, s.song_name
    FROM Album a
    JOIN Album_Artist aa ON a.album_id = aa.album_id
    JOIN Artist ar ON aa.artist_id = ar.artist_id
    JOIN Songs s ON a.album_id = s.album_id';
     DBMS_OUTPUT.PUT_LINE('view album details created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
    -- A view to show all the songs details who has rating above 3
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_TOP_RATED_SONGS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
   CREATE VIEW VW_TOP_RATED_SONGS AS
    SELECT rating, song_id, song_name, song_release_date, song_duration, genre_name
    FROM songs
    WHERE rating > 3 ';
    DBMS_OUTPUT.PUT_LINE('view top rated songs created');
     ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
    -- A view to show all the users who have auto-renewal on
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_AUTO_SUBS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
     CREATE VIEW VW_AUTO_SUBS AS
    SELECT s.subs_id, s.auto_subscription, s.subs_plan_name, s.subs_start_date, s.subs_end_date, ud.user_name AS appadmin
    FROM subscription s
    INNER JOIN user_details ud ON s.user_id = ud.user_id
    where s.auto_subscription = ''Y''
    and s.subs_end_date > sysdate';
     DBMS_OUTPUT.PUT_LINE('view auto subs created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
    -- A view to show songs in a particular album
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_SONGS_BY_ALBUM';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
    CREATE VIEW VW_SONGS_BY_ALBUM AS
    SELECT distinct
        s.song_id,
        s.song_name,
        s.rating,
        s.song_duration,
        s.genre_name,
        a.album_id,
        a.album_name,
        a.album_release_date
    FROM songs s
    INNER JOIN album a ON s.album_id = a.album_id
    INNER JOIN album_artist aa ON aa.album_id = a.album_id';
     DBMS_OUTPUT.PUT_LINE('view songs by album created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;

    -- A view to show a user’s favorite songs
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_USER_FAVOURITE_SONGS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
     CREATE VIEW VW_USER_FAVOURITE_SONGS AS
    SELECT f.user_id, u.user_name, f.song_id, s.song_name, s.album_id, a.album_name, a.album_release_date, s.song_duration
    FROM favourites f
    JOIN songs s ON f.song_id = s.song_id
    JOIN album a ON s.album_id = a.album_id
    join user_details u ON f.user_id = u.user_id
    order by f.user_id ';
     DBMS_OUTPUT.PUT_LINE('view user fav created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
    -- A view to show songs with lyrics in a specific language
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_SONGS_WITH_LYRICS_IN_LANGUAGE';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
    CREATE VIEW VW_SONGS_WITH_LYRICS_IN_LANGUAGE AS
    SELECT s.song_name, s.song_duration, a.album_name, l.lyrics_text, l.lyrics_language FROM Songs s
    LEFT JOIN Album a ON s.album_id = a.album_id
    LEFT JOIN Lyrics l ON s.song_id = l.song_id ';
     DBMS_OUTPUT.PUT_LINE('view songs with lyrics created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
    -- A view to show the user’s card details and their associated subscription
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
    CREATE VIEW VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS AS 
    SELECT 
        ud.user_id, 
        ud.user_name, 
        c.card_id,
        c.cvv, 
        c.name_on_card, 
        c.exp_date, 
        c.card_num, 
        s.subs_id, 
        s.auto_subscription, 
        s.subs_plan_name, 
        s.subs_start_date, 
        s.subs_end_date
    FROM User_Details ud
    JOIN Card_Details c ON ud.user_id = c.user_id 
    JOIN Subscription s ON ud.user_id = s.user_id
    order by ud.user_id';
     DBMS_OUTPUT.PUT_LINE('view user subs created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
    -- A view to show the most popular artists
    SELECT COUNT(*) INTO V_COUNTER FROM ALL_VIEWS WHERE VIEW_NAME = 'VW_POPULAR_ARTISTS';
    IF V_COUNTER = 0 THEN 
    EXECUTE IMMEDIATE '
    CREATE VIEW VW_POPULAR_ARTISTS AS
    SELECT artist.artist_id, artist.artist_name
    FROM artist
    JOIN album_artist ON artist.artist_id = album_artist.artist_id 
    JOIN album ON album_artist.album_id = album.album_id 
    JOIN songs ON album.album_id = songs.album_id
    JOIN favourites ON songs.song_id = favourites.song_id 
    GROUP BY artist.artist_id, artist.artist_name
    HAVING COUNT(favourites.song_id) > 3';
     DBMS_OUTPUT.PUT_LINE('view popular artist created');
      ELSE
      RAISE EX_FAILED_TO_CREATE_TABLE;
    END IF;
    
COMMIT;
EXCEPTION
WHEN EX_INCORRECT_USER THEN
        DBMS_OUTPUT.PUT_LINE('YOU CANNOT PERFORM THIS ACTION. PLEASE CONTACT ADMIN');
WHEN EX_FAILED_TO_CREATE_TABLE THEN
        DBMS_OUTPUT.PUT_LINE('VIEW WAS NOT CREATED SUCCESSFULLY');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
    ROLLBACK;
    
END;
/


-- executing drop views procedure
EXECUTE DROP_VIEWS;

-- executing create views procedure
EXECUTE CREATEVIEWS;
-- Grants for paid user
GRANT select on VW_POPULAR_SONGS to apppaiduser;
GRANT select on VW_PLAYLIST_SONGS to apppaiduser;
GRANT select on VW_ALBUM_DETAILS to apppaiduser;
GRANT select on VW_TOP_RATED_SONGS to apppaiduser;
--GRANT select on VW_AUTO_SUBS to apppaiduser;
GRANT select on VW_SONGS_BY_ALBUM to apppaiduser;
GRANT select on VW_USER_FAVOURITE_SONGS to apppaiduser;
GRANT select on VW_SONGS_WITH_LYRICS_IN_LANGUAGE to apppaiduser;
--GRANT select on VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS to apppaiduser;
GRANT select on VW_POPULAR_ARTISTS to apppaiduser;

-- Grants for unpaid user
--GRANT select on VW_POPULAR_SONGS to appunpaiduser;
GRANT select on VW_PLAYLIST_SONGS to appunpaiduser;
GRANT select on VW_ALBUM_DETAILS to appunpaiduser;
GRANT select on VW_TOP_RATED_SONGS to appunpaiduser;
--GRANT select on VW_AUTO_SUBS to appunpaiduser;
GRANT select on VW_SONGS_BY_ALBUM to appunpaiduser;
GRANT select on VW_USER_FAVOURITE_SONGS to appunpaiduser;
GRANT select on VW_SONGS_WITH_LYRICS_IN_LANGUAGE to appunpaiduser;
--GRANT select on VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS to appunpaiduser;
GRANT select on VW_POPULAR_ARTISTS to appunpaiduser;

-- Grants for customer service user
GRANT select on VW_POPULAR_SONGS to appcustomerservice;
GRANT select on VW_PLAYLIST_SONGS to appcustomerservice;
GRANT select on VW_ALBUM_DETAILS to appcustomerservice;
GRANT select on VW_TOP_RATED_SONGS to appcustomerservice;
GRANT select on VW_AUTO_SUBS to appcustomerservice;
GRANT select on VW_SONGS_BY_ALBUM to appcustomerservice;
GRANT select on VW_USER_FAVOURITE_SONGS to appcustomerservice;
GRANT select on VW_SONGS_WITH_LYRICS_IN_LANGUAGE to appcustomerservice;
GRANT select on VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS to appcustomerservice;
GRANT select on VW_POPULAR_ARTISTS to appcustomerservice;



select * from VW_POPULAR_SONGS;
select * from VW_PLAYLIST_SONGS;
select * from VW_ALBUM_DETAILS;
select * from VW_TOP_RATED_SONGS;
select * from VW_AUTO_SUBS;
select * from VW_SONGS_BY_ALBUM;
select * from VW_USER_FAVOURITE_SONGS;
select * from VW_SONGS_WITH_LYRICS_IN_LANGUAGE;
select * from VW_USER_SUBSCRIPTION_WITH_CARD_DETAILS;
select * from VW_POPULAR_ARTISTS;

commit;