Set serveroutput on;

create or replace package PKG_user_mgmt
as 

PROCEDURE register_user(
  p_user_name IN User_details.User_name%TYPE,
  p_user_pwd IN User_details.User_pwd%TYPE,
  p_user_email IN User_details.User_Email%TYPE,
  p_user_category IN User_details.User_category%TYPE,
  p_user_addr IN User_details.User_addr%TYPE,
  p_user_phone IN User_details.User_phone%TYPE,
  p_cvv IN Card_Details.cvv%TYPE,
  p_Name_on_Card IN Card_Details.Name_on_card%TYPE,
  p_Exp_date IN Card_Details.Exp_date%TYPE,
  p_Card_Num IN Card_Details.Card_Num%TYPE  
);

PROCEDURE user_login (
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ); 
    
PROCEDURE user_management(
  p_user_name IN User_details.User_name%TYPE,
  p_user_pwd IN User_details.User_pwd%TYPE,
  p_user_email IN User_details.User_Email%TYPE,
  p_user_addr IN User_details.User_addr%TYPE,
  p_user_phone IN User_details.User_phone%TYPE
);

PROCEDURE USER_PLAYLIST (
  p_user_email IN User_Details.user_email%TYPE,
  p_playlist_name IN Playlist.playlist_name%TYPE,
  p_new_playlist_name IN Playlist.playlist_name%TYPE DEFAULT NULL,
  p_delete_playlist_name IN Playlist.playlist_name%TYPE DEFAULT NULL ,
  p_action IN VARCHAR2
);


PROCEDURE favorites_upsert (
    pi_song_name IN Songs.song_name%TYPE,
    pi_artist_name IN Artist.artist_name%TYPE,
    pi_user_email IN User_details.user_email%TYPE,
    pi_action in VARCHAR2
);

procedure delete_user(pi_user_email IN User_Details.user_email%TYPE);

PROCEDURE add_delete_songs_from_playlist(pi_user_email IN User_Details.user_email%TYPE, pi_playlist_name IN Playlist.playlist_name%TYPE, pi_song_name IN Songs.song_name%TYPE, pi_artist_name IN Artist.artist_name%TYPE, pi_operation IN VARCHAR2);
end PKG_user_mgmt;
/


create or replace package body PKG_user_mgmt
as 
procedure delete_user(pi_user_email IN User_Details.user_email%TYPE)
is
v_user_count NUMBER;
v_user_id User_Details.user_id%TYPE;
ex_invalid_email exception;
ex_invalid_user_email exception;
begin

