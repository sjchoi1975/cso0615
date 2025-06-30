// 특수 레이아웃 적용 경로 및 네이밍 규칙 관리
const specialLayoutRoutes = [
  {
    path: /^\/edi\/submit\/\d+\/\d+$/,
    async menuName(params) {
      const { settlementMonthId, hospitalId } = params;

      const { data: month } = await supabase
        .from('edi_months')
        .select('settlement_month')
        .eq('id', settlementMonthId)
        .single();
      const monthLabel = month ? month.settlement_month : '';
      
      const { data: hospital } = await supabase
        .from('hospitals')
        .select('hospital_name')
        .eq('id', hospitalId)
        .single();
      const hospitalName = hospital ? hospital.hospital_name : '';

      return `${monthLabel} - ${hospitalName}`;
    }
  },
  {
    path: /^\/admin\/notices\/create$/,
    menuName: () => '공지사항 작성'
  },
  {
    path: /^\/admin\/notices\/edit\//,
    menuName: () => '공지사항 수정'
  },
  {
    path: /^\/admin\/products\/create$/,
    menuName: () => '제품 등록'
  },
  {
    path: /^\/admin\/products\/edit\//,
    menuName: () => '제품 수정'
  },
  {
    path: /^\/admin\/hospitals\/create$/,
    menuName: () => '거래처 등록'
  },
  {
    path: /^\/hospitals\/create$/,
    menuName: () => '거래처 등록'
  },
  {
    path: /^\/hospitals\/edit\//,
    menuName: () => '거래처 수정'
  }
];

const currentSpecial = computed(() => {
  const path = route.path;
  return specialLayoutRoutes.find(r => r.path.test(path));
});
// ... existing code ... 