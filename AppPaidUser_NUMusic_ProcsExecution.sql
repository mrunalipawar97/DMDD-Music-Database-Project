
set serveroutput on;
-- ENTERING VALUES IN TABLES
-- created paid user- inserted records in user_details, subcription and card_Details
execute appadmin_numusic.PKG_user_mgmt.register_user('Sampada','SAM123', 'sam@gmail.com','PU', '123 Main St', '5552321234', '123', 'Sampada', '04-APR-24', 1234567890123456);
-- created paid user- inserted records in user_details, subcription and card_Details
execute appadmin_numusic.PKG_user_mgmt.register_user('Shubhda','SHU123', 'shubhda@gmail.com','PU', '123 Main St', '5552323234', '122', 'Shubhda', '04-APR-28', 1234567890123111);


-- creating user playlist
EXECUTE appadmin_numusic.PKG_user_mgmt.USER_PLAYLIST('sam@gmail.com', 'My Favorite Songs', NULL, NULL, 'Insert');
EXECUTE appadmin_numusic.PKG_user_mgmt.USER_PLAYLIST('sam@gmail.com', 'Gym Music', NULL, NULL, 'Insert');
EXECUTE appadmin_numusic.PKG_user_mgmt.USER_PLAYLIST('shubhda@gmail.com', 'Calming music', NULL, NULL, 'Insert');

--Downlaod upsert
EXECUTE appadmin_numusic.DOWNLOAD_SONGS('sam@gmail.com', 'Thriller' ,'Michael Jackson');
EXECUTE appadmin_numusic.DOWNLOAD_SONGS('shubhda@gmail.com','Thriller' ,'Michael Jackson');
EXECUTE appadmin_numusic.DOWNLOAD_SONGS('sam@gmail.com', 'Black or White' ,'Michael Jackson');
EXECUTE appadmin_numusic.DOWNLOAD_SONGS('shubhda@gmail.com','Black or White' ,'Michael Jackson');
EXECUTE appadmin_numusic.DOWNLOAD_SONGS('sam@gmail.com', 'Good For You' ,'Olivia Rodrigo');
EXECUTE appadmin_numusic.DOWNLOAD_SONGS('shubhda@gmail.com','Liar' ,'Olivia Rodrigo');
EXECUTE appadmin_numusic.DOWNLOAD_SONGS('sam@gmail.com', 'Liar' ,'Olivia Rodrigo');

--add delete songs from playlist
execute appadmin_numusic.PKG_user_mgmt.add_delete_songs_from_playlist('sam@gmail.com', 'Gym Music' , 'Thriller' , 'Michael Jackson' , 'ADD');
execute appadmin_numusic.PKG_user_mgmt.add_delete_songs_from_playlist('sam@gmail.com', 'Gym Music' , 'Black or White' , 'Michael Jackson' , 'ADD');
execute appadmin_numusic.PKG_user_mgmt.add_delete_songs_from_playlist('sam@gmail.com', 'My Favorite Songs' , 'Thriller' , 'Michael Jackson' , 'ADD');
execute appadmin_numusic.PKG_user_mgmt.add_delete_songs_from_playlist('shubhda@gmail.com', 'Calming music' , 'Thriller' , 'Michael Jackson' , 'ADD');
execute appadmin_numusic.PKG_user_mgmt.add_delete_songs_from_playlist('shubhda@gmail.com', 'Calming music' , 'Black or White' , 'Michael Jackson' , 'ADD');

-- add songs to favorites
execute appadmin_numusic.PKG_user_mgmt.favorites_upsert('Black or White', 'Michael Jackson', 'sam@gmail.com', 'ADD');
execute appadmin_numusic.PKG_user_mgmt.favorites_upsert('Black or White', 'Michael Jackson', 'shubhda@gmail.com', 'ADD');
execute appadmin_numusic.PKG_user_mgmt.favorites_upsert('Thriller', 'Michael Jackson', 'sam@gmail.com', 'ADD');
execute appadmin_numusic.PKG_user_mgmt.favorites_upsert('Thriller', 'Michael Jackson', 'shubhda@gmail.com', 'ADD');
execute appadmin_numusic.PKG_user_mgmt.favorites_upsert('Liar', 'Olivia Rodrigo', 'sam@gmail.com', 'ADD');

--user login
execute appadmin_numusic.PKG_user_mgmt.user_login('Sampada','SAM123');
--user managerment
execute appadmin_numusic.PKG_user_mgmt.user_management('SampadaJ','SAM123', 'sam@gmail.com', 'ABCD', 5678498765);
-- upsert card
execute appadmin_numusic.PKG_SUBSCRIPTION_mgmt.upsert_card('sam@gmail.com', 5678456734569889,'12-FEB-25', 'Sampada', 6797, 'INSERT');

-- discontinue subscription

EXECUTE appadmin_numusic.update_auto_renewal('shubhda@gmail.com');
commit;