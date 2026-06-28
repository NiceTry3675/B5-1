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

## 3. 파일 구성

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

## 4. 실행 방법

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

## 5. 요구사항 충족 체크

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

## 6. 쿼리 범위

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

## 7. 보너스 과제

보너스 과제도 함께 정리했습니다.

| 보너스 | 제출물 |
| --- | --- |
| 조인 1개를 두 방식으로 풀기 | `bonus.sql`의 BONUS 1-A, 1-B, 1-C |
| 데이터 정합성 깨뜨려 보기 | `bonus.sql`의 BONUS 2, `results/fk_error.txt`, `explain.md`의 FK 오류 예시 |
| 미니 리포트 만들기 | `bonus.sql`의 BONUS 3-1 ~ 3-3, `explain.md`의 핵심 지표 3개 |
