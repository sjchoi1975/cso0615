/* =====================================================================================================*/
/* 관리자용 테이블
/* =====================================================================================================*/


/* 공지사항 ============================================================================================ */
export const noticeTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'id', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'title', label: '제목', width: '26%', align: 'left', sortable: false },
      { field: 'content', label: '내용', width: '34%', align: 'left', sortable: false },
      { field: 'created_at', label: '작성일자', width: '8%', align: 'center', sortable: false },
      { field: 'author', label: '작성자', width: '10%', align: 'center', sortable: false },
      { field: 'edit', label: '수정', width: '6%', align: 'center', sortable: false },
      { field: 'delete', label: '삭제', width: '6%', align: 'center', sortable: false },
      { field: 'status', label: '상태', width: '6%', align: 'center', sortable: false }
    ]
  },
    
  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '100vw',
      width: '100vw'
    },
    columns: [
      /*{ field: 'id', label: '순번', width: '10%', align: 'center', sortable: false },*/
      { field: 'title', label: '제목', width: '40%', align: 'left', sortable: false },
      { field: 'created_at', label: '작성일자', width: '24%', align: 'center', sortable: false },
      { field: 'edit', label: '수정', width: '12%', align: 'center', sortable: false },
      { field: 'delete', label: '삭제', width: '12%', align: 'center', sortable: false },
      { field: 'status', label: '상태', width: '12%', align: 'center', sortable: false }
    ]
  }
}; 


/* 회원 목록 ============================================================================================ */
export const membersTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'id_email', label: '아이디', width: '8%', align: 'left', sortable: true },
      { field: 'company_name', label: '회사명', width: '10%', align: 'left', sortable: true },
      { field: 'biz_no', label: '사업자등록번호', width: '8%', align: 'center', sortable: true },
      { field: 'ceo_name', label: '대표자명', width: '6%', align: 'center', sortable: true },
      { field: 'address', label: '주소', width: '14%', align: 'left', sortable: true },
      { field: 'cso_regist_no', label: 'CSO 신고번호', width: '8%', align: 'center', sortable: true },
      { field: 'manager_name', label: '담당자', width: '6%', align: 'center', sortable: true },
      { field: 'phone', label: '휴대폰번호', width: '8%', align: 'center', sortable: true },
      { field: 'email', label: '이메일', width: '10%', align: 'left', sortable: true },
      { field: 'approval', label: '인증', width: '6%', align: 'center', sortable: true, type: 'toggle' },
      { field: 'grade', label: '등급', width: '6%', align: 'center', sortable: true, type: 'dropdown' },
      { field: 'created_at', label: '가입일자', width: '6%', align: 'center', sortable: true }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '1600px',
      width: '100vw'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'id_email', label: '아이디', width: '8%', align: 'left', sortable: true },
      { field: 'company_name', label: '회사명', width: '10%', align: 'left', sortable: true },
      { field: 'biz_no', label: '사업자등록번호', width: '8%', align: 'center', sortable: true },
      { field: 'ceo_name', label: '대표자명', width: '6%', align: 'center', sortable: true },
      { field: 'address', label: '주소', width: '12%', align: 'left', sortable: true },
      { field: 'cso_regist_no', label: 'CSO 신고번호', width: '10%', align: 'center', sortable: true },
      { field: 'manager_name', label: '담당자', width: '6%', align: 'center', sortable: true },
      { field: 'phone', label: '휴대폰번호', width: '8%', align: 'center', sortable: true },
      { field: 'email', label: '이메일', width: '10%', align: 'left', sortable: true },
      { field: 'approval', label: '인증', width: '6%', align: 'center', sortable: true, type: 'toggle' },
      { field: 'grade', label: '등급', width: '6%', align: 'center', sortable: true, type: 'dropdown' },
      { field: 'created_at', label: '가입일자', width: '6%', align: 'center', sortable: true }
    ]
  }
};


