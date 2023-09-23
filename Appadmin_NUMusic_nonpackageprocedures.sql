CREATE OR REPLACE PROCEDURE DOWNLOAD_SONGS (
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
END DOWNLOAD_SONGS;
/

------------------------------------------------------------------------------------------------------------------------------------------------------

create or replace PROCEDURE update_auto_renewal(pi_user_email User_Details.user_email%TYPE) IS
  v_user_id User_Details.user_id%TYPE;
  v_subs_id Subscription.subs_id%TYPE;
  v_auto_subscription Subscription.auto_subscription%TYPE;
  v_user_count1 number;
  ex_invalid_email exception;
  ex_invalid_user_email exception;
  ex_no_valid_subs exception;
BEGIN

  -- validate email
  IF pi_user_email IS NULL OR INSTR(pi_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
    -- if user email deosnt match a record in user_details table 
  SELECT COUNT(*) INTO v_user_count1 FROM USER_DETAILS WHERE user_email = pi_user_email;
  IF v_user_count1 = 0 THEN
  RAISE ex_invalid_user_email;
  END IF;
  
  -- Get user ID based on email
  SELECT user_id INTO v_user_id FROM USER_DETAILS WHERE user_email = pi_user_email;

  -- Get active subscription ID for user (start_date less than 6 months ago and plan_name is 'P')
 SELECT count(*) INTO v_user_count1 FROM Subscription WHERE user_id = v_user_id AND subs_start_date >= ADD_MONTHS(SYSDATE, -6) AND subs_plan_name = 'P' AND subs_end_date > SYSDATE;

-- IF NO SUBS ID FOUND RAISE ERROR ELSE UPDATE
IF v_user_count1 = 0 THEN
    RAISE  ex_no_valid_subs;
  END IF;
  
   -- Get active subscription ID for user (start_date less than 6 months ago and plan_name is 'P')
 SELECT subs_id, auto_subscription INTO v_subs_id, v_auto_subscription FROM Subscription WHERE user_id = v_user_id AND subs_start_date >= ADD_MONTHS(SYSDATE, -6) AND subs_plan_name = 'P' AND subs_end_date > SYSDATE;
    -- Update auto_subscription value
    IF v_auto_subscription = 'Y' THEN
      UPDATE Subscription SET auto_subscription = 'N' WHERE subs_id = v_subs_id;
    ELSE
      UPDATE Subscription SET auto_subscription = 'Y' WHERE subs_id = v_subs_id;
    END IF;
    -- Print success message
    DBMS_OUTPUT.PUT_LINE('Auto-renewal for subscription ' || v_subs_id || ' has been updated');
    COMMIT;
    
EXCEPTION
   WHEN ex_invalid_email THEN
    DBMS_OUTPUT.PUT_LINE('Please enter a valid email ID');
     WHEN ex_invalid_user_email THEN
    DBMS_OUTPUT.PUT_LINE('Please enter a valid email ID associated with a user account');
    WHEN ex_no_valid_subs THEN
    DBMS_OUTPUT.PUT_LINE('NO paid and current Subscription found');
    WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Enter Valid Values');
    ROLLBACK;
END update_auto_renewal;
/
----------------------------------------------------------------------------------------------------------------------------------------------------------------

-- this would be a scheduled job that will be run every day (already discussed with professor, he asked to add a comment and no need to schedule)
create or replace procedure renew_subscription
as
begin
-- Renew U subscription for current Unpaid users with expired subscription and autorenewal on
  INSERT INTO Subscription (subs_id, user_id, auto_subscription, subs_plan_name, subs_start_date, subs_end_date, card_id)
  SELECT subs_id_seq.nextval, user_id, 'Y', 'U', SYSDATE, ADD_MONTHS(SYSDATE, 6), card_id
  FROM Subscription
  WHERE auto_subscription = 'Y' AND TRUNC(SYSDATE)-2 < subs_end_date AND subs_end_date < SYSDATE AND subs_plan_name = 'U';
  
  -- Renew P subscription for current paid users with expired subscription and autorenewal on
  INSERT INTO Subscription (subs_id, user_id, auto_subscription, subs_plan_name, subs_start_date, subs_end_date, card_id)
  SELECT subs_id_seq.nextval, user_id, 'Y', 'P', SYSDATE, ADD_MONTHS(SYSDATE, 6), card_id
  FROM Subscription
  WHERE auto_subscription = 'Y' AND  TRUNC(SYSDATE)-2 < subs_end_date AND subs_end_date < SYSDATE AND subs_plan_name = 'P';
  
    -- Update to U subscription for paid users with expired subscription and autorenewal off
  INSERT INTO Subscription (subs_id, user_id, auto_subscription, subs_plan_name, subs_start_date, subs_end_date, card_id)
  SELECT subs_id_seq.nextval, user_id, 'Y', 'U', SYSDATE, ADD_MONTHS(SYSDATE, 6), card_id
  FROM Subscription
  WHERE auto_subscription = 'N' AND TRUNC(SYSDATE)-2 < subs_end_date AND subs_end_date < SYSDATE AND subs_plan_name = 'P';
end renew_subscription;
/
