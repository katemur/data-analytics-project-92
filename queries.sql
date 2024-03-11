-- 4 этот запрос возвращает количество покупателей
select count(*)
from customers;

/* 5.1 этот запрос возвращает информацию про топ 10 продавцов
с максимальной выручкой за все время:
полное имя продавца, склеенное из имени и фамилии, суммарное количество сделок
и суммарную выручку за все время */
select
    e.first_name || ' ' || e.last_name as seller,
    count(s.sales_id) as operations,
    trunc(sum(s.quantity * p.price)) as income
from sales as s
inner join employees as e on s.sales_person_id = e.employee_id
inner join products as p on s.product_id = p.product_id
group by 1
order by 3 desc
limit 10;

/* 5.2 этот запрос возвращает информацию обо всех продавцах,
чья выручка ниже средней по всем продавцам:
 полное имя продавца и его суммарную выручку.
 сортировка по возрастанию выручки */
select
    e.first_name || ' ' || e.last_name as seller,
    trunc(avg(s.quantity * p.price)) as average_income
from sales as s
inner join employees as e on s.sales_person_id = e.employee_id
inner join products as p on s.product_id = p.product_id
group by 1
having
    avg(s.quantity * p.price) < (
        --подсчет средней выручки по всем продавцам
        select avg(s.quantity * p.price)
        from sales as s
        inner join products as p on s.product_id = p.product_id
    )
order by 2;

/* 5.3 этот запрос возвращает информацию и выручке каждого продавца
по дням недели,
 отсортирован по дню недели и имени продавца */
with tab as (
/* вспомогательный запрос, возвращающий полное имя продавца,
    * номер дня недели(для сортировки по нему),
    * сумму продаж продавца в этот день недели и
    * максимальную дату конретного дня недели
    *(чтобы после сортировки взять из нее название дня недели)
    */
    select
        e.first_name || ' ' || e.last_name as seller,
        extract(isodow from s.sale_date) as week_day,
        trunc(sum(s.quantity * p.price)) as income,
        max(s.sale_date) as s_date
    from sales as s
    inner join employees as e on s.sales_person_id = e.employee_id
    inner join products as p on s.product_id = p.product_id
    group by 1, 2
    order by 2, 1
)

/* этот запрос возвращает полное имя продавца, название дня недели
 * и сумму продаж продавца в этот день недели, сохраняя нужную сортировку
 */
select
    seller,
    income,
    to_char(s_date, 'day') as day_of_week
from tab;


/* 6.1 этот запрос возвращает количество покупателей,
 * относящихся к возрастным группам 16-25, 26-40, 40+
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
    from customers
)

select
    age_category,
    count(age_category) as age_count
from age_cat
group by 1
order by 1;


/* 6.2 этот запрос возвращает количество покупателей и суммарную выручку,
 * которую они принесли по месяца
 */
with tab2 as (
/* вспомогательный запрос,
 * возвращающий дату в формате год-месяц, id покупателя, дату, доход
 */
    select
        to_char(s.sale_date, 'YYYY-MM') as selling_month,
        c.customer_id,
        date_trunc('month', s.sale_date)::date as order_month,
        sum(s.quantity * p.price) as income
    from sales as s
    inner join customers as c on s.customer_id = c.customer_id
    inner join products as p on s.product_id = p.product_id
    group by 1, 2, 3
)

/* основной запрос, возвращающий дату в формате год-месяц,
 * количество покупателей и доход за этот месяц
 */
select
    selling_month,
    count(customer_id) as total_customers,
    trunc(sum(income)) as income
from tab2
group by 1, order_month
order by order_month;


/* 6.3 этот запрос возвращает информацию о покупателях,
 * чья первая покупка была в ходе проведения акций
 */
with tab as (
/* этот запрос возвращает id покупателя, полное имя покупателя,
 * дату первой покупки, сумму первой покупки, полное имя продавца
 */
    select
        c.customer_id,
        s.sale_date,
        p.price,
        c.first_name || ' ' || c.last_name as customer,
        row_number()
            over (partition by s.customer_id order by s.sale_date)
            as rn,
        e.first_name || ' ' || e.last_name as seller
    from customers as c
    inner join sales as s on c.customer_id = s.customer_id
    inner join employees as e on s.sales_person_id = e.employee_id
    inner join products as p on s.product_id = p.product_id
)

/* этот запрос возвращает полное имя покупателя, дату первой покупки,
 * сумму первой покупки, полное имя продавца
 */
select
    customer,
    sale_date,
    seller
from tab
where price = 0 and rn = 1
order by customer_id;