/* 수수료율 ============================================================================================ */
export const productsTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center' },
      { field: 'pharmacist', label: '제약사', width: '6%', align: 'left', sortable: true },
      { field: 'product_name', label: '제품명', width: '10%', align: 'left', sortable: true },
      { field: 'Ingredient', label: '성분명', width: '10%', align: 'left', sortable: false },
      { field: 'price', label: '약가', width: '4%', align: 'right', sortable: true, format: 'number' },
      { field: 'commission_rate_a', label: '수수료 A', width: '4%', align: 'center', sortable: true, format: 'percent' },
      { field: 'commission_rate_b', label: '수수료 B', width: '4%', align: 'center', sortable: true, format: 'percent' },
      { field: 'commission_rate_c', label: '수수료 C', width: '4%', align: 'center', sortable: true, format: 'percent' },
      { field: 'reimbursement', label: '급여', width: '4%', align: 'center', sortable: true },
      { field: 'insurance_code', label: '보험코드', width: '5%', align: 'center', sortable: true },
      { field: 'classification', label: '분류명', width: '7%', align: 'left', sortable: true },
      { field: 'comparator', label: '대조약', width: '10%', align: 'left', sortable: false },
      { field: 'bioequivalence', label: '생동', width: '4%', align: 'center', sortable: true },
      { field: 'Inhouse', label: '자사/위탁', width: '4%', align: 'center', sortable: true },
      { field: 'remarks', label: '비고', width: '8%', align: 'left', sortable: false },
      { field: 'edit', label: '수정', width: '4%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '4%', align: 'center', type: 'icon', icon: 'pi-trash' },
      { field: 'status', label: '상태', width: '4%', align: 'center', type: 'toggle' }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '1600px',
      width: '100vw'
    },
    columns: [
        { field: 'index', label: '순번', width: '3%', align: 'center' },
        { field: 'pharmacist', label: '제약사', width: '6%', align: 'left', sortable: true },
        { field: 'product_name', label: '제품명', width: '10%', align: 'left', sortable: true, },
        { field: 'Ingredient', label: '성분명', width: '10%', align: 'left', sortable: false },
        { field: 'price', label: '약가', width: '4%', align: 'right', sortable: true, format: 'number' },
        { field: 'commission_rate_a', label: '수수료 A', width: '4%', align: 'center', sortable: true, format: 'percent' },
        { field: 'commission_rate_b', label: '수수료 B', width: '4%', align: 'center', sortable: true, format: 'percent' },
        { field: 'commission_rate_c', label: '수수료 C', width: '4%', align: 'center', sortable: true, format: 'percent' },
        { field: 'reimbursement', label: '급여', width: '4%', align: 'center', sortable: true },
        { field: 'insurance_code', label: '보험코드', width: '6%', align: 'center', sortable: true },
        { field: 'classification', label: '분류명', width: '7%', align: 'left', sortable: true },
        { field: 'comparator', label: '대조약', width: '10%', align: 'left', sortable: false },
        { field: 'bioequivalence', label: '생동', width: '4%', align: 'center', sortable: true },
        { field: 'Inhouse', label: '자사/위탁', width: '4%', align: 'center', sortable: true },
        { field: 'remarks', label: '비고', width: '8%', align: 'left', sortable: false },
        { field: 'edit', label: '수정', width: '4%', align: 'center', type: 'icon', icon: 'pi-pencil' },
        { field: 'delete', label: '삭제', width: '4%', align: 'center', type: 'icon', icon: 'pi-trash' },
        { field: 'status', label: '상태', width: '4%', align: 'center', type: 'toggle' }
    ]
  }
};


