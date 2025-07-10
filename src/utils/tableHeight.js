/**
 * 테이블의 스크롤 높이를 동적으로 계산하는 유틸리티 함수
 * @param {boolean} hasPaginator - 페이지네이터 존재 여부
 * @param {number} bottomMargin - 페이지네이터가 없을 때 하단 여백 (px)
 * @returns {string} CSS calc() 값
 */
export const getTableScrollHeight = (hasPaginator = false, bottomMargin = 8) => {
  const isMobile = window.innerWidth <= 768;
  
  // PC와 모바일의 다른 높이 설정
  const topAreaHeight = isMobile ? 96 : 128; // 상단 필터/버튼 영역 (모바일에서는 더 작게)
  const paginatorHeight = 44; // 페이지네이터 높이
  
  if (hasPaginator) {
    // 페이지네이터가 있는 경우
    return isMobile
      ? `calc(100vh - ${topAreaHeight + paginatorHeight + 56}px)` // 모바일은 추가 여백
      : `calc(100vh - ${topAreaHeight + paginatorHeight}px)`;
  } else {
    // 페이지네이터가 없는 경우
    return isMobile
      ? `calc(100vh - ${topAreaHeight + bottomMargin + 56}px)` // 모바일은 추가 여백
      : `calc(100vh - ${topAreaHeight + bottomMargin}px)`;
  }
}; 

