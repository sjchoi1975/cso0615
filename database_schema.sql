-- 제약사 테이블
CREATE TABLE pharmaceutical_companies (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    filtering_status VARCHAR(20) DEFAULT 'inactive',
    edi_status VARCHAR(20) DEFAULT 'inactive',
    filtering_comment TEXT,
    edi_comment TEXT
);

-- Add RLS policy
ALTER TABLE pharmaceutical_companies ENABLE ROW LEVEL SECURITY;

-- Allow read access for authenticated users
CREATE POLICY "Allow read access for authenticated users"
ON pharmaceutical_companies
FOR SELECT
TO authenticated
USING (true);

-- Allow all access for service_role
CREATE POLICY "Allow all access for service_role"
ON pharmaceutical_companies
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 병의원 테이블
CREATE TABLE IF NOT EXISTS hospitals (
  id SERIAL PRIMARY KEY,
  hospital_name VARCHAR(255) NOT NULL,
  business_registration_number VARCHAR(20) NOT NULL UNIQUE,
  director_name VARCHAR(100) NOT NULL,
  address TEXT NOT NULL,
  business_license_file VARCHAR(500), -- 사업자등록증 파일 경로 (향후 확장)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 병원-회원 매칭 테이블 (member_id를 UUID로 수정)
CREATE TABLE IF NOT EXISTS hospital_member_mappings (
  id SERIAL PRIMARY KEY,
  hospital_id INTEGER REFERENCES hospitals(id) ON DELETE CASCADE,
  member_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(hospital_id, member_id)
);

-- 필터링 요청 테이블 (member_id를 UUID로 수정)
CREATE TABLE IF NOT EXISTS filtering_requests (
  id SERIAL PRIMARY KEY,
  member_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  hospital_id INTEGER REFERENCES hospitals(id) ON DELETE CASCADE,
  pharmaceutical_company_id INTEGER REFERENCES pharmaceutical_companies(id) ON DELETE CASCADE,
  filter_type VARCHAR(20) NOT NULL CHECK (filter_type IN ('new', 'transfer')), -- 신규, 이관
  user_remarks TEXT, -- 이용자가 관리자에게 코멘트
  request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(20) NOT NULL DEFAULT 'checking' CHECK (status IN ('checking', 'approved', 'rejected', 'pending', 'cancelled')), -- 확인중, 승인, 반려, 대기, 취소
  admin_remarks TEXT, -- 관리자가 회원에게 전달사항
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_filtering_requests_member_id ON filtering_requests(member_id);
CREATE INDEX IF NOT EXISTS idx_filtering_requests_hospital_id ON filtering_requests(hospital_id);
CREATE INDEX IF NOT EXISTS idx_filtering_requests_status ON filtering_requests(status);
CREATE INDEX IF NOT EXISTS idx_filtering_requests_request_date ON filtering_requests(request_date);

-- RLS (Row Level Security) 설정
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospital_member_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE filtering_requests ENABLE ROW LEVEL SECURITY;

-- 병의원 테이블 정책 (모든 인증된 사용자 조회 가능, 관리자만 생성/수정)
CREATE POLICY "Users can view hospitals" ON hospitals
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admin can manage hospitals" ON hospitals
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM members 
      WHERE id_email = auth.jwt() ->> 'email' 
      AND role = 'admin'
    )
  );

-- 병원-회원 매칭 테이블 정책
CREATE POLICY "Users can view their hospital mappings" ON hospital_member_mappings
  FOR SELECT USING (member_id = auth.uid());

CREATE POLICY "Users can create their hospital mappings" ON hospital_member_mappings
  FOR INSERT WITH CHECK (member_id = auth.uid());

-- 필터링 요청 테이블 정책
CREATE POLICY "Users can view their filtering requests" ON filtering_requests
  FOR SELECT USING (member_id = auth.uid());

CREATE POLICY "Users can create filtering requests" ON filtering_requests
  FOR INSERT WITH CHECK (member_id = auth.uid());

CREATE POLICY "Users can update their filtering requests" ON filtering_requests
  FOR UPDATE USING (member_id = auth.uid());

