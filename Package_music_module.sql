CREATE OR REPLACE PACKAGE pkg_music_module 
AS 

    PROCEDURE songs_upsert(
        p_song_id IN songs.song_id%TYPE,
        p_rating IN songs.rating%TYPE,
        p_song_name IN songs.song_name%TYPE,
        p_release_date IN songs.song_release_date%TYPE,
        p_duration IN songs.song_duration%TYPE,
        p_album_id IN songs.album_id%TYPE,
        p_genre_name IN songs.genre_name%TYPE,
        p_action IN VARCHAR2,
        p_user IN VARCHAR2
    );
    
END pkg_music_module;
/

CREATE OR REPLACE PACKAGE BODY pkg_music_module AS
    
    -- Exception declarations
    invalid_song_name EXCEPTION;
    invalid_song_id_or_album_id EXCEPTION;
    duplicate_song EXCEPTION;
    song_not_found EXCEPTION;
    invalid_user EXCEPTION;
    
    PROCEDURE songs_upsert(
    p_song_id IN songs.song_id%TYPE,
    p_rating IN songs.rating%TYPE,
    p_song_name IN songs.song_name%TYPE,
    p_release_date IN songs.song_release_date%TYPE,
    p_duration IN songs.song_duration%TYPE,
    p_album_id IN songs.album_id%TYPE,
    p_genre_name IN songs.genre_name%TYPE,
    p_action IN VARCHAR2,
    p_user IN VARCHAR2
)
IS
    -- Local variable declarations
    v_song_name_pattern VARCHAR2(40) := '[A-Za-z0-9 ]+';
    v_user_role VARCHAR2(20);
    v_delete_song_id NUMBER(3);
BEGIN      
    -- Validate user
        SELECT user INTO v_user_role FROM dual WHERE user = p_user;
        
        IF v_user_role <> 'APPADMIN' THEN
            RAISE invalid_user;
        END IF;
    -- Validate song name
    IF NOT REGEXP_LIKE(p_song_name, v_song_name_pattern) THEN
        RAISE invalid_song_name;
    END IF;
    
    -- Validate song and album IDs
    IF p_action = 'Insert' THEN
        DECLARE
            v_album_exists INTEGER;
            v_song_exists INTEGER;
        BEGIN
            SELECT COUNT(*) INTO v_album_exists FROM album WHERE album_id = p_album_id;
            IF v_album_exists = 0 THEN
                RAISE invalid_song_id_or_album_id;
            END IF;
            
            SELECT COUNT(*) INTO v_song_exists FROM songs WHERE song_id = p_song_id OR (song_name = p_song_name AND album_id = p_album_id);
            IF v_song_exists > 0 THEN
                RAISE duplicate_song;
            END IF;
        END;
    END IF;
    
    -- Perform upsert operation based on action
    IF p_action = 'Insert' THEN
        INSERT INTO songs (
            song_id,
            rating,
            song_name,
            song_release_date,
            song_duration,
            album_id,
            genre_name
        ) VALUES (
            p_song_id,
            p_rating,
            p_song_name,
            p_release_date,
            p_duration,
            p_album_id,
            p_genre_name
        );
    ELSIF p_action = 'Update' THEN
        UPDATE songs SET
            rating = p_rating,
            song_name = p_song_name,
            song_release_date = p_release_date,
            song_duration = p_duration,
            album_id = p_album_id,
            genre_name = p_genre_name
        WHERE song_id = p_song_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            dbms_output.put_line('3');
            RAISE song_not_found;
        END IF;
        
    ELSIF p_action = 'Delete' THEN
        --Select Song_id_seq.currval into v_delete_song_id from songs;
        DELETE FROM songs WHERE song_id = p_song_id;
        dbms_output.put_line(p_song_id);
        
        IF SQL%ROWCOUNT = 0 THEN
            dbms_output.put_line('2');
            RAISE song_not_found;
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN invalid_user THEN
            dbms_output.put_line('Invalid user. Only APPADMIN is allowed to perform this operation.');
    WHEN invalid_song_name THEN
        DBMS_OUTPUT.PUT_LINE('Invalid song name. Song name should only contain alphabets, numbers and spaces.');
    WHEN invalid_song_id_or_album_id THEN
        dbms_output.put_line('Invalid song_id or album_id');
    WHEN duplicate_song THEN
        dbms_output.put_line('Duplicate song_id or song_name with same album_id');
    WHEN SONG_NOT_FOUND THEN
        dbms_output.put_line('Song not found');
    WHEN OTHERS THEN
        dbms_output.put_line(SQLERRM);
      ROLLBACK;
  END songs_upsert;
END pkg_music_module;
/

Execute pkg_music_module.songs_upsert(10,3.5,'Pyramids',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,album_id_seq.currval,'Flowers','Delete','APPADMIN');
delete from songs where song_name = 'Pyramids';  
select song_id_seq.currval from songs;
select * from songs;
desc songs;
drop package pkg_music_module;