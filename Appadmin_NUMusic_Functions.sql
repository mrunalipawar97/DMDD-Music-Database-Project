--All functions
set SERVEROUTPUT on;
--Function for getting user subscription

CREATE OR REPLACE FUNCTION get_user_subscription(user_email_in VARCHAR2)
RETURN SYS_REFCURSOR
AS
    subscription_cursor SYS_REFCURSOR;
    user_id_var User_Details.user_id%TYPE;
    INVALID_EMAIL exception;
BEGIN
SELECT user_id INTO user_id_var FROM User_Details WHERE user_email = user_email_in;
   IF user_email_in IS NOT NULL AND user_id_var IS NOT NULL THEN
        OPEN subscription_cursor FOR
            SELECT u.user_name, u.user_email, s.subs_plan_name, s.auto_subscription, s.subs_start_date, s.subs_end_date, c.card_num
            FROM Subscription s
            JOIN User_Details u ON s.user_id = u.user_id
            JOIN Card_Details c ON s.card_id = c.card_id
            WHERE u.user_email = user_email_in and s.subs_start_date >= ADD_MONTHS(SYSDATE, -6);
            
    IF NOT subscription_cursor%ISOPEN THEN
     DBMS_OUTPUT.PUT_LINE('No records found');
    END IF;
    
    ELSE
        RAISE invalid_email;
    END IF;
    
    RETURN subscription_cursor;
END;
/

DECLARE
    subscription_cursor SYS_REFCURSOR;
    user_name User_details.user_name%TYPE;
    user_email User_details.user_email%TYPE;
    subs_plan_name Subscription.subs_plan_name%TYPE;
    auto_subscription Subscription.auto_subscription%TYPE;
    subs_start_date Subscription.subs_start_date%TYPE;
    subs_end_date Subscription.subs_end_date%TYPE;
    card_num Card_details.card_num%TYPE;
    invalid_email EXCEPTION;
    no_data_found exception;
BEGIN
    subscription_cursor := get_user_subscription('sam@gmail.com');
    
    Loop
        FETCH subscription_cursor INTO user_name, user_email, subs_plan_name, auto_subscription, subs_start_date, subs_end_date, card_num;
        EXIT WHEN  subscription_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Subscription details:');
        DBMS_OUTPUT.PUT_LINE('----------------------');
        DBMS_OUTPUT.PUT_LINE('User Name: ' || user_name);
        DBMS_OUTPUT.PUT_LINE('User Email: ' || user_email);
        DBMS_OUTPUT.PUT_LINE('Subscription Plan: ' || subs_plan_name);
        DBMS_OUTPUT.PUT_LINE('Auto-Renewal: ' || auto_subscription);
        DBMS_OUTPUT.PUT_LINE('Subscription Start Date : ' || subs_start_date);
        DBMS_OUTPUT.PUT_LINE('Subscription End Date: ' || subs_end_date);
        DBMS_OUTPUT.PUT_LINE('Card Used: ' || card_num);
        DBMS_OUTPUT.PUT_LINE('----------------------');
    End Loop;
    CLOSE subscription_cursor;
    EXCEPTION
        WHEN INVALID_EMAIL THEN
             DBMS_OUTPUT.PUT_LINE('User email not found');
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('User Email not found');
END;
/

----------------------------------------------------------------------------------------------------------

-- Get User Downloads

CREATE OR REPLACE FUNCTION get_user_downloads(user_email_in VARCHAR2)
RETURN SYS_REFCURSOR
AS
    download_cursor SYS_REFCURSOR;
    user_id_var User_Details.user_id%TYPE;
    INVALID_EMAIL exception;
    No_data_found exception;
BEGIN
SELECT user_id INTO user_id_var FROM User_Details WHERE user_email = user_email_in;
   IF user_email_in IS NOT NULL AND user_id_var IS NOT NULL THEN
        OPEN download_cursor FOR
          SELECT distinct u.user_email, s.song_name, s.genre_name, 
    LISTAGG(DISTINCT a.artist_name, ', ') WITHIN GROUP (ORDER BY a.artist_name) AS artist_names, 
    al.album_name, d.download_date
