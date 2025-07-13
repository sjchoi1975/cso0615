# Supabase에 CSV 데이터 업로드 방법

## 방법 1: Supabase 대시보드 사용

1. **Supabase 대시보드 접속**
   - https://app.supabase.com 접속
   - 프로젝트 선택

2. **Table Editor로 이동**
   - 왼쪽 메뉴에서 "Table Editor" 클릭
   - `products_mfds` 테이블 선택

3. **CSV 파일 업로드**
   - "Insert" 버튼 클릭
   - "Upload CSV" 옵션 선택
   - CSV 파일 업로드
   - 컬럼 매핑 확인 (`insurance_code` → `insurance_code`, `detail_url` → `detail_url`)

## 방법 2: SQL Editor 사용

1. **SQL Editor로 이동**
   - 왼쪽 메뉴에서 "SQL Editor" 클릭

2. **SQL 실행**
   - 생성된 SQL 파일 내용을 복사하여 붙여넣기
   - "Run" 버튼 클릭

## 방법 3: 배치 처리 (대용량 데이터용)

```sql
-- 임시 테이블 생성
CREATE TEMP TABLE temp_products_mfds (
    insurance_code VARCHAR(20),
    detail_url TEXT
);

-- CSV 데이터 복사 (PostgreSQL COPY 명령 사용)
COPY temp_products_mfds FROM '/path/to/products_mfds.csv' 
WITH (FORMAT csv, HEADER true);

-- 중복 제거 후 실제 테이블에 INSERT
INSERT INTO products_mfds (insurance_code, detail_url)
SELECT DISTINCT insurance_code, detail_url 
FROM temp_products_mfds
WHERE insurance_code IS NOT NULL 
  AND detail_url IS NOT NULL
ON CONFLICT (insurance_code) DO UPDATE SET 
    detail_url = EXCLUDED.detail_url,
    updated_at = NOW();
```

## 주의사항

- 중복된 `insurance_code`가 있으면 오류가 발생할 수 있습니다
- URL에 작은따옴표(')가 있으면 이스케이프 처리가 필요합니다
- 대용량 데이터는 배치 단위로 나누어 처리하는 것이 좋습니다 