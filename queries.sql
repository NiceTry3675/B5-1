PRAGMA foreign_keys = ON;
.headers on
.mode column

.print 'Q01. 가격이 6000원 이하인 판매 가능 메뉴를 가격순으로 조회한다.'
SELECT menu_item_id, name, price
FROM menu_items
WHERE is_available = 1
  AND price <= 6000
ORDER BY price ASC;

.print ''
.print 'Q02. 최근 가입 고객 5명을 조회한다. (ORDER BY + LIMIT)'
SELECT customer_id, name, grade, joined_at
FROM customers
ORDER BY joined_at DESC
LIMIT 5;

.print ''
.print 'Q03. 2024-06-03 이후 완료된 주문을 금액이 큰 순서로 조회한다.'
SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
WHERE order_date >= '2024-06-03'
  AND status = 'COMPLETED'
ORDER BY total_amount DESC;

.print ''
.print 'Q04. 이름에 라떼가 포함된 메뉴를 검색한다. (LIKE)'
SELECT menu_item_id, name, price, is_available
FROM menu_items
WHERE name LIKE '%라떼%'
ORDER BY price DESC;

.print ''
.print 'Q05. INNER JOIN: 주문과 고객 이름을 함께 조회한다.'
SELECT o.order_id, c.name AS customer_name, o.order_date, o.order_type, o.total_amount
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id
ORDER BY o.order_id;

.print ''
.print 'Q06. INNER JOIN: 주문 상세에서 주문번호, 메뉴명, 수량, 금액을 조회한다.'
SELECT oi.order_id, mi.name AS menu_name, oi.quantity, oi.unit_price,
       oi.quantity * oi.unit_price AS line_amount
FROM order_items AS oi
INNER JOIN menu_items AS mi ON oi.menu_item_id = mi.menu_item_id
ORDER BY oi.order_id, oi.order_item_id;

.print ''
.print 'Q07. INNER JOIN: 카테고리별 메뉴 목록을 조회한다.'
SELECT mc.name AS category_name, mi.name AS menu_name, mi.price, mi.is_available
FROM menu_categories AS mc
INNER JOIN menu_items AS mi ON mc.category_id = mi.category_id
ORDER BY mc.category_id, mi.price;

.print ''
.print 'Q08. LEFT JOIN: 모든 고객과 고객별 주문 횟수를 조회한다. 주문이 없어도 고객은 나온다.'
SELECT c.customer_id, c.name, COUNT(o.order_id) AS order_count
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY order_count DESC, c.customer_id;

.print ''
.print 'Q09. 집계: 주문 상태별 주문 수와 매출 합계를 구한다. (COUNT + SUM + GROUP BY)'
SELECT status, COUNT(*) AS order_count, SUM(total_amount) AS total_sales
FROM orders
GROUP BY status
ORDER BY total_sales DESC;

.print ''
.print 'Q10. 집계: 고객 등급별 평균 주문 금액을 구한다. (AVG + GROUP BY)'
SELECT c.grade, ROUND(AVG(o.total_amount), 1) AS avg_order_amount
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.status <> 'CANCELED'
GROUP BY c.grade
ORDER BY avg_order_amount DESC;

.print ''
.print 'Q11. 집계: 메뉴별 판매 수량 TOP 5를 구한다.'
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
.print 'Q12. 서브쿼리: 평균 주문 금액보다 큰 완료 주문을 조회한다.'
SELECT order_id, customer_id, order_date, total_amount
FROM orders
WHERE status = 'COMPLETED'
  AND total_amount > (
      SELECT AVG(total_amount)
      FROM orders
      WHERE status = 'COMPLETED'
  )
ORDER BY total_amount DESC;

.print ''
.print 'Q13. UPDATE 실습: 특정 메뉴를 품절 처리한 뒤 결과를 확인하고 ROLLBACK한다.'
BEGIN TRANSACTION;
UPDATE menu_items
SET is_available = 0
WHERE name = '딸기 스무디';
SELECT menu_item_id, name, is_available
FROM menu_items
WHERE name = '딸기 스무디';
ROLLBACK;

.print ''
.print 'Q14. DELETE 실습: 취소된 주문의 상세 항목을 삭제한 뒤 결과를 확인하고 ROLLBACK한다.'
BEGIN TRANSACTION;
DELETE FROM order_items
WHERE order_id IN (
    SELECT order_id
    FROM orders
    WHERE status = 'CANCELED'
);
SELECT COUNT(*) AS canceled_order_item_count
FROM order_items
WHERE order_id = 12;
ROLLBACK;

.print ''
.print 'Q15. 인덱스: 주문 날짜 검색을 빠르게 하기 위해 orders(order_date)에 인덱스를 만든다.'
.print '적용 이유: 기간별 주문 조회와 정렬은 자주 발생하므로 order_date 인덱스가 검색 범위를 줄이는 데 도움이 된다.'
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
SELECT name, tbl_name, sql
FROM sqlite_master
WHERE type = 'index'
  AND name = 'idx_orders_order_date';