/* 거래처 ============================================================================================= */
export const hospitalsTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '12%', align: 'left', sortable: true },
      { field: 'business_registration_number', label: '사업자등록번호', width: '8%', align: 'center', sortable: true },
      { field: 'director_name', label: '원장명', width: '6%', align: 'center', sortable: true },
      { field: 'address', label: '주소', width: '14%', align: 'left', sortable: true },
      { field: 'license', label: '사업자등록증', width: '6%', align: 'center', type: 'icon', icon: 'pi-file' },
      /*{ field: 'member_count', label: '연결회원', width: '6%', align: 'center', sortable: false },*/
      { field: 'mapped_members', label: '회원사', width: '8%', align: 'left', sortable: false },
      { field: 'registered_at', label: '등록일자', width: '6%', align: 'center', sortable: true },
      { field: 'creator_name', label: '등록자', width: '8%', align: 'center', sortable: false },
      { field: 'updated_at', label: '수정일자', width: '6%', align: 'center', sortable: true },
      { field: 'updater_name', label: '수정자', width: '8%', align: 'center', sortable: false },
      { field: 'edit', label: '수정', width: '4%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '4%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '1280px',
      width: '100vw'
    },
    columns: [
        { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
        { field: 'hospital_name', label: '거래처명', width: '10%', align: 'left', sortable: true },
        { field: 'business_registration_number', label: '사업자등록번호', width: '8%', align: 'center', sortable: true },
        { field: 'director_name', label: '원장명', width: '6%', align: 'center', sortable: true },
        { field: 'address', label: '주소', width: '12%', align: 'left', sortable: true },
        { field: 'license', label: '사업자등록증', width: '6%', align: 'center', type: 'icon', icon: 'pi-file' },
        /*{ field: 'member_count', label: '회원 수', width: '6%', align: 'center', sortable: false },**/
        { field: 'mapped_members', label: '회원사', width: '8%', align: 'left', sortable: false },
        { field: 'registered_at', label: '등록일자', width: '8%', align: 'center', sortable: true },
        { field: 'creator_name', label: '등록자', width: '8%', align: 'center', sortable: false },
        { field: 'updated_at', label: '수정일자', width: '8%', align: 'center', sortable: true },
        { field: 'updater_name', label: '수정자', width: '8%', align: 'center', sortable: false },
        { field: 'edit', label: '수정', width: '4%', align: 'center', type: 'icon', icon: 'pi-pencil' },
        { field: 'delete', label: '삭제', width: '4%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  }
};


/* 필터링 요청 =========================================================================================== */
export const filterRequestsTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'request_date', label: '요청일시', width: '8%', align: 'center', sortable: false },
      { field: 'member_name', label: '업체명', width: '12%', align: 'left', sortable: false },
      { field: 'filter_type', label: '구분', width: '6%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '12%', align: 'left', sortable: false },
      { field: 'pharmaceutical_company_name', label: '제약사', width: '10%', align: 'left', sortable: false },
      { field: 'user_remarks', label: '회원 요청사항', width: '16%', align: 'left', sortable: false },
      { field: 'status', label: '처리결과', width: '8%', align: 'center', sortable: false },
      { field: 'admin_comments', label: '회원 전달사항', width: '16%', align: 'left', sortable: false },
      { field: 'updated_at', label: '수정일시', width: '8%', align: 'center', sortable: false }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '960px',
      width: '100vw'
    },
    columns: [
      { field: 'index', label: '순번', width: '5%', align: 'center', sortable: false },
      { field: 'request_date', label: '요청일시', width: '14%', align: 'center', sortable: false },
      { field: 'member_name', label: '업체명', width: '12%', align: 'left', sortable: false },
      { field: 'filter_type', label: '구분', width: '5%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '16%', align: 'left', sortable: false },
      { field: 'pharmaceutical_company_name', label: '제약사', width: '10%', align: 'left', sortable: false },
      { field: 'user_remarks', label: '요청사항', width: '8%', align: 'left', sortable: false },
      { field: 'status', label: '처리결과', width: '8%', align: 'center', sortable: false },
      { field: 'admin_comments', label: '전달사항', width: '8%', align: 'left', sortable: false },
      { field: 'updated_at', label: '수정일시', width: '14%', align: 'center', sortable: false }
    ]
  }
};


/* 제약사 ============================================================================================= */
export const pharmaceuticalCompaniesTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'company_name', label: '제약사명', width: '76%', align: 'left', sortable: true },
      { field: 'created_at', label: '등록일자', width: '8%', align: 'center', sortable: true },
      { field: 'edit', label: '수정', width: '6%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '6%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      minWidth: '100vw',
      width: '100vw'
    },
    columns: [
      { field: 'index', label: '순번', width: '12%', align: 'center', sortable: false },
      { field: 'company_name', label: '제약사명', width: '34%', align: 'left', sortable: true },
      { field: 'created_at', label: '등록일자', width: '20%', align: 'center', sortable: true },
      { field: 'edit', label: '수정', width: '12%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '12%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  }
};



