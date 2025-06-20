use Practice;

-- Movie Database Creation Script

-- 1. Create Database
CREATE DATABASE MovieDB;
USE MovieDB;

-- 2. Movies Table
CREATE TABLE Movies (
    movie_id INT PRIMARY KEY,
    title VARCHAR(100),
    genre VARCHAR(50),
    release_year INT,
    rating FLOAT
);

-- Insert Data into Movies Table
INSERT INTO Movies (movie_id, title, genre, release_year, rating) VALUES
(1, 'Inception', 'Sci-Fi', 2010, 8.8),
(2, 'Titanic', 'Romance', 1997, 7.8),
(3, 'The Godfather', 'Crime', 1972, 9.2),
(4, 'The Dark Knight', 'Action', 2008, 9.0),
(5, 'Avatar', 'Sci-Fi', 2009, 7.9);

-- 3. Actors Table
CREATE TABLE Actors (
    actor_id INT PRIMARY KEY,
    name VARCHAR(100),
    birth_year INT,
    nationality VARCHAR(50)
);

-- Insert Data into Actors Table
INSERT INTO Actors (actor_id, name, birth_year, nationality) VALUES
(1, 'Leonardo DiCaprio', 1974, 'American'),
(2, 'Christian Bale', 1974, 'British'),
(3, 'Al Pacino', 1940, 'American'),
(4, 'Sam Worthington', 1976, 'Australian'),
(5, 'Morgan Freeman', 1937, 'American');

-- 4. MovieActors Table
CREATE TABLE MovieActors (
    movie_id INT,
    actor_id INT,
    FOREIGN KEY (movie_id) REFERENCES Movies(movie_id),
    FOREIGN KEY (actor_id) REFERENCES Actors(actor_id)
);

-- Insert Data into MovieActors Table
INSERT INTO MovieActors (movie_id, actor_id) VALUES
(1, 1), (1, 4), (2, 1), (3, 3), (4, 2), (4, 5), (5, 4);

-- 5. Reviews Table
CREATE TABLE Reviews (
    review_id INT PRIMARY KEY,
    movie_id INT,
    critic_name VARCHAR(100),
    score FLOAT,
    FOREIGN KEY (movie_id) REFERENCES Movies(movie_id)
);

-- Insert Data into Reviews Table
INSERT INTO Reviews (review_id, movie_id, critic_name, score) VALUES
(1, 1, 'Critic A', 9.0), (2, 2, 'Critic B', 8.0), (3, 3, 'Critic C', 9.5),
(4, 4, 'Critic D', 9.1), (5, 5, 'Critic E', 7.7);

-- 6. BoxOffice Table
CREATE TABLE BoxOffice (
    movie_id INT,
    domestic_gross BIGINT,
    international_gross BIGINT,
    FOREIGN KEY (movie_id) REFERENCES Movies(movie_id)
);

-- Insert Data into BoxOffice Table
INSERT INTO BoxOffice (movie_id, domestic_gross, international_gross) VALUES
(1, 300000000, 500000000), (2, 600000000, 1500000000), (3, 250000000, 133000000),
(4, 530000000, 470000000), (5, 760000000, 2040000000);

-- Data Validation
SELECT * FROM Movies;
SELECT * FROM Actors;
SELECT * FROM MovieActors;
SELECT * FROM Reviews;
SELECT * FROM BoxOffice;

-- Practice Questions MovieDB

--1. Which movies from each genre are considered the most critically acclaimed based on their ratings?
WITH Acclaimed AS(select genre,title, rating,
DENSE_RANK() over(partition by genre order by rating desc) as rank_ret 
from Movies)
select * from Acclaimed
where rank_ret = 1;

--2. Can you find the top 3 movies with the highest audience appreciation, regardless of genre?
WITH top_movies AS (
select movie_id, score, ROW_NUMBER() over(order by score desc) as Row_score from reviews) 
select tp.movie_id, m.genre , m.title, tp.score from top_movies as tp
inner join Movies as m
on tp.movie_id = m.movie_id
where tp.Row_score < 4;

--3. Within each release year, which movies performed the best in terms of domestic revenue?
select m.title, m.release_year, b.domestic_gross, DENSE_RANK() over(order by b.domestic_gross desc) as top_performer from Movies as m
inner join BoxOffice as b
on m.movie_id = b.movie_id;

