<script setup>
import { RouterLink, RouterView } from 'vue-router'
import HelloWorld from './components/HelloWorld.vue'
import { ref, watch, computed, onMounted, onUnmounted } from 'vue'
import SidebarMenu from './components/SidebarMenu.vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/supabase'
import TopbarMenu from './components/TopbarMenu.vue'
import ConfirmDialog from 'primevue/confirmdialog';
import Toast from 'primevue/toast';
import '@/assets/main.css';

// 임시: 관리자/회원 구분 (추후 로그인 연동)
const isAdmin = ref(true) // true: 관리자, false: 회원
const sidebarVisible = ref(false)
const userInfo = ref(null)
const route = useRoute()
const router = useRouter()
const isMobile = ref(false);

// 로그인 후 userInfo를 세팅하는 예시(실제 구현에서는 로그인 성공 시 setUserInfo 호출)
function setUserInfo(info) {
  userInfo.value = info
}
window.setUserInfo = setUserInfo;

// 예시: 페이지 새로고침 시 세션이 있으면 userInfo 자동 세팅(간단 버전)
supabase.auth.getUser().then(async ({ data }) => {
  if (data?.user?.email) {
    const { data: member } = await supabase
      .from('members')
      .select('role, company_name')
      .eq('id_email', data.user.email)
      .single()
    if (member) userInfo.value = member
  }
})




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
  { path: /^\/admin\/notices\/create\/?$/, menuName: () => '공지사항 작성' },
  { path: /^\/admin\/notices\/edit\/.*$/, menuName: () => '공지사항 수정' },
  { path: /^\/admin\/products\/create\/?$/, menuName: () => '제품 등록' },
  { path: /^\/admin\/products\/edit\/.*$/, menuName: () => '제품 수정' },
  { path: /^\/admin\/hospitals\/create\/?$/, menuName: () => '거래처 등록' },
  { path: /^\/admin\/hospitals\/edit\/.*$/, menuName: () => '거래처 수정' },
  { path: /^\/hospitals\/create\/?$/, menuName: () => '거래처 등록' },
  { path: /^\/hospitals\/edit\/.*$/, menuName: () => '거래처 수정' },
  {
    path: /^\/admin\/settlement\/month\/\d{4}-\d{2}$/,
    menuName: (params) => `정산내역서 상세 - ${params[0].slice(-7, -5)}년 ${params[0].slice(-2)}월`
  },
  {
    path: /^\/admin\/settlement\/share\/\d{4}-\d{2}$/,
    menuName: (params) => `정산내역서 공유 - ${params[0].slice(-7, -5)}년 ${params[0].slice(-2)}월`
  },
  {
    path: /^\/user\/settlement-month-detail.*month=(\d{4}-\d{2})/,
    menuName: (params) => `정산내역서 상세 - ${params[1].slice(0,4)}년 ${params[1].slice(5,7)}월`
  },
  // 필요시 추가
];

// 이미 specialLayoutRoutes에 /admin/hospitals/edit/ 경로가 없다면 추가
if (!specialLayoutRoutes.some(r => r.path && r.path.toString() === '/^\/admin\/hospitals\/edit\//')) {
  specialLayoutRoutes.push({
    path: /^\/admin\/hospitals\/edit\//,
    menuName: () => '거래처 수정'
  });
}

const currentSpecial = computed(() => {
  const path = route.path;
  return specialLayoutRoutes.find(r => r.path.test(path));
});

const isSpecialLayout = computed(() => !!currentSpecial.value);
const isLoginOrSignup = computed(() => ['/login', '/signup'].includes(route.path));

const showSidebar = computed(() => !isLoginOrSignup.value && !isSpecialLayout.value);
const showCompany = computed(() => !isLoginOrSignup.value && !isSpecialLayout.value);
const showBack = computed(() => !isLoginOrSignup.value && isSpecialLayout.value);
const hideMenuToggle = computed(() => !isLoginOrSignup.value && isSpecialLayout.value && isMobile.value);

