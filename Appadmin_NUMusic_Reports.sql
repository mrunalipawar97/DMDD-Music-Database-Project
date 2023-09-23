--All Reports
-- weekwise downloads of songs
SET SERVEROUTPUT ON;   
 SELECT 
    TRUNC(d.download_date, 'IW') AS week,
    s.song_name,
    LISTAGG(distinct a.artist_name, ', ') WITHIN GROUP (ORDER BY a.artist_name) AS artist_names,
    al.album_name,
    s.genre_name,
    s.song_release_date,
    COUNT(distinct subs_id) AS download_count
FROM 
    Download d
    JOIN Songs s ON d.song_id = s.song_id
    JOIN Album al ON s.album_id = al.album_id
    JOIN Album_Artist aa ON al.album_id = aa.album_id
    JOIN Artist a ON aa.artist_id = a.artist_id
GROUP BY 
    TRUNC(d.download_date, 'IW'),
    s.song_name,
    al.album_name,
    s.genre_name,
    s.song_release_date
ORDER BY 
    week DESC,
    download_count DESC; 
    
select * from Download;

-------------------------------------------------------------------------------------------------------------

--a report showing the user along with paid active subscription plan details 
SELECT 
  ud.user_id, 
  ud.user_name, 
  ud.user_email, 
  s.subs_plan_name, 
  s.subs_start_date, 
  s.subs_end_date 
FROM 
  User_Details ud 
  INNER JOIN Subscription s ON ud.user_id = s.user_id 
WHERE 
  s.subs_end_date > SYSDATE AND s.auto_subscription = 'Y';
  
select * from subscription;

-------------------------------------------------------------------------------------------------------------

--To generate a report showing the subscription status of all user along with their subscription plan details sorted by active subscription status
SELECT 
  ud.user_id, 
  ud.user_name, 
  ud.user_email, 
  s.subs_plan_name, 
  s.auto_subscription,
  s.subs_start_date, 
  s.subs_end_date 
FROM 
  User_Details ud 
  INNER JOIN Subscription s ON ud.user_id = s.user_id
WHERE 
  s.subs_end_date > SYSDATE 
ORDER BY 
  s.auto_subscription DESC;


-------------------------------------------------------------------------------------------------------------
--This report can show a list of all artists and the number of albums and songs they have in the database along with album names and song names.


SELECT A.artist_name, COUNT(DISTINCT AA.album_id) AS num_albums, COUNT(DISTINCT S.song_id) AS num_songs, 
       LISTAGG(DISTINCT NVL(AL.album_name,'No Album'), ', ') WITHIN GROUP (ORDER BY AL.album_name) AS album_names,
       LISTAGG(DISTINCT NVL(S.song_name,'No Songs'), ', ') WITHIN GROUP (ORDER BY S.song_name) AS song_names
FROM Artist A
LEFT JOIN Album_Artist AA ON A.artist_id = AA.artist_id
LEFT JOIN Album AL ON AA.album_id = AL.album_id
LEFT JOIN Songs_Artist SA ON A.artist_id = SA.artist_id
LEFT JOIN Songs S ON SA.song_id = S.song_id
GROUP BY A.artist_name;



select * from album;

select * from songs;
-------------------------------------------------------------------------------------------------------------
--Report showing the top songs in each genre based on the number of times they have been downloaded

SELECT s.song_name, s.genre_name, 
    COUNT(d.song_id) as download_count
FROM Songs s
INNER JOIN Download d ON s.song_id = d.song_id
GROUP BY 
    s.genre_name, s.song_name
ORDER BY 
    s.genre_name, download_count DESC;
    
select * from songs;
select * from download;
    
-------------------------------------------------------------------------------------------------------------

--This report would provide information on the playlists created by users within the music streaming service including the number of songs on each playlist, no.of playlist for each user and Most popular playlist for each user
SELECT 
  u.user_id, 
  u.user_name, 
  COUNT(DISTINCT p.playlist_id) AS number_of_playlists,
  COUNT(sp.song_id) AS number_of_songs,
  (
    SELECT 
      playlist_name 
    FROM 
      (
        SELECT 
          p2.playlist_id, 
          p2.playlist_name, 
          COUNT(sp2.song_id) AS num_songs
        FROM 
          Playlist p2 
          LEFT JOIN Songs_Playlist sp2 ON p2.playlist_id = sp2.playlist_id 
        WHERE 
          p2.user_id = u.user_id 
        GROUP BY 
          p2.playlist_id, 
          p2.playlist_name 
        ORDER BY 
          COUNT(sp2.song_id) DESC, 
          p2.playlist_name ASC
      )
    WHERE 
      ROWNUM = 1
  ) AS most_popular_playlist
FROM 
  User_Details u 
  JOIN Playlist p ON u.user_id = p.user_id 
  LEFT JOIN Songs_Playlist sp ON p.playlist_id = sp.playlist_id 
GROUP BY 
  u.user_id, 
  u.user_name
ORDER BY 
  COUNT(sp.song_id) DESC, 
  number_of_playlists DESC, 
  u.user_name ASC;
  
