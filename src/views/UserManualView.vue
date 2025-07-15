<template>
  <div class="manual-container">
    <!-- 헤더 -->
    <div class="manual-header">
      <h1>CSO 운영관리 시스템</h1>
      <h2>이용자용 기능 소개서 및 매뉴얼</h2>
    </div>

    <!-- 목차 -->
    <div class="manual-toc">
      <h3>📋 목차</h3>
      <ul>
        <li><a href="#overview">시스템 개요</a></li>
        <li><a href="#signup">회원가입 및 로그인</a></li>
        <li><a href="#main">메인 화면</a></li>
        <li><a href="#products">수수료율 조회</a></li>
        <li><a href="#hospitals">거래처 관리</a></li>
        <li><a href="#filters">필터 관리</a></li>
        <li><a href="#notices">공지사항</a></li>
        <li><a href="#edi">EDI 증빙파일 제출</a></li>
        <li><a href="#settlement">정산내역서 조회</a></li>
        <li><a href="#profile">프로필 관리</a></li>
      </ul>
    </div>

    <!-- 컨텐츠 -->
    <div class="manual-content">
      <section id="overview" class="manual-section">
        <h2>시스템 개요</h2>
        <div class="section-content">
          <h3>시스템 목적</h3>
          <p>CSO 업체와 소속 MR 간의 성과 데이터를 체계적으로 관리하고, 투명한 정산 프로세스를 제공합니다.</p>

          <h3>주요 기능</h3>
          <ul>
            <li>제품별 수수료율 조회</li>
            <li>거래처(병의원) 정보 관리</li>
            <li>EDI 증빙파일 제출</li>
            <li>월별 정산내역서 조회 및 확인</li>
            <li>공지사항 확인</li>
            <li>개인 프로필 관리</li>
          </ul>
          
          <h3>접속 정보</h3>
          <ul>
            <li><strong>지원 브라우저</strong>: Chrome, Firefox, Safari, Edge</li>
            <li><strong>모바일</strong>: 반응형 웹 지원</li>
          </ul>
        </div>
      </section>

      <section id="signup" class="manual-section">
        <h2>회원가입 및 로그인</h2>
        <div class="section-content">
          <h3>1. 회원가입 절차</h3>
          <ol>
            <li>시스템 URL 접속</li>
            <li><strong>"회원가입"</strong> 버튼 클릭</li>
            <li>필수 정보 입력
              <ul class="sub-list">
                <li>MR명</li>
                <li>소속 업체명</li>
                <li>사업자등록번호</li>
                <li>담당 지역/구역</li>
                <li>휴대폰번호</li>
                <li>이메일 주소</li>
              </ul>
            </li>
            <li><strong>"가입신청"</strong> 버튼 클릭</li>
            <li>관리자 승인 대기</li>
          </ol>

          <h3>2. 로그인</h3>
          <ol>
            <li>승인 완료 후 이메일로 가입 승인 통보</li>
            <li>로그인 페이지에서 이메일/비밀번호 입력</li>
            <li><strong>"로그인"</strong> 버튼 클릭</li>
          </ol>

          <h3>3. 비밀번호 재설정</h3>
          <ol>
            <li>로그인 페이지에서 <strong>"비밀번호 찾기"</strong> 클릭</li>
            <li>가입 시 등록한 이메일 입력</li>
            <li>이메일로 받은 재설정 링크 클릭</li>
            <li>새 비밀번호 설정</li>
          </ol>
        </div>
      </section>

      <section id="main" class="manual-section">
        <h2>메인 화면</h2>
        <div class="section-content">
          <h3>메뉴 구성</h3>
          <p>좌측 사이드바에서 다음 메뉴를 이용할 수 있습니다:</p>

          <div class="menu-grid">
            <div class="menu-item">
              <span class="menu-icon">📊</span>
              <div>
                <strong>대시보드</strong>
                <p>주요 현황 요약</p>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-icon">💰</span>
              <div>
                <strong>수수료율</strong>
                <p>제품별 수수료율 조회</p>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-icon">🏥</span>
              <div>
                <strong>거래처</strong>
                <p>거래처 정보 관리</p>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-icon">🔍</span>
              <div>
                <strong>필터</strong>
                <p>개인 맞춤 필터 관리</p>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-icon">📢</span>
              <div>
                <strong>공지사항</strong>
                <p>중요 공지 확인</p>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-icon">📁</span>
              <div>
                <strong>EDI 증빙파일</strong>
                <p>증빙파일 제출 및 관리</p>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-icon">📋</span>
              <div>
                <strong>정산내역서</strong>
                <p>월별 정산 결과 조회</p>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-icon">👤</span>
              <div>
                <strong>프로필</strong>
                <p>개인정보 관리</p>
              </div>
            </div>
          </div>

          <h3>상단 헤더</h3>
          <ul>
            <li><strong>업체명</strong>: 현재 로그인한 업체명 표시</li>
            <li><strong>알림</strong>: 새로운 공지사항 알림</li>
            <li><strong>로그아웃</strong>: 시스템 로그아웃</li>
          </ul>
        </div>
      </section>

      <section id="products" class="manual-section">
        <h2>수수료율 조회</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>회사에서 설정한 제품별 수수료율을 조회할 수 있습니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li>좌측 메뉴에서 <strong>"수수료율"</strong> 클릭</li>
            <li>검색 조건 설정 (제약사, 제품명 등)</li>
            <li>목록에서 원하는 제품의 수수료율 확인</li>
            <li><strong>"상세보기"</strong> 버튼으로 상세 정보 확인</li>
          </ol>
        </div>
      </section>

      <section id="hospitals" class="manual-section">
        <h2>거래처 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>MR이 담당하는 병의원 거래처 정보를 등록하고 관리합니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"거래처"</strong> 메뉴 클릭</li>
            <li><strong>"등록"</strong> 버튼으로 신규 거래처 추가</li>
            <li>거래처 정보 입력 후 저장</li>
            <li>목록에서 <strong>"수정"</strong> 버튼으로 정보 업데이트</li>
          </ol>

          <h3>입력 정보</h3>
          <div class="info-grid">
            <div class="info-item">
              <h4>기본정보</h4>
              <p>거래처명, 사업자등록번호, 대표자</p>
            </div>
            <div class="info-item">
              <h4>연락정보</h4>
              <p>주소, 전화번호, 팩스번호</p>
            </div>
            <div class="info-item">
              <h4>분류정보</h4>
              <p>의료기관 유형, 진료과목</p>
            </div>
            <div class="info-item">
              <h4>담당정보</h4>
              <p>담당자명, 연락처</p>
            </div>
          </div>
        </div>
      </section>

      <section id="filters" class="manual-section">
        <h2>필터 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>개인 맞춤형 데이터 필터를 생성하여 원하는 조건의 데이터만 조회할 수 있습니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"필터"</strong> 메뉴 클릭</li>
            <li><strong>"등록"</strong> 버튼으로 새 필터 생성</li>
            <li>원하는 조건 설정
              <ul class="sub-list">
                <li>제약사 선택</li>
                <li>제품 선택</li>
                <li>거래처 선택</li>
              </ul>
            </li>
            <li>필터명 입력 후 저장</li>
          </ol>
        </div>
      </section>

      <section id="notices" class="manual-section">
        <h2>공지사항</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>회사에서 발행하는 중요한 공지사항을 확인할 수 있습니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"공지사항"</strong> 메뉴 클릭</li>
            <li>목록에서 읽고 싶은 공지 클릭</li>
            <li>상세 내용 확인</li>
            <li>필요시 첨부파일 다운로드</li>
          </ol>

          <h3>공지 유형</h3>
          <div class="notice-types">
            <div class="notice-type">
              <span class="notice-badge required">🔴 필수공지</span>
              <p>반드시 확인해야 하는 중요 공지</p>
            </div>
            <div class="notice-type">
              <span class="notice-badge general">📢 일반공지</span>
              <p>시스템 관련 일반 공지</p>
            </div>
          </div>
        </div>
      </section>

      <section id="edi" class="manual-section">
        <h2>EDI 증빙파일 제출</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>월별 EDI 증빙파일을 제출하고 제출 현황을 관리합니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"EDI 증빙파일"</strong> 메뉴 클릭</li>
            <li>제출할 정산월 선택</li>
            <li><strong>"제출"</strong> 버튼 클릭</li>
            <li>거래처별 파일 업로드</li>
            <li>제출 내역 작성 후 저장</li>
          </ol>

          <h3>파일 업로드 가이드</h3>
          <div class="upload-guide">
            <div class="guide-item">
              <strong>지원 파일</strong>
              <p>Excel (.xlsx, .xls), PDF</p>
            </div>
            <div class="guide-item">
              <strong>파일 크기</strong>
              <p>최대 10MB</p>
            </div>
            <div class="guide-item">
              <strong>파일명 규칙</strong>
              <p>[업체명]_[거래처명]_[YYYYMM].xlsx</p>
            </div>
          </div>
        </div>
      </section>

      <section id="settlement" class="manual-section">
        <h2>정산내역서 조회</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>회사에서 제공하는 월별 정산내역서를 조회하고 확인 처리할 수 있습니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"정산내역서"</strong> 메뉴 클릭</li>
            <li>조회할 정산월 선택</li>
            <li><strong>"상세보기"</strong> 버튼으로 내역 확인</li>
            <li>내용 확인 후 상태 변경
              <ul class="sub-list">
                <li><strong>확정</strong>: 정산 내역에 동의</li>
                <li><strong>정정요청</strong>: 수정이 필요한 경우</li>
              </ul>
            </li>
          </ol>

          <h3>확정상태 안내</h3>
          <div class="status-examples">
            <div class="status-item">
              <span class="badge badge-confirmed">🟢 확정</span>
              <p>정산 확정 완료</p>
            </div>
            <div class="status-item">
              <span class="badge badge-unconfirmed">🟠 미확인</span>
              <p>확인 대기 중</p>
            </div>
            <div class="status-item">
              <span class="badge badge-correction">🔴 정정요청</span>
              <p>정정 요청 상태</p>
            </div>
          </div>

          <h3>정정요청 방법</h3>
          <ol>
            <li>정산내역서에서 <strong>"정정요청"</strong> 버튼 클릭</li>
            <li>정정이 필요한 사유 작성</li>
            <li><strong>"요청"</strong> 버튼으로 전송</li>
            <li>관리자 검토 후 회신</li>
          </ol>
        </div>
      </section>

      <section id="profile" class="manual-section">
        <h2>프로필 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>개인 계정 정보와 업체 정보를 관리할 수 있습니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"프로필"</strong> 메뉴 클릭</li>
            <li><strong>"수정"</strong> 버튼으로 정보 변경</li>
            <li>변경할 정보 입력</li>
            <li><strong>"저장"</strong> 버튼으로 저장</li>
          </ol>

          <h3>비밀번호 변경</h3>
          <ol>
            <li>프로필 페이지에서 <strong>"비밀번호 변경"</strong> 클릭</li>
            <li>현재 비밀번호 입력</li>
            <li>새 비밀번호 입력 (8자 이상, 영문+숫자+특수문자 조합)</li>
            <li>비밀번호 확인 입력</li>
            <li><strong>"변경"</strong> 버튼 클릭</li>
          </ol>
        </div>
      </section>

      <!-- FAQ -->
      <section class="manual-section">
        <h2>❓ 자주 묻는 질문 (FAQ)</h2>
        <div class="section-content">
          <div class="faq-list">
            <div class="faq-item">
              <h4>Q1. 회원가입 후 언제 승인되나요?</h4>
              <p><strong>A</strong>: 관리자 검토 후 승인 처리되며, 보통 1-2 영업일 소요됩니다. 승인 완료 시 이메일로 안내드립니다.</p>
            </div>

            <div class="faq-item">
              <h4>Q2. 비밀번호를 잊어버렸어요.</h4>
              <p><strong>A</strong>: 로그인 페이지의 "비밀번호 찾기"를 이용하여 이메일로 재설정 링크를 받으실 수 있습니다.</p>
            </div>

            <div class="faq-item">
              <h4>Q3. EDI 파일은 언제까지 제출해야 하나요?</h4>
              <p><strong>A</strong>: 매월 말일까지 해당월의 EDI 파일을 제출해주시기 바랍니다.</p>
            </div>

            <div class="faq-item">
              <h4>Q4. 정산내역서에 오류가 있는 경우 어떻게 하나요?</h4>
              <p><strong>A</strong>: 정산내역서에서 "정정요청" 기능을 이용하여 구체적인 사유를 작성해 주시면 관리자가 검토 후 회신드립니다.</p>
            </div>

            <div class="faq-item">
              <h4>Q5. 거래처 정보를 일괄로 등록할 수 있나요?</h4>
              <p><strong>A</strong>: 현재는 개별 등록만 지원합니다. 대량 등록이 필요한 경우 관리자에게 문의해 주세요.</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 문의 및 지원 -->
      <section class="manual-section">
        <h2>📞 문의 및 지원</h2>
        <div class="section-content">
          <div class="contact-grid">
            <div class="contact-item">
              <h3>시스템 이용 문의</h3>
              <ul>
                <li><strong>이메일</strong>: support@shinil.co.kr</li>
                <li><strong>전화</strong>: 02-XXXX-XXXX</li>
                <li><strong>운영시간</strong>: 평일 09:00 ~ 18:00</li>
              </ul>
            </div>

            <div class="contact-item">
              <h3>긴급 문의</h3>
              <ul>
                <li><strong>담당자</strong>: [담당자명]</li>
                <li><strong>휴대폰</strong>: 010-XXXX-XXXX</li>
              </ul>
            </div>
          </div>

          <h3>기술 지원</h3>
          <ul>
            <li>로그인 문제</li>
            <li>파일 업로드 오류</li>
            <li>시스템 접속 장애</li>
            <li>기타 기술적 문제</li>
          </ul>
        </div>
      </section>
    </div>

    <!-- 푸터 -->
    <div class="manual-footer">
      <p>본 매뉴얼은 시스템 업데이트에 따라 변경될 수 있습니다. 최신 정보는 공지사항을 확인해 주세요.</p>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

