-- 기존 데이터를 새로운 테이블 구조로 마이그레이션하는 스크립트

-- 1. 새 테이블들 생성 (database_schema_proposal.sql 실행 후)

-- 2. 기존 edi_files 데이터를 새 구조로 마이그레이션
INSERT INTO edi_submissions (
    settlement_month_id,
    member_id,
    hospital_id,
    memo,
    confirm,
    is_deleted,
    created_at,
    created_by,
    updated_at,
    updated_by
)
SELECT DISTINCT
    settlement_month_id,
    member_id,
    hospital_id,
    memo,
    confirm,
    is_deleted,
    MIN(created_at) as created_at,
    created_by,
    MAX(updated_at) as updated_at,
    updated_by
FROM edi_files
WHERE is_deleted = FALSE
GROUP BY settlement_month_id, member_id, hospital_id, memo, confirm, is_deleted, created_by, updated_by
ON CONFLICT (settlement_month_id, member_id, hospital_id) DO NOTHING;

-- 3. 파일 데이터 마이그레이션
INSERT INTO edi_submission_files (
    submission_id,
    file_url,
    file_name,
    original_file_name,
    file_size,
    created_at,
    created_by
)
SELECT 
    s.id as submission_id,
    ef.file_url,
    ef.file_name,
    ef.original_file_name,
    ef.file_size,
    ef.created_at,
    ef.created_by
FROM edi_files ef
JOIN edi_submissions s ON (
    ef.settlement_month_id = s.settlement_month_id AND
    ef.member_id = s.member_id AND
    ef.hospital_id = s.hospital_id
)
WHERE ef.is_deleted = FALSE;

-- 4. 제약사 데이터 마이그레이션
INSERT INTO edi_submission_companies (
    submission_id,
    company_id,
    created_at,
    created_by
)
SELECT DISTINCT
    s.id as submission_id,
    efc.company_id,
    MIN(efc.created_at) as created_at,
    efc.created_by
FROM edi_file_companies efc
JOIN edi_files ef ON efc.edi_file_id = ef.id
JOIN edi_submissions s ON (
    ef.settlement_month_id = s.settlement_month_id AND
    ef.member_id = s.member_id AND
    ef.hospital_id = s.hospital_id
)
WHERE ef.is_deleted = FALSE
GROUP BY s.id, efc.company_id, efc.created_by
ON CONFLICT (submission_id, company_id) DO NOTHING;

-- 5. 초기 파일-제약사 매핑 생성 (관리자가 나중에 수정할 수 있도록)
-- 모든 파일에 모든 제약사를 매핑 (관리자가 나중에 정리)
INSERT INTO edi_file_pharma_mappings (
    submission_id,
    file_id,
    company_id,
    created_at,
    created_by
)
SELECT 
    s.id as submission_id,
    sf.id as file_id,
    sc.company_id,
    NOW() as created_at,
    s.created_by
FROM edi_submissions s
JOIN edi_submission_files sf ON s.id = sf.submission_id
JOIN edi_submission_companies sc ON s.id = sc.submission_id
ON CONFLICT (file_id, company_id) DO NOTHING;

-- 6. 데이터 검증 쿼리
SELECT 
    '기존 edi_files 개수' as description,
    COUNT(*) as count
FROM edi_files 
WHERE is_deleted = FALSE
UNION ALL
SELECT 
    '새로운 submissions 개수' as description,
    COUNT(*) as count
FROM edi_submissions
UNION ALL
SELECT 
    '새로운 files 개수' as description,
    COUNT(*) as count
FROM edi_submission_files
UNION ALL
SELECT 
    '새로운 companies 개수' as description,
    COUNT(*) as count
FROM edi_submission_companies
UNION ALL
SELECT 
    '새로운 mappings 개수' as description,
    COUNT(*) as count
FROM edi_file_pharma_mappings;

-- 7. 기존 테이블 백업 (필요시)
-- CREATE TABLE edi_files_backup AS SELECT * FROM edi_files;
-- CREATE TABLE edi_file_companies_backup AS SELECT * FROM edi_file_companies; 