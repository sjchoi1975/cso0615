/**
 * 제약사 이름 매칭 유틸리티
 * products 테이블의 pharmacist와 pharmaceutical_companies 테이블의 company_name을 매칭
 */

/**
 * 회사명에서 법인 구분자와 특수문자를 제거하여 정규화
 * @param {string} companyName - 원본 회사명
 * @returns {string} 정규화된 회사명
 */
export function normalizeCompanyName(companyName) {
  if (!companyName) return '';
  
  return companyName
    .replace(/\(주\)/g, '') // (주) 제거
    .replace(/\(유\)/g, '') // (유) 제거
    .replace(/주식회사/g, '') // 주식회사 제거
    .replace(/유한회사/g, '') // 유한회사 제거
    .replace(/\s+/g, '') // 모든 공백 제거
    .replace(/[^\w가-힣]/g, '') // 특수문자 제거 (한글, 영문, 숫자만 남김)
    .toLowerCase() // 소문자로 변환
    .trim();
}

/**
 * products 테이블의 pharmacist로 pharmaceutical_companies에서 일치하는 회사 찾기
 * @param {string} pharmacistName - products 테이블의 pharmacist 값
 * @param {Array} pharmaceuticalCompanies - pharmaceutical_companies 테이블 데이터
 * @returns {Object|null} 일치하는 제약사 객체 또는 null
 */
export function findMatchingCompany(pharmacistName, pharmaceuticalCompanies) {
  if (!pharmacistName || !pharmaceuticalCompanies || pharmaceuticalCompanies.length === 0) {
    return null;
  }
  
  const normalizedPharmacist = normalizeCompanyName(pharmacistName);
  
  // 정확히 일치하는 회사 찾기
  const exactMatch = pharmaceuticalCompanies.find(company => {
    const normalizedCompany = normalizeCompanyName(company.company_name);
    return normalizedCompany === normalizedPharmacist;
  });
  
  if (exactMatch) {
    return exactMatch;
  }
  
  // 정확한 일치가 없으면 null 반환 (유사성 매칭은 하지 않음)
  return null;
}

/**
 * 매칭 결과를 로깅하는 함수 (디버깅용)
 * @param {string} pharmacistName - 원본 pharmacist 이름
 * @param {Object|null} matchedCompany - 매칭된 회사 객체
 */
export function logMatchingResult(pharmacistName, matchedCompany) {
  if (matchedCompany) {
    console.log(`✅ 매칭 성공: "${pharmacistName}" → "${matchedCompany.company_name}" (ID: ${matchedCompany.id})`);
  } else {
    console.log(`❌ 매칭 실패: "${pharmacistName}" - 일치하는 제약사를 찾을 수 없습니다.`);
  }
} 