/* EDI 정산월 ============================================================================================ */
export const ediMonthsTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'settlement_month', label: '정산월', width: '8%', align: 'center', sortable: true },
      { field: 'start_date', label: '시작일자', width: '8%', align: 'center', sortable: true },
      { field: 'end_date', label: '마감일자', width: '8%', align: 'center', sortable: true },
      { field: 'remarks', label: '공지사항', width: '54%', align: 'left', sortable: false },
      { field: 'detail', label: '상세', width: '6%', align: 'center', type: 'icon', icon: 'pi-list' },
      { field: 'edit', label: '수정', width: '6%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '6%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '720px',
      width: '100vw'
    },
    columns: [
      /*{ field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },*/
      { field: 'settlement_month', label: '정산월', width: '10%', align: 'center', sortable: true },
      { field: 'start_date', label: '시작일자', width: '12%', align: 'center', sortable: true },
      { field: 'end_date', label: '마감일자', width: '12%', align: 'center', sortable: true },
      { field: 'remarks', label: '공지사항', width: '30%', align: 'left', sortable: false },
      { field: 'detail', label: '상세', width: '8%', align: 'center', type: 'icon', icon: 'pi-list' },
      { field: 'edit', label: '수정', width: '8%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '8%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  }
};


/* 정산내역서 - 정산월 ======================================================================================= */
/* 업체명, 거래처명 -> 업체수, 거래처수 로 변경! =================================================== */
export const settlementMonthTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'settlement_month', label: '정산월', width: '8%', align: 'center', sortable: true },
      { field: 'company_name', label: '업체', width: '12%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처', width: '12%', align: 'center', sortable: false },
      { field: 'total_amount', label: '정산금액', width: '12%', align: 'right', sortable: false },
      { field: 'note', label: '비고', width: '42%', align: 'left', sortable: false },
      { field: 'detail', label: '상세', width: '10%', align: 'center', type: 'icon', icon: 'pi-list' }
    ]
  },
  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      minWidth: '720px',
      width: '100vw'
    },
    columns: [
      /*{ field: 'index', label: '순번', width: '6%', align: 'center', sortable: false },*/
      { field: 'settlement_month', label: '정산월', width: '10%', align: 'center', sortable: true },
      { field: 'company_name', label: '업체', width: '12%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처', width: '12%', align: 'center', sortable: false },
      { field: 'total_amount', label: '정산금액', width: '18%', align: 'right', sortable: false },
      { field: 'note', label: '비고', width: '32%', align: 'left', sortable: false },
      { field: 'detail', label: '상세', width: '8%', align: 'center', type: 'icon', icon: 'pi-list' }
    ]
  }
};

/* 정산내역서 - 상세 ======================================================================================== */
export const settlementMonthDetailTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '3%', align: 'center', sortable: false },
      { field: 'company_name', label: '업체명', width: '9%', align: 'left', sortable: false },
      { field: 'company_reg_no', label: '사업자등록번호', width: '7%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '9%', align: 'left', sortable: false },
      { field: 'hospital_reg_no', label: '사업자등록번호', width: '7%', align: 'center', sortable: false },
      { field: 'prescription_month', label: '처방월', width: '5%', align: 'center', sortable: false },
      { field: 'pharma_name', label: '제약사', width: '7%', align: 'left', sortable: false },
      { field: 'product_name', label: '제품명', width: '9%', align: 'left', sortable: false },
      { field: 'insurance_code', label: '보험코드', width: '7%', align: 'center', sortable: false },
      { field: 'price', label: '약가', width: '5%', align: 'right', sortable: false },
      { field: 'quantity', label: '수량', width: '5%', align: 'right', sortable: false },
      { field: 'prescription_amount', label: '처방액', width: '7%', align: 'right', sortable: false },
      { field: 'commission_rate', label: '수수료율', width: '5%', align: 'center', sortable: false },
      { field: 'payment_amount', label: '지급액', width: '7%', align: 'right', sortable: false },
      { field: 'remarks', label: '비고', width: '8%', align: 'left', sortable: false }
    ]
  },
  
  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '1840px',
      width: '100vw'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center' },
      { field: 'hospital_name', label: '병의원', width: '10%', align: 'left', sortable: true },
      { field: 'product_name', label: '제품명', width: '10%', align: 'left', sortable: true },
      { field: 'prescription_month', label: '처방월', width: '7%', align: 'center', sortable: true },
      { field: 'pharma_name', label: '제약사', width: '8%', align: 'left', sortable: true },
      { field: 'insurance_code', label: '보험코드', width: '8%', align: 'center' },
      { field: 'price', label: '약가', width: '7%', align: 'right', format: 'number' },
      { field: 'quantity', label: '수량', width: '7%', align: 'right', format: 'number' },
      { field: 'prescription_amount', label: '처방액', width: '8%', align: 'right', format: 'currency' },
      { field: 'commission_rate', label: '수수료율', width: '7%', align: 'center', format: 'percent' },
      { field: 'payment_amount', label: '지급액', width: '8%', align: 'right', format: 'currency' },
      { field: 'remarks', label: '비고', width: '16%', align: 'left' }
    ]
  }
};



