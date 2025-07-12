-- 심플한 해결방안: 기존 테이블에 submission_group_id만 추가

-- 1. edi_files 테이블에 submission_group_id 컬럼 추가
ALTER TABLE edi_files ADD COLUMN submission_group_id UUID;

-- 2. 기존 데이터에 submission_group_id 설정
-- 같은 정산월-업체-거래처-등록시간(10분 내)을 같은 그룹으로 묶기
UPDATE edi_files 
SET submission_group_id = uuid_generate_v4()
WHERE submission_group_id IS NULL;

-- 실제로는 이렇게 처리:
-- 같은 시간대(10분 내)에 등록된 같은 업체-거래처 파일들을 같은 그룹으로 묶기
WITH grouped_files AS (
    SELECT 
        id,
        settlement_month_id,
        member_id,
        hospital_id,
        created_at,
        -- 10분 단위로 그룹화
        DATE_TRUNC('minute', created_at) + 
        INTERVAL '10 minutes' * FLOOR(EXTRACT(MINUTE FROM created_at) / 10) as time_group,
        ROW_NUMBER() OVER (
            PARTITION BY settlement_month_id, member_id, hospital_id,
            DATE_TRUNC('minute', created_at) + 
            INTERVAL '10 minutes' * FLOOR(EXTRACT(MINUTE FROM created_at) / 10)
            ORDER BY created_at
        ) as rn
    FROM edi_files 
    WHERE submission_group_id IS NULL
)
UPDATE edi_files 
SET submission_group_id = (
    SELECT uuid_generate_v4() 
    FROM grouped_files g 
    WHERE g.id = edi_files.id AND g.rn = 1
)
WHERE id IN (SELECT id FROM grouped_files WHERE rn = 1);

-- 나머지 파일들은 첫 번째 파일의 group_id를 사용
UPDATE edi_files 
SET submission_group_id = (
    SELECT DISTINCT ef2.submission_group_id
    FROM edi_files ef2
    WHERE ef2.settlement_month_id = edi_files.settlement_month_id
    AND ef2.member_id = edi_files.member_id
    AND ef2.hospital_id = edi_files.hospital_id
    AND ef2.submission_group_id IS NOT NULL
    AND ABS(EXTRACT(EPOCH FROM (ef2.created_at - edi_files.created_at))) <= 600 -- 10분 이내
    LIMIT 1
)
WHERE submission_group_id IS NULL;

-- 3. 이용자용 뷰 (제출 그룹 기준)
CREATE OR REPLACE VIEW user_edi_submissions_view AS
SELECT 
    submission_group_id as id,
    settlement_month_id,
    member_id,
    hospital_id,
    h.hospital_name,
    h.business_registration_number as hospital_biz_no,
    h.director_name,
    -- 그룹의 첫 번째 파일 정보 사용
    (SELECT memo FROM edi_files ef WHERE ef.submission_group_id = grouped.submission_group_id LIMIT 1) as memo,
    -- 그룹 내 모든 파일이 확인되었는지 체크
    BOOL_AND(confirm) as confirm,
    MIN(created_at) as created_at,
    MAX(updated_at) as updated_at,
    COUNT(*) as file_count,
    -- 제약사 개수 (중복 제거)
    (SELECT COUNT(DISTINCT company_id) 
     FROM edi_file_companies efc 
     JOIN edi_files ef ON efc.edi_file_id = ef.id 
     WHERE ef.submission_group_id = grouped.submission_group_id) as company_count,
    -- 파일 목록
    JSON_AGG(jsonb_build_object(
        'id', id,
        'file_url', file_url,
        'file_name', file_name,
        'original_file_name', original_file_name,
        'file_size', file_size
    )) as files,
    -- 제약사 목록 (중복 제거)
    (SELECT JSON_AGG(DISTINCT jsonb_build_object(
        'id', pc.id,
        'company_name', pc.company_name
    ))
     FROM edi_file_companies efc 
     JOIN edi_files ef ON efc.edi_file_id = ef.id 
     JOIN pharmaceutical_companies pc ON efc.company_id = pc.id
     WHERE ef.submission_group_id = grouped.submission_group_id) as companies
FROM edi_files grouped
JOIN hospitals h ON grouped.hospital_id = h.id
WHERE grouped.is_deleted = FALSE
GROUP BY submission_group_id, settlement_month_id, member_id, hospital_id, 
         h.hospital_name, h.business_registration_number, h.director_name;

-- 4. 관리자용 뷰 (파일별 + 제약사별)
CREATE OR REPLACE VIEW admin_edi_final_view AS
SELECT 
    ef.id as file_id,
    ef.submission_group_id,
    ef.settlement_month_id,
    sm.settlement_month,
    ef.member_id,
    mem.company_name,
    mem.biz_no as member_biz_no,
    mem.ceo_name as member_ceo_name,
    ef.hospital_id,
    h.hospital_name,
    h.business_registration_number as hospital_biz_no,
    h.director_name,
    h.address,
    ef.file_url,
    ef.file_name,
    ef.original_file_name,
    ef.file_size,
    pc.id as company_id,
    pc.company_name as pharma_name,
    ef.memo,
    ef.confirm,
    ef.is_deleted,
    ef.created_at,
    ef.created_by,
    mem_created.company_name as created_by_name,
    ef.updated_at,
    ef.updated_by,
    mem_updated.company_name as updated_by_name,
    -- 같은 제출 그룹 내 파일 개수
    (SELECT COUNT(*) FROM edi_files ef2 WHERE ef2.submission_group_id = ef.submission_group_id) as group_file_count
FROM edi_files ef
JOIN edi_months sm ON ef.settlement_month_id = sm.id
JOIN members mem ON ef.member_id = mem.id
JOIN hospitals h ON ef.hospital_id = h.id
JOIN edi_file_companies efc ON ef.id = efc.edi_file_id
JOIN pharmaceutical_companies pc ON efc.company_id = pc.id
LEFT JOIN members mem_created ON ef.created_by = mem_created.id
LEFT JOIN members mem_updated ON ef.updated_by = mem_updated.id
WHERE ef.is_deleted = FALSE;

-- 5. 제출 그룹별 통계 뷰
CREATE OR REPLACE VIEW edi_submission_stats AS
SELECT 
    submission_group_id,
    settlement_month_id,
    member_id,
    hospital_id,
    COUNT(*) as file_count,
    COUNT(DISTINCT efc.company_id) as company_count,
    MIN(ef.created_at) as first_submitted_at,
    MAX(ef.updated_at) as last_updated_at,
    BOOL_AND(ef.confirm) as all_confirmed
FROM edi_files ef
LEFT JOIN edi_file_companies efc ON ef.id = efc.edi_file_id
WHERE ef.is_deleted = FALSE
GROUP BY submission_group_id, settlement_month_id, member_id, hospital_id; 