const goToLogin = () => {
  router.push('/login');
};

const switchToAdmin = () => {
  router.push('/manual/admin');
};
</script>

<style scoped>
.manual-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  line-height: 1.6;
  color: #333;
}

.manual-header {
  text-align: center;
  margin-bottom: 1rem;
  padding-bottom: 2rem;
  border-bottom: 2px solid #e0e0e0;
}

.manual-header h1 {
  color: #1976d2;
  font-size: 2.4rem;
  margin-bottom: 0;
}

.manual-header h2 {
  color: #666;
  font-size: 1.3rem;
  font-weight: 500;
  margin-bottom: 0.5rem;
}

.manual-nav {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

.btn-back, .btn-switch {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.3s;
}

.btn-back {
  background-color: #666;
  color: white;
}

.btn-back:hover {
  background-color: #555;
}

.btn-switch {
  background-color: #1976d2;
  color: white;
}

.btn-switch:hover {
  background-color: #1565c0;
}

.manual-toc {
  background-color: #f5f5f5;
  padding: 1.5rem;
  border-radius: 8px;
  margin-bottom: 2rem;
}

.manual-toc h3 {
  margin-top: 0;
  color: #1976d2;
}

.manual-toc ul {
  margin: 0;
  padding-left: 1.5rem;
}

.manual-toc li {
  margin-bottom: 0.5rem;
}

.manual-toc a {
  color: #1976d2;
  text-decoration: none;
}

.manual-toc a:hover {
  text-decoration: underline;
}

.manual-section {
  margin-bottom: 3rem;
  padding: 2rem;
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.manual-section h2 {
  color: #1976d2;
  border-bottom: 2px solid #e0e0e0;
  padding-bottom: 0.5rem;
  margin-bottom: 1.5rem;
}

.section-content h3 {
  color: #333;
  margin-top: 1.5rem;
  margin-bottom: 1rem;
}

.sub-list {
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
}

.menu-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
  margin: 1.5rem 0;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background-color: #f9f9f9;
  border-radius: 8px;
  border-left: 4px solid #1976d2;
}

.menu-icon {
  font-size: 2rem;
}

.menu-item strong {
  color: #1976d2;
  font-size: 1.1rem;
}

.menu-item p {
  margin: 0;
  color: #666;
  font-size: 0.9rem;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin: 1rem 0;
}

.info-item {
  padding: 1rem;
  background-color: #f9f9f9;
  border-radius: 6px;
}

.info-item h4 {
  margin: 0 0 0.5rem 0;
  color: #1976d2;
}

.info-item p {
  margin: 0;
  font-size: 0.9rem;
  color: #666;
}

.notice-types {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin: 1rem 0;
}

.notice-type {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background-color: #f9f9f9;
  border-radius: 6px;
}

.notice-badge {
  font-size: 1rem;
  font-weight: 500;
}

.upload-guide {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin: 1rem 0;
}

.guide-item {
  padding: 1rem;
  background-color: #f0f8ff;
  border-radius: 6px;
  border-left: 4px solid #1976d2;
}

.guide-item strong {
  color: #1976d2;
  display: block;
  margin-bottom: 0.5rem;
}

.status-examples {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin: 1rem 0;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.5rem;
}

.badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 500;
  display: inline-block;
  min-width: 60px;
  text-align: center;
}