/* =====================================================================================================*/
/* 이용자용 테이블
/* =====================================================================================================*/

/* 이용자 - 공지사항 ==================================================================================== */
export const userNoticesTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'id', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'title', label: '제목', width: '30%', align: 'left', sortable: true },
      { field: 'content', label: '내용', width: '46%', align: 'left', sortable: true },
      { field: 'created_at', label: '작성일자', width: '10%', align: 'center', sortable: true },
      { field: 'author', label: '작성자', width: '10%', align: 'center', sortable: true }
    ]
  },
  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '100vw',
      width: '100vw'
    },
    columns: [
      { field: 'id', label: '순번', width: '14%', align: 'center', sortable: false },
      { field: 'title', label: '제목', width: '58%', align: 'left', sortable: true },
      { field: 'created_at', label: '작성일시', width: '28%', align: 'center', sortable: true }
    ]
  }
};


/* 이용자 - 수수료율 ==================================================================================== */
export const userProductsTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
      columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'pharmacist', label: '제약사', width: '6%', align: 'left', sortable: false },
      { field: 'product_name', label: '제품명', width: '12%', align: 'left', sortable: false },
      { field: 'Ingredient', label: '성분명', width: '14%', align: 'left', sortable: false },
      { field: 'price', label: '약가', width: '6%', align: 'right', sortable: false },
      { field: 'commission_rate', label: '수수료율', width: '5%', align: 'center', sortable: false },
      { field: 'reimbursement', label: '급여', width: '5%', align: 'center', sortable: false },
      { field: 'insurance_code', label: '보험코드', width: '6%', align: 'center', sortable: false },
      { field: 'classification', label: '분류명', width: '10%', align: 'left', sortable: false },
      { field: 'comparator', label: '대조약', width: '12%', align: 'left', sortable: false },
      { field: 'bioequivalence', label: '생동', width: '5%', align: 'center', sortable: false },
      { field: 'Inhouse', label: '자사/위탁', width: '5%', align: 'center', sortable: false },
      { field: 'remarks', label: '비고', width: '10%', align: 'left', sortable: false }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '780px',
      width: '100vw'
    },
    columns: [
      /*{ field: 'index', label: '순번', width: '4%', align: 'center', sortable: false, frozen: false },*/
      { field: 'pharmacist', label: '제약사', width: '6%', align: 'left', sortable: false, frozen: false, },
      { field: 'product_name', label: '제품명', width: '12%', align: 'left', sortable: false, frozen: false },
      { field: 'Ingredient', label: '성분명', width: '12%', align: 'left', sortable: false, frozen: false },
      { field: 'price', label: '약가', width: '6%', align: 'right', sortable: false, frozen: false },
      { field: 'commission_rate', label: '수수료율', width: '6%', align: 'center', sortable: false, frozen: false },
      { field: 'reimbursement', label: '급여', width: '6%', align: 'center', sortable: false, frozen: false },
      { field: 'insurance_code', label: '보험코드', width: '9%', align: 'center', sortable: false, frozen: false },
      /*{ field: 'classification', label: '분류명', width: '12%', align: 'left', sortable: false, frozen: false },
      { field: 'comparator', label: '대조약', width: '12%', align: 'left', sortable: false, frozen: false },
      { field: 'bioequivalence', label: '생동', width: '5%', align: 'center', sortable: false, frozen: false },
      { field: 'Inhouse', label: '자사/위탁', width: '5%', align: 'center', sortable: false, frozen: false },*/
      { field: 'remarks', label: '비고', width: '12%', align: 'left', sortable: false, frozen: false }
    ]
  }
};