FROM Download d
INNER JOIN Subscription sub ON d.subs_id = sub.subs_id
INNER JOIN User_Details u ON sub.user_id = u.user_id
INNER JOIN Songs s ON d.song_id = s.song_id
INNER JOIN Album al ON s.album_id = al.album_id
INNER JOIN Songs_Artist sa ON s.song_id = sa.song_id
INNER JOIN Artist a ON sa.artist_id = a.artist_id
WHERE u.user_email = user_email_in
AND sub.subs_id IN (SELECT sub.subs_id 
FROM Subscription sub 
INNER JOIN User_Details u ON sub.user_id = u.user_id 
WHERE u.user_email = user_email_in)
GROUP BY 
    u.user_email,
    s.song_name,
    al.album_name,
    s.genre_name,
    d.download_date;
            
    IF NOT download_cursor%ISOPEN THEN
      RAISE NO_DATA_FOUND;
    END IF;
    
    ELSE
        RAISE invalid_email;
    END IF;
    
    RETURN download_cursor;
END;
/

DECLARE
    download_cursor SYS_REFCURSOR;
    user_email User_details.user_email%TYPE;
    song_name Songs.song_name%TYPE;
    genre_name songs.genre_name%TYPE;
    artist_name artist.artist_name%TYPE;
    album_name album.album_name%TYPE;
    Download_date download.download_date%TYPE;
    invalid_email EXCEPTION;
    no_data_found exception;
BEGIN
    download_cursor := get_user_downloads('sam@gmail.com');
    
    Loop
        FETCH download_cursor INTO user_email, song_name, genre_name, artist_name, album_name, download_date;
        EXIT WHEN  download_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Download details:');
        DBMS_OUTPUT.PUT_LINE('----------------------');
        DBMS_OUTPUT.PUT_LINE('User Email: ' || user_email);
        DBMS_OUTPUT.PUT_LINE('Song Name: ' || song_name);
        DBMS_OUTPUT.PUT_LINE('genre name: ' || genre_name);
        DBMS_OUTPUT.PUT_LINE('artist: ' || artist_name);
        DBMS_OUTPUT.PUT_LINE('album: ' || album_name);
        DBMS_OUTPUT.PUT_LINE('Download Date: ' || download_date);
        DBMS_OUTPUT.PUT_LINE('----------------------');
    End Loop;
    CLOSE download_cursor;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No records found');
        WHEN INVALID_EMAIL THEN
             DBMS_OUTPUT.PUT_LINE('User email not found');
        WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('User Email not found');
END;
/


--Function Get User details
CREATE OR REPLACE FUNCTION Get_User_Details(user_id_in IN NUMBER)
RETURN SYS_REFCURSOR IS
  user_details_cur SYS_REFCURSOR;
  v_count Number;
BEGIN
  OPEN user_details_cur FOR
    SELECT *
    FROM User_Details
    WHERE user_id = user_id_in;
    
    SELECT count(*) into v_count from User_details where user_id = user_id_in;
    IF v_count = 0 THEN
        dbms_output.put_line('User Not found');
    END IF;
  RETURN user_details_cur;
END;
/

DECLARE
  user_id_in NUMBER := 100; -- Replace with the user ID you want to retrieve details for
  user_details_cur SYS_REFCURSOR;
  user_details_rec User_Details%ROWTYPE;
