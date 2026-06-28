PRAGMA foreign_keys = ON;
.headers on
.mode column

.print 'BONUS 1-A. 같은 요구를 JOIN으로 풀기: 주문이 있는 고객 목록과 주문 횟수를 조회한다.'
SELECT c.customer_id, c.name, COUNT(o.order_id) AS order_count
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY order_count DESC, c.customer_id;

.print ''
.print 'BONUS 1-B. 같은 요구를 서브쿼리로 풀기: 주문이 있는 고객 목록과 주문 횟수를 조회한다.'
SELECT c.customer_id, c.name,
       (
           SELECT COUNT(*)
           FROM orders AS o
           WHERE o.customer_id = c.customer_id
       ) AS order_count
FROM customers AS c
WHERE c.customer_id IN (
    SELECT customer_id
    FROM orders
)
ORDER BY order_count DESC, c.customer_id;

.print ''
.print 'BONUS 1-C. 비교: JOIN은 여러 테이블을 한 결과 집합으로 연결해 집계할 때 자연스럽고, 서브쿼리는 바깥 행마다 조건을 따로 계산하는 생각을 표현하기 좋다.'
.print '두 쿼리는 같은 결과를 만들지만, 주문 수 집계처럼 연결된 데이터를 묶어 계산할 때는 JOIN + GROUP BY가 보통 더 읽기 쉽다.'

.print ''
.print 'BONUS 2. 데이터 정합성 깨뜨려 보기: 존재하지 않는 고객 999의 주문은 FK 때문에 실패해야 한다.'
.print '아래 INSERT는 직접 실행하면 FOREIGN KEY constraint failed 오류가 난다.'
.print 'INSERT INTO orders (order_id, customer_id, order_date, order_type, status, total_amount)'
.print 'VALUES (999, 999, ''2024-06-10 10:00:00'', ''STORE'', ''PAID'', 5000);'

.print ''
.print 'BONUS 2-B. 올바른 해결: 먼저 존재하는 customer_id를 사용하거나 customers에 고객을 먼저 추가해야 한다.'
SELECT customer_id, name
FROM customers
WHERE customer_id IN (1, 999)
ORDER BY customer_id;

.print ''
.print 'BONUS 3-1. 미니 리포트: 주문 상태별 매출 합계'
SELECT status, COUNT(*) AS order_count, SUM(total_amount) AS total_sales
FROM orders
GROUP BY status
ORDER BY total_sales DESC;

.print ''
.print 'BONUS 3-2. 미니 리포트: 메뉴별 판매 수량 TOP 5'
SELECT mi.name AS menu_name, SUM(oi.quantity) AS sold_quantity,
       SUM(oi.quantity * oi.unit_price) AS sales_amount
FROM order_items AS oi
INNER JOIN menu_items AS mi ON oi.menu_item_id = mi.menu_item_id
INNER JOIN orders AS o ON oi.order_id = o.order_id
WHERE o.status <> 'CANCELED'
GROUP BY mi.menu_item_id, mi.name
ORDER BY sold_quantity DESC, sales_amount DESC
LIMIT 5;

.print ''
.print 'BONUS 3-3. 미니 리포트: 고객 등급별 평균 주문 금액'
SELECT c.grade, ROUND(AVG(o.total_amount), 1) AS avg_order_amount
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.status <> 'CANCELED'
GROUP BY c.grade
ORDER BY avg_order_amount DESC;