/* 이용자 - 거래처 ============================================================================================= */
export const userHospitalsTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '20%', align: 'left', sortable: true },
      { field: 'business_registration_number', label: '사업자등록번호', width: '8%', align: 'center', sortable: true },
      { field: 'director_name', label: '원장명', width: '8%', align: 'center', sortable: true },
      { field: 'address', label: '주소', width: '28%', align: 'left', sortable: true },
      { field: 'license', label: '사업자등록증', width: '8%', align: 'center', type: 'icon', icon: 'pi-file' },
      { field: 'registered_at', label: '등록일자', width: '8%', align: 'center', sortable: true },
      /*{ field: 'creator_name', label: '등록자', width: '8%', align: 'center', sortable: false },
      { field: 'updated_at', label: '수정일자', width: '8%', align: 'center', sortable: true },
      { field: 'updater_name', label: '수정자', width: '8%', align: 'center', sortable: false },*/
      { field: 'edit', label: '수정', width: '8%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '8%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '100vw',
      width: '100vw'
    },
    columns: [
      /*{ field: 'index', label: '순번', width: '5%', align: 'center', sortable: false },*/
      { field: 'hospital_name', label: '거래처명', width: '20%', align: 'left', sortable: true },
      /*{ field: 'business_registration_number', label: '사업자등록번호', width: '10%', align: 'center', sortable: true },
      { field: 'director_name', label: '원장명', width: '8%', align: 'center', sortable: true },*/
      { field: 'address', label: '주소', width: '16%', align: 'left', sortable: true },
      { field: 'license', label: '등록증', width: '7%', align: 'center', type: 'icon', icon: 'pi-file' },
      { field: 'edit', label: '수정', width: '7%', align: 'center', type: 'icon', icon: 'pi-pencil' },
      { field: 'delete', label: '삭제', width: '7%', align: 'center', type: 'icon', icon: 'pi-trash' }
    ]
  }
};


/* 이용자 - 필터링 내역 ========================================================================================= */
export const userFilterRequestsTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'filter_type', label: '구분', width: '6%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '18%', align: 'left', sortable: false },
      { field: 'pharmaceutical_company_name', label: '제약사', width: '10%', align: 'left', sortable: false },
      { field: 'status', label: '결과', width: '8%', align: 'center', sortable: false },
      { field: 'admin_comments', label: '전달사항', width: '18%', align: 'left', sortable: false },
      { field: 'updated_at', label: '처리일시', width: '10%', align: 'center', sortable: false },
      { field: 'user_remarks', label: '요청사항', width: '18%', align: 'left', sortable: false },
      { field: 'request_date', label: '요청일시', width: '10%', align: 'center', sortable: false }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '800px',
      width: '100vw'
    },
    columns: [
      /*{ field: 'index', label: '순번', width: '6%', align: 'center', sortable: false },*/
      { field: 'filter_type', label: '구분', width: '6%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '16%', align: 'left', sortable: false },
      { field: 'pharmaceutical_company_name', label: '제약사', width: '10%', align: 'left', sortable: false },
      { field: 'status', label: '결과', width: '8%', align: 'center', sortable: false },
      { field: 'admin_comments', label: '전달사항', width: '10%', align: 'left', sortable: false },
      { field: 'updated_at', label: '처리일시', width: '16%', align: 'center', sortable: false },
      { field: 'user_remarks', label: '요청사항', width: '10%', align: 'left', sortable: false },
      { field: 'request_date', label: '요청일시', width: '16%', align: 'center', sortable: false }
    ]
  }
};



