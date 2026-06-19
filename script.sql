create table customers(
-- щоб праймері ключ генерувався самостійно мені підказав ШІ "generated always as identity "
	customer_id int generated always as identity primary key,
	customer_age int,
	customer_email varchar(50)
);

-- для стврення цього запиту та інших запитів для генерації даних в таблиці використовувався ші, в даному запиті, для того щоб правильно встановити генерацію віку
-- і для того щоб правильно записати цей запит
insert into customers ( customer_age, customer_email )
select
	floor(random()*(83-13+1)+13)::int ,
	--рандом видає число від 0 до 1, в душепх ми шукаємо проміжок потім додаємо 1 бо тут нумерація починається з 1 а не 0 дал, премножаємо і додаємо 13 щоб вибірка була  між 13 і 83
	'user' || id || '@kse.org.ua'
from generate_series(1,10000) id;




create table cinemas(
	cinema_id int generated always as identity primary key,
	cinema_city varchar(50),
	cinema_employees_count int
);

insert into cinemas ( cinema_city, cinema_employees_count  )
select
	(array['Kyiv','Chernihaiv','Lviv','Kharkiv','Cherepyn','Odesa','Mykylaiv','Kolky','Ivanutsa','Dnipro','Hawai'])[floor(random()*11+1)],
	floor(random()*300+10)::int
	--числа від 10 до 309
from generate_series(1,500) id;

create table movies(
	movie_id int  generated always as identity primary key,
	movie_ganre varchar(50),
	movie_age_rating varchar(50),
	movie_rating numeric(2,1)
	-- numeric(2,1) для того щоб були десяткові дроби 2 кількість цифр 1 кількість після коми
);

insert into movies ( movie_ganre, movie_age_rating, movie_rating )
select
	(array['Action','Drama','Adventure','Horror','Comedy','History','Romance','Crime','Thriller','Superhero','Zombie','Science Fiction','Detective'])[floor(random()*13+1)::int],
	(array['13+','16+','18+','21+','3+','12+','0+'])[floor(random()*7+1)],
	round((random()*4+1)::numeric, 1)
	-- переводимо в numeric
from generate_series(1,10000) id;

create table sessions(
	session_id int generated always as identity primary key,
	session_time timestamp,
	price numeric(4,1),
	movie_id int,
	cinema_id int,
	foreign key (movie_id) references movies(movie_id),
	foreign key (cinema_id) references cinemas(cinema_id)

);

insert into sessions ( session_time, price, movie_id, cinema_id )
select
	now() + (random() * interval '120 days'),
	--бере поточну дату+ рандомне число від 0 до 1 * 120
	round((random()*460+180)::numeric,1),
	floor(random()*10000+1)::int,
	floor(random()*500+1)::int
from generate_series(1,10000) id;



create table tickets(
	ticket_id int generated always as identity primary key,
	ticket_count int,
-- скільки квитків буде у одного кастомера на руках
	customer_id int,
	session_id int,

	foreign key (customer_id) references customers(customer_id),
	foreign key (session_id) references sessions(session_id)
);

insert into tickets( ticket_count,  customer_id, session_id )
select
	floor(random()*5+1),
	floor(random()*10000 + 1)::int,
    floor(random()*10000 + 1)::int
    -- ці два запису ту для того щоб зв'язати квиток з покупцем і сесією рандомним чином
from generate_series(1,10000) id;


select
--це селект поверне кастомерів які купили квитки на фільм рейтинг якого вище за 4 а вікове обмеження 16+, в порядку спадання за кількістю білетів
	cu.customer_id,
	cu.customer_email,
	ci.cinema_city,
	m.movie_rating,
	sum(t.ticket_count) as total_tickets
from customers cu
join tickets t
	on cu.customer_id= t.customer_id
join sessions s
	on t.session_id = s.session_id
join movies m
	on s.movie_id = m.movie_id
join cinemas ci
	on s.cinema_id  = ci.cinema_id
where m.movie_rating > 4 and m.movie_age_rating  = '16+'
group by
-- group by тут для того щоб коли рахувалась кількість булетів вона рахувалась на точного кастомера а не просто загальна кількість
	cu.customer_id,
	cu.customer_email,
	ci.cinema_city,
	m.movie_rating
order by total_tickets desc;


-- цей запит покаже топ 3 кінотеатра за кількістю проданих білетів
with cinema_rating as(
	select
		ci.cinema_id,
		ci.cinema_city,
		sum(t.ticket_count) as total_ticket
	from cinemas ci
	join sessions s
		on ci.cinema_id = s.cinema_id
	join tickets t
		on s.session_id = t.session_id
	group by ci.cinema_id, ci.cinema_city
)
select *
from cinema_rating
order by total_ticket desc limit 3;



