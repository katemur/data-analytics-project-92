-- 4 этот запрос возвращает количество покупателей
select count(*)
from customers;

/* 5.1 этот запрос возвращает информацию про топ 10 продавцов с максимальной выручкой за все время: 
полное имя продавца, склеенное из имени и фамилии, суммарное количество сделок 
и суммарную выручку за все время */
select 
	concat(e.first_name , ' ', e.last_name) as name,
	count(s.sales_id) as operations,
	sum(s.quantity * p.price) as income
from sales s
inner join employees e on s.sales_person_id = e.employee_id 
inner join products p on s.product_id = p.product_id
group by 1
order by 3 desc
limit 10;

/* 5.2 этот запрос возвращает информацию обо всех продавцах, чья выручка ниже средней по всем продавцам: 
 полное имя продавца и его суммарную выручку. сортировка по возрастанию выручки */
select 
	concat(e.first_name , ' ', e.last_name) as name,
	round(avg(s.quantity * p.price)) as average_income
from sales s 
inner join employees e on s.sales_person_id = e.employee_id 
inner join products p on s.product_id = p.product_id 
group by 1
having avg(s.quantity * p.price) < (
--подсчет средней выручки по всем продавцам
	select avg(s.quantity * p.price)
	from sales s
	inner join products p on s.product_id = p.product_id)
order by 2;

/* 5.3 этот запрос возвращает информацию и выручке каждого продавца по дням недели, 
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
	group by 1, 2
	order by 2, 1)
/* этот запрос возвращает полное имя продавца, название дня недели 
 * и сумму продаж продавца в этот день недели, сохраняя нужную сортировку
 */
select 
	name,
	to_char(s_date, 'day'),
	income
from tab;

/* 6.1 этот запрос возвращает количество покупателей, относящихся к возрастным группам 16-25, 26-40, 40+
 * сортировка по возрастанию возраста
 */
with age_cat as (
--всомогательный запрос, в зависимости от возраста выдает возрастную группу
	select 
		case
			when age between 16 and 25 then '16-25'
			when age between 26 and 40 then '26-40'
			when age > 40 then '40+'
		end as age_category
	from customers c)
select 
	age_category,
	count(age_category)
from age_cat
group by 1
order by 1;

/* 6.2 этот запрос возвращает количество покупателей и суммарную выручку, которую они принесли по месяца
 */
with tab2 as(
--вспомогательный запрос, возвращающий дату в формате год-месяц, id покупателя, дату, доход 
SELECT 
    concat(extract(year from s.sale_date), '-', extract(month from s.sale_date)) as date,
    c.customer_id,
    date_trunc('month', s.sale_date)::date order_month,
    sum(s.quantity * p.price) as income
from sales s
inner join customers c on s.customer_id = c.customer_id
INNER join products p on s.product_id = p.product_id
group by 1,2,3
)
-- основной запрос, возвращающий дату в формате год-месяц, количество покупателей и доход за этот месяц
select 
    date,
    count(customer_id) as total_customers,
    SUM(income) as income
from tab2
group by 1, order_month
order by order_month;

-- 6.3 этот запрос возвращает информацию о покупателях, чья первая покупка была в ходе проведения акций
with tab as(
-- этот запрос возвращает id покупателя, полное имя покупателя, дату первой покупки, сумму первой покупки, полное имя продавца
	select
		c.customer_id,
		concat(c.first_name , ' ', c.last_name) as customer,
		first_value(s.sale_date) over (partition by s.customer_id order by s.sale_date) as sale_date,
		p.price,
		concat(e.first_name , ' ', e.last_name) as seller
	from customers c  
	inner join sales s on c.customer_id =  s.customer_id
	inner join employees e on s.sales_person_id = e.employee_id
	inner join products p on s.product_id =p.product_id
),
tab2 as(
/* этот запрос возвращает id покупателя, полное имя покупателя, дату первой покупки, сумму первой покупки, полное имя продавца, если стоимость первой покупки была 0
 * сортировка по id покупателя
 */
	select 
		customer_id,
		customer,
		sale_date,
		seller
	from tab
	where price = 0
	group by 1, 2, 3,4
	order by 1)
-- этот запрос возвращает полное имя покупателя, дату первой покупки, сумму первой покупки, полное имя продавца
select 
	customer,
	sale_date,
	seller
from tab2;
	
	

	