BEGIN
  user_details_cur := Get_User_Details(user_id_in);
  
  LOOP
    FETCH user_details_cur INTO user_details_rec;
    EXIT WHEN user_details_cur%NOTFOUND; -- Exits loop if the cursor is not found
    
    DBMS_OUTPUT.PUT_LINE('User ID: ' || user_details_rec.user_id);
    DBMS_OUTPUT.PUT_LINE('User Name: ' || user_details_rec.user_name);
    DBMS_OUTPUT.PUT_LINE('User Address: ' || user_details_rec.user_addr);
    DBMS_OUTPUT.PUT_LINE('User Phone: ' || user_details_rec.user_phone);
    DBMS_OUTPUT.PUT_LINE('User Email: ' || user_details_rec.user_email);
  END LOOP;
  
  CLOSE user_details_cur;
END;

/
-- Get_Custom_Playlist_Songs function
CREATE OR REPLACE FUNCTION Get_Custom_Playlist_Songs(
    user_id_in IN User_Details.user_id%TYPE,
    playlist_name_in IN Playlist.playlist_name%TYPE
) RETURN SYS_REFCURSOR
AS
    playlist_id Playlist.playlist_id%TYPE;
    songs_cursor SYS_REFCURSOR;

BEGIN
    -- Get the playlist_id associated with the given playlist_name and user_id
    SELECT playlist_id
    INTO playlist_id
    FROM Playlist
    WHERE user_id = user_id_in
    AND playlist_name = playlist_name_in;

    -- Get the songs associated with the playlist_id
    OPEN songs_cursor FOR
    SELECT s.song_id, s.song_name, s.song_duration, s.rating, s.genre_name
    FROM Songs s
    INNER JOIN Songs_Playlist sp ON s.song_id = sp.song_id
    WHERE sp.playlist_id = playlist_id;
 
    RETURN songs_cursor;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Data not found');
    

END;
/

DECLARE
    songs_cursor SYS_REFCURSOR;
    song_id Songs.song_id%TYPE;
    song_name Songs.song_name%TYPE;
    song_duration Songs.song_duration%TYPE;
    rating Songs.rating%TYPE;
    genre_name Songs.genre_name%TYPE;
BEGIN
    songs_cursor := Get_Custom_Playlist_Songs(101,'Gym Music');
    
    -- Print out the songs
    DBMS_OUTPUT.PUT_LINE('Songs:');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('SONG ID' || chr(9) || 'SONG NAME' || chr(9) || 'DURATION' || chr(9) || 'RATING' || chr(9) || 'GENRE');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');
    
    LOOP
        FETCH songs_cursor INTO song_id, song_name, song_duration, rating, genre_name;
        EXIT WHEN songs_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(song_id || chr(9) || song_name || chr(9) || song_duration || chr(9) || rating || chr(9) || genre_name);
    END LOOP;
    
    CLOSE songs_cursor;
END;
/

--get_song_details function
CREATE OR REPLACE FUNCTION get_song_details(song_name_in VARCHAR2)
RETURN SYS_REFCURSOR
AS
    song_cursor SYS_REFCURSOR;
    v_count Number;
BEGIN
    OPEN song_cursor FOR
        SELECT s.song_id, s.song_name, s.song_release_date, s.song_duration, a.album_name, a.album_release_date, l.lyrics_text, l.lyrics_language, COUNT(d.song_id) as download_count
        FROM Songs s
        JOIN Album a ON s.album_id = a.album_id
        JOIN Songs_Artist sa ON s.song_id = sa.song_id
        JOIN Artist ar ON sa.artist_id = ar.artist_id
        LEFT JOIN Lyrics l ON s.song_id = l.song_id
        LEFT JOIN download d ON s.song_id = d.song_id
        WHERE s.song_name = song_name_in
        GROUP BY s.song_id, s.song_name, s.song_release_date, s.song_duration, a.album_name, a.album_release_date, l.lyrics_text, l.lyrics_language;
        
    SELECT count(*) into v_count from Songs where song_name = song_name_in;
    IF v_count = 0 THEN
        dbms_output.put_line('Song Not found');
    END IF;
    RETURN song_cursor;
END;
/

