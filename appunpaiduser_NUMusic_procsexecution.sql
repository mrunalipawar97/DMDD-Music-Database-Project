Set SERVEROUTPUT on;
-- ENTERING VALUES IN TABLES
-- created unpaid user- inserted records in user_details, subcription and card_Details
execute appadmin_numusic.PKG_user_mgmt.register_user('Aditi','ADI123', 'aditi@gmail.com','UU', '123 Main St', '5552323222', '144', 'Aditi', '04-MAY-24', 1234447890123111);
execute appadmin_numusic.PKG_user_mgmt.register_user('Random','ADI123', 'random@gmail.com','UU', '123 Main St', '5552323662', '644', 'Random', '04-MAY-25', 1234445550123111);
-- add subscription
EXECUTE appadmin_numusic.PKG_subscription_mgmt.add_subscription('aditi@gmail.com', 'Y');

-- delete user
execute appadmin_numusic.PKG_user_mgmt.delete_user('random@gmail.com');
commit;