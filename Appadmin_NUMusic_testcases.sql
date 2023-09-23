Set SERVEROUTPUT on;
/*
-- adding values to the tables- user_details, playlist, downloads, subscription, card_Details
-- inserting into user_Details
-- created paid user- inserted records in user_details, subcription and card_Details
execute PKG_user_mgmt.register_user('Sampada','SAM123', 'sam@gmail.com','PU', '123 Main St', '5552321234', '123', 'Sampada', '04-APR-24', 1234567890123456);
-- created paid user- inserted records in user_details, subcription and card_Details
execute PKG_user_mgmt.register_user('Shubhda','SHU123', 'shubhda@gmail.com','PU', '123 Main St', '5552323234', '122', 'Shubhda', '04-APR-28', 1234567890123111);
-- created unpaid user- inserted records in user_details, subcription and card_Details
execute PKG_user_mgmt.register_user('Aditi','ADI123', 'aditi@gmail.com','UU', '123 Main St', '5552323222', '144', 'Aditi', '04-MAY-24', 1234447890123111);
-- created admin user- inserted records in user_details and card_Details
execute PKG_user_mgmt.register_user('Mrunali','MRU123', 'mrunali@gmail.com','A', '123 Main St', '5552323299', '120', 'Mrunali', '08-APR-24', 1234567890123901);
-- created customer service user- inserted records in user_details and card_Details
execute PKG_user_mgmt.register_user('Dheeraj','DHE123', 'dheeraj@gmail.com','CS', '123 Main St', '5552323200', '657', 'Dheeraj', '08-APR-27', 1234567890123999);


-- creating user playlist
EXECUTE PKG_user_mgmt.USER_PLAYLIST('sam@gmail.com', 'My Favorite Songs', NULL, NULL, 'Insert');
EXECUTE PKG_user_mgmt.USER_PLAYLIST('sam@gmail.com', 'Gym Music', NULL, NULL, 'Insert');
EXECUTE PKG_user_mgmt.USER_PLAYLIST('shubhda@gmail.com', 'Calming music', NULL, NULL, 'Insert');

-- entering values into songs, album, artist, album_artist, songs_artist, lyrics

--ADD values to album, album_Artist and Artist
execute pkg_music_module.upsert_album('Sour', '05-SEP-22','Sour', '05-SEP-22', 'Insert', 'Olivia Rodrigo');
execute pkg_music_module.upsert_album('505', '05-MAY-22','505', '05-MAY-22', 'Insert', 'Arctic Monkeys');
execute pkg_music_module.upsert_album('Red', '05-MAY-22','Red', '05-MAY-22', 'Insert', 'Taylor Swift');
execute pkg_music_module.upsert_album('Thriller', '05-MAY-01','Thriller', '05-MAY-01', 'Insert', 'Michael Jackson');
execute pkg_music_module.upsert_album('Music Box', '05-MAY-08','Music Box', '05-MAY-08', 'Insert', 'Mariah Carey');

-- insert into song and song_Artist 

Execute pkg_music_module.songs_upsert('Good For You',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,10 ,'pop','Insert','Olivia Rodrigo');
Execute pkg_music_module.songs_upsert('Drivers Liscence',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,10 ,'pop','Insert','Olivia Rodrigo');
Execute pkg_music_module.songs_upsert('Liar',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,10 ,'pop','Insert','Olivia Rodrigo');
Execute pkg_music_module.songs_upsert('Thriller',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,13 ,'Rock','Insert','Michael Jackson');
Execute pkg_music_module.songs_upsert('Black or White',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,13 ,'pop','Insert','Michael Jackson');

-- insert into lyrics table
Execute pkg_music_module.lyrics_upsert(1, 'anbscgds' ,'English','Insert');
Execute pkg_music_module.lyrics_upsert(1, 'anbscgds' ,'Arabic','Insert');
Execute pkg_music_module.lyrics_upsert(2, 'anbscgds' ,'English','Insert');

-- insert into artist table
execute pkg_music_module.upsert_artist('Keshi', 'Kesh', 'Insert');

-- entering values into favourites, songs_playlist, download
--Downlaod upsert
EXECUTE PKG_user_mgmt.DOWNLOAD_SONGS('sam@gmail.com', 'Thriller' ,'Michael Jackson');
EXECUTE PKG_user_mgmt.DOWNLOAD_SONGS('shubhda@gmail.com','Thriller' ,'Michael Jackson');
EXECUTE PKG_user_mgmt.DOWNLOAD_SONGS('sam@gmail.com', 'Black or White' ,'Michael Jackson');
EXECUTE PKG_user_mgmt.DOWNLOAD_SONGS('shubhda@gmail.com','Black or White' ,'Michael Jackson');
EXECUTE PKG_user_mgmt.DOWNLOAD_SONGS('sam@gmail.com', 'Good For You' ,'Olivia Rodrigo');
EXECUTE PKG_user_mgmt.DOWNLOAD_SONGS('shubhda@gmail.com','Liar' ,'Olivia Rodrigo');
EXECUTE PKG_user_mgmt.DOWNLOAD_SONGS('sam@gmail.com', 'Liar' ,'Olivia Rodrigo');

--add delete songs from playlist
execute PKG_user_mgmt.add_delete_songs_from_playlist('sam@gmail.com', 'Gym Music' , 'Thriller' , 'Michael Jackson' , 'ADD');
execute PKG_user_mgmt.add_delete_songs_from_playlist('sam@gmail.com', 'Gym Music' , 'Black or White' , 'Michael Jackson' , 'ADD');
execute PKG_user_mgmt.add_delete_songs_from_playlist('sam@gmail.com', 'My Favorite Songs' , 'Thriller' , 'Michael Jackson' , 'ADD');
execute PKG_user_mgmt.add_delete_songs_from_playlist('shubhda@gmail.com', 'Calming music' , 'Thriller' , 'Michael Jackson' , 'ADD');
execute PKG_user_mgmt.add_delete_songs_from_playlist('shubhda@gmail.com', 'Calming music' , 'Black or White' , 'Michael Jackson' , 'ADD');

-- add songs to favorites
execute PKG_user_mgmt.favorites_upsert('Black or White', 'Michael Jackson', 'sam@gmail.com', 'ADD');
execute PKG_user_mgmt.favorites_upsert('Black or White', 'Michael Jackson', 'shubhda@gmail.com', 'ADD');
execute PKG_user_mgmt.favorites_upsert('Thriller', 'Michael Jackson', 'sam@gmail.com', 'ADD');
execute PKG_user_mgmt.favorites_upsert('Thriller', 'Michael Jackson', 'shubhda@gmail.com', 'ADD');
execute PKG_user_mgmt.favorites_upsert('Liar', 'Olivia Rodrigo', 'sam@gmail.com', 'ADD');
*/

