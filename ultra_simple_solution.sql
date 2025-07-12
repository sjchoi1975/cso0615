-- 가장 심플한 방법: 제출 순서 번호만 추가

-- 1. edi_files 테이블에 submission_seq 컬럼 추가
ALTER TABLE edi_files ADD COLUMN submission_seq INTEGER DEFAULT 1;

-- 2. 기존 데이터에 submission_seq 설정
-- 같은 정산월-업체-거래처별로 등록 시간 순서대로 번호 부여
UPDATE edi_files 
SET submission_seq = seq.row_num
FROM (
    SELECT 
        id,
        ROW_NUMBER() OVER (
            PARTITION BY settlement_month_id, member_id, hospital_id 
            ORDER BY created_at
        ) as row_num
    FROM edi_files 
    WHERE is_deleted = FALSE
) seq
WHERE edi_files.id = seq.id;

-- 3. 이용자용 뷰 (제출 순서별 그룹화)
CREATE OR REPLACE VIEW user_edi_submissions_simple AS
SELECT 
    -- 가상의 submission_id 생성 (정산월-업체-거래처-순서)
    CONCAT(settlement_month_id, '-', member_id, '-', hospital_id, '-', submission_seq) as submission_id,
    settlement_month_id,
    member_id,
    hospital_id,
    submission_seq,
    h.hospital_name,
    h.business_registration_number as hospital_biz_no,
    h.director_name,
    -- 같은 순서의 첫 번째 파일 정보 사용
    (SELECT memo FROM edi_files ef2 
     WHERE ef2.settlement_month_id = grouped.settlement_month_id
     AND ef2.member_id = grouped.member_id
     AND ef2.hospital_id = grouped.hospital_id
     AND ef2.submission_seq = grouped.submission_seq
     AND ef2.is_deleted = FALSE
     LIMIT 1) as memo,
    -- 같은 순서의 모든 파일이 확인되었는지 체크
    BOOL_AND(confirm) as confirm,
    MIN(created_at) as created_at,
    MAX(updated_at) as updated_at,
    COUNT(*) as file_count,
    -- 제약사 개수 (중복 제거)
    COUNT(DISTINCT efc.company_id) as company_count,
    -- 파일 목록
    JSON_AGG(jsonb_build_object(
        'id', grouped.id,
        'file_url', grouped.file_url,
        'file_name', grouped.file_name,
        'original_file_name', grouped.original_file_name,
        'file_size', grouped.file_size
    )) as files,
    -- 제약사 목록 (중복 제거)
    JSON_AGG(DISTINCT jsonb_build_object(
        'id', pc.id,
        'company_name', pc.company_name
    )) as companies
FROM edi_files grouped
JOIN hospitals h ON grouped.hospital_id = h.id
LEFT JOIN edi_file_companies efc ON grouped.id = efc.edi_file_id
LEFT JOIN pharmaceutical_companies pc ON efc.company_id = pc.id
WHERE grouped.is_deleted = FALSE
GROUP BY settlement_month_id, member_id, hospital_id, submission_seq,
         h.hospital_name, h.business_registration_number, h.director_name;

-- 4. 관리자용 뷰는 기존과 동일하되 submission_seq 추가
CREATE OR REPLACE VIEW admin_edi_list_view_v2 AS
SELECT 
    ef.id,
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
    ef.file_size,
    ef.file_name,
    ef.original_file_name,
    ef.file_url,
    ef.memo,
    ef.is_deleted,
    ef.confirm,
    ef.created_at,
    ef.created_by,
    mem_created.company_name as created_by_name,
    ef.updated_at,
    ef.updated_by,
    mem_updated.company_name as updated_by_name,
    ef.submission_seq,
    -- 같은 제출 순서의 파일 개수
    (SELECT COUNT(*) FROM edi_files ef2 
     WHERE ef2.settlement_month_id = ef.settlement_month_id
     AND ef2.member_id = ef.member_id
     AND ef2.hospital_id = ef.hospital_id
     AND ef2.submission_seq = ef.submission_seq
     AND ef2.is_deleted = FALSE) as file_count,
    -- 제약사 목록 (JSON)
    COALESCE(
        (SELECT JSON_AGG(jsonb_build_object(
            'id', pc.id,
            'company_name', pc.company_name
        ))
         FROM edi_file_companies efc 
         JOIN pharmaceutical_companies pc ON efc.company_id = pc.id
         WHERE efc.edi_file_id = ef.id), 
        '[]'::json
    ) as pharmaceutical_companies
FROM edi_files ef
JOIN edi_months sm ON ef.settlement_month_id = sm.id
JOIN members mem ON ef.member_id = mem.id
JOIN hospitals h ON ef.hospital_id = h.id
LEFT JOIN members mem_created ON ef.created_by = mem_created.id
LEFT JOIN members mem_updated ON ef.updated_by = mem_updated.id
WHERE ef.is_deleted = FALSE;

-- 5. 새로운 제출 시 submission_seq 자동 증가 함수
CREATE OR REPLACE FUNCTION get_next_submission_seq(
    p_settlement_month_id INTEGER,
    p_member_id UUID,
    p_hospital_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    next_seq INTEGER;
BEGIN
    SELECT COALESCE(MAX(submission_seq), 0) + 1
    INTO next_seq
    FROM edi_files
    WHERE settlement_month_id = p_settlement_month_id
    AND member_id = p_member_id
    AND hospital_id = p_hospital_id
    AND is_deleted = FALSE;
    
    RETURN next_seq;
END;
$$ LANGUAGE plpgsql; 