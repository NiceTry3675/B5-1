# Cafe Order Database

SQLite로 구현한 카페 주문 관리 데이터베이스 과제입니다. 백엔드 프레임워크 없이 SQL만 사용해 테이블 설계, 샘플 데이터 입력, 조회/조인/집계/서브쿼리/수정/삭제/인덱스 쿼리까지 확인합니다.

## 1. 주제

이 데이터베이스는 작은 카페의 주문 데이터를 관리합니다.

관리하는 데이터는 다음과 같습니다.

| 테이블 | 의미 |
| --- | --- |
| `customers` | 카페 고객 |
| `menu_categories` | 메뉴 카테고리 |
| `menu_items` | 판매 메뉴 |
| `orders` | 고객 주문 |
| `order_items` | 주문에 포함된 메뉴 상세 |

## 2. 관계 구조

이 과제의 핵심은 테이블 사이의 1:N 관계입니다.

```text
menu_categories 1 ── N menu_items
customers       1 ── N orders
orders          1 ── N order_items
menu_items      1 ── N order_items
```

예를 들어 고객 한 명은 여러 주문을 만들 수 있으므로 `customers.customer_id`를 `orders.customer_id`가 FK로 참조합니다. 주문 하나에는 여러 메뉴가 들어갈 수 있으므로 `orders.order_id`를 `order_items.order_id`가 참조합니다.

## 3. 설계 및 개념 설명 요약

### 3.1 테이블을 나눈 이유

처음에는 주문 데이터를 엑셀처럼 한 표에 모두 넣을 수도 있습니다.

```text
주문번호 | 고객명 | 전화번호 | 메뉴명 | 메뉴가격 | 수량
1       | 김민준 | 010...  | 아메리카노 | 4500 | 1
1       | 김민준 | 010...  | 카페라떼   | 5000 | 1
```

하지만 이렇게 저장하면 같은 고객 정보와 메뉴 정보가 여러 줄에 반복됩니다. 전화번호나 메뉴 가격이 바뀌면 여러 행을 모두 수정해야 해서 데이터가 서로 어긋날 위험이 큽니다.

그래서 이 과제에서는 데이터를 역할별로 분리했습니다.

| 테이블 | 나눈 이유 |
| --- | --- |
| `customers` | 고객 이름, 전화번호, 등급처럼 고객 자체의 정보를 한 번만 저장 |
| `menu_categories` | Coffee, Bakery 같은 메뉴 분류를 중복 없이 관리 |
| `menu_items` | 메뉴명, 가격, 판매 여부를 메뉴 단위로 관리 |
| `orders` | 주문 일시, 주문 방식, 상태, 총액처럼 주문 한 건의 정보를 저장 |
| `order_items` | 주문 한 건에 들어간 여러 메뉴와 수량을 저장 |

이 구조에서는 고객 정보는 `customers`에 한 번만 저장하고, 주문은 `customer_id`로 고객을 참조합니다. 이것이 엑셀과 관계형 DB의 큰 차이입니다. DB는 단순히 표를 저장하는 도구가 아니라, 테이블 사이의 관계와 제약조건으로 데이터 정합성을 지키는 도구입니다.

### 3.2 PK와 FK가 데이터를 연결하는 방식

PK(Primary Key)는 테이블에서 한 행을 고유하게 구분하는 값입니다. FK(Foreign Key)는 다른 테이블의 PK를 참조하는 값입니다.

| 관계 | 의미 | 예시 |
| --- | --- | --- |
| `customers.customer_id` -> `orders.customer_id` | 고객 1명은 주문 여러 건을 만들 수 있음 | 김민준 고객은 주문 1번과 6번을 가짐 |
| `orders.order_id` -> `order_items.order_id` | 주문 1건에는 여러 메뉴가 들어갈 수 있음 | 주문 1번에는 아메리카노와 카페라떼가 들어감 |
| `menu_items.menu_item_id` -> `order_items.menu_item_id` | 같은 메뉴는 여러 주문상세에서 팔릴 수 있음 | 아메리카노는 여러 주문에서 반복 판매됨 |
| `menu_categories.category_id` -> `menu_items.category_id` | 카테고리 1개에는 여러 메뉴가 속할 수 있음 | Coffee 카테고리에 아메리카노, 카페라떼, 바닐라라떼가 속함 |

예를 들어 `orders`의 `customer_id = 1`은 `customers.customer_id = 1`인 김민준 고객을 가리킵니다. 존재하지 않는 `customer_id = 999`로 주문을 넣으면 FK 제약조건 때문에 실패합니다. 실제 실패 결과는 `results/fk_error.txt`에 남겼습니다.

### 3.3 컬럼 타입을 선택한 이유

SQLite는 타입이 비교적 유연하지만, 데이터 의미에 맞춰 타입을 정했습니다.

