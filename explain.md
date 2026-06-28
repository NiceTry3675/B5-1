# 카페 주문 DB 개념 설명

이 문서는 `schema.sql`, `seed.sql`, `queries.sql`이 어떤 개념을 연습하기 위해 만들어졌는지 설명합니다. 목표는 SQL 문법을 외우는 것이 아니라, 데이터를 왜 여러 테이블로 나누고 어떻게 다시 연결해서 조회하는지 이해하는 것입니다.

## 1. 엑셀과 DB는 뭐가 다른가?

엑셀도 표이고 DB 테이블도 표입니다. 하지만 DB는 표 사이의 관계와 규칙을 더 엄격하게 관리합니다.

엑셀에 주문 데이터를 한 시트로만 저장하면 이런 모양이 되기 쉽습니다.

```text
주문번호 | 고객명 | 전화번호 | 메뉴명 | 메뉴가격 | 수량
1       | 김민준 | 010...  | 아메리카노 | 4500 | 1
1       | 김민준 | 010...  | 카페라떼   | 5000 | 1
```

이 방식은 처음에는 쉽지만 같은 고객 정보와 메뉴 정보가 계속 반복됩니다. 전화번호가 바뀌거나 메뉴 가격을 수정해야 할 때 여러 줄을 모두 찾아 고쳐야 합니다.

DB에서는 데이터를 역할별 테이블로 나눕니다.

```text
customers      고객 정보
menu_items     메뉴 정보
orders         주문 한 건의 정보
order_items    주문 안에 들어간 메뉴 정보
```

이렇게 나누면 고객 정보는 고객 테이블에서 한 번만 관리하고, 주문 테이블은 고객 번호만 참조하면 됩니다. 이것이 관계형 DB가 엑셀보다 강한 지점입니다.

## 2. PK는 각 행의 주민등록번호 같은 값

PK(Primary Key)는 테이블 안에서 한 행을 정확히 구분하는 값입니다.

이 과제에서는 아래 컬럼들이 PK입니다.

| 테이블 | PK |
| --- | --- |
| `customers` | `customer_id` |
| `menu_categories` | `category_id` |
| `menu_items` | `menu_item_id` |
| `orders` | `order_id` |
| `order_items` | `order_item_id` |

예를 들어 고객 이름은 같은 사람이 있을 수 있습니다. 하지만 `customer_id = 1`인 고객은 한 명뿐입니다. 그래서 다른 테이블에서 고객을 가리킬 때 이름이 아니라 `customer_id`를 사용합니다.

## 3. FK는 다른 테이블의 PK를 가리키는 연결고리

FK(Foreign Key)는 다른 테이블의 PK를 참조하는 컬럼입니다.

예를 들어 `orders.customer_id`는 `customers.customer_id`를 참조합니다.

```text
customers
customer_id | name
1           | 김민준

orders
order_id | customer_id | total_amount
1        | 1           | 9500
```

주문 1번의 `customer_id`가 1이므로, 이 주문은 김민준 고객의 주문이라는 뜻입니다.

SQLite에서는 FK 검사를 실제로 켜기 위해 아래 문장이 필요합니다.

```sql
PRAGMA foreign_keys = ON;
```

이 설정이 켜져 있으면 존재하지 않는 고객 번호로 주문을 넣으려 할 때 DB가 막아줍니다.

```sql
INSERT INTO orders (order_id, customer_id, order_date, order_type, status, total_amount)
VALUES (999, 999, '2024-06-10 10:00:00', 'STORE', 'PAID', 5000);
```

위 예시는 `customer_id = 999`인 고객이 없기 때문에 FK 오류가 납니다. 이것이 데이터 정합성을 지키는 방식입니다.

## 4. 1:N 관계 이해하기

1:N은 한 행이 다른 테이블의 여러 행과 연결될 수 있다는 뜻입니다.

### 고객 1명은 주문 N개를 가질 수 있다

```text
customers.customer_id = 1
  ├─ orders.order_id = 1
  └─ orders.order_id = 6
```

김민준 고객은 6월 1일에도 주문하고, 6월 3일에도 주문할 수 있습니다. 그래서 `customers`와 `orders`는 1:N 관계입니다.

### 주문 1건은 주문상세 N개를 가질 수 있다

```text
orders.order_id = 1
  ├─ 아메리카노 1잔
  └─ 카페라떼 1잔
```

주문 한 건에 메뉴가 여러 개 들어갈 수 있으므로 `orders`와 `order_items`도 1:N 관계입니다.

## 5. SELECT, INSERT, UPDATE, DELETE

SQL의 기본 조작은 CRUD로 볼 수 있습니다.

| SQL | 의미 | 이 과제의 예 |
| --- | --- | --- |
| `INSERT` | 새 데이터 추가 | `seed.sql`에서 고객, 메뉴, 주문 입력 |
| `SELECT` | 데이터 조회 | `queries.sql`의 Q01 ~ Q12 |
| `UPDATE` | 기존 데이터 수정 | Q13에서 메뉴 품절 처리 |
| `DELETE` | 기존 데이터 삭제 | Q14에서 취소 주문 상세 삭제 |