--4. Are there any movies within the same genre that have an equal standing when it comes to international box office collections?
WITH Equal_standing AS(
select m.title, m.genre, b.international_gross,
count(*) over(partition by m.genre, b.international_gross) as equal 
from movies as m
inner join BoxOffice as b
on m.movie_id = b.movie_id)
select genre, title, international_gross from Equal_standing
where equal > 1;

--5. What are the best-rated movies in each genre according to critics?
select genre, title, score from (
select m.movie_id, m.genre , m.title, r.critic_name, r.score, 
max(r.score) over(partition by m.genre) as Max_score from movies as m
inner join Reviews as r
on m.movie_id = r.movie_id) as g
where g.score = g.Max_score;


--6. How can we divide the movies into four equal groups based on their domestic earnings?
select *, ntile(4) over(order by domestic_gross) as groups 
from BoxOffice;

--7. Can we group movies into three distinct categories according to their international revenue?
select m.genre, b.international_gross, ntile(3) over(order by b.international_gross) as Movie_group from Movies as m
inner join BoxOffice as b
on m.movie_id = b.movie_id;

--8. How would you classify movies based on how they rank in terms of audience rating?
select movie_id, genre, rating, dense_rank() over(order by rating desc) as Rank_top from Movies;

--9. If we split the actors based on the number of movies they've acted in, how many groups would we have if we only had two categories?
select v.actor_id, v.no_of_movie, ntile(2) over (order by v.actor_id) as Category 
from (select actor_id, count(movie_id) as no_of_movie from MovieActors
group by actor_id) as v;

--10. Can we divide the movies into ten segments based on their total box office performance?
With total_box AS(
select movie_id, domestic_gross from BoxOffice
union all
select movie_id, international_gross from BoxOffice)
select movie_id, domestic_gross, ntile(10) over(order by domestic_gross)as segments from total_box;


--11. How would you determine the relative position of each movie based on its critic score?
select m.movie_id, m.title, r.critic_name, r.score, PERCENT_RANK() over(order by r.score desc) as Relative_posistion from movies as m
inner join Reviews as r
on m.movie_id = r.movie_id;

--12. If we look at the movies within a specific genre, how would you find their relative success in terms of domestic box office collection?
select m.genre, m.title, b.domestic_gross, DENSE_RANK() over(order by b.domestic_gross desc) as relative_success from movies as m
inner join BoxOffice as b
on m.movie_id = b.movie_id
where m.genre = 'Sci-Fi';


insert into movies
values (6,'Drishyam','Thriller',2010,8.2);

--13. Considering the movies from the same year, can you identify how well each one did in terms of overall revenue?
with same_year_movies AS (
select m.movie_id, m.title, m.release_year,
(b.domestic_gross + b.international_gross) as Overall_revenue, 
count(*) over(partition by m.release_year) as same_year  
from movies as m
left join BoxOffice as b
on m.movie_id = b.movie_id
)
select s.title, s.release_year ,s.Overall_revenue, rank() over(order by s.overall_revenue desc) as top_performer
from same_year_movies as s
where s.same_year > 1;


--14. How would you place actors on a timeline based on their birth years, showing how they compare to one another?
SELECT birth_year , actor_id, name  from Actors
order by birth_year;


--15. What is the relative standing of each movie's rating within its genre?
select movie_id, genre, rating, PERCENT_RANK() over(partition by genre order by rating desc) as rank_rating
from Movies;

--16. Can you determine how movies from the same genre compare to one another in terms of ratings?
WITH same_genre AS (select genre, movie_id , title, rating, count(*) over(partition by genre) as count_rat from Movies)
select genre, title, rating, rating-lead(rating) over(partition by genre order by rating desc) as diff from same_genre
where count_rat > 1;

--17. How do the movies from each release year compare to one another when we look at international revenue?
select m.release_year, m.movie_id, b.international_gross,
b.international_gross-lead(b.international_gross) over(order by b.international_gross desc) as differnce_amont 
from movies as m
inner join BoxOffice as b
on m.movie_id = b.movie_id;

--18. Among all movies, how would you rate them based on the number of actors they feature ?
WITH rating_actor_no AS(select movie_id, count(actor_id) as actor_count,
dense_rank() over(order by count(actor_id) desc) as ranking from MovieActors
group by movie_id)
select r.movie_id, m.title, r.ranking from rating_actor_no as r
inner join movies as m
on m.movie_id = r.movie_id;