| 타입 | 사용한 컬럼 예 | 선택 이유 |
| --- | --- | --- |
| `INTEGER` | `customer_id`, `price`, `quantity`, `total_amount` | id와 금액, 수량처럼 숫자 비교/계산이 필요한 값 |
| `TEXT` | `name`, `phone`, `email`, `order_date`, `status` | 문자열, 날짜 문자열, 상태값 저장 |
| `INTEGER CHECK (값 IN (0, 1))` | `is_available` | SQLite에 별도 Boolean 타입이 없으므로 0/1로 판매 여부 표현 |
| `TEXT CHECK (...)` | `grade`, `order_type`, `status` | 정해진 값만 들어오게 제한해 오타와 잘못된 상태 방지 |

금액은 소수점이 필요 없는 원화 기준이라 `INTEGER`로 저장했습니다. 날짜는 SQLite에서 정렬 가능한 `YYYY-MM-DD HH:MM:SS` 형식의 `TEXT`로 저장했습니다.

### 3.4 INNER JOIN과 LEFT JOIN 결과 해석

`INNER JOIN`은 양쪽 테이블에 연결되는 데이터가 있을 때만 결과에 나옵니다. Q05는 `orders`와 `customers`를 연결해서 주문 12건에 고객 이름을 붙입니다. 주문은 반드시 고객을 참조하므로 주문 12건이 모두 고객 이름과 함께 출력됩니다.

`LEFT JOIN`은 왼쪽 테이블의 행을 모두 남깁니다. Q08은 `customers`를 왼쪽에 두고 `orders`를 붙였기 때문에 주문이 없는 고객도 결과에 나옵니다. 실행 결과에서 `문하늘` 고객은 `order_count = 0`으로 표시됩니다. 이 행이 LEFT JOIN의 특징을 보여줍니다.

### 3.5 GROUP BY와 집계 함수 결과 해석

`GROUP BY`는 같은 기준의 행을 묶고, 묶음마다 계산합니다.

Q09는 `orders.status`별로 주문을 묶습니다. 결과에서 `COMPLETED`는 주문 수가 9건이고 매출 합계가 128900입니다. 즉 `status = 'COMPLETED'`인 여러 주문 행을 하나의 그룹으로 모은 뒤 `COUNT(*)`와 `SUM(total_amount)`를 계산한 것입니다.

Q10은 고객 등급별 평균 주문 금액을 구합니다. `customers`와 `orders`를 JOIN한 뒤 `grade`로 묶고, 각 등급의 `total_amount` 평균을 `AVG`로 계산합니다. Q11은 메뉴별 판매 수량을 `SUM(oi.quantity)`로 더해서 인기 메뉴 TOP 5를 보여줍니다.

### 3.6 인덱스를 건 컬럼과 이유

Q15에서는 `orders(order_date)`에 인덱스를 만들었습니다.

```sql
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
```

카페 운영에서는 “이번 달 주문”, “최근 7일 주문”, “날짜순 주문 내역”처럼 기간 기준 조회가 자주 발생합니다. `order_date`에 인덱스가 있으면 DB가 모든 주문을 처음부터 끝까지 훑기보다 날짜 범위를 기준으로 더 빠르게 찾을 수 있습니다. 단, 인덱스는 INSERT/UPDATE 때 함께 갱신되어야 하므로 자주 검색하거나 정렬하는 컬럼에만 선택적으로 만드는 것이 좋습니다.

### 3.7 가장 복잡했던 쿼리 설명

가장 복잡한 쿼리는 Q11 메뉴별 판매 수량 TOP 5입니다.

```sql
SELECT mi.name AS menu_name, SUM(oi.quantity) AS sold_quantity,
       SUM(oi.quantity * oi.unit_price) AS sales_amount
FROM order_items AS oi
INNER JOIN menu_items AS mi ON oi.menu_item_id = mi.menu_item_id
INNER JOIN orders AS o ON oi.order_id = o.order_id
WHERE o.status <> 'CANCELED'
GROUP BY mi.menu_item_id, mi.name
ORDER BY sold_quantity DESC, sales_amount DESC
LIMIT 5;
```

이 쿼리는 먼저 `order_items`에서 실제 판매된 메뉴와 수량을 가져옵니다. 그다음 `menu_items`를 JOIN해서 메뉴 이름을 붙이고, `orders`를 JOIN해서 취소 주문을 제외합니다. 이후 메뉴별로 `GROUP BY`를 하고, `SUM(quantity)`로 판매 수량을 더합니다. 마지막으로 많이 팔린 순서대로 정렬하고 `LIMIT 5`로 상위 5개만 남깁니다.

### 3.8 어려웠던 부분과 해결 방법

