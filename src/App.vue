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
const isSidebarHovered = ref(false);

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

// 현재 라우트에 따른 메뉴명 추출
const menuNameMap = {
  '/admin/notice/list': '공지사항 목록',
  '/admin/members/list': '회원 목록',
  '/admin/products/list': '수수료율 관리',
  '/admin/filter/list': '필터링 요청 목록',
  '/admin/pharmaceutical-companies': '제약사 관리',
  '/admin/edi/months': 'EDI 제출월 설정',
  '/admin/edi/list': 'EDI 제출 목록',
  '/admin/settlement/month': '월별 정산 현황',
     
  '/notice/list': '공지사항',
  '/products/list': '수수료율',
  '/hospitals/list': '거래처',
  '/filter/create': '필터링 요청',
  '/filter/list': '요청 내역',
  '/edi/submit': 'EDI 제출',
  '/edi/list': '제출 내역',
  '/settlement/list': '정산내역서',
}
const menuName = computed(() => {
  const path = route.path;
  const params = route.params;

  if (path.startsWith('/admin/settlement/month/') && params.year_month) {
    const [year, month] = params.year_month.split('-');
    return `월별 정산 현황 > ${year}년 ${parseInt(month, 10)}월`;
  }
  
  return menuNameMap[path] || '';
});

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
      '/edi/upload'
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

const handleSidebarHover = (hovered) => {
  isSidebarHovered.value = hovered;
};
</script>

<template>
  <div class="layout">
    <Toast />
    <ConfirmDialog />
    <SidebarMenu
      v-if="!['/login','/signup'].includes(route.path)"
      :visible="sidebarVisible"
      :user-info="userInfo"
      @menu-click="handleMenuClick"
      @sidebar-hover="handleSidebarHover"
    />
    <div v-if="sidebarVisible" class="sidebar-overlay" @click="sidebarVisible = false"></div>
    <div v-if="isSidebarHovered" class="content-overlay"></div>
    <TopbarMenu
      v-if="!['/login','/signup'].includes(route.path)"
      :menu-name="menuName"
      :company-name="userInfo?.company_name || ''"
      @logout="handleLogout"
      @profile="handleProfile"
      @toggle-sidebar="sidebarVisible = !sidebarVisible"
    />
    <div class="main-content main-margin">
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
.content-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(0, 0, 0, 0.2);
  z-index: 800; /* 사이드바(900)보다는 낮고, 콘텐츠보다는 높게 */
  display: none; /* 모바일에서는 보이지 않음 */
}

@media (min-width: 901px) {
  .content-overlay {
    display: block; /* PC에서만 보임 */
  }
}
</style>