/* 이용자 - EDI 제출 ========================================================================================= */
export const userEdiSubmitTableConfig = {
  pc: {
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', type: 'index' },
      { field: 'hospital_name', label: '거래처명', width: '16%', align: 'left', sortable: true },
      { field: 'business_registration_number', label: '사업자등록번호', width: '12%', align: 'center', sortable: true },
      { field: 'director_name', label: '원장명', width: '8%', align: 'center', sortable: true },
      { field: 'address', label: '주소', width: '30%', align: 'left', sortable: true },
      { field: 'last_month_files', label: '전월 제출 파일', width: '10%', align: 'center', sortable: false },
      { field: 'current_month_files', label: '당월 제출 파일', width: '10%', align: 'center', sortable: false },
      { field: 'submit_button', label: '제출하기', width: '10%', align: 'center', type: 'button', icon: 'pi pi-upload' }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '800px',
      width: '100vw'
    },
    columns: [
      /*{ field: 'index', label: '순번', width: '4%', align: 'center', type: 'index' },*/
      { field: 'hospital_name', label: '거래처명', width: '20%', align: 'left', sortable: true },
      /*{ field: 'business_registration_number', label: '사업자등록번호', width: '12%', align: 'center', sortable: false },
      { field: 'director_name', label: '원장명', width: '8%', align: 'center', sortable: false },*/
      { field: 'address', label: '주소', width: '16%', align: 'left', sortable: true },
      { field: 'last_month_files', label: '전월', width: '8%', align: 'center', sortable: false },
      { field: 'current_month_files', label: '당월', width: '8%', align: 'center', sortable: false },
      { field: 'submit_button', label: '제출', width: '8%', align: 'center', type: 'button', icon: 'pi pi-upload' }
    ]
  }
};



/* EDI 증빙파일 =========================================================================================== */
export const adminEdiListTableConfig = {
  pc: {
    tableWidth: '1840px',
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center', sortable: false },
      { field: 'settlement_month', label: '정산월', width: '6%', align: 'center', sortable: true },
      { field: 'company_name', label: '업체명', width: '10%', align: 'left', sortable: true },
      { field: 'member_biz_no', label: '사업자번호', width: '8%', align: 'center', sortable: false },
      { field: 'member_ceo_name', label: '대표자', width: '6%', align: 'center', sortable: false },
      { field: 'hospital_name', label: '거래처명', width: '10%', align: 'left', sortable: true },
      { field: 'hospital_biz_no', label: '사업자번호', width: '8%', align: 'center', sortable: false },
      { field: 'director_name', label: '원장명', width: '6%', align: 'center', sortable: false },
      { field: 'hospital_address', label: '주소', width: '10%', align: 'left', sortable: false },
      { field: 'proof_file', label: '파일보기', width: '6%', align: 'center', sortable: false, type: 'icon' },
      { field: 'download', label: '다운로드', width: '6%', align: 'center', sortable: false, type: 'icon' },
      { field: 'created_at', label: '등록일자', width: '8%', align: 'center', sortable: true },
      { field: 'created_by_name', label: '등록자', width: '8%', align: 'center', sortable: false }
    ]
  },
  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '1600px',
      width: '100vw'
    },
    columns: [
      { field: 'settlement_month', label: '정산월', width: '10%', align: 'center', sortable: true },
      { field: 'company_name', label: '업체명', width: '20%', align: 'left', sortable: true },
      { field: 'hospital_name', label: '거래처명', width: '20%', align: 'left', sortable: true },
      { field: 'created_at', label: '등록일자', label: '15%', align: 'center', sortable: true },
      { field: 'proof_file', label: '보기', width: '10%', align: 'center', sortable: false, type: 'icon' },
      { field: 'download', label: '받기', width: '10%', align: 'center', sortable: false, type: 'icon' },
      { field: 'created_by_name', label: '등록자', width: '15%', align: 'center', sortable: false }
    ]
  }
};



