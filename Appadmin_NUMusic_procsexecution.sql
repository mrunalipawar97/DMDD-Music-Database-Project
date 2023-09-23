set SERVEROUTPUT on;
-- ENTERING VALUES IN TABLES
-- created admin user- inserted records in user_details and card_Details
execute PKG_user_mgmt.register_user('Mrunali','MRU123', 'mrunali@gmail.com','A', '123 Main St', '5552323299', '120', 'Mrunali', '08-APR-24', 1234567890123901);


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

-- -- insert into lyrics table
Execute pkg_music_module.lyrics_upsert(1, 'anbscgds' ,'English','Insert');
Execute pkg_music_module.lyrics_upsert(1, 'anbscgds' ,'Arabic','Insert');
Execute pkg_music_module.lyrics_upsert(2, 'anbscgds' ,'English','Insert');

-- insert into artist table
execute pkg_music_module.upsert_artist('Keshi', 'Kesh', 'Insert');
