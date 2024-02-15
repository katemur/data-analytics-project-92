/* этот запрос возвращает информацию про топ 10 продавцов с максимальной выручкой за все время: 
полное имя продавца, склеенное из имени и фамилии, суммарное количество сделок 
и суммарную выручку за все время */
select 
	concat(e.first_name , ' ', e.last_name) as name,
	count(s.sales_id) as operations,
	sum(s.quantity * p.price) as income
from sales s
inner join employees e on s.sales_person_id = e.employee_id 
inner join products p on s.product_id = p.product_id
group by concat(e.first_name , ' ', e.last_name)
order by income desc
limit 10;

/* этот запрос возвращает информацию обо всех продавцах, чья выручка ниже средней по всем продавцам: 
 полное имя продавца и его суммарную выручку. сортировка по возрастанию выручки */
select 
	concat(e.first_name , ' ', e.last_name) as name,
	round(avg(s.quantity * p.price)) as average_income
from sales s 
inner join employees e on s.sales_person_id = e.employee_id 
inner join products p on s.product_id = p.product_id 
group by concat(e.first_name , ' ', e.last_name)
having avg(s.quantity * p.price) < (
--подсчет средней выручки по всем продавцам
	select avg(s.quantity * p.price)
	from sales s
	inner join products p on s.product_id = p.product_id)
order by average_income;

/* этот запрос возвращает информацию и выручке каждого продавца по дням недели, 
 отсортирован по дню недели и имени продавца */
with tab as (
/* вспомогательный запрос, возвращающий полное имя продавца, номер дня недели(для сортировки по нему),
 * сумму продаж продавца в этот день недели и 
 * максимальную дату конретного дня недели(чтобы после сортировки взять из нее название дня недели)
 */
	select 
		concat(e.first_name , ' ', e.last_name) as name,
		extract(isodow from s.sale_date) as weekday,
		round(sum(s.quantity * p.price)) as income,
		max(s.sale_date) as s_date
	from sales s 
	inner join employees e on s.sales_person_id = e.employee_id
	inner join products p on s.product_id =p.product_id
	group by concat(e.first_name , ' ', e.last_name), extract(isodow from s.sale_date)
	order by weekday, name)
/* этот запрос возвращает полное имя продавца, название дня недели 
 * и сумму продаж продавца в этот день недели, сохраняя нужную сортировку
 */
select 
	name,
	to_char(s_date, 'day'),
	income
from tab;
