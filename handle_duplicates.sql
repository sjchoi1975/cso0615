-- 중복 데이터 처리 방법

-- 방법 1: 기존 데이터 삭제 후 새로 삽입
TRUNCATE TABLE products_mfds;

-- 방법 2: ON CONFLICT 사용 (중복 시 업데이트)
INSERT INTO products_mfds (insurance_code, detail_url) 
VALUES 
('64804410', 'https://nedrug.mfds.go.kr/pbp/CCBBB01/getItemDetailCache?cacheSeq=199201988'),
('67300600', 'https://nedrug.mfds.go.kr/pbp/CCBBB01/getItemDetailCache?cacheSeq=201907917')
-- ... 나머지 데이터
ON CONFLICT (insurance_code) 
DO UPDATE SET 
    detail_url = EXCLUDED.detail_url,
    updated_at = NOW();

-- 방법 3: 중복 확인 쿼리
SELECT insurance_code, COUNT(*) as count
FROM (
    -- 여기에 CSV 데이터를 VALUES로 넣어서 확인
    VALUES 
    ('64804410', 'url1'),
    ('64804410', 'url2'),  -- 중복 예시
    ('67300600', 'url3')
) AS temp_data(insurance_code, detail_url)
GROUP BY insurance_code
HAVING COUNT(*) > 1;

-- 방법 4: 임시 테이블 사용
CREATE TEMP TABLE temp_products_mfds (
    insurance_code VARCHAR(20),
    detail_url TEXT
);

-- CSV 데이터를 임시 테이블에 INSERT (중복 허용)
-- INSERT INTO temp_products_mfds VALUES ...

-- 중복 제거 후 실제 테이블에 INSERT
INSERT INTO products_mfds (insurance_code, detail_url)
SELECT DISTINCT ON (insurance_code) insurance_code, detail_url 
FROM temp_products_mfds
WHERE insurance_code IS NOT NULL 
  AND detail_url IS NOT NULL
ON CONFLICT (insurance_code) DO NOTHING; 