-- 관리자는 모든 필터링 요청 조회/수정 가능
CREATE POLICY "Admin can manage all filtering requests" ON filtering_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM members 
      WHERE id_email = auth.jwt() ->> 'email' 
      AND role = 'admin'
    )
  );

-- 샘플 제약사 데이터 (10개)
INSERT INTO pharmaceutical_companies (company_name) VALUES
('한국제약'),
('대한제약'),
('서울제약'),
('부산제약'),
('인천제약'),
('대구제약'),
('광주제약'),
('대전제약'),
('울산제약'),
('세종제약')
ON CONFLICT (company_name) DO NOTHING;

-- EDI 파일 테이블
CREATE TABLE edi_files (
  id SERIAL PRIMARY KEY,
  settlement_month VARCHAR(7) NOT NULL, -- 제출월 (정산월)
  company_id INTEGER REFERENCES companies(id) NOT NULL, -- 제출자 (업체)
  user_id UUID REFERENCES auth.users(id) NOT NULL, -- 회원 id
  client_id INTEGER REFERENCES clients(id) NOT NULL, -- 병의원id
  file_url TEXT NOT NULL, -- 파일url
  file_name TEXT NOT NULL, -- 원본 파일명
  file_size INTEGER, -- 파일 크기
  is_deleted BOOLEAN DEFAULT FALSE, -- 삭제여부 (소프트 삭제)
  confirm BOOLEAN DEFAULT FALSE, -- 제약사 확인 여부
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 등록일자
  created_by UUID REFERENCES auth.users(id), -- 등록자
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 수정일자
  updated_by UUID REFERENCES auth.users(id), -- 수정자
  UNIQUE(settlement_month, company_id, client_id, is_deleted)
);

-- RLS 정책
ALTER TABLE edi_files ENABLE ROW LEVEL SECURITY;

-- 관리자는 모든 EDI 파일 조회 가능
CREATE POLICY "관리자는 모든 EDI 파일 조회" ON edi_files
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM companies c 
      WHERE c.id = edi_files.company_id 
      AND c.user_id = auth.uid() 
      AND c.role = 'admin'
    )
  );

-- 사용자는 자신의 회사 EDI 파일만 조회 가능
CREATE POLICY "사용자는 자신의 회사 EDI 파일 조회" ON edi_files
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM companies c 
      WHERE c.id = edi_files.company_id 
      AND c.user_id = auth.uid()
    )
  );

-- 사용자는 자신의 회사 EDI 파일만 삽입 가능
CREATE POLICY "사용자는 자신의 회사 EDI 파일 삽입" ON edi_files
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM companies c 
      WHERE c.id = edi_files.company_id 
      AND c.user_id = auth.uid()
    )
  );

-- 사용자는 자신의 회사 EDI 파일만 수정 가능
CREATE POLICY "사용자는 자신의 회사 EDI 파일 수정" ON edi_files
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM companies c 
      WHERE c.id = edi_files.company_id 
      AND c.user_id = auth.uid()
    )
  );

-- 사용자는 자신의 회사 EDI 파일만 삭제 가능
CREATE POLICY "사용자는 자신의 회사 EDI 파일 삭제" ON edi_files
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM companies c 
      WHERE c.id = edi_files.company_id 
      AND c.user_id = auth.uid()
    )
  );

-- EDI 파일-제약사 매핑 테이블
CREATE TABLE edi_file_companies (
    id SERIAL PRIMARY KEY,
    edi_file_id INTEGER REFERENCES edi_files(id) ON DELETE CASCADE,
    company_id INTEGER REFERENCES pharmaceutical_companies(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id),
    UNIQUE(edi_file_id, company_id)
);

-- RLS 정책 설정
ALTER TABLE edi_file_companies ENABLE ROW LEVEL SECURITY;

-- 관리자는 모든 매핑 조회/수정 가능
CREATE POLICY "관리자는 모든 매핑 관리" ON edi_file_companies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM members m
            WHERE m.id = auth.uid()
            AND m.role = 'admin'
        )
    );

-- 사용자는 자신의 회사 EDI 파일의 매핑만 조회/수정 가능
CREATE POLICY "사용자는 자신의 매핑 관리" ON edi_file_companies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM edi_files ef
            WHERE ef.id = edi_file_companies.edi_file_id
            AND ef.member_id = auth.uid()
        )
    );

