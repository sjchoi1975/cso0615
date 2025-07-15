<template>
  <div class="manual-container">
    <!-- 헤더 -->
    <div class="manual-header">
      <h1>CSO 운영관리 시스템</h1>
      <h2>관리자용 기능 소개서 및 매뉴얼</h2>
    </div>

    <!-- 목차 -->
    <div class="manual-toc">
      <h3>📋 목차</h3>
      <ul>
        <li><a href="#overview">시스템 개요</a></li>
        <li><a href="#login">로그인 및 메인 화면</a></li>
        <li><a href="#members">회원 관리</a></li>
        <li><a href="#products">수수료율 관리</a></li>
        <li><a href="#hospitals">거래처 관리</a></li>
        <li><a href="#filters">필터 관리</a></li>
        <li><a href="#notices">공지사항 관리</a></li>
        <li><a href="#edi">EDI 증빙파일 관리</a></li>
        <li><a href="#settlement">정산내역서 관리</a></li>
      </ul>
    </div>

    <!-- 컨텐츠 -->
    <div class="manual-content">
      <section id="overview" class="manual-section">
        <h2>시스템 개요</h2>
        <div class="section-content">
          <h3>주요 기능</h3>
          <ul>
            <li>CSO 업체 MR 회원 승인 및 관리</li>
            <li>제품별 수수료율 설정 및 관리</li>
            <li>거래처(병의원) 정보 관리</li>
            <li>필터링 조건 관리</li>
            <li>공지사항 발행 및 관리</li>
            <li>EDI 증빙파일 제출 현황 관리</li>
            <li>정산내역서 생성 및 공유 관리</li>
          </ul>
          
          <h3>접속 정보</h3>
          <ul>
            <li><strong>관리자 계정</strong>: admin@company.co.kr</li>
            <li><strong>권한</strong>: 전체 시스템 관리</li>
          </ul>
        </div>
      </section>

      <section id="login" class="manual-section">
        <h2>로그인 및 메인 화면</h2>
        <div class="section-content">
          <h3>1. 로그인</h3>
          <ol>
            <li>시스템 URL 접속</li>
            <li>관리자 계정으로 로그인</li>
            <li>대시보드 진입</li>
          </ol>

          <h3>2. 메인 메뉴 구성</h3>
          <ul>
            <li><strong>회원 관리</strong>: CSO 업체 회원 승인 및 정보 관리</li>
            <li><strong>수수료율</strong>: 제품별 수수료율 설정</li>
            <li><strong>거래처 관리</strong>: 병의원 정보 관리</li>
            <li><strong>필터 관리</strong>: 업체별 필터링 조건 설정</li>
            <li><strong>공지사항</strong>: 공지사항 작성 및 발행</li>
            <li><strong>EDI 증빙 파일</strong>: EDI 파일 제출 현황 관리</li>
            <li><strong>정산내역서</strong>: 월별 정산 데이터 관리</li>
          </ul>
        </div>
      </section>

      <section id="members" class="manual-section">
        <h2>회원 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>CSO 업체 소속 MR의 회원가입 승인 및 회원 정보를 관리합니다.</p>

          <h3>주요 기능</h3>
          <div class="feature-list">
            <div class="feature-item">
              <h4>1. 회원 목록 조회</h4>
              <ul>
                <li>전체 회원 목록 확인</li>
                <li>가입일자, 승인상태별 필터링</li>
                <li>업체명, 사업자번호로 검색</li>
              </ul>
            </div>
            
            <div class="feature-item">
              <h4>2. 회원 승인 관리</h4>
              <ul>
                <li>신규 가입 회원 승인/반려</li>
                <li>회원 등급 설정 (일반/우수/VIP)</li>
                <li>계정 활성화/비활성화</li>
              </ul>
            </div>

            <div class="feature-item">
              <h4>3. 회원 정보 수정</h4>
              <ul>
                <li>업체 기본정보 수정</li>
                <li>담당자 정보 변경</li>
                <li>연락처 정보 업데이트</li>
              </ul>
            </div>
          </div>

          <h3>사용 방법</h3>
          <ol>
            <li>좌측 메뉴에서 <strong>"회원 관리"</strong> 클릭</li>
            <li>회원 목록에서 승인 대기 회원 확인</li>
            <li>승인 토글 스위치로 승인/반려 처리</li>
            <li>등급 드롭다운으로 회원 등급 설정</li>
          </ol>
        </div>
      </section>

      <section id="products" class="manual-section">
        <h2>수수료율 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>제약사별, 제품별 수수료율을 설정하고 관리합니다.</p>

          <h3>주요 기능</h3>
          <div class="feature-list">
            <div class="feature-item">
              <h4>1. 수수료율 목록 조회</h4>
              <ul>
                <li>제약사별 제품 목록</li>
                <li>보험코드별 수수료율 확인</li>
              </ul>
            </div>

            <div class="feature-item">
              <h4>2. 수수료율 등록</h4>
              <ul>
                <li>새로운 제품 등록</li>
                <li>수수료율 설정</li>
              </ul>
            </div>

            <div class="feature-item">
              <h4>3. 수수료율 수정</h4>
              <ul>
                <li>기존 제품 수수료율 변경</li>
                <li>일괄 수정 기능</li>
              </ul>
            </div>
          </div>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"수수료율"</strong> 메뉴 클릭</li>
            <li><strong>"등록"</strong> 버튼으로 신규 제품 추가</li>
            <li>제품 정보 입력 후 저장</li>
            <li>기존 제품은 목록에서 수정</li>
          </ol>
        </div>
      </section>

      <section id="hospitals" class="manual-section">
        <h2>거래처 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>병의원 거래처 정보를 등록하고 관리합니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"거래처 관리"</strong> 메뉴 클릭</li>
            <li><strong>"등록"</strong> 버튼으로 신규 거래처 추가</li>
            <li>거래처 정보 입력 후 저장</li>
            <li>목록에서 기존 거래처 수정/삭제</li>
          </ol>
        </div>
      </section>

      <section id="filters" class="manual-section">
        <h2>필터 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>CSO 업체별로 특정 조건의 데이터만 볼 수 있도록 필터를 설정합니다.</p>
        </div>
      </section>

      <section id="notices" class="manual-section">
        <h2>공지사항 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>시스템 사용자에게 공지사항을 작성하고 발행합니다.</p>

          <h3>사용 방법</h3>
          <ol>
            <li><strong>"공지사항"</strong> 메뉴 클릭</li>
            <li><strong>"등록"</strong> 버튼으로 새 공지 작성</li>
            <li>제목, 내용 입력</li>
            <li>필수공지 여부 선택 후 저장</li>
            <li>목록에서 수정/삭제 가능</li>
          </ol>
        </div>
      </section>

      <section id="edi" class="manual-section">
        <h2>EDI 증빙파일 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>CSO 업체들의 EDI 증빙파일 제출 현황을 모니터링합니다.</p>

          <h3>주요 기능</h3>
          <div class="feature-list">
            <div class="feature-item">
              <h4>1. EDI 대시보드</h4>
              <ul>
                <li>정산월별 전체 현황 조회</li>
                <li>업체별 제출 현황 요약</li>
                <li>제약사 확인/미확인 현황</li>
              </ul>
            </div>

            <div class="feature-item">
              <h4>2. 상세 현황 조회</h4>
              <ul>
                <li>업체별 상세 제출 내역</li>
                <li>거래처별 파일 제출 상태</li>
                <li>제약사 확인 처리</li>
              </ul>
            </div>
          </div>

          <h3>화면 구성</h3>
          <ul>
            <li><strong>필터카드</strong>: 정산월 선택</li>
            <li><strong>기능카드</strong>: 전체 업체수, 전체 상세보기, 엑셀 다운로드</li>
            <li><strong>테이블</strong>: 업체별 제출 현황 요약</li>
          </ul>
        </div>
      </section>

      <section id="settlement" class="manual-section">
        <h2>정산내역서 관리</h2>
        <div class="section-content">
          <h3>기능 개요</h3>
          <p>월별 정산 데이터를 생성하고 CSO 업체와 공유를 관리합니다.</p>

          <h3>주요 기능</h3>
          <div class="feature-list">
            <div class="feature-item">
              <h4>1. 정산월 관리</h4>
              <ul>
                <li>정산월별 데이터 조회</li>
                <li>정산 데이터 생성</li>
              </ul>
            </div>

            <div class="feature-item">
              <h4>2. 정산내역서 상세</h4>
              <ul>
                <li>업체별 상세 정산 내역</li>
                <li>거래처별 처방 데이터</li>
                <li>수수료 계산 결과</li>
              </ul>
            </div>

            <div class="feature-item">
              <h4>3. 정산내역서 공유</h4>
              <ul>
                <li>업체별 공유 설정</li>
                <li>확정상태 관리 (확정/미확인/정정요청)</li>
                <li>전달사항 입력</li>
              </ul>
            </div>
          </div>

          <h3>확정상태 관리</h3>
          <div class="badge-examples">
            <span class="badge badge-confirmed">확정</span>
            <span>초록색 배지 - 정산 확정 완료</span>
          </div>
          <div class="badge-examples">
            <span class="badge badge-unconfirmed">미확인</span>
            <span>주황색 배지 - 업체 확인 대기</span>
          </div>
          <div class="badge-examples">
            <span class="badge badge-correction">정정요청</span>
            <span>빨간색 배지 - 업체에서 정정 요청</span>
          </div>
        </div>
      </section>

      <!-- 문의 및 지원 -->
      <section class="manual-section">
        <h2>📞 문의 및 지원</h2>
        <div class="section-content">
          <div class="contact-info">
            <h3>기술 지원</h3>
            <ul>
              <li><strong>담당자</strong>: [담당자명]</li>
              <li><strong>연락처</strong>: [연락처]</li>
              <li><strong>이메일</strong>: [이메일]</li>
            </ul>

            <h3>시스템 관련 문의</h3>
            <ul>
              <li>회원 승인 관련 문의</li>
              <li>수수료율 설정 문의</li>
              <li>정산 데이터 관련 문의</li>
            </ul>
          </div>
        </div>
      </section>
    </div>

    <!-- 푸터 -->
    <div class="manual-footer">
      <p>본 매뉴얼은 시스템 업데이트에 따라 변경될 수 있습니다.</p>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

const goToLogin = () => {
  router.push('/login');
};

const switchToUser = () => {
  router.push('/manual/user');
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

.feature-list {
  display: grid;
  gap: 1.5rem;
  margin: 1.5rem 0;
}

.feature-item {
  background-color: #f9f9f9;
  padding: 1.5rem;
  border-radius: 6px;
  border-left: 4px solid #1976d2;
}

.feature-item h4 {
  margin-top: 0;
  color: #1976d2;
}

.badge-examples {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
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

.contact-info h3 {
  color: #1976d2;
  margin-bottom: 1rem;
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
}
</style> 