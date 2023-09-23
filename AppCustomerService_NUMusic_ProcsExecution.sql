Set SERVEROUTPUT on;
select * from appadmin_numusic.user_details;
select * from appadmin_numusic.SUBSCRIPTION;
select * from appadmin_numusic.DOWNLOAD;

-- created customer service user- inserted records in user_details and card_Details
execute appadmin_numusic.PKG_user_mgmt.register_user('Dheeraj','DHE123', 'dheeraj@gmail.com','CS', '123 Main St', '5552323200', '657', 'Dheeraj', '08-APR-27', 1234567890123999);

commit;
/