-- Filtering requests distinct options functions
CREATE OR REPLACE FUNCTION get_distinct_request_members()
RETURNS TABLE(uid uuid, company_name text) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT m.uid, m.company_name
  FROM filtering_requests fr
  JOIN members m ON fr.member_id = m.uid
  ORDER BY m.company_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_distinct_request_hospitals()
RETURNS TABLE(id int, hospital_name text) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT h.id, h.hospital_name
  FROM filtering_requests fr
  JOIN hospitals h ON fr.hospital_id = h.id
  ORDER BY h.hospital_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_distinct_request_pharmas()
RETURNS TABLE(id int, company_name text) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT pc.id, pc.company_name
  FROM filtering_requests fr
  JOIN pharmaceutical_companies pc ON fr.pharmaceutical_company_id = pc.id
  ORDER BY pc.company_name;
END;
$$ LANGUAGE plpgsql;

-- 제약사 테이블에 새로운 컬럼 추가
ALTER TABLE pharmaceutical_companies
  ADD COLUMN IF NOT EXISTS filtering_status VARCHAR(20) DEFAULT 'inactive',
  ADD COLUMN IF NOT EXISTS edi_status VARCHAR(20) DEFAULT 'inactive',
  ADD COLUMN IF NOT EXISTS filtering_comment TEXT,
  ADD COLUMN IF NOT EXISTS edi_comment TEXT;

-- 기존 status 컬럼의 값을 filtering_status와 edi_status로 복사
UPDATE pharmaceutical_companies
SET filtering_status = status,
    edi_status = status
WHERE status IS NOT NULL;

-- 기존 status 컬럼 삭제 (선택사항)
-- ALTER TABLE pharmaceutical_companies DROP COLUMN IF EXISTS status;

-- 1. 뷰 삭제
DROP VIEW IF EXISTS admin_edi_list_view;

-- 3. 새로운 뷰 생성
-- EDI 파일 목록 뷰 생성
CREATE OR REPLACE VIEW admin_edi_list_view AS
WITH formatted_settlement_month AS (
    SELECT 
        id,
        CASE 
            WHEN settlement_month ~ '^\d{4}-\d{2}$' THEN settlement_month
            WHEN settlement_month ~ '^\d{6}$' THEN 
                substring(settlement_month, 1, 4) || '-' || substring(settlement_month, 5, 2)
            ELSE settlement_month
        END as settlement_month
    FROM edi_months
),
file_counts AS (
    SELECT 
        settlement_month_id,
        member_id,
        hospital_id,
        COUNT(*) as file_count
    FROM edi_files
    WHERE is_deleted = false
    GROUP BY settlement_month_id, member_id, hospital_id
)
SELECT 
    ef.id,
    ef.settlement_month_id,
    em.settlement_month,
    ef.member_id,
    m.company_name,
    m.biz_no as member_biz_no,
    m.ceo_name as member_ceo_name,
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
    cb.company_name as created_by_name,
    ef.updated_at,
    ef.updated_by,
    ub.company_name as updated_by_name,
    fc.file_count,
    (
        SELECT json_agg(json_build_object(
            'id', pc.id,
            'company_name', pc.company_name
        ))
        FROM edi_file_companies efc
        JOIN pharmaceutical_companies pc ON pc.id = efc.company_id
        WHERE efc.edi_file_id = ef.id
    ) as pharmaceutical_companies
FROM 
    edi_files ef
    LEFT JOIN formatted_settlement_month em ON em.id = ef.settlement_month_id
    LEFT JOIN members m ON m.id = ef.member_id
    LEFT JOIN hospitals h ON h.id = ef.hospital_id
    LEFT JOIN members cb ON cb.id = ef.created_by
    LEFT JOIN members ub ON ub.id = ef.updated_by
    LEFT JOIN file_counts fc ON fc.settlement_month_id = ef.settlement_month_id 
        AND fc.member_id = ef.member_id 
        AND fc.hospital_id = ef.hospital_id;

COMMIT;

--
-- PostgreSQL database dump complete
-- 