.badge-confirmed {
  background-color: #e8f5e8;
  color: #2e7d32;
  border: 1px solid #c8e6c9;
}

.badge-unconfirmed {
  background-color: #fff3e0;
  color: #f57c00;
  border: 1px solid #ffcc02;
}

.badge-correction {
  background-color: #ffebee;
  color: #c62828;
  border: 1px solid #ffcdd2;
}

.faq-list {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.faq-item {
  padding: 1.5rem;
  background-color: #f9f9f9;
  border-radius: 8px;
  border-left: 4px solid #4caf50;
}

.faq-item h4 {
  margin: 0 0 1rem 0;
  color: #4caf50;
}

.faq-item p {
  margin: 0;
  line-height: 1.6;
}

.contact-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin: 1.5rem 0;
}

.contact-item {
  padding: 1.5rem;
  background-color: #f9f9f9;
  border-radius: 8px;
  border-left: 4px solid #ff9800;
}

.contact-item h3 {
  margin: 0 0 1rem 0;
  color: #ff9800;
}

.manual-footer {
  text-align: center;
  padding: 2rem;
  margin-top: 3rem;
  border-top: 2px solid #e0e0e0;
  color: #666;
  font-style: italic;
}

/* 모바일 반응형 */
@media (max-width: 768px) {
  .manual-container {
    padding: 1rem;
  }
  
  .manual-header h1 {
    font-size: 2rem;
  }
  
  .manual-header h2 {
    font-size: 1.2rem;
  }
  
  .manual-nav {
    flex-direction: column;
    align-items: center;
  }
  
  .manual-section {
    padding: 1.5rem;
  }
  
  .menu-grid {
    grid-template-columns: 1fr;
  }
  
  .contact-grid {
    grid-template-columns: 1fr;
  }
}
</style> 