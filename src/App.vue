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
    path: /^\/admin\/notices\/create$/,
    menuName: () => '공지사항 작성',
    showBack: true
  },
  {
    path: /^\/admin\/notices\/edit\//,
    menuName: () => '공지사항 수정',
    showBack: true
  },
  {
    path: /^\/admin\/products\/create$/,
    menuName: () => '제품 등록',
    showBack: true
  },
  {
    path: /^\/admin\/products\/edit\//,
    menuName: () => '제품 수정',
    showBack: true
  },
  {
    path: /^\/admin\/hospitals\/create$/,
    menuName: () => '거래처 등록',
    showBack: true
  },
  {
    path: /^\/hospitals\/create$/,
    menuName: () => '거래처 등록',
    showBack: true
  },
  {
    path: /^\/hospitals\/edit\//,
    menuName: () => '거래처 수정',
    showBack: true
  },
  // EDI 제출 관련 경로
  {
    path: /^\/edi\/submit\/\d+\/\d+$/, // EDI 증빙자료 제출
    async menuName(params) {
      const { hospitalId } = params;
      const { data: hospital } = await supabase
        .from('hospitals')
        .select('hospital_name')
        .eq('id', hospitalId)
        .single();
      return hospital ? hospital.hospital_name : '';
    },
    showBack: true
  },
  {
    path: /^\/edi\/submit\/\d+\/\d+\/detail$/, // EDI 증빙자료 제출내역
    async menuName(params) {
      const { hospitalId } = params;
      const { data: hospital } = await supabase
        .from('hospitals')
        .select('hospital_name')
        .eq('id', hospitalId)
        .single();
      return hospital ? hospital.hospital_name : '';
    },
    showBack: true
  },
  {
    path: /^\/edi\/submit\/\d+\/\d+\/[^\/]+\/edit$/, // EDI 증빙자료 제출내역 수정
    async menuName(params) {
      const { hospitalId } = params;
      const { data: hospital } = await supabase
        .from('hospitals')
        .select('hospital_name')
        .eq('id', hospitalId)
        .single();
      return hospital ? hospital.hospital_name : '';
    },
    showBack: true
  },
  {
    path: /^\/admin\/edi\/months\/list$/,
    menuName: () => 'EDI 증빙파일 상세',
    showBack: true
  },
  {
    path: /^\/admin\/settlement\/month\/[^\/]+$/,
    menuName: () => '정산내역서 상세',
    showBack: true
  },
  {
    path: /^\/admin\/settlement\/share\/[^\/]+$/,
    menuName: () => '정산내역서 공유',
    showBack: true
  },
  {
    path: /^\/settlement\/month\/detail/,
    menuName: () => {
      const month = route.query.month;
      if (month) {
        const [year, monthNum] = month.split('-');
        return `정산내역서 상세 - ${year}년 ${parseInt(monthNum)}월`;
      }
      return '정산내역서 상세';
    },
    showBack: true
  },
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
const isLoginOrSignup = computed(() => ['/login', '/signup', '/reset-password'].includes(route.path));

// 사이드바 표시 여부 결정
const showSidebar = computed(() => !isLoginOrSignup.value);
const showCompany = computed(() => !isLoginOrSignup.value && (!isSpecialLayout.value || (currentSpecial.value && !currentSpecial.value.showBack)));
const showBack = computed(() => !isLoginOrSignup.value && isSpecialLayout.value && currentSpecial.value?.showBack);
const hideMenuToggle = computed(() => !isLoginOrSignup.value && isSpecialLayout.value && currentSpecial.value?.showBack && isMobile.value);

const defaultMenuName = computed(() => {
const menuNameMap = {
  '/admin/notice/list': '공지사항',
  '/admin/members/list': '회원 목록',
  '/admin/products/list': '수수료율 관리',
  '/admin/hospitals/list': '거래처 목록',
  '/admin/filter/list': '필터링 요청',
  '/admin/pharmaceutical-companies': '제약사 관리',
  '/admin/edi/months': '마감 일정 관리',
  '/admin/edi/dashboard': 'EDI 증빙 파일',
  '/admin/edi/months/list': 'EDI 증빙파일 상세',
  '/admin/settlement/month': '정산내역서',
  '/notice/list': '공지사항',
  '/notice/detail': '공지사항 상세',  
  '/products/list': '수수료율',
  '/hospitals/list': '거래처',
  '/filter/create': '필터링 요청',
  '/filter/list': '필터링 내역',
  '/edi/submit': 'EDI 제출',
  '/settlement/month': '정산내역서',
  '/settlement/month/detail': '정산내역서 상세',
};
  
  const path = route.path;
  const params = route.params;

// EDI 제출 경로 처리
if (path.match(/^\/edi\/submit\/\d+$/)) {
  return 'EDI 제출';
}

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
  // 안내 alert 완전 제거
  // 기존: alert('내 정보 변경 기능은 추후 제공됩니다.')
};

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
      '/profile',
      '/profile/edit',
      '/admin/notices/create', 
      '/admin/notices/detail/',  // 동적 라우트 체크를 위해 끝에 /만 남김
      '/admin/notices/edit/',    // 동적 라우트 체크를 위해 끝에 /만 남김
      '/admin/products/create',
      '/admin/products/edit/',
      '/admin/hospitals/create',
      '/admin/hospitals/edit/',
      '/hospitals/create',
      '/hospitals/edit/',
      '/filter/create',
      '/edi/submit/',
      '/edi/submit/upload',
      '/edi/submit/detail',
      '/edi/submit/edit',
      '/settlement/month',
      '/manual/admin',    // 관리자 매뉴얼 페이지
      '/manual/user',     // 이용자 매뉴얼 페이지
      // =============================
      // [중요] 루트 App.vue에서만 있던 경로 (2024-06-07 기준)
      // '/edi/files/' 경로는 루트 App.vue에만 있었으나 혹시 모를 호환성/누락 방지 위해 추가함
      // 실제 사용 여부는 추후 확인 필요
      '/edi/files/',
      // =============================
    ];
    
    // 동적 라우트를 포함한 페이지 체크
    const isScrollEnabled = scrollEnabledPages.some(page => {
      if (page.endsWith('/')) {
        return newPath.startsWith(page);
      }
      return newPath === page;
    });
    
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
      :menuName="menuName"
      :companyName="userInfo?.company_name"
      :showLogo="showCompany"
      :hideMenuToggle="hideMenuToggle"
      :showBack="showBack"
      @logout="handleLogout"
      @profile="handleProfile"
      @toggle-sidebar="sidebarVisible = !sidebarVisible"
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
