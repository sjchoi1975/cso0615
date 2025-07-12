-- EDI 제출 단위 관리를 위한 새로운 테이블 구조 제안

-- 1. edi_submissions 테이블 (제출 단위 관리)
CREATE TABLE edi_submissions (
    id BIGSERIAL PRIMARY KEY,
    settlement_month_id INTEGER NOT NULL REFERENCES edi_months(id),
    member_id UUID NOT NULL REFERENCES members(id),
    hospital_id INTEGER NOT NULL REFERENCES hospitals(id),
    memo TEXT,
    confirm BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL DEFAULT auth.uid(),
    updated_at TIMESTAMPTZ,
    updated_by UUID,
    
    -- 제약조건: 같은 정산월-업체-거래처 조합은 1개만 허용
    UNIQUE(settlement_month_id, member_id, hospital_id)
);

-- 2. edi_submission_files 테이블 (제출 단위별 파일 관리)
CREATE TABLE edi_submission_files (
    id BIGSERIAL PRIMARY KEY,
    submission_id BIGINT NOT NULL REFERENCES edi_submissions(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    original_file_name TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL DEFAULT auth.uid()
);

-- 3. edi_submission_companies 테이블 (제출 단위별 제약사 관리)
CREATE TABLE edi_submission_companies (
    id SERIAL PRIMARY KEY,
    submission_id BIGINT NOT NULL REFERENCES edi_submissions(id) ON DELETE CASCADE,
    company_id INTEGER NOT NULL REFERENCES pharmaceutical_companies(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL DEFAULT auth.uid(),
    
    -- 제약조건: 같은 제출에 같은 제약사 중복 불가
    UNIQUE(submission_id, company_id)
);

-- 4. edi_file_pharma_mappings 테이블 (최종 파일-제약사 1:1 매핑)
CREATE TABLE edi_file_pharma_mappings (
    id BIGSERIAL PRIMARY KEY,
    submission_id BIGINT NOT NULL REFERENCES edi_submissions(id) ON DELETE CASCADE,
    file_id BIGINT NOT NULL REFERENCES edi_submission_files(id) ON DELETE CASCADE,
    company_id INTEGER NOT NULL REFERENCES pharmaceutical_companies(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL DEFAULT auth.uid(),
    updated_at TIMESTAMPTZ,
    updated_by UUID,
    
    -- 제약조건: 파일-제약사 1:1 관계 보장
    UNIQUE(file_id, company_id)
);

-- 5. 관리자용 뷰 (파일-제약사 1:1 기준)
CREATE OR REPLACE VIEW admin_edi_final_view AS
SELECT 
    m.id as mapping_id,
    s.id as submission_id,
    s.settlement_month_id,
    sm.settlement_month,
    s.member_id,
    mem.company_name,
    mem.biz_no as member_biz_no,
    mem.ceo_name as member_ceo_name,
    s.hospital_id,
    h.hospital_name,
    h.business_registration_number as hospital_biz_no,
    h.director_name,
    h.address,
    f.id as file_id,
    f.file_url,
    f.file_name,
    f.original_file_name,
    f.file_size,
    pc.id as company_id,
    pc.company_name as pharma_name,
    s.memo,
    s.confirm,
    s.is_deleted,
    s.created_at,
    s.created_by,
    mem_created.company_name as created_by_name,
    s.updated_at,
    s.updated_by,
    mem_updated.company_name as updated_by_name
FROM edi_file_pharma_mappings m
JOIN edi_submissions s ON m.submission_id = s.id
JOIN edi_months sm ON s.settlement_month_id = sm.id
JOIN members mem ON s.member_id = mem.id
JOIN hospitals h ON s.hospital_id = h.id
JOIN edi_submission_files f ON m.file_id = f.id
JOIN pharmaceutical_companies pc ON m.company_id = pc.id
LEFT JOIN members mem_created ON s.created_by = mem_created.id
LEFT JOIN members mem_updated ON s.updated_by = mem_updated.id
WHERE s.is_deleted = FALSE;

-- 6. 이용자용 뷰 (제출 단위 기준)
CREATE OR REPLACE VIEW user_edi_submissions_view AS
SELECT 
    s.id,
    s.settlement_month_id,
    sm.settlement_month,
    s.member_id,
    s.hospital_id,
    h.hospital_name,
    h.business_registration_number as hospital_biz_no,
    h.director_name,
    s.memo,
    s.confirm,
    s.created_at,
    s.updated_at,
    -- 파일 개수
    COUNT(DISTINCT f.id) as file_count,
    -- 제약사 개수
    COUNT(DISTINCT sc.company_id) as company_count,
    -- 파일 목록 (JSON)
    JSON_AGG(DISTINCT jsonb_build_object(
        'id', f.id,
        'file_url', f.file_url,
        'file_name', f.file_name,
        'original_file_name', f.original_file_name,
        'file_size', f.file_size
    )) as files,
    -- 제약사 목록 (JSON)
    JSON_AGG(DISTINCT jsonb_build_object(
        'id', pc.id,
        'company_name', pc.company_name
    )) as companies
FROM edi_submissions s
JOIN edi_months sm ON s.settlement_month_id = sm.id
JOIN hospitals h ON s.hospital_id = h.id
LEFT JOIN edi_submission_files f ON s.id = f.submission_id
LEFT JOIN edi_submission_companies sc ON s.id = sc.submission_id
LEFT JOIN pharmaceutical_companies pc ON sc.company_id = pc.id
WHERE s.is_deleted = FALSE
GROUP BY s.id, sm.settlement_month, h.hospital_name, h.business_registration_number, h.director_name;

-- 인덱스 추가
CREATE INDEX idx_edi_submissions_settlement_member_hospital ON edi_submissions(settlement_month_id, member_id, hospital_id);
CREATE INDEX idx_edi_submission_files_submission_id ON edi_submission_files(submission_id);
CREATE INDEX idx_edi_submission_companies_submission_id ON edi_submission_companies(submission_id);
CREATE INDEX idx_edi_file_pharma_mappings_submission_id ON edi_file_pharma_mappings(submission_id);
CREATE INDEX idx_edi_file_pharma_mappings_file_company ON edi_file_pharma_mappings(file_id, company_id); 