수정과 삭제는 실무에서 조심해야 합니다. 그래서 이 과제에서는 트랜잭션 안에서 실행한 뒤 `ROLLBACK`해서 연습 결과만 확인하고 실제 데이터는 보존합니다.

## 6. JOIN은 나눠진 테이블을 다시 연결하는 방법

테이블을 나눠 저장하면 중복은 줄지만, 화면이나 리포트에서는 다시 합쳐서 보고 싶을 때가 많습니다. 이때 JOIN을 사용합니다.

예를 들어 주문 목록에 고객 이름을 함께 보고 싶다면 `orders`와 `customers`를 연결합니다.

```sql
SELECT o.order_id, c.name, o.order_date, o.total_amount
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id;
```

`ON o.customer_id = c.customer_id`가 연결 조건입니다. 주문 테이블의 고객 번호와 고객 테이블의 고객 번호가 같은 행끼리 붙입니다.

`LEFT JOIN`은 왼쪽 테이블의 행을 모두 남깁니다. 그래서 주문이 없는 고객까지 보고 싶을 때 유용합니다.

## 7. GROUP BY는 묶어서 계산하는 방법

`GROUP BY`는 여러 행을 기준별로 묶고, 그 묶음마다 계산합니다.

예를 들어 주문 상태별 주문 수와 매출 합계를 구할 수 있습니다.

```sql
SELECT status, COUNT(*) AS order_count, SUM(total_amount) AS total_sales
FROM orders
GROUP BY status;
```

결과는 `COMPLETED`, `PAID`, `READY`, `CANCELED` 같은 상태별로 한 줄씩 나옵니다.

자주 쓰는 집계 함수는 다음과 같습니다.

| 함수 | 의미 |
| --- | --- |
| `COUNT` | 행 개수 |
| `SUM` | 합계 |
| `AVG` | 평균 |
| `MIN` | 최솟값 |
| `MAX` | 최댓값 |

## 8. 서브쿼리는 쿼리 안의 쿼리

서브쿼리는 SQL 안에 들어가는 또 다른 SQL입니다.

예를 들어 평균 주문 금액보다 큰 주문만 찾으려면 평균을 먼저 계산해야 합니다.

```sql
SELECT order_id, total_amount
FROM orders
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM orders
    WHERE status = 'COMPLETED'
);
```

안쪽 쿼리가 평균 주문 금액을 구하고, 바깥쪽 쿼리가 그 평균보다 큰 주문을 찾습니다.

## 9. 인덱스는 책의 색인 같은 것

인덱스는 데이터를 더 빨리 찾기 위해 만드는 보조 구조입니다. 책 뒤의 색인을 생각하면 쉽습니다. 어떤 단어가 몇 페이지에 나오는지 색인을 보면 처음부터 끝까지 읽지 않아도 됩니다.

이 과제에서는 주문 날짜에 인덱스를 만듭니다.

```sql
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
```

카페에서는 기간별 주문 조회가 자주 일어납니다.

```sql
SELECT *
FROM orders
WHERE order_date >= '2024-06-01'
  AND order_date < '2024-07-01';
```

이런 조건에서 `order_date` 인덱스가 있으면 DB가 날짜 범위를 더 빠르게 찾을 수 있습니다.

다만 인덱스는 많을수록 무조건 좋은 것이 아닙니다. 데이터를 추가하거나 수정할 때 인덱스도 함께 갱신해야 하므로, 자주 검색하거나 정렬하는 컬럼에 신중하게 만드는 것이 좋습니다.

## 10. 이 DB로 뽑을 수 있는 핵심 지표 3개

이 카페 DB로는 아래 같은 지표를 뽑을 수 있습니다.

| 지표 | 필요한 테이블 | 의미 |
| --- | --- | --- |
| 메뉴별 판매 수량 TOP 5 | `order_items`, `menu_items`, `orders` | 가장 많이 팔린 메뉴 확인 |
| 고객 등급별 평균 주문 금액 | `customers`, `orders` | VIP/GOLD 등급 고객의 구매 규모 비교 |
| 주문 상태별 매출 합계 | `orders` | 완료, 준비, 취소 주문의 현황 확인 |

이 지표들은 `queries.sql`의 Q09, Q10, Q11에서 확인할 수 있습니다.

## 11. 보너스: 같은 요구를 JOIN과 서브쿼리로 풀기

요구사항은 같습니다.

```text
주문이 있는 고객 목록과 고객별 주문 횟수를 조회한다.
```

JOIN 방식은 `customers`와 `orders`를 먼저 연결한 뒤 고객별로 묶습니다.

```sql
SELECT c.customer_id, c.name, COUNT(o.order_id) AS order_count
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;
```

서브쿼리 방식은 바깥쪽에서 고객을 하나씩 보면서, 안쪽 쿼리로 그 고객의 주문 수를 계산합니다.

```sql
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
);
```

두 방식 모두 같은 결과를 만들 수 있습니다. 다만 주문 수처럼 연결된 데이터를 묶어 집계할 때는 `JOIN + GROUP BY`가 보통 더 자연스럽고 읽기 쉽습니다. 반대로 서브쿼리는 “이 조건에 해당하는 것만”, “평균보다 큰 것만”처럼 한 쿼리 결과를 다른 쿼리의 조건으로 쓰고 싶을 때 이해하기 좋습니다.