-- validate email
  IF pi_user_email IS NULL OR INSTR(pi_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
 -- if user email deosnt match a record in user_details table 
  SELECT COUNT(*) INTO v_user_count FROM USER_DETAILS WHERE user_email = pi_user_email;
  IF v_user_count = 0 THEN
  RAISE ex_invalid_user_email;
  END IF;
  
   -- Get user ID based on email
  SELECT user_id INTO v_user_id FROM USER_DETAILS WHERE user_email = pi_user_email;
    DBMS_OUTPUT.PUT_LINE('User ID is' ||' ' || v_user_id);
 
    -- Delete related records in the Download table
    DELETE FROM Download
    WHERE subs_id IN (
        SELECT subs_id
        FROM Subscription
        WHERE user_id = v_user_id
    );
     DBMS_OUTPUT.PUT_LINE('download details deleted');
     
  -- Delete related records in the Subscription table
    DELETE FROM Subscription
    WHERE user_id = v_user_id;
    DBMS_OUTPUT.PUT_LINE('subscription details deleted');
    
    
    -- Delete related records in the Songs_Playlist table
    DELETE FROM Songs_Playlist
    WHERE playlist_id IN (
        SELECT playlist_id
        FROM Playlist
        WHERE user_id = v_user_id
    );
    DBMS_OUTPUT.PUT_LINE('songs_playlist details deleted');
    -- Delete from Playlist table
       DELETE FROM Playlist
    WHERE user_id = v_user_id;
    
    DBMS_OUTPUT.PUT_LINE('playlists deleted');
    
    -- Delete related records in the Favourites table
    DELETE FROM Favourites
    WHERE user_id = v_user_id;
    
    DBMS_OUTPUT.PUT_LINE('favourites details deleted');
    
    -- Delete the user's card details
    DELETE FROM Card_Details
    WHERE user_id = v_user_id;
    
    DBMS_OUTPUT.PUT_LINE('card details deleted');
    -- Delete the user from the User_Details table
    DELETE FROM User_Details
    WHERE user_id = v_user_id;
     DBMS_OUTPUT.PUT_LINE('User deleted');

    COMMIT;
    EXCEPTION
  -- Handle exceptions
   WHEN EX_INVALID_EMAIL THEN
     DBMS_OUTPUT.PUT_LINE('Enter Valid Email');
  WHEN EX_INVALID_USER_EMAIL THEN
     DBMS_OUTPUT.PUT_LINE('Invalid Email ID, Email should be associated with an existing user account');
  WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Enter Valid Values');
     ROLLBACK;
end delete_user;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE add_delete_songs_from_playlist(pi_user_email IN User_Details.user_email%TYPE, pi_playlist_name IN Playlist.playlist_name%TYPE, pi_song_name IN Songs.song_name%TYPE, pi_artist_name IN Artist.artist_name%TYPE, pi_operation IN VARCHAR2)
IS
v_user_id       User_Details.user_id%TYPE;
  v_playlist_id   Playlist.playlist_id%TYPE;
  v_song_id       Songs.song_id%TYPE;
  v_artist_id     Artist.artist_id%TYPE;
  v_playlist_size INTEGER;
  v_count INTEGER;
  ex_invalid_email EXCEPTION;
  ex_invalid_user_email EXCEPTION;
  ex_invalid_playlist_name EXCEPTION;
  ex_invalid_song_name EXCEPTION;
  ex_invalid_artist_name EXCEPTION;
  ex_playlist_not_exists EXCEPTION;
  ex_artist_not_exists EXCEPTION;
  ex_song_not_exists_for_artist EXCEPTION;
Begin

 -- Validate user email
  IF pi_user_email IS NULL OR INSTR(pi_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
    -- Validate user exists
  SELECT count(*) INTO v_count FROM User_Details WHERE user_email = pi_user_email;
  IF v_count = 0 THEN
    RAISE ex_invalid_user_email;
 ELSE 
   SELECT user_id INTO v_user_id FROM User_Details WHERE user_email = pi_user_email;
  END IF;
  
  
  -- Validate playlist name
    IF pi_playlist_name IS NULL OR pi_playlist_name = '' THEN
        RAISE ex_invalid_playlist_name;
    END IF;

    -- Validate song name
    IF pi_song_name IS NULL OR pi_song_name = '' THEN
        RAISE ex_invalid_song_name;
    END IF;

    -- Validate artist name
    IF pi_artist_name IS NULL OR pi_artist_name = '' THEN
        RAISE ex_invalid_artist_name;
    END IF;

  -- Get playlist ID based on user ID and playlist name
    SELECT count(*) INTO v_count FROM Playlist WHERE user_id = v_user_id AND playlist_name = pi_playlist_name;
    IF v_count = 0 THEN
        RAISE ex_playlist_not_exists;
    ELSE 
      SELECT playlist_id INTO v_playlist_id FROM Playlist WHERE user_id = v_user_id AND playlist_name = pi_playlist_name;
    END IF;
  
    -- Get artist ID based on artist name
    SELECT COUNT(*) INTO v_count FROM Artist WHERE artist_name = pi_artist_name;
    IF v_count = 0 THEN
        RAISE ex_artist_not_exists;
    ELSE
      SELECT artist_id INTO v_artist_id FROM Artist WHERE artist_name = pi_artist_name;
    END IF;

 -- Get song ID based on song name and artist name
  SELECT count(*) INTO v_count FROM Songs s 
INNER JOIN Songs_Artist sa ON s.song_id = sa.song_id 
INNER JOIN Artist a ON sa.artist_id = a.artist_id 
WHERE s.song_name = pi_song_name AND a.artist_name = pi_artist_name;

    IF v_count = 0 THEN
        RAISE ex_song_not_exists_for_artist;
    ELSE 
     SELECT s.song_id INTO v_song_id
FROM Songs s 
INNER JOIN Songs_Artist sa ON s.song_id = sa.song_id 
INNER JOIN Artist a ON sa.artist_id = a.artist_id 
WHERE s.song_name = pi_song_name AND a.artist_name = pi_artist_name;
  
    END IF;
 
  IF pi_operation = 'ADD' THEN
    -- Check if song is already in the playlist
    SELECT COUNT(*) INTO v_playlist_size FROM Songs_Playlist WHERE playlist_id = v_playlist_id AND song_id = v_song_id;

    IF v_playlist_size = 0 THEN
      -- Add song to the playlist
      INSERT INTO Songs_Playlist (playlist_id, song_id) VALUES (v_playlist_id, v_song_id);
      DBMS_OUTPUT.PUT_LINE(pi_song_name || ' by ' || pi_artist_name || ' has been added to ' || pi_playlist_name);
    ELSE
      DBMS_OUTPUT.PUT_LINE(pi_song_name || ' by ' || pi_artist_name || ' is already in ' || pi_playlist_name);
    END IF;
  ELSIF pi_operation = 'DELETE' THEN
    -- Check if song is in the playlist
    SELECT COUNT(*) INTO v_playlist_size FROM Songs_Playlist WHERE playlist_id = v_playlist_id AND song_id = v_song_id;

    IF v_playlist_size = 0 THEN
      DBMS_OUTPUT.PUT_LINE(pi_song_name || ' by ' || pi_artist_name || ' is not in ' || pi_playlist_name);
    ELSE
      -- Delete song from the playlist
      DELETE FROM Songs_Playlist WHERE playlist_id = v_playlist_id AND song_id = v_song_id;
      DBMS_OUTPUT.PUT_LINE(pi_song_name || ' by ' || pi_artist_name || ' has been removed from ' || pi_playlist_name);
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Invalid input, add_or_delete should be either "ADD" or "DELETE"');
  END IF;
  commit;
EXCEPTION
  WHEN ex_invalid_email THEN
        DBMS_OUTPUT.PUT_LINE('Invalid email.');
    WHEN ex_invalid_user_email THEN
        DBMS_OUTPUT.PUT_LINE('User does not exist.');
    WHEN ex_invalid_playlist_name THEN
        DBMS_OUTPUT.PUT_LINE('Invalid playlist name.');
    WHEN ex_invalid_song_name THEN
        DBMS_OUTPUT.PUT_LINE('Invalid song name.');
    WHEN ex_invalid_artist_name THEN
        DBMS_OUTPUT.PUT_LINE('Invalid artist name.');
    WHEN ex_playlist_not_exists THEN
    DBMS_OUTPUT.PUT_LINE('Playlist doesnt exist');
  WHEN ex_artist_not_exists THEN
  DBMS_OUTPUT.PUT_LINE('Artist doesnt exist');
  WHEN  ex_song_not_exists_for_artist THEN
   DBMS_OUTPUT.PUT_LINE('this song doesnt exist for this artist');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error occurred');
    rollback;
END add_delete_songs_from_playlist;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 PROCEDURE register_user(
  p_user_name IN User_details.User_name%TYPE,
  p_user_pwd IN User_details.User_pwd%TYPE,
  p_user_email IN User_details.User_Email%TYPE,
  p_user_category IN User_details.User_category%TYPE,
  p_user_addr IN User_details.User_addr%TYPE,
  p_user_phone IN User_details.User_phone%TYPE,
  p_cvv IN Card_Details.cvv%TYPE,
  p_Name_on_Card IN Card_Details.Name_on_card%TYPE,
  p_Exp_date IN Card_Details.Exp_date%TYPE,
  p_Card_Num IN Card_Details.Card_Num%TYPE  
) AS
  v_user_id_count NUMBER;
  v_user_id NUMBER;
  v_card_id NUMBER;
  Ex_invalid_user Exception;
  Ex_invalid_user_name exception;
  ex_user_name_taken exception;
  ex_invalid_card_num exception;
  ex_invalid_user_email exception;
  ex_invalid_expiry exception;
  ex_invalid_name exception;
  ex_invalid_cvv exception;
  ex_card_found exception;
  ex_invalid_email exception;
  ex_invalid_phone exception;
BEGIN

 -- validate email
  IF p_user_email IS NULL OR INSTR(p_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
  -- if user email match a record in user_details table 
  SELECT COUNT(*) INTO v_user_id_count FROM USER_DETAILS WHERE user_email = p_user_email;
  IF v_user_id_count > 0 THEN
  RAISE ex_invalid_user_email;
  END IF;

  -- Check if the username is already taken
  SELECT COUNT(*) INTO v_user_id_count
  FROM user_details
  WHERE user_details.user_name = p_user_name;

  IF v_user_id_count> 0 THEN
      RAISE ex_user_name_taken;
  END IF;

-- validate phone number
IF p_user_phone IS NULL OR LENGTH(p_user_phone) <> 10 OR NOT REGEXP_LIKE(p_user_phone, '^[0-9]+$') THEN
  RAISE ex_invalid_phone;
END IF;

-- validate card_num
IF p_card_num IS NULL OR LENGTH(p_card_num) <> 16 OR NOT REGEXP_LIKE(p_card_num, '^[0-9]+$') THEN
    RAISE EX_INVALID_CARD_NUM;
END IF;


-- validate exp_Date
IF p_exp_date IS NULL THEN
    raise EX_INVALID_EXPIRY;
END IF;


-- validate name_on_card
IF p_name_on_card IS NULL THEN
  RAISE EX_INVALID_NAME;
ELSIF NOT REGEXP_LIKE(p_name_on_card, '^[[:alpha:][:space:]]*$') THEN
  RAISE EX_INVALID_NAME;
END IF;

-- validate cvv
 IF p_cvv IS NULL OR LENGTH(p_cvv) < 3 THEN
    RAISE EX_INVALID_CVV;
END IF; 

-- validate user category
IF p_user_category NOT IN ('PU', 'UU', 'CS', 'A') THEN
  RAISE EX_Invalid_User;
END IF; 

-- get user_id
  SELECT user_id_seq.nextval INTO v_user_id FROM dual;
  
-- raise exception if card num defined belongs to another user
    SELECT COUNT(*)
   INTO v_user_id_count
    FROM card_details
   WHERE card_num = p_card_num
   AND user_id <> v_user_id;
   
   IF v_user_id_count > 0 THEN
    RAISE EX_CARD_FOUND;
END IF;
   
 -- raise exception if card is expired while entering       
    IF p_exp_date <= SYSDATE THEN
    raise EX_INVALID_EXPIRY;
    END IF;

  -- Insert the new user into user_details table
  INSERT INTO user_details(user_id, user_name, user_addr, user_phone,  user_email, user_category, user_pwd)
  VALUES(v_user_id, p_user_name, p_user_addr, p_user_phone,  p_user_email, p_user_category , p_user_pwd );
  
  DBMS_OUTPUT.PUT_LINE('record inserted in user details');
  
    -- Insert the new card into card_details table
    -- get user_id
  SELECT card_details_id_seq.nextval INTO v_card_id FROM dual;
  
    
  INSERT INTO card_details(card_id, cvv, name_on_card, exp_date, card_num, user_id)
  VALUES(v_card_id, p_cvv, p_Name_on_Card, p_Exp_date, p_Card_Num, v_user_id);
    DBMS_OUTPUT.PUT_LINE('record inserted in card details');

  -- Insert the new subscription into subscriptions table
  if p_user_category = 'PU' then
  INSERT INTO subscription(subs_id, user_id, auto_subscription, subs_plan_name, subs_start_date, subs_end_date, card_id)
  VALUES(subs_id_seq.nextval, v_user_id, 'N', 'P' , SYSDATE, ADD_MONTHS(SYSDATE,6),v_card_id);
  DBMS_OUTPUT.PUT_LINE('record inserted in subscription');
  end if;
 
   if p_user_category = 'UU' then
  INSERT INTO subscription(subs_id, user_id, auto_subscription, subs_plan_name, subs_start_date, subs_end_date, card_id)
  VALUES(subs_id_seq.nextval, v_user_id, 'Y', 'U' , SYSDATE, ADD_MONTHS(SYSDATE,6),v_card_id);
  DBMS_OUTPUT.PUT_LINE('record inserted in subscription');
  end if; 
  
  COMMIT;
    EXCEPTION
  -- Handle exceptions
  
  WHEN  Ex_invalid_user THEN
  DBMS_OUTPUT.PUT_LINE('User Category should be UU/PU/CS/A');
  when Ex_invalid_user_name then
   DBMS_OUTPUT.PUT_LINE('User name not accepted');
 when ex_user_name_taken then
  DBMS_OUTPUT.PUT_LINE('User name already taken');
  when ex_invalid_card_num then
   DBMS_OUTPUT.PUT_LINE('Invalid Card Number');
 when ex_invalid_expiry then
  DBMS_OUTPUT.PUT_LINE('Card Expired- give card with valid expiry date');
 when ex_invalid_name then
  DBMS_OUTPUT.PUT_LINE('Invalid Name on Card');
  when ex_invalid_cvv then
   DBMS_OUTPUT.PUT_LINE('Invalid CVV value');
  when ex_card_found then
   DBMS_OUTPUT.PUT_LINE('Card belongs to another user');
  when ex_invalid_email then
   DBMS_OUTPUT.PUT_LINE('Enter Valid Email');
   when ex_invalid_user_email then
   DBMS_OUTPUT.PUT_LINE('user email already in database');
   when ex_invalid_phone then
    DBMS_OUTPUT.PUT_LINE('enter valid phone number'); 
  WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Enter Valid Values');
     ROLLBACK;
END register_user;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

PROCEDURE user_login (
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    )
IS
    -- Local variable declaration
    v_user_id NUMBER;
    v_password VARCHAR2(30);
    v_username_name_pattern VARCHAR2(40) := '[A-Za-z0-9 ]+';
    password_incorrect exception;
    username_not_found exception;
    v_count number;
     
BEGIN
        -- Check if the username exists in the User_Details table
        SELECT count(*) into v_count
        FROM User_Details
        WHERE user_name = p_username;
        
        if v_count = 0 then
        raise username_not_found;
        end if;
        
        -- get user id and user password
        SELECT user_id, user_pwd
        INTO v_user_id, v_password
        FROM User_Details
        WHERE user_name = p_username;
        
        -- If the password matches, set the output parameter to the user ID
        IF v_password = p_password THEN
            DBMS_OUTPUT.PUT_LINE('Login successful for User: ' || p_username);
        ELSE
            Raise password_incorrect;
                END IF;
        commit;
        
    EXCEPTION
        -- If user not found
        WHEN username_not_found THEN
            DBMS_OUTPUT.PUT_LINE('Username not found');  
        
        -- If password is incorrect
        WHEN password_incorrect THEN
            DBMS_OUTPUT.PUT_LINE('Password is incorrect');
        
        -- If the username is invalid
        WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('Please enter correct credentials');
             Rollback;
    END user_login;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

PROCEDURE user_management(
  p_user_name IN User_details.User_name%TYPE,
  p_user_pwd IN User_details.User_pwd%TYPE,
  p_user_email IN User_details.User_Email%TYPE,
  p_user_addr IN User_details.User_addr%TYPE,
  p_user_phone IN User_details.User_phone%TYPE
) AS
v_user_id number;
v_user_id_count number;
ex_invalid_email exception;
ex_invalid_user_email exception;
ex_user_name_taken exception;
ex_invalid_phone exception;

BEGIN

-- validate phone number
IF p_user_phone IS NULL OR LENGTH(p_user_phone) <> 10 OR NOT REGEXP_LIKE(p_user_phone, '^[0-9]+$') THEN
  RAISE ex_invalid_phone;
END IF;

-- validate email
  IF p_user_email IS NULL OR INSTR(p_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
-- if user email doesnt match a record in user_details table 
  SELECT COUNT(*) INTO v_user_id_count FROM USER_DETAILS WHERE user_email = p_user_email;
  IF v_user_id_count = 0 THEN
  RAISE ex_invalid_user_email;
  END IF;

-- Check if the username is already taken
  SELECT COUNT(*) INTO v_user_id_count
  FROM user_details
  WHERE user_details.user_name = p_user_name;
  
    IF v_user_id_count> 0 THEN
      RAISE ex_user_name_taken;
  END IF;

-- validate phone number
IF p_user_phone IS NULL OR LENGTH(p_user_phone) <> 10 OR NOT REGEXP_LIKE(p_user_phone, '^[0-9]+$') THEN
  RAISE ex_invalid_phone;
END IF;

 -- Get user ID based on email
  SELECT user_id INTO v_user_id FROM USER_DETAILS WHERE user_email = p_user_email;
    DBMS_OUTPUT.PUT_LINE('User ID is' ||' ' || v_user_id);
    
-- Update the user's details in the user_details table
  UPDATE user_details
  SET user_name = p_user_name,
      user_addr = p_user_addr,
      user_pwd = p_user_pwd,
      user_email = p_user_email,
      user_phone = p_user_phone
  WHERE user_id = v_user_id;
  
    DBMS_OUTPUT.PUT_LINE('user details updated');
    
  COMMIT;
      EXCEPTION
  -- Handle exceptions
  
 when ex_user_name_taken then
  DBMS_OUTPUT.PUT_LINE('User name already taken');
  when ex_invalid_email then
   DBMS_OUTPUT.PUT_LINE('Enter Valid Email');
   when ex_invalid_user_email then
   DBMS_OUTPUT.PUT_LINE('user email already in database');
   when ex_invalid_phone then
    DBMS_OUTPUT.PUT_LINE('enter valid phone number'); 

  WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Enter Valid Values');
  rollback;
END user_management;   
---------------------------------------------------------------------------------------------------------------------------------------------------------------------     
     PROCEDURE USER_PLAYLIST (
  p_user_email IN User_Details.user_email%TYPE,
  p_playlist_name IN Playlist.playlist_name%TYPE,
  p_new_playlist_name IN Playlist.playlist_name%TYPE DEFAULT NULL,
  p_delete_playlist_name IN Playlist.playlist_name%TYPE DEFAULT NULL ,
  p_action IN VARCHAR2
) IS
  v_user_id User_Details.user_id%TYPE;
  v_playlist_id Playlist.playlist_id%TYPE;
  v_user_id_count number;
  Ex_invalid_email exception;
  ex_invalid_user_email exception;
  EX_Invalid_action exception;
  ex_playlist_exists exception;
BEGIN

 -- validate email
  IF p_user_email IS NULL OR INSTR(p_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
  -- if user email match a record in user_details table 
  SELECT COUNT(*) INTO v_user_id_count FROM USER_DETAILS WHERE user_email = p_user_email;
  IF v_user_id_count = 0 THEN
  RAISE ex_invalid_user_email;
  END IF;

-- validate user category
IF p_action NOT IN ('Insert', 'Delete', 'Update') THEN
  RAISE EX_Invalid_action;
END IF;


-- unique constraint
    -- Get the user ID based on the provided email
  SELECT user_id INTO v_user_id
  FROM User_Details
  WHERE user_email = p_user_email;

    -- Perform upsert operation based on action
    IF p_action = 'Insert' THEN
    
    -- raise exception if playlist name already exists for that user
    select count(*) into v_user_id_count from playlist
    where playlist_name = p_playlist_name
    and user_id = v_user_id;
    
    if v_user_id_count > 0 then
    raise ex_playlist_exists;
    end if;
    
    
    -- Insert a new row into the Playlist table with the next value from playlist_id_seq
       IF p_playlist_name IS NOT NULL AND p_new_playlist_name IS NULL THEN
        v_playlist_id := playlist_id_seq.nextval;
        INSERT INTO Playlist (playlist_id, playlist_name, user_id)
        VALUES (v_playlist_id, p_playlist_name, v_user_id);
      END IF;
      
        DBMS_OUTPUT.PUT_LINE('Playlist Created');
   ELSIF p_action = 'Update' THEN
   
   -- unique name validation
   
    select count(*) into v_user_id_count from playlist
    where playlist_name = p_new_playlist_name
    and user_id = v_user_id;
    
    if v_user_id_count > 0 then
    raise ex_playlist_exists;
    end if;
   
            IF p_new_playlist_name IS NOT NULL THEN
          SELECT playlist_id INTO v_playlist_id
          FROM Playlist
          WHERE playlist_name = p_playlist_name
            AND user_id = v_user_id;
        END IF;
        UPDATE Playlist
        SET playlist_name = p_new_playlist_name
        WHERE playlist_id = v_playlist_id
          AND user_id = v_user_id;
         
         DBMS_OUTPUT.PUT_LINE('Playlist Updated'); 
        
    ELSIF p_action = 'Delete' THEN  
    IF p_delete_playlist_name IS NOT NULL THEN
    SELECT playlist_id INTO v_playlist_id
          FROM Playlist
          WHERE playlist_name = p_delete_playlist_name
            AND user_id = v_user_id;
            
      DELETE FROM Playlist
      WHERE playlist_id = v_playlist_id
        AND user_id = v_user_id;
    END IF; 
     DBMS_OUTPUT.PUT_LINE('Playlist Deleted');
     
    END IF;
      COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'User not found');
     when Ex_invalid_email then
      DBMS_OUTPUT.PUT_LINE('Invalid Email');
  when ex_invalid_user_email then
   DBMS_OUTPUT.PUT_LINE('email not associated with a user');
  when EX_Invalid_action then
   DBMS_OUTPUT.PUT_LINE('invalid actions- enter Insert/Delete/Update');
  when ex_playlist_exists then
   DBMS_OUTPUT.PUT_LINE('Playlist with this name already exists for user');
      ROLLBACK;
END USER_PLAYLIST;
---------------------------------------------------------------------------------------------------------------------------------------------------------------


/*PROCEDURE DOWNLOAD_SONGS (
    p_user_email IN User_Details.user_email%TYPE,
    p_song_name IN Songs.song_name%TYPE,
    p_artist_name IN Artist.artist_name%TYPE
) AS
    v_subs_id Subscription.subs_id%TYPE;
    v_subs_plan_name Subscription.subs_plan_name%TYPE;
    v_download_date Download.download_date%TYPE := SYSDATE;
    v_song_id Songs.song_id%TYPE;
    v_user_id User_Details.user_id%TYPE;
    v_count number;
    ex_user_not_found exception;
    ex_invalid_song_artist exception;
    ex_song_not_found exception;
    ex_not_paid exception;
    ex_song_already_downloaded exception;
BEGIN

    -- include validation to check if user email exists and get user_id
    SELECT count(*) INTO v_count FROM User_Details WHERE user_email = p_user_email;
    if v_count = 0 then
    raise ex_user_not_found;
  end if;
    
    -- get user id
  SELECT user_id INTO v_user_id FROM User_Details WHERE user_email = p_user_email;

      
    -- include validation for checking song name and artist name parameters are not null
    IF p_song_name IS NULL OR p_artist_name IS NULL THEN
    raise ex_invalid_song_artist;
    END IF;
    
     -- add exception for song not found
         SELECT count(*) INTO v_count
        FROM Songs s
        JOIN Songs_Artist sa ON s.song_id = sa.song_id
        JOIN Artist a ON sa.artist_id = a.artist_id
        WHERE s.song_name = p_song_name AND a.artist_name = p_artist_name; 
        
        if v_count = 0 then
        raise ex_song_not_found;
        end if;

    -- get song_id using song name and artist name
   
        SELECT s.song_id INTO v_song_id
        FROM Songs s
        JOIN Songs_Artist sa ON s.song_id = sa.song_id
        JOIN Artist a ON sa.artist_id = a.artist_id
        WHERE s.song_name = p_song_name AND a.artist_name = p_artist_name; 
       
      
    -- no paid subscription
    SELECT count(*) INTO v_count FROM Subscription WHERE user_id = v_user_id AND subs_start_date >= ADD_MONTHS(SYSDATE, -6) AND subs_plan_name = 'P' AND subs_end_date > SYSDATE;
    
    if v_count = 0 
    then raise ex_not_paid;
    end if;
    -- get the most recent subs_id for the user using the user_id
  
        SELECT subs_id INTO v_subs_id
        FROM Subscription
        WHERE user_id = v_user_id AND subs_start_date >= ADD_MONTHS(SYSDATE, -6) AND subs_plan_name = 'P' AND subs_end_date > SYSDATE;
        
    -- throw exception if user has already downloaded
    select count(*) into v_count from download
    where song_id = v_song_id and subs_id in (select subs_id from subscription where user_id = v_user_id);
    
    if v_count > 0 then
    raise ex_song_already_downloaded;
    end if;
    
      dbms_output.put_line(v_subs_id);
    -- insert download record
    INSERT INTO Download (song_id, subs_id, download_date)
    VALUES (v_song_id, v_subs_id, SYSDATE);

     dbms_output.put_line('Download successful.');
    COMMIT;
EXCEPTION
    WHEN ex_user_not_found THEN
        dbms_output.put_line('User not found');
    when ex_invalid_song_artist then
    dbms_output.put_line('Invalid Song/Artist');
    when ex_song_not_found then
     dbms_output.put_line('song not found');
    when ex_not_paid then
     dbms_output.put_line('Only Paid Users can download');
     when ex_song_already_downloaded then
      dbms_output.put_line('song had already been downloaded');
    WHEN OTHERS THEN
       dbms_output.put_line('enter valid values');
       ROLLBACK;
END DOWNLOAD_SONGS; */
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE favorites_upsert (
    pi_song_name IN Songs.song_name%TYPE,
    pi_artist_name IN Artist.artist_name%TYPE,
    pi_user_email IN User_details.user_email%TYPE,
    pi_action in VARCHAR2
)

IS
 v_user_id  User_Details.user_id%TYPE;
  v_song_id Songs.song_id%TYPE;
  v_artist_id Artist.artist_id%TYPE;
  v_playlist_size INTEGER;
  v_count INTEGER;
  ex_invalid_email EXCEPTION;
  ex_invalid_user_email EXCEPTION;
  ex_invalid_playlist_name EXCEPTION;
  ex_invalid_song_name EXCEPTION;
  ex_invalid_artist_name EXCEPTION;
  ex_playlist_not_exists EXCEPTION;
  ex_artist_not_exists EXCEPTION;
  ex_song_not_exists_for_artist EXCEPTION;
Begin

 -- Validate user email
  IF pi_user_email IS NULL OR INSTR(pi_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
    -- Validate user exists
  SELECT count(*) INTO v_count FROM User_Details WHERE user_email = pi_user_email;
  IF v_count = 0 THEN
    RAISE ex_invalid_user_email;
 ELSE 
 
 -- get user id
   SELECT user_id INTO v_user_id FROM User_Details WHERE user_email = pi_user_email;
  END IF;
  

    -- Validate song name
    IF pi_song_name IS NULL OR pi_song_name = '' THEN
        RAISE ex_invalid_song_name;
    END IF;

    -- Validate artist name
    IF pi_artist_name IS NULL OR pi_artist_name = '' THEN
        RAISE ex_invalid_artist_name;
    END IF;

  
    -- Get artist ID based on artist name
    SELECT COUNT(*) INTO v_count FROM Artist WHERE artist_name = pi_artist_name;
    IF v_count = 0 THEN
        RAISE ex_artist_not_exists;
    ELSE
      SELECT artist_id INTO v_artist_id FROM Artist WHERE artist_name = pi_artist_name;
    END IF;

 -- Get song ID based on song name and artist name
  SELECT count(*) INTO v_count FROM Songs s 
INNER JOIN Songs_Artist sa ON s.song_id = sa.song_id 
INNER JOIN Artist a ON sa.artist_id = a.artist_id 
WHERE s.song_name = pi_song_name AND a.artist_name = pi_artist_name;

    IF v_count = 0 THEN
        RAISE ex_song_not_exists_for_artist;
    ELSE 
     SELECT s.song_id INTO v_song_id
FROM Songs s 
INNER JOIN Songs_Artist sa ON s.song_id = sa.song_id 
INNER JOIN Artist a ON sa.artist_id = a.artist_id 
WHERE s.song_name = pi_song_name AND a.artist_name = pi_artist_name;
  
    END IF;

  IF pi_action = 'ADD' THEN
    -- Check if song is already in the playlist
    SELECT COUNT(*) INTO v_playlist_size FROM favourites WHERE user_id = v_user_id AND song_id = v_song_id;

    IF v_playlist_size = 0 THEN
      -- Add song to the playlist
      INSERT INTO favourites (user_id, song_id) VALUES (v_user_id, v_song_id);
      DBMS_OUTPUT.PUT_LINE('song added to favourites');
    ELSE
      DBMS_OUTPUT.PUT_LINE('song already in favourotes');
    END IF;
  ELSIF pi_action = 'DELETE' THEN
    -- Check if song is in the playlist
 SELECT COUNT(*) INTO v_playlist_size FROM favourites WHERE user_id = v_user_id AND song_id = v_song_id;

    IF v_playlist_size = 0 THEN
      DBMS_OUTPUT.PUT_LINE('song not in favorites');
    ELSE
      -- Delete song from the playlist
      DELETE FROM  favourites WHERE user_id = v_user_id AND song_id = v_song_id;
      DBMS_OUTPUT.PUT_LINE('song removed');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Invalid input, add_or_delete should be either "ADD" or "DELETE"');
  END IF;
  commit;
EXCEPTION
  WHEN ex_invalid_email THEN
        DBMS_OUTPUT.PUT_LINE('Invalid email.');
    WHEN ex_invalid_user_email THEN
        DBMS_OUTPUT.PUT_LINE('User does not exist.');
    WHEN ex_invalid_playlist_name THEN
        DBMS_OUTPUT.PUT_LINE('Invalid playlist name.');
    WHEN ex_invalid_song_name THEN
        DBMS_OUTPUT.PUT_LINE('Invalid song name.');
    WHEN ex_invalid_artist_name THEN
        DBMS_OUTPUT.PUT_LINE('Invalid artist name.');
    WHEN ex_playlist_not_exists THEN
    DBMS_OUTPUT.PUT_LINE('Playlist doesnt exist');
  WHEN ex_artist_not_exists THEN
  DBMS_OUTPUT.PUT_LINE('Artist doesnt exist');
  WHEN  ex_song_not_exists_for_artist THEN
   DBMS_OUTPUT.PUT_LINE('this song doesnt exist for this artist');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error occurred');
    rollback;
END favorites_upsert;
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 
end PKG_user_mgmt;
/



