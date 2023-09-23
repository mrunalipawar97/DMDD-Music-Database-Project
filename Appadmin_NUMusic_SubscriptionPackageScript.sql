set SERVEROUTPUT on;


create or replace package PKG_subscription_mgmt
as 
procedure add_subscription(pi_user_email IN User_Details.user_email%TYPE, pi_auto_subscription IN Subscription.auto_subscription%TYPE);

procedure upsert_card(pi_user_email IN User_Details.user_email%TYPE, pi_card_num IN Card_Details.card_num%TYPE , pi_exp_date IN Card_Details.exp_date%TYPE, pi_name_on_card IN Card_Details.name_on_card%TYPE, pi_cvv IN Card_Details.cvv%TYPE, pi_operation varchar2);

end PKG_subscription_mgmt;
/

create or replace package body PKG_subscription_mgmt
as 
procedure add_subscription(pi_user_email IN User_Details.user_email%TYPE, pi_auto_subscription IN Subscription.auto_subscription%TYPE)
is
v_user_count NUMBER;
v_user_id User_Details.user_id%TYPE;
v_card_id Card_Details.card_id%TYPE;
ex_invalid_email exception;
ex_invalid_user_email exception;
ex_invalid_autosubs exception;
ex_subs_already_exists exception;

BEGIN
  -- validate email
  IF pi_user_email IS NULL OR INSTR(pi_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  

  -- validate Auto subscription value
  IF pi_auto_subscription NOT IN ('Y', 'N') THEN
  RAISE ex_invalid_autosubs;
   END IF;
 
  -- if user email deosnt match a record in user_details table 
  SELECT COUNT(*) INTO v_user_count FROM USER_DETAILS WHERE user_email = pi_user_email;
  IF v_user_count = 0 THEN
  RAISE ex_invalid_user_email;
  END IF;

  -- Get user ID based on email
  SELECT user_id INTO v_user_id FROM USER_DETAILS WHERE user_email = pi_user_email;
    DBMS_OUTPUT.PUT_LINE('User ID is' ||' ' || v_user_id);
 
-- SINCE EVERY USER HAS ATLEAST 1 CARD, GET THE CARD WITH A LATER EXPIRY DATE

select card_id into v_card_id from card_details c join user_details u on c.user_id = u.user_id
where u.user_email = pi_user_email and c.exp_date = ( select max(ca.exp_date) from card_details ca join user_details us on ca.user_id = us.user_id where us.user_email = pi_user_email);
  
   -- Check if the user has an active subscription
  SELECT COUNT(*) INTO v_user_count
  FROM Subscription
  WHERE user_id = v_user_id
  AND subs_end_date > SYSDATE
  AND subs_plan_name = 'P';
  
  IF v_user_count > 0 THEN
    RAISE ex_subs_already_exists;
  END IF;
  
  -- Check if user has an existing 'U' subscription with an end date in the future
SELECT COUNT(*) INTO v_user_count
FROM Subscription
WHERE user_id = v_user_id
AND subs_end_date > SYSDATE
AND subs_plan_name = 'U';

IF v_user_count > 0 THEN
  -- Update the end date of the 'U' subscription to today's date
  UPDATE Subscription
  SET subs_end_date = SYSDATE
  WHERE user_id = v_user_id
  AND subs_end_date > SYSDATE
  AND subs_plan_name = 'U';
  
end if;
  
  -- Add 'P'  subscription
  INSERT INTO Subscription(subs_id, user_id, auto_subscription, subs_plan_name, subs_start_date, subs_end_date, card_id)
  VALUES(SUBS_ID_SEQ.nextval, v_user_id, pi_auto_subscription, 'P' , SYSDATE, ADD_MONTHS(SYSDATE, 6), v_card_id);
  
  UPDATE user_details SET user_category = 'PU' WHERE user_id = V_USER_ID;
  -- Print success message
  DBMS_OUTPUT.PUT_LINE('Subscription added successfully.');
    COMMIT;
EXCEPTION
  -- Handle exceptions
   WHEN EX_INVALID_EMAIL THEN
     DBMS_OUTPUT.PUT_LINE('Enter Valid Email');
  WHEN EX_INVALID_USER_EMAIL THEN
     DBMS_OUTPUT.PUT_LINE('Invalid Email ID, Email should be associated with an existing user account');
       WHEN ex_invalid_autosubs THEN
     DBMS_OUTPUT.PUT_LINE('Auto subscription value can only be Y or N');
     WHEN ex_subs_already_exists THEN
     DBMS_OUTPUT.PUT_LINE('Paid Subscription already exists for this time frame');
     
  WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Enter Valid Values');
     ROLLBACK;
end add_subscription;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE upsert_card (
        pi_user_email   IN user_details.user_email%TYPE,
        pi_card_num     IN card_details.card_num%TYPE,
        pi_exp_date     IN card_details.exp_date%TYPE,
        pi_name_on_card IN card_details.name_on_card%TYPE,
        pi_cvv          IN card_details.cvv%TYPE,
        pi_operation    VARCHAR2
    ) IS
        v_user_id user_details.user_id%TYPE;
        v_card_id card_details.card_id%TYPE;
        v_counter Number;
        v_user_count1 number;
        EX_CARD_NOT_FOUND EXCEPTION;
        EX_INVALID_OPERATION EXCEPTION;
        EX_INVALID_EMAIL EXCEPTION;
        EX_INVALID_USER_EMAIL EXCEPTION;
        EX_INVALID_CARD_NUM EXCEPTION;
        EX_INVALID_EXPIRY EXCEPTION;
        EX_INVALID_NAME EXCEPTION;
        EX_INVALID_CVV EXCEPTION;
        EX_CARD_FOUND EXCEPTION;
        EX_MIN_CARD EXCEPTION;
        
    BEGIN 
    
-- validate email
  IF pi_user_email IS NULL OR INSTR(pi_user_email, '@') = 0 THEN
    RAISE ex_invalid_email;
  END IF;
  
-- validate card_num
IF pi_card_num IS NULL OR LENGTH(pi_card_num) <> 16 OR NOT REGEXP_LIKE(pi_card_num, '^[0-9]+$') THEN
    RAISE EX_INVALID_CARD_NUM;
END IF;

-- validate exp_Date
IF pi_exp_date IS NULL THEN
    raise EX_INVALID_EXPIRY;
END IF;
-- validate name_on_card
IF pi_name_on_card IS NULL THEN
  RAISE EX_INVALID_NAME;
ELSIF NOT REGEXP_LIKE(pi_name_on_card, '^[[:alpha:][:space:]]*$') THEN
  RAISE EX_INVALID_NAME;
END IF;

-- validate cvv
 IF pi_cvv IS NULL OR LENGTH(pi_cvv) < 3 THEN
    RAISE EX_INVALID_CVV;
END IF; 

    -- if user email deosnt match a record in user_details table 
  SELECT COUNT(*) INTO v_user_count1 FROM USER_DETAILS WHERE user_email = pi_user_email;
  IF v_user_count1 = 0 THEN
  RAISE ex_invalid_user_email;
  END IF;
  
-- Get the user ID for the specified email
        SELECT
            user_id
        INTO v_user_id
        FROM
            user_details
        WHERE
            user_email = pi_user_email;
            
-- raise exception if card num defined belongs to another user
    SELECT COUNT(*)
   INTO v_counter
    FROM card_details
   WHERE card_num = pi_card_num
   AND user_id <> v_user_id;

IF v_counter > 0 THEN
    RAISE EX_CARD_FOUND;
END IF;
    

        IF pi_operation = 'INSERT' THEN
        -- Insert new card details for the user
        
        -- check if card already exists
          SELECT
                count(*)
            INTO v_counter
            FROM
                card_details
            WHERE
                    user_id = v_user_id
                AND card_num = pi_card_num;

      -- raise exception if card already exists
            IF v_counter <> 0 THEN
                raise EX_CARD_FOUND;
            END IF;
     -- raise exception if card is expired while entering       
    IF pi_exp_date <= SYSDATE THEN
    raise EX_INVALID_EXPIRY;
    END IF;
    
            INSERT INTO card_details (
                card_id,
                user_id,
                card_num,
                exp_date,
                name_on_card,
                cvv
            ) VALUES (
                card_details_id_seq.NEXTVAL,
                v_user_id,
                pi_card_num,
                pi_exp_date,
                pi_name_on_card,
                pi_cvv
            );

            dbms_output.put_line('Card details inserted successfully.');
        ELSIF pi_operation = 'UPDATE' THEN
        -- Get the card ID for the specified user and card number
            SELECT
                count(*)
            INTO v_counter
            FROM
                card_details
            WHERE
                    user_id = v_user_id
                AND card_num = pi_card_num;
            -- Raise exception if card not found
            IF v_counter = 0 THEN
                raise EX_CARD_NOT_FOUND;
            END IF;
        
        -- Update the existing card details for the user
        -- we dont allow card number to be updated. For this scenario, user will have to delete and re-create card
           SELECT card_id INTO v_card_id FROM Card_Details WHERE user_id = v_user_id AND card_num = pi_card_num;
          
            UPDATE card_details
            SET
                exp_date = pi_exp_date,
                name_on_card = pi_name_on_card,
                cvv = pi_cvv
            WHERE
                card_id = v_card_id;

            dbms_output.put_line('Card details updated successfully.');
        ELSIF pi_operation = 'DELETE' THEN
        
        
        -- Get the number of cards the user has, excluding the card being deleted
    SELECT
        COUNT(*)
    INTO v_counter
    FROM
        card_details
    WHERE
            user_id = v_user_id
        AND card_num != pi_card_num;
    
    -- Raise an exception if the user doesn't have at least one card attached to their account
    IF v_counter < 1 THEN
        raise ex_min_card;
    END IF;
    
        -- Get the card ID for the specified user and card number
            SELECT
                count(*)
            INTO v_counter
            FROM
                card_details
            WHERE
                    user_id = v_user_id
                AND card_num = pi_card_num
                AND exp_date = pi_exp_date
                and name_on_card = pi_name_on_card
                and cvv = pi_cvv;
                
           -- Raise exception if card not found
            IF v_counter = 0 THEN
                raise EX_CARD_NOT_FOUND;
            END IF;

        
        -- Delete the existing card details for the user
         SELECT card_id INTO v_card_id FROM Card_Details WHERE user_id = v_user_id AND card_num = pi_card_num;
         
            DELETE FROM card_details
            WHERE
                card_id = v_card_id;

            dbms_output.put_line('Card details deleted successfully.');
        ELSE
            raise EX_INVALID_OPERATION;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN EX_CARD_NOT_FOUND THEN
       dbms_output.put_line('Card details not found for this user- please check the card details entered');
       WHEN EX_INVALID_OPERATION THEN
       dbms_output.put_line('Enter Valid Operation- INSERT/DELETE/UPDATE');
       WHEN  EX_INVALID_USER_EMAIL THEN
       dbms_output.put_line('Email is not associated with user');
       WHEN EX_INVALID_EMAIL THEN
        dbms_output.put_line('Enter valid email address');
       WHEN EX_INVALID_CARD_NUM THEN
         dbms_output.put_line('Enter valid card number');
        WHEN EX_INVALID_EXPIRY THEN
        dbms_output.put_line('Enter valid expiry date, should be in the future and not null');
        WHEN EX_INVALID_NAME THEN
        dbms_output.put_line('Enter valid Name on Card- only letters and spaces allowed, should not be NULL');
        WHEN EX_INVALID_CVV THEN
        dbms_output.put_line('Enter valid CVV (3-4 digits)');
         WHEN EX_CARD_FOUND THEN
        dbms_output.put_line('This card already exist for this or another user so this action is not authorized');
        WHEN EX_MIN_CARD THEN
         dbms_output.put_line('Users must have minumum one card associated with account. Add another card before deleting');
        WHEN OTHERS THEN
        dbms_output.put_line('Enter Valid Values');
            ROLLBACK;
    END upsert_card;
 
end PKG_subscription_mgmt;
/
