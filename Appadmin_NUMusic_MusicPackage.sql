SET SERVEROUTPUT ON;
CREATE OR REPLACE PACKAGE pkg_music_module 
AS 

    PROCEDURE songs_upsert(
        p_song_name IN songs.song_name%TYPE,
        p_release_date IN songs.song_release_date%TYPE,
        p_duration IN songs.song_duration%TYPE,
        p_album_id IN songs.album_id%TYPE,
        p_genre_name IN songs.genre_name%TYPE,
        p_action IN VARCHAR2,
        p_artist_name IN artist.artist_name%TYPE
    
        
    );
    
   PROCEDURE lyrics_upsert(
        p_song_id IN lyrics.song_id%TYPE,
        p_lyrics_text IN lyrics.lyrics_text%TYPE,
        p_lyrics_language IN lyrics.lyrics_language%TYPE,
        p_action IN VARCHAR2
        
    );
    
    PROCEDURE upsert_album(
        p_album_name IN album.album_name%TYPE, 
        p_album_release_date IN album.album_release_date%TYPE,
        p_new_album_name IN album.album_name%TYPE, 
        p_new_album_release_date IN album.album_release_date%TYPE, 
        p_action IN VARCHAR2,
        p_artist_name in artist.artist_name%TYPE
    );
    
  PROCEDURE upsert_artist(
        p_artist_name IN artist.artist_name%TYPE, 
     p_Artist_new_name In artist.artist_name%TYPE, 
        p_action IN VARCHAR2
    );
   
END pkg_music_module;
/

CREATE OR REPLACE PACKAGE BODY pkg_music_module AS
    
    
    PROCEDURE songs_upsert(
    p_song_name IN songs.song_name%TYPE,
    p_release_date IN songs.song_release_date%TYPE,
    p_duration IN songs.song_duration%TYPE,
    p_album_id IN songs.album_id%TYPE,
    p_genre_name IN songs.genre_name%TYPE,
    p_action IN VARCHAR2,
    p_artist_name IN artist.artist_name%TYPE

)
IS
    -- Exception declarations
    invalid_song_name EXCEPTION;
    duplicate_song EXCEPTION;
    ex_song_not_found EXCEPTION;
    cannot_be_null EXCEPTION;
    invalid_user EXCEPTION; 
    EX_Invalid_action EXCEPTION;
    EX_Album_not_found exception; 
    ex_Artist_not_found exception;

    -- Local variable declarations
    v_song_name_pattern VARCHAR2(40) := '[A-Za-z0-9 ]+';
    v_delete_song_id NUMBER(3);
    v_user_role VARCHAR2(20);
    v_album_id NUMBER(3);
    v_artist_id NUMBER(3);
     v_album_exists INTEGER;
    v_song_exists INTEGER;
    v_song_id integer;
BEGIN
    -- Validate user
    SELECT USER INTO v_user_role FROM DUAL;
    IF (v_user_role <> 'APPADMIN_NUMUSIC') THEN
        RAISE invalid_user;
    END IF;
    
    -- Validate song name
    IF NOT REGEXP_LIKE(p_song_name, v_song_name_pattern) THEN
        RAISE invalid_song_name;
        
    END IF;
    
    --Validating if null or not
    IF p_song_name IS NULL THEN
        RAISE cannot_be_null;
    END IF;

-- validate action
IF p_action NOT IN ('Insert', 'Delete', 'Update') THEN
  RAISE EX_Invalid_action;