가장 어려운 부분은 주문 총액과 주문상세 금액의 관계를 자연스럽게 맞추는 것이었습니다. `orders.total_amount`는 주문 한 건의 총액이고, `order_items`는 메뉴별 `quantity * unit_price`를 저장합니다. 두 값이 맞지 않으면 집계 결과가 어색해지므로 샘플 데이터를 넣을 때 주문상세 금액 합계와 주문 총액이 맞도록 계산했습니다.

또 하나의 어려움은 `DELETE` 실습이 실제 샘플 데이터를 망가뜨리지 않게 하는 것이었습니다. 해결 방법으로 Q13, Q14를 트랜잭션 안에서 실행하고 `ROLLBACK`했습니다. 덕분에 UPDATE/DELETE 결과는 확인할 수 있지만, 다음 쿼리나 재실행에는 원본 데이터가 유지됩니다.

## 4. 파일 구성

```text
B5-1/
  requirement.md
  schema.sql
  seed.sql
  queries.sql
  bonus.sql
  README.md
  explain.md
  results/
    query_results.txt
    bonus_results.txt
    fk_error.txt
```

| 파일 | 역할 |
| --- | --- |
| `schema.sql` | 테이블 생성, PK/FK/제약조건 정의 |
| `seed.sql` | 각 테이블에 10행 이상 샘플 데이터 입력 |
| `queries.sql` | 핵심 SQL 쿼리 15개와 한 줄 설명 |
| `bonus.sql` | 보너스 과제 쿼리와 비교 설명 |
| `results/query_results.txt` | 실제 SQLite 실행 결과 텍스트 |
| `results/bonus_results.txt` | 보너스 과제 실행 결과 텍스트 |
| `results/fk_error.txt` | FK 제약조건 실패 확인 결과 |
| `explain.md` | DB 개념과 설계 의도 설명 |

## 5. 실행 방법

SQLite CLI가 설치되어 있다면 아래 명령으로 DB를 새로 만들 수 있습니다.

```bash
cd B5-1
rm -f cafe.db
sqlite3 cafe.db < schema.sql
sqlite3 cafe.db < seed.sql
sqlite3 cafe.db < queries.sql
sqlite3 cafe.db < bonus.sql
```

실행 결과를 텍스트 파일로 다시 만들려면 아래처럼 실행합니다.

```bash
sqlite3 cafe.db < queries.sql > results/query_results.txt
sqlite3 cafe.db < bonus.sql > results/bonus_results.txt
```

## 6. 요구사항 충족 체크

| 요구사항 | 충족 내용 |
| --- | --- |
| 최소 4개 테이블 | 5개 테이블 사용 |
| 테이블별 PK | 모든 테이블에 `INTEGER PRIMARY KEY` 적용 |
| 1:N 관계 2개 이상 | 4개의 FK 관계 적용 |
| NOT NULL | 주요 필수 컬럼에 적용 |
| UNIQUE | 고객 전화번호, 고객 이메일, 카테고리명, 메뉴명에 적용 |
| FK 동작 | `PRAGMA foreign_keys = ON;`과 FK 제약조건 적용 |
| 각 테이블 10행 이상 | 고객 11행, 카테고리 10행, 메뉴 12행, 주문 12행, 주문상세 20행 |
| 핵심 쿼리 15개 | `queries.sql`에 15개 작성 |
| 결과 확인 자료 | `results/query_results.txt` 작성 |
| 보너스 과제 | `bonus.sql`, `results/bonus_results.txt`, `explain.md`에 정리 |

## 7. 쿼리 범위

`queries.sql`에는 아래 범주의 쿼리가 들어 있습니다.

| 범주 | 쿼리 번호 |
| --- | --- |
| 기본 조회 | Q01 ~ Q04 |
| 조인 | Q05 ~ Q08 |
| 집계 | Q09 ~ Q11 |
| 서브쿼리 | Q12 |
| 수정/삭제 | Q13 ~ Q14 |
| 인덱스 | Q15 |

수정과 삭제 실습은 `BEGIN TRANSACTION` 후 결과를 확인하고 `ROLLBACK`합니다. 그래서 쿼리를 실행해도 샘플 데이터 원본은 유지됩니다.

## 8. 보너스 과제

보너스 과제도 함께 정리했습니다.

| 보너스 | 제출물 |
| --- | --- |
| 조인 1개를 두 방식으로 풀기 | `bonus.sql`의 BONUS 1-A, 1-B, 1-C |
| 데이터 정합성 깨뜨려 보기 | `bonus.sql`의 BONUS 2, `results/fk_error.txt`, `explain.md`의 FK 오류 예시 |
| 미니 리포트 만들기 | `bonus.sql`의 BONUS 3-1 ~ 3-3, `explain.md`의 핵심 지표 3개 |