-- renew subscription

--
Set SERVEROUTPUT on;

--User name already taken
EXECUTE PKG_user_mgmt.register_user('Shubhda','SHU12356', 'shubh@gmail.com','PU', '1458 Tremont St', '5552323234', '122', 'Shubhda', '04-APR-28', 1234567890123111);
--Enter Valid Email
EXECUTE PKG_user_mgmt.register_user('John','jo123', 'jogmail.com','PU', '1458 harvard sq', '5550003234', '122', 'John', '12-APR-27', 1234567891023111);


-- creating user playlist
-- playlist already exists
EXECUTE PKG_user_mgmt.USER_PLAYLIST('sam@gmail.com', 'My Favorite Songs', NULL, NULL, 'Insert');
--email not associated with a user 
EXECUTE PKG_user_mgmt.USER_PLAYLIST('mrunali@gmail', '', NULL, NULL, 'Insert');
-- playlist created
EXECUTE PKG_user_mgmt.USER_PLAYLIST('mrunali@gmail.com', ' Gym', NULL, NULL, 'Insert');
-- playlist deleted
EXECUTE PKG_user_mgmt.USER_PLAYLIST('mrunali@gmail.com', ' Gym', NULL, NULL, 'Delete');
--invalid operation/action
EXECUTE PKG_user_mgmt.USER_PLAYLIST('mrunali@gmail.com', 'Vibe', NULL, NULL, 'Read');
--update playlist
EXECUTE PKG_user_mgmt.USER_PLAYLIST('sam@gmail.com', 'My Favorite Songs', 'My fav songs', NULL, 'Update');

-- entering values into songs, album, artist, album_artist, songs_artist, lyrics
--invalid album name 
EXECUTE pkg_music_module.upsert_album('******', '05-MAY-22','******', '05-MAY-22', 'Insert', 'Taylor Swift');
--invalid operation
EXECUTE pkg_music_module.upsert_album('Midnights', '05-MAY-22','Midnights', '05-MAY-22', 'read', 'Taylor Swift');


-- insert into song and song_Artist 
--update operation
EXECUTE pkg_music_module.songs_upsert('Black or White',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,13 ,'jazz','Update','Michael Jackson');
--Invalid song name. Song name should only contain alphabets, numbers and spaces.
EXECUTE pkg_music_module.songs_upsert('$$$$$$$$',TO_DATE('2021-07-04', 'YYYY-MM-DD'),NUMTODSINTERVAL(205, 'SECOND') ,13 ,'pop','Insert','Michael Jackson');


-- insert into lyrics table
-- lyrics already exists
EXECUTE pkg_music_module.lyrics_upsert(1, 'anbscgds' ,'English','Insert');
-- inseritng lyrics in different lang
EXECUTE pkg_music_module.lyrics_upsert(3, '?? ????, ??? ?' ,'Arabic','Insert');
--successful insertion
EXECUTE pkg_music_module.lyrics_upsert(4, 'anbscgds' ,'English','Insert');
--song not found
EXECUTE pkg_music_module.lyrics_upsert(9, '????' ,'Hindi','Insert');


-- invalid artist name
EXECUTE pkg_music_module.upsert_artist('----$$$$$----', 'Weeknd', 'Insert');
-- invalid operation
EXECUTE pkg_music_module.upsert_artist('Justin', 'Justin Bieber', 'Create');

commit;


