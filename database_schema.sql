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