const defaultMenuName = computed(() => {
const menuNameMap = {
  '/admin/notice/list': '공지사항',
  '/admin/members/list': '회원 목록',
  '/admin/products/list': '수수료율 관리',
  '/admin/hospitals/list': '거래처 목록',
  '/admin/filter/list': '필터링 요청',
  '/admin/pharmaceutical-companies': '제약사 관리',
  '/admin/edi/months': '마감 일정 관리',
  '/admin/edi/list': 'EDI 증빙 파일',
  '/admin/settlement/month': '정산내역서',
  '/notice/list': '공지사항',
  '/products/list': '수수료율',
  '/hospitals/list': '거래처',
  '/filter/create': '필터링 요청',
  '/filter/list': '필터링 내역',
  '/edi/submit': 'EDI 자료 제출',
  '/edi/list': 'EDI 제출 내역',
  '/settlement/month': '정산내역서',
  '/products/list': '수수료율표',
  '/notice/list': '공지사항',
  '/notice/detail': '공지사항',
  };
  const path = route.path;
  const params = route.params;
  if (path.startsWith('/admin/settlement/month/') && params.year_month) {
    const [year, month] = params.year_month.split('-');
    return `월별 정산 현황 > ${year}년 ${parseInt(month, 10)}월`;
  }
  return menuNameMap[path] || '';
});

const menuName = ref('');
watch(
  () => route.fullPath,
  async () => {
    if (isSpecialLayout.value && currentSpecial.value && typeof currentSpecial.value.menuName === 'function') {
      menuName.value = await currentSpecial.value.menuName(route.params);
    } else {
      menuName.value = defaultMenuName.value;
    }
  },
  { immediate: true }
);

const handleLogout = async () => {
  await supabase.auth.signOut()
  router.push('/login')
}
const handleProfile = () => {
  // 내 정보 변경 로직(추후 구현)
  alert('내 정보 변경 기능은 추후 제공됩니다.')
}

function handleMenuClick() {
  if (window.innerWidth <= 900) sidebarVisible.value = false
}

const checkMobile = () => {
  isMobile.value = window.innerWidth <= 900;
};

onMounted(() => {
  checkMobile();
  window.addEventListener('resize', checkMobile);
});

onUnmounted(() => {
  window.removeEventListener('resize', checkMobile);
});

// 로그인/회원가입 화면일 때 body에 login-page 클래스 추가
watch(
  () => route.path,
  (newPath) => {
    if (['/login', '/signup'].includes(newPath)) {
      document.body.classList.add('login-page');
    } else {
      document.body.classList.remove('login-page');
    }

    
        
    // 스크롤이 필요한 페이지들
    const scrollEnabledPages = [
      '/login', 
      '/signup', 
      '/admin/notices/create', 
      '/admin/notices/detail/',  // 동적 라우트 체크를 위해 끝에 /만 남김
      '/admin/notices/edit/',    // 동적 라우트 체크를 위해 끝에 /만 남김
      '/admin/products/create',
      '/admin/products/edit/',
      '/filter/create',
      '/edi/files/'
    ];
    
    // 동적 라우트를 포함한 페이지 체크
    const isScrollEnabled = scrollEnabledPages.some(page => 
      newPath.startsWith(page)
    );
    
    if (isScrollEnabled) {
      document.documentElement.classList.add('scroll-enabled');
      document.body.classList.add('scroll-enabled');
    } else {
      document.documentElement.classList.remove('scroll-enabled');
      document.body.classList.remove('scroll-enabled');
    }
  },
  { immediate: true }
);

function toggleMobileSidebar() {
  sidebarVisible.value = !sidebarVisible.value;
}
</script>

<template>
  <div class="layout">
    <Toast />
    <ConfirmDialog />
    <SidebarMenu
      v-if="showSidebar"
      :visible="sidebarVisible"
      :user-info="userInfo"
      @menu-click="handleMenuClick"
      @toggle="sidebarVisible = false"
    />
    <div 
      v-if="sidebarVisible && isMobile" 
      class="content-overlay" 
      @click="toggleMobileSidebar">
    </div>
    <TopbarMenu
      v-if="!isLoginOrSignup"
      :menu-name="menuName"
      :company-name="userInfo?.company_name || ''"
      :show-logo="showCompany"
      :hide-menu-toggle="hideMenuToggle"
      :show-back="showBack"
      @logout="handleLogout"
      @profile="handleProfile"
      @toggle-sidebar="toggleMobileSidebar"
    />
    <div class="main-content main-margin" :class="{ 'no-sidebar': !showSidebar }">
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
.content-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.4);
  z-index: 1999; /* 모바일 사이드바(2000) 바로 아래 */
}
</style>