/* 이용자 - 정산내역서 - 정산월 ======================================================================================= */
export const userSettlementMonthTableConfig = {
  pc: {
    tableStyle: { minWidth: '1840px' },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center' },
      { field: 'settlement_month', label: '정산월', width: '8%', align: 'center', sortable: true },
      { field: 'hospital_name', label: '거래처수', width: '8%', align: 'center', sortable: true },
      { field: 'prescription_count', label: '처방건수', width: '8%', align: 'center', sortable: true },
      { field: 'prescription_amount', label: '처방액', width: '10%', align: 'center', sortable: true, format: 'currency' },
      { field: 'payment_amount', label: '지급액', width: '10%', align: 'center', sortable: true, format: 'currency' },
      { field: 'note', label: '전달사항', width: '34%', align: 'left' },
      { field: 'detail', label: '상세보기', width: '8%', align: 'center', type: 'icon' },
      { field: 'created_at', label: '등록일자', width: '10%', align: 'center', sortable: true }
    ]
  },
  
  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '680px',
    },
    columns: [
      /*{ field: 'index', label: '순번', width: '6%', align: 'center' },*/
      { field: 'settlement_month', label: '정산월', width: '10%', align: 'center', sortable: true },
      { field: 'detail', label: '상세보기', width: '8%', align: 'center', type: 'icon' },
      { field: 'hospital_name', label: '거래처수', width: '8%', align: 'center', sortable: true },
      /*{ field: 'prescription_count', label: '처방건수', width: '10%', align: 'center', sortable: true },*/
      { field: 'prescription_amount', label: '처방액', width: '10%', align: 'center', sortable: true, format: 'currency' },
      { field: 'payment_amount', label: '지급액', width: '10%', align: 'center', sortable: true, format: 'currency' },
      { field: 'note', label: '전달사항', width: '18%', align: 'left' },
      { field: 'created_at', label: '등록일자', width: '10%', align: 'center', sortable: true }
    ]
  }
};



/* 이용자 - 정산내역서 - 상세 ======================================================================================== */
export const userSettlementMonthDetailTableConfig = {
  pc: {
    tableStyle: {
      minWidth: '1840px'
    },
    columns: [
      { field: 'index', label: '순번', width: '4%', align: 'center' },
      { field: 'hospital_name', label: '병의원', width: '10%', align: 'left', sortable: true },
      { field: 'product_name', label: '제품명', width: '10%', align: 'left', sortable: true },
      { field: 'prescription_month', label: '처방월', width: '7%', align: 'center', sortable: true },
      { field: 'pharma_name', label: '제약사', width: '8%', align: 'left', sortable: true },
      { field: 'insurance_code', label: '보험코드', width: '8%', align: 'center' },
      { field: 'price', label: '약가', width: '7%', align: 'right', format: 'number' },
      { field: 'quantity', label: '수량', width: '7%', align: 'right', format: 'number' },
      { field: 'prescription_amount', label: '처방액', width: '8%', align: 'right', format: 'currency' },
      { field: 'commission_rate', label: '수수료율', width: '7%', align: 'center', format: 'percent' },
      { field: 'payment_amount', label: '지급액', width: '8%', align: 'right', format: 'currency' },
      { field: 'remarks', label: '비고', width: '16%', align: 'left' }
    ]
  },

  mobile: {
    tableWidth: '100vw',
    tableStyle: {
      overflowX: 'auto',
      minWidth: '1080px',
    },
    columns: [
      { field: 'index', label: '순번', width: '5%', align: 'center' },
      { field: 'hospital_name', label: '병의원', width: '10%', align: 'left', sortable: true },
      { field: 'product_name', label: '제품명', width: '10%', align: 'left', sortable: true },
      { field: 'prescription_month', label: '처방월', width: '6%', align: 'center', sortable: true },
      { field: 'pharma_name', label: '제약사', width: '6%', align: 'left', sortable: true },
      { field: 'insurance_code', label: '보험코드', width: '8%', align: 'center' },
      { field: 'price', label: '약가', width: '6%', align: 'right', format: 'number' },
      { field: 'quantity', label: '수량', width: '6%', align: 'right', format: 'number' },
      { field: 'prescription_amount', label: '처방액', width: '8%', align: 'right', format: 'currency' },
      { field: 'commission_rate', label: '수수료율', width: '6%', align: 'center', format: 'percent' },
      { field: 'payment_amount', label: '지급액', width: '8%', align: 'right', format: 'currency' },
      { field: 'remarks', label: '비고', width: '12%', align: 'left' }
    ]
  }
};