END IF;

    -- Perform upsert operation based on action
    IF p_action = 'Insert' THEN
        --check if album_id exists
        SELECT COUNT(*) INTO v_album_id from album WHERE album_id = p_album_id;
        IF v_album_id = 0 THEN
           RAISE EX_Album_not_found; 
      end if;
      
      select count(*) into v_album_id
      FROM Artist a
      INNER JOIN Album_Artist aa ON a.artist_id = aa.artist_id
      WHERE aa.album_id = p_album_id
      AND a.artist_name = p_artist_name;
      
      if v_album_id = 0 then
      raise ex_Artist_not_found;
      else 
       select aa.artist_id into v_artist_id
      FROM Artist a
      INNER JOIN Album_Artist aa ON a.artist_id = aa.artist_id
      WHERE aa.album_id = p_album_id
      AND a.artist_name = p_artist_name;
      end if;

        -- check if duplicate song not being inserted
          SELECT COUNT(*) INTO v_song_exists FROM songs WHERE song_name = p_song_name AND album_id = p_album_id;
            IF v_song_exists > 0 THEN
                RAISE duplicate_song;
        end if;
        select song_id_seq.nextval into v_song_id from dual;
        INSERT INTO songs (
                    song_id,
                     rating,
                    song_name,
                    song_release_date,
                    song_duration,
                    album_id,
                    genre_name
                ) VALUES (
                    v_song_id,
                     1.0,
                    p_song_name,
                    p_release_date,
                    p_duration,
                    p_album_id,
                    p_genre_name
                );
            select artist_id into v_artist_id from album_artist where album_id = p_album_id;
          insert into songs_artist (song_id, artist_id) values (v_song_id, v_artist_id) ;     
        -- artist validation
          
         dbms_output.put_line('Song with sond id:' || v_song_id || ' ' || 'inserted successfully');
       
    ELSIF p_action = 'Update' THEN
    
      SELECT COUNT(*) INTO v_song_exists FROM songs WHERE song_name = p_song_name AND album_id = p_album_id;
            IF v_song_exists = 0 THEN
                RAISE ex_song_not_found;
        end if;
       
       select song_id into v_song_id from songs where song_name = p_song_name AND album_id = p_album_id; 

        UPDATE songs SET
            song_name = p_song_name,
            song_release_date = p_release_date,
            song_duration = p_duration,
            genre_name = p_genre_name
        WHERE song_id = v_song_id;
        
        dbms_output.put_line('Song with song id:' || v_song_id || ' updated successfully');
        
    ELSIF p_action = 'Delete' THEN  
            
     SELECT COUNT(*) INTO v_song_exists FROM songs WHERE song_name = p_song_name AND album_id = p_album_id;
            IF v_song_exists = 0 THEN
                RAISE ex_song_not_found;
        end if;
       
       select song_id into v_song_id from songs where song_name = p_song_name AND album_id = p_album_id;        
            
            
    DELETE FROM songs_artist WHERE song_id = v_song_id;
    DELETE FROM LYRICS WHERE song_id = v_song_id;
    DELETE FROM SONGS_PLAYLIST WHERE song_id = v_song_id;
    DELETE FROM FAVOURITES WHERE song_id = v_song_id;
    DELETE FROM download WHERE song_id = v_song_id;
    DELETE FROM songs WHERE song_id = v_song_id;
       
        dbms_output.put_line('Song with song id:' || v_song_id || ' ' || ' deleted successfully');
        END IF;
    
    COMMIT;
EXCEPTION
    WHEN invalid_song_name THEN
        dbms_output.put_line('Invalid song name. Song name should only contain alphabets, numbers and spaces.');
    WHEN cannot_be_null THEN
        dbms_output.put_line('Song name or song id cannot be null');
    WHEN duplicate_song THEN
        dbms_output.put_line('Duplicate song_id or song_name with same album_id');
    WHEN ex_song_not_found THEN
        dbms_output.put_line('Song not found');
    WHEN invalid_user THEN
        dbms_output.put_line('Invalid user. Cannot perform these actions');
           WHEN ex_invalid_action THEN
        dbms_output.put_line('Cannot perform these actions- enter insert/delete/update');
           WHEN ex_album_not_found THEN
        dbms_output.put_line('album doesnt exists, please add album first to add song');
           WHEN ex_artist_not_found THEN
        dbms_output.put_line('This artist is not associated with this album so cant perform action');
    WHEN OTHERS THEN
        dbms_output.put_line(SQLERRM);
      ROLLBACK;
  END songs_upsert;
  
  

