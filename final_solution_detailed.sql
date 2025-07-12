-- 방안 2: submission_seq + 파일별 제약사 확정 테이블

-- 1. 기존 edi_files 테이블에 submission_seq 컬럼 추가
ALTER TABLE edi_files ADD COLUMN submission_seq INTEGER DEFAULT 1;

-- 2. 새로운 테이블: edi_file_final_pharma (관리자 확정 제약사)
CREATE TABLE edi_file_final_pharma (
    id SERIAL PRIMARY KEY,
    edi_file_id BIGINT NOT NULL REFERENCES edi_files(id) ON DELETE CASCADE,
    company_id INTEGER NOT NULL REFERENCES pharmaceutical_companies(id),
    confirmed_by UUID NOT NULL REFERENCES members(id), -- 확정한 관리자
    confirmed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT, -- 관리자 메모
    
    -- 제약조건: 파일당 1개 제약사만 확정 가능
    UNIQUE(edi_file_id)
);

-- 3. 기존 데이터 migration
-- 기존 파일들의 submission_seq 설정
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

-- 4. 이용자용 뷰 (제출 순서별 그룹화)
CREATE OR REPLACE VIEW user_edi_submissions_view AS
SELECT 
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
    -- 제약사 개수 (이용자가 선택한 것, 중복 제거)
    COUNT(DISTINCT efc.company_id) as selected_company_count,
    -- 확정된 제약사 개수 (관리자가 확정한 것)
    COUNT(DISTINCT efp.company_id) as confirmed_company_count,
    -- 파일 목록
    JSON_AGG(jsonb_build_object(
        'id', grouped.id,
        'file_url', grouped.file_url,
        'file_name', grouped.file_name,
        'original_file_name', grouped.original_file_name,
        'file_size', grouped.file_size,
        'confirmed_pharma', efp.company_id -- 확정된 제약사 ID
    )) as files,
    -- 이용자가 선택한 제약사 목록
    JSON_AGG(DISTINCT jsonb_build_object(
        'id', pc.id,
        'company_name', pc.company_name
    )) FILTER (WHERE pc.id IS NOT NULL) as selected_companies,
    -- 관리자가 확정한 제약사 목록
    JSON_AGG(DISTINCT jsonb_build_object(
        'id', pc_final.id,
        'company_name', pc_final.company_name
    )) FILTER (WHERE pc_final.id IS NOT NULL) as confirmed_companies
FROM edi_files grouped
JOIN hospitals h ON grouped.hospital_id = h.id
LEFT JOIN edi_file_companies efc ON grouped.id = efc.edi_file_id
LEFT JOIN pharmaceutical_companies pc ON efc.company_id = pc.id
LEFT JOIN edi_file_final_pharma efp ON grouped.id = efp.edi_file_id
LEFT JOIN pharmaceutical_companies pc_final ON efp.company_id = pc_final.id
WHERE grouped.is_deleted = FALSE
GROUP BY settlement_month_id, member_id, hospital_id, submission_seq,
         h.hospital_name, h.business_registration_number, h.director_name;

-- 5. 관리자용 뷰 (파일별 상세 정보 + 제약사 확정 상태)
CREATE OR REPLACE VIEW admin_edi_file_review_view AS
SELECT 
    ef.id as file_id,
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
    ef.memo,
    ef.confirm,
    ef.submission_seq,
    ef.created_at,
    ef.created_by,
    mem_created.company_name as created_by_name,
    
    -- 이용자가 선택한 제약사들 (JSON)
    COALESCE(
        (SELECT JSON_AGG(jsonb_build_object(
            'id', pc.id,
            'company_name', pc.company_name
        ))
         FROM edi_file_companies efc 
         JOIN pharmaceutical_companies pc ON efc.company_id = pc.id
         WHERE efc.edi_file_id = ef.id), 
        '[]'::json
    ) as user_selected_companies,
    
    -- 관리자가 확정한 제약사 정보
    efp.company_id as confirmed_company_id,
    pc_final.company_name as confirmed_company_name,
    efp.confirmed_by as confirmed_by_id,
    mem_admin.company_name as confirmed_by_name,
    efp.confirmed_at,
    efp.notes as admin_notes,
    
    -- 확정 상태
    CASE 
        WHEN efp.company_id IS NOT NULL THEN '확정완료'
        ELSE '검토대기'
    END as review_status,
    
    -- 같은 제출 그룹의 파일 개수
    (SELECT COUNT(*) FROM edi_files ef2 
     WHERE ef2.settlement_month_id = ef.settlement_month_id
     AND ef2.member_id = ef.member_id
     AND ef2.hospital_id = ef.hospital_id
     AND ef2.submission_seq = ef.submission_seq
     AND ef2.is_deleted = FALSE) as group_file_count,
     
    -- 같은 제출 그룹에서 확정 완료된 파일 개수
    (SELECT COUNT(*) FROM edi_files ef2 
     JOIN edi_file_final_pharma efp2 ON ef2.id = efp2.edi_file_id
     WHERE ef2.settlement_month_id = ef.settlement_month_id
     AND ef2.member_id = ef.member_id
     AND ef2.hospital_id = ef.hospital_id
     AND ef2.submission_seq = ef.submission_seq
     AND ef2.is_deleted = FALSE) as group_confirmed_count
     
FROM edi_files ef
JOIN edi_months sm ON ef.settlement_month_id = sm.id
JOIN members mem ON ef.member_id = mem.id
JOIN hospitals h ON ef.hospital_id = h.id
LEFT JOIN members mem_created ON ef.created_by = mem_created.id
LEFT JOIN edi_file_final_pharma efp ON ef.id = efp.edi_file_id
LEFT JOIN pharmaceutical_companies pc_final ON efp.company_id = pc_final.id
LEFT JOIN members mem_admin ON efp.confirmed_by = mem_admin.id
WHERE ef.is_deleted = FALSE;

-- 6. 관리자 작업용 통계 뷰
CREATE OR REPLACE VIEW admin_edi_work_stats AS
SELECT 
    settlement_month_id,
    settlement_month,
    COUNT(*) as total_files,
    COUNT(confirmed_company_id) as confirmed_files,
    COUNT(*) - COUNT(confirmed_company_id) as pending_files,
    ROUND(COUNT(confirmed_company_id) * 100.0 / COUNT(*), 2) as completion_rate
FROM admin_edi_file_review_view
GROUP BY settlement_month_id, settlement_month
ORDER BY settlement_month_id DESC;

-- 7. 제출 순서 자동 증가 함수
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

-- 8. 관리자 제약사 확정 함수
CREATE OR REPLACE FUNCTION confirm_file_pharma(
    p_file_id BIGINT,
    p_company_id INTEGER,
    p_admin_id UUID,
    p_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    -- 기존 확정 정보 삭제 후 새로 입력
    DELETE FROM edi_file_final_pharma WHERE edi_file_id = p_file_id;
    
    INSERT INTO edi_file_final_pharma (
        edi_file_id, 
        company_id, 
        confirmed_by, 
        notes
    ) VALUES (
        p_file_id, 
        p_company_id, 
        p_admin_id, 
        p_notes
    );
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 인덱스 추가
CREATE INDEX idx_edi_files_submission_seq ON edi_files(settlement_month_id, member_id, hospital_id, submission_seq);
CREATE INDEX idx_edi_file_final_pharma_file_id ON edi_file_final_pharma(edi_file_id);
CREATE INDEX idx_edi_file_final_pharma_company_id ON edi_file_final_pharma(company_id);
CREATE INDEX idx_edi_file_final_pharma_confirmed_by ON edi_file_final_pharma(confirmed_by); 