DECLARE
    song_cursor SYS_REFCURSOR;
    song_id Songs.song_id%TYPE;
    song_name_in Songs.song_name%TYPE;
    song_release_date Songs.song_release_date%TYPE;
    song_duration Songs.song_duration%TYPE;
    album_name Album.album_name%TYPE;
    album_release_date Album.album_release_date%TYPE;
    lyrics_text Lyrics.lyrics_text%TYPE;
    lyrics_language Lyrics.lyrics_language%TYPE;
    download_count NUMBER(3);
BEGIN
    song_cursor := get_song_details('Liar');
    Loop
        FETCH song_cursor INTO song_id, song_name_in, song_release_date, song_duration, album_name, album_release_date, lyrics_text, lyrics_language, download_count;
        EXIT WHEN song_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || song_id);
        DBMS_OUTPUT.PUT_LINE('Name: ' || song_name_in);
        DBMS_OUTPUT.PUT_LINE('Release Date: ' || song_release_date);
        DBMS_OUTPUT.PUT_LINE('Duration: ' || song_duration);
        DBMS_OUTPUT.PUT_LINE('Album Name: ' || album_name);
        DBMS_OUTPUT.PUT_LINE('Album Release Date: ' || album_release_date);
        DBMS_OUTPUT.PUT_LINE('Lyrics: ' || lyrics_text);
        DBMS_OUTPUT.PUT_LINE('Lyrics Language: ' || lyrics_language);
        DBMS_OUTPUT.PUT_LINE('No of times downloaded: ' || download_count);
        DBMS_OUTPUT.PUT_LINE('----------------------');
    End Loop;
    CLOSE song_cursor;
END;
/


--Function for getting songs by artist
CREATE OR REPLACE FUNCTION get_songs_by_artist(art_name IN VARCHAR2)
RETURN SYS_REFCURSOR
IS
  song_cursor SYS_REFCURSOR;
BEGIN
    IF art_name IS NOT NULL THEN
      OPEN song_cursor FOR
        SELECT s.song_name, s.song_release_date, s.song_duration, a.artist_name, al.album_name, s.genre_name, s.rating
        FROM songs s
        JOIN album_artist aa ON s.album_id = aa.album_id
        JOIN artist a ON a.artist_id = aa.artist_id
        JOIN album al ON al.album_id = aa.album_id
        WHERE a.artist_name = art_name;
    ELSE
        DBMS_OUTPUT.PUT_LINE( 'Invalid artist name input parameter');
    END IF;
  RETURN song_cursor;
END;
/

DECLARE
  song_cursor SYS_REFCURSOR;
  song_name SONGS.song_name%TYPE;
  song_release_date SONGS.song_release_date%TYPE;
  song_duration SONGS.song_duration%TYPE;
  artist_name ARTIST.artist_name%TYPE;
  album_name ALBUM.album_name%TYPE;
  genre_name SONGS.genre_name%TYPE;
  rating SONGS.rating%TYPE;
BEGIN
  song_cursor := get_songs_by_artist('Olivia Rodrigo');
  DBMS_OUTPUT.PUT_LINE('Song Name | Release Date | Duration | Artist Name | Album Name | Genre | Rating');
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------');
  LOOP
    FETCH song_cursor INTO song_name, song_release_date, song_duration, artist_name, album_name, genre_name, rating;
    EXIT WHEN song_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(song_name || ' | ' || song_release_date || ' | ' || song_duration || ' | ' || artist_name || ' | ' || album_name || ' | ' || genre_name || ' | ' || rating);
  END LOOP;
  CLOSE song_cursor;
END;
/

--Function for getting albums by artist

CREATE OR REPLACE FUNCTION get_albums_by_artist(art_name IN VARCHAR2)
RETURN SYS_REFCURSOR
IS
  album_cursor SYS_REFCURSOR;