-- Procedure lyrics_upsert
   
  
    PROCEDURE lyrics_upsert(
        p_song_id IN lyrics.song_id%TYPE,
        p_lyrics_text IN lyrics.lyrics_text%TYPE,
        p_lyrics_language IN lyrics.lyrics_language%TYPE,
        p_action IN VARCHAR2

    )
    IS
    lyrics_not_found EXCEPTION;
    duplicate_lyrics EXCEPTION;
    existing_lyrics_in_other_lang EXCEPTION;
    invalid_user EXCEPTION;
    ex_song_not_found exception;
    EX_Invalid_action exception;
        -- Local variable declarations
        v_if_song_id_available NUMBER(3);
        v_user_role VARCHAR2(20);
        v_delete_lyrics_id NUMBER(5);
        v_update_lyrics_id NUMBER(5);
        v_lyrics_id Number;
        v_count number;
   BEGIN  
      
        -- check if song exists
        select count(*) into v_count from songs where song_id = p_song_id;
        if v_Count = 0 then
        raise ex_song_not_found;
        end if;
        
        IF p_action NOT IN ('Insert', 'Delete') THEN
       RAISE EX_Invalid_action;
       END IF;
        
         IF p_action = 'Insert' THEN
            -- Check if lyrics_id and song_id already exist
            SELECT COUNT(*) INTO v_if_song_id_available FROM lyrics WHERE song_id = p_song_id AND lyrics_language = p_lyrics_language;
            IF (v_if_song_id_available > 0) THEN
                RAISE duplicate_lyrics;
            ELSE
                -- Insert the new record
                INSERT INTO lyrics (lyrics_id, song_id, lyrics_text, lyrics_language)
                VALUES (lyrics_id_seq.nextval, p_song_id, p_lyrics_text, p_lyrics_language);
                dbms_output.put_line('Lyrics inserted successfully');
            END IF;
            
            
        ELSIF (p_action = 'Delete' AND p_lyrics_text IS NULL) THEN
            -- Check if the lyrics_id and song_id exist
            SELECT COUNT(*) INTO v_delete_lyrics_id FROM lyrics WHERE song_id = p_song_id AND lyrics_language = p_lyrics_language;
            IF (v_delete_lyrics_id = 0) THEN
                RAISE lyrics_not_found;
            ELSE
              SELECT lyrics_id INTO v_delete_lyrics_id FROM lyrics WHERE song_id = p_song_id AND lyrics_language = p_lyrics_language;
                -- Delete the record
                DELETE FROM lyrics WHERE lyrics_id = v_delete_lyrics_id AND song_id = p_song_id;
                 dbms_output.put_line('Lyrics deleted successfully');
            END IF;
        END IF;
        
        COMMIT;
        EXCEPTION
     WHEN invalid_user THEN
            dbms_output.put_line('Invalid user. Only APPADMIN is allowed to perform this operation.');
    WHEN duplicate_lyrics THEN
        dbms_output.put_line('Lyrics already exist in this language. Try to add in another language');
    WHEN lyrics_not_found THEN
        dbms_output.put_line('No lyrics found to delete');
    WHEN existing_lyrics_in_other_lang THEN
        dbms_output.put_line('Lyrics are present already in this language for this song');
         WHEN ex_song_not_found THEN
            dbms_output.put_line('Song not found');
        when EX_Invalid_action then
         dbms_output.put_line('enter valid action- Insert/Delete');
    WHEN OTHERS THEN
        dbms_output.put_line('enter valid values');
      ROLLBACK;
 End lyrics_upsert;  
 
 
  --- Upsert procedure to add, update, delete album details
    PROCEDURE upsert_album(
        p_album_name IN album.album_name%TYPE, 
        p_album_release_date IN album.album_release_date%TYPE,
        p_new_album_name IN album.album_name%TYPE, 
        p_new_album_release_date IN album.album_release_date%TYPE, 
        p_action IN VARCHAR2,
        p_artist_name in artist.artist_name%TYPE
    )
    IS
        -- Local variable declaration
        v_counter NUMBER;
        v_count number;
        v_user_role VARCHAR2(20);
        v_album_name_pattern VARCHAR2(40) := '[A-Za-z0-9 ]+';
        v_Artist_id number;
        v_album_id number;
        v_song_id number;
        
        -- Exception declarations
        album_id_already_exists EXCEPTION;
        album_doesnt_exists EXCEPTION;
        invalid_action EXCEPTION;
        invalid_user EXCEPTION;
        invalid_album_name EXCEPTION;
    
    BEGIN
         -- Validate user
         SELECT USER INTO v_user_role FROM DUAL;
    IF (v_user_role <> 'APPADMIN_NUMUSIC') THEN
        RAISE invalid_user;
    END IF;
    
       IF p_action NOT IN ('Insert', 'Delete', 'Update') THEN
       RAISE Invalid_action;
       END IF;
       
        -- Validate Album name
        IF NOT REGEXP_LIKE(p_album_name, v_album_name_pattern) THEN
            RAISE invalid_album_name;
        END IF;
        
        IF p_action = 'Insert' THEN
        
            SELECT COUNT(*) INTO v_counter FROM Album WHERE album_name = p_album_name and album_release_date= p_album_release_date;
            IF v_counter = 0 THEN
            select album_id_seq.nextval into v_album_id from dual;
                INSERT INTO ALBUM (
                    album_id,
                    album_name,
                    album_release_date
                ) VALUES (
                   v_album_id,
                   p_album_name,
                    p_album_release_date
                );
            select count(*) into v_count from artist where artist_name = p_artist_name; 
            if v_count > 0 then 
            select artist_id into v_artist_id from artist where artist_name = p_artist_name; 
            insert into album_Artist(album_id, artist_id) values (v_album_id, v_artist_id);
            
            else
            select artist_id_seq.nextval into v_artist_id from dual;
            insert into Artist(artist_id, artist_name) values (v_artist_id, p_artist_name);
            insert into album_Artist(album_id, artist_id) values (v_album_id, v_artist_id);
            end if;
                DBMS_OUTPUT.PUT_LINE('Album details added successfully');
            ELSE
                RAISE album_id_already_exists;
            END IF; 
         ELSIF p_action = 'Update' THEN
         
          SELECT COUNT(*) INTO v_counter FROM Album WHERE album_name = p_album_name and album_release_date= p_album_release_date;
            IF v_counter = 0 THEN
            raise album_doesnt_exists;
            else
            select album_id into v_album_id from album where album_name = p_album_name and album_release_date= p_album_release_date;
             UPDATE Album SET album_name = p_new_album_name , album_release_date = p_new_album_release_date WHERE album_id = v_album_id;
             
                    DBMS_OUTPUT.PUT_LINE('Album updated');
             END IF;
             
        ELSIF p_action = 'Delete' THEN
         SELECT COUNT(*) INTO v_counter FROM Album WHERE album_name = p_album_name and album_release_date= p_album_release_date;
            IF v_counter = 0 THEN
            raise album_doesnt_exists;
               else
            select album_id into v_album_id from album where album_name = p_album_name and album_release_date= p_album_release_date; 
           
             
                DELETE FROM ALBUM_ARTIST where album_id = v_album_id;
               
               -- select song_id into v_song_id from songs where album_id = v_album_id;
                
                delete from songs_artist where song_id in (select song_id from songs where album_id = v_album_id);
               
                delete from lyrics where song_id in (select song_id from songs where album_id = v_album_id);
               
                delete from songs_playlist where song_id in (select song_id from songs where album_id = v_album_id);
                
                 delete from favourites where song_id in (select song_id from songs where album_id = v_album_id);
                 
                  delete from download where song_id in (select song_id from songs where album_id = v_album_id);
                  
                DELETE FROM SONGS where album_id = v_album_id;
                  DELETE FROM ALBUM WHERE album_id = v_album_id;
                
        
                    DBMS_OUTPUT.PUT_LINE('Album deleted successfully ' || p_action || ' action.');
                END IF; 
          
            END IF;  
        COMMIT;
    EXCEPTION
        WHEN invalid_user THEN
            dbms_output.put_line('Invalid user. Only APPADMIN is allowed to perform this operation.');
        WHEN invalid_album_name THEN
            DBMS_OUTPUT.PUT_LINE('Invalid Album name. Album name should only contain alphabets, numbers and spaces.');
        WHEN album_id_already_exists THEN
            DBMS_OUTPUT.PUT_LINE('Album ID already exists in the table ' || p_action || ' action.');
        WHEN invalid_action THEN
            DBMS_OUTPUT.PUT_LINE('Invalid action specified. enter Insert/Delete');    
        WHEN album_doesnt_exists THEN
            DBMS_OUTPUT.PUT_LINE('Album ID does not exist in the table '|| p_action || ' action.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('enter valid values');
            rollback;
    END upsert_album;
    
   PROCEDURE upsert_artist(
        p_artist_name IN artist.artist_name%TYPE, 
        p_Artist_new_name In artist.artist_name%TYPE, 
        p_action IN VARCHAR2
    )
    IS
        -- Local variable declaration
        artist_count NUMBER;
        v_user_role VARCHAR2(20);
        v_artist_name_pattern VARCHAR2(40) := '[A-Za-z0-9 ]+';
        v_artist_id number;
        
        -- Exception declarations
        artist_id_already_exists EXCEPTION;
        artist_doesnt_exists EXCEPTION;
        invalid_action EXCEPTION;
        invalid_user EXCEPTION;
        invalid_artist_name EXCEPTION;
    
    BEGIN
        
        -- Validate Album name
        IF NOT REGEXP_LIKE(p_artist_name, v_artist_name_pattern) THEN
            RAISE invalid_artist_name;
        END IF;
        
        IF p_action = 'Insert' THEN
            SELECT COUNT(*) INTO artist_count FROM Artist WHERE artist_name = p_artist_name;
            IF artist_count = 0 THEN
                INSERT INTO Artist(artist_id, artist_name) VALUES (artist_id_Seq.nextval, p_artist_name);
                DBMS_OUTPUT.PUT_LINE(' Artist inserted successfully.');
            ELSE
                RAISE artist_id_already_exists;
            END IF;
        ELSIF p_action = 'Update' THEN
            SELECT COUNT(*) INTO artist_count FROM Artist WHERE artist_name = p_artist_name;
            IF artist_count > 0 THEN
            select artist_id into v_artist_id from artist where artist_name = p_artist_name;
                UPDATE Artist SET artist_name = p_artist_new_name WHERE artist_id = v_artist_id;
                DBMS_OUTPUT.PUT_LINE(p_action || ' action : ' || ' Artist updated successfully.');
            ELSE
                RAISE artist_doesnt_exists;
            END IF;
        ELSIF p_action = 'Delete' THEN
            SELECT COUNT(*) INTO artist_count FROM Artist WHERE artist_name = p_artist_name;
            IF artist_count > 0 THEN
            select artist_id into v_artist_id from artist where artist_name = p_artist_name;
             UPDATE Artist SET artist_name = v_artist_id || 'Deleted' WHERE artist_id = v_artist_id;
               
               
                DBMS_OUTPUT.PUT_LINE(p_action || ' action : ' || ' Artist deleted successfully.');
            ELSE
               RAISE artist_doesnt_exists;
            END IF;
        ELSE
            RAISE invalid_action;
        END IF;
        COMMIT;
    EXCEPTION
        WHEN invalid_user THEN
            dbms_output.put_line('Invalid user. Only APPADMIN is allowed to perform this operation.');
        WHEN invalid_artist_name THEN
            DBMS_OUTPUT.PUT_LINE('Invalid Artist name. Artist name should only contain alphabets, numbers and spaces.');
        WHEN artist_id_already_exists THEN
             DBMS_OUTPUT.PUT_LINE(p_action || ' action : ' || ' Artist already exists.');
        WHEN artist_doesnt_exists THEN
            DBMS_OUTPUT.PUT_LINE(p_action || ' action : ' || ' Artist not found.');
        WHEN invalid_action THEN
            DBMS_OUTPUT.PUT_LINE('Invalid operation. Valid operations are INSERT, UPDATE, and DELETE.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLCODE || ' - ' || SQLERRM);
            rollback;
    END upsert_artist;  
END pkg_music_module;
/

   


