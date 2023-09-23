set SERVEROUTPUT on;

CREATE OR REPLACE TRIGGER update_song_rating
AFTER INSERT ON FAVOURITES
FOR EACH ROW
BEGIN
    UPDATE SONGS
    SET rating = rating + 1
    WHERE song_id = :NEW.song_id;
END;
/
commit;

-- successful execution
execute PKG_user_mgmt.favorites_upsert('Good For You', 'Olivia Rodrigo', 'sam@gmail.com', 'ADD');
