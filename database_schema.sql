-- 제약사 테이블
CREATE TABLE IF NOT EXISTS pharmaceutical_companies (
  id SERIAL PRIMARY KEY,
  company_name VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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
ALTER TABLE pharmaceutical_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospital_member_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE filtering_requests ENABLE ROW LEVEL SECURITY;

-- 제약사 테이블 정책 (관리자만 CRUD 가능)
CREATE POLICY "Admin can manage pharmaceutical companies" ON pharmaceutical_companies
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM members 
      WHERE id_email = auth.jwt() ->> 'email' 
      AND role = 'admin'
    )
  );

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

COMMIT;

--
-- PostgreSQL database dump complete
-- 