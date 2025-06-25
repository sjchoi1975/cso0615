/**
 * 테이블의 스크롤 높이를 동적으로 계산하는 유틸리티 함수
 * @param {boolean} hasPaginator - 페이지네이터 존재 여부
 * @param {number} bottomMargin - 페이지네이터가 없을 때 하단 여백 (px)
 * @returns {string} CSS calc() 값
 */
export const getTableScrollHeight = (hasPaginator = false, bottomMargin = 40) => {
  const topAreaHeight = 120; // 상단 필터+버튼 영역 (고정값)
  const paginatorHeight = 48; // 페이지네이터 높이
  
  if (hasPaginator) {
    return `calc(100vh - ${topAreaHeight + paginatorHeight}px)`;
  } else {
    return `calc(100vh - ${topAreaHeight + bottomMargin}px)`;
  }
}; 