INSERT INTO Reviews (review_id, movie_id, critic_name, score) VALUES
(6, 1, 'Critic B', 7.5), (7, 2, 'Critic A', 7.0), (8, 4, 'Critic C', 9.5),
(9, 3, 'Critic D', 7.3), (10, 5, 'Critic A', 7.7),
(11, 3, 'Critic B',8.3), (12, 5, 'Critic C', 7.3), (13, 2, 'Critic C', 9.5),
(14, 4, 'Critic D', 7.2), (15, 1, 'Critic E', 8.9);

--19. Which critics tend to give higher ratings compared to others, and how do they rank?
with movie_critic as (
select movie_id,
			FIRST_VALUE(critic_name)over(Partition by movie_id order by score) as minName,
            FIRST_VALUE(score)over(Partition by movie_id order by score) as min_score,
			LAST_VALUE(critic_name) over(partition by movie_id order by score) as maxName,
            LAST_VALUE(score) over(partition by movie_id order by score) as max_score
from Reviews
)
select movie_id,minName,min_score,maxName,max_score,max_score-min_score as difference_  from movie_critic
where max_score-min_score>0;

--20. How does each movie fare when  comparing their total box office income to others?
with comparing_income AS(select movie_id, sum(domestic_gross+ international_gross) as total_Income from BoxOffice
group by movie_id),
comparing_income_2 AS(select movie_id, total_income, 
total_income - lag(total_income) over(order by total_income) as Movie_fare 
from comparing_income)
select movie_id, total_income, movie_fare, percent_rank() over(order by total_income) as ranking from comparing_income_2;

--21. What are the differences in the way movies are ranked when you consider audience ratings versus the number of awards won?


--22. Can you list the movies that consistently rank high both in domestic gross and in audience appreciation?





--23. What would the movie list look like if we grouped them by their performance within their release year?
select release_year, movie_id, rating,
ntile(5) over(partition by release_year order by release_year desc) as Group_no from Movies;





--24. Can we find the top movies from each genre, while also displaying how they compare in terms of critical reception and revenue distribution?
--Critical reception refers to the way a creative work, like a book, film, or piece of music, is evaluated and received by critics and the public. 
with All_data as(
select m.movie_id, m.genre, m.title, r.score,
b.domestic_gross + b.international_gross as total_revenue from Movies as m
inner join Reviews as r
on m.movie_id = r.movie_id
inner join BoxOffice as b
on m.movie_id = b.movie_id)
select movie_id, genre, title, score, lead(score) over(order by score desc) as next_score,
score-lead(score) over(order by score desc) as S_diff,
total_revenue, lead(total_revenue) over(order by score desc) as next_revenue,
total_revenue-lead(total_revenue) over(order by score desc) as R_diff from All_data;



--25. If you were to group actors based on the number of movies they've been in, how would you categorize them?
select a.actor_id, count(ma.movie_id) as count_of_movies from Actors as a
inner join MovieActors as ma
on a.actor_id = ma.actor_id
group by a.actor_id;	





--VIEWS

----------- 1 ----------------
CREATE VIEW Equal_standing AS(
select m.title, m.genre, b.international_gross,
count(*) over(partition by m.genre, b.international_gross) as equal 
from movies as m
inner join BoxOffice as b
on m.movie_id = b.movie_id);

select * from Equal_standing;


------------- 2 --------------------

CREATE VIEW Total_revenue AS(
select m.movie_id, m.genre, m.title, r.score,
b.domestic_gross + b.international_gross as total_revenue from Movies as m
inner join Reviews as r
on m.movie_id = r.movie_id
inner join BoxOffice as b
on m.movie_id = b.movie_id);

select * from Total_revenue;


------------- 3 -----------------


CREATE VIEW Ranking_ac_Actors as (
select movie_id, count(actor_id) as actor_count,
dense_rank() over(order by count(actor_id) desc) as ranking from MovieActors
group by movie_id);

drop view Rating_ac_Actors;

select * from Ranking_ac_Actors;


-------------- 4 --------------------

CREATE VIEW best_scoreIN_genre AS(
select m.movie_id, m.genre , m.title, r.critic_name, r.score, 
max(r.score) over(partition by m.genre) as Best_score from movies as m
inner join Reviews as r
on m.movie_id = r.movie_id);

select * from best_scoreIN_genre;