BEGIN
  IF art_name IS NOT NULL THEN
    OPEN album_cursor FOR
      SELECT a.album_id, a.album_name, a.album_release_date
      FROM album a
      JOIN album_artist aa ON a.album_id = aa.album_id
      JOIN artist ar ON ar.artist_id = aa.artist_id
      WHERE ar.artist_name = art_name;
  ELSE
    DBMS_OUTPUT.PUT_LINE( 'Invalid artist name input parameter');
  END IF;
  
  RETURN album_cursor;
END;
/

DECLARE
  album_cursor SYS_REFCURSOR;
  album_id Album.album_id%TYPE; -- declare the variable here
  album_name Album.album_name%TYPE; -- declare the variable here
  album_release_date Album.album_release_date%TYPE; -- declare the variable here
BEGIN
  album_cursor := get_albums_by_artist('Olivia Rodrigo');
  DBMS_OUTPUT.PUT_LINE('Album Id | Album Name | Release Date');
  DBMS_OUTPUT.PUT_LINE('------------------------------------');
  LOOP
    FETCH album_cursor INTO album_id, album_name, album_release_date;
    EXIT WHEN album_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(album_id || ' | ' || album_name || ' | ' || album_release_date);
  END LOOP;
  CLOSE album_cursor;
END;
/

--Function to retrieve songs based on genre

CREATE OR REPLACE FUNCTION get_songs_by_genre(p_genre_name IN VARCHAR2)
RETURN SYS_REFCURSOR
AS
  v_cursor SYS_REFCURSOR;
BEGIN
    IF p_genre_name IS NOT NULL THEN
      OPEN v_cursor FOR
        SELECT song_id, rating, song_name, song_release_date, song_duration, album_id, genre_name
        FROM songs
        WHERE genre_name = p_genre_name;
    ELSE
        DBMS_OUTPUT.PUT_LINE( 'Invalid artist name input parameter');
    END IF;    
  RETURN v_cursor;
END;
/

DECLARE
  songs_cursor SYS_REFCURSOR;
  song_id Songs.song_id%TYPE;
  rating Songs.rating%TYPE;
  song_name Songs.song_name%TYPE;
  song_release_date Songs.song_release_date%TYPE;
  song_duration Songs.song_duration%TYPE;
  album_id Songs.album_id%TYPE;
  genre_name Songs.genre_name%TYPE;
BEGIN
  songs_cursor := get_songs_by_genre('Rock');
  DBMS_OUTPUT.PUT_LINE('Song Id |  Rating | Song Name | Release Date | Duration | Album Id | Genre Name');
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------');
  LOOP
    FETCH songs_cursor INTO song_id, rating, song_name, song_release_date, song_duration, album_id, genre_name;
    EXIT WHEN songs_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(song_id || ' | ' || rating || ' | ' || song_name || ' | ' || song_release_date || ' | ' || song_duration || ' | ' || album_id || ' | ' || genre_name);
  END LOOP;
  CLOSE songs_cursor;
END;
/

-- get songs based on Pop genre 
DECLARE
  songs_cursor SYS_REFCURSOR;
  song_id Songs.song_id%TYPE;
  rating Songs.rating%TYPE;
  song_name Songs.song_name%TYPE;
  song_release_date Songs.song_release_date%TYPE;
  song_duration Songs.song_duration%TYPE;
  album_id Songs.album_id%TYPE;
  genre_name Songs.genre_name%TYPE;
BEGIN
  songs_cursor := get_songs_by_genre('Pop');
  DBMS_OUTPUT.PUT_LINE('Song Id |  Rating | Song Name | Release Date | Duration | Album Id | Genre Name');
  DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------');
  LOOP
    FETCH songs_cursor INTO song_id, rating, song_name, song_release_date, song_duration, album_id, genre_name;
    EXIT WHEN songs_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(song_id || ' | ' || rating || ' | ' || song_name || ' | ' || song_release_date || ' | ' || song_duration || ' | ' || album_id || ' | ' || genre_name);
  END LOOP;
  CLOSE songs_cursor;
END;
/