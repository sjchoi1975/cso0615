<script setup>
import { RouterLink, RouterView } from 'vue-router'
import HelloWorld from './components/HelloWorld.vue'
import { ref, watch, computed, onMounted, onUnmounted } from 'vue'
import SidebarMenu from './components/SidebarMenu.vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/supabase'
import TopbarMenu from './components/TopbarMenu.vue'

// 임시: 관리자/회원 구분 (추후 로그인 연동)
const isAdmin = ref(true) // true: 관리자, false: 회원
const sidebarVisible = ref(false)
const userInfo = ref(null)
const route = useRoute()
const router = useRouter()

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

// 현재 라우트에 따른 메뉴명 추출(간단 예시)
const menuNameMap = {
  '/admin/notice/list': '공지사항 목록',
  '/admin/members/list': '회원 목록',
  '/admin/products/list': '요율표 관리',
  '/admin/filter/list': '필터링 요청 목록',
  '/admin/pharmaceutical-companies': '제약사 관리',
  '/admin/edi/list': 'EDI 제출 내역',
  '/admin/settlement/list': '정산내역서',
  '/notice/list': '공지사항',
  '/products/list': '요율표',
  '/filter/list': '요청 목록',
  '/filter/create': '필터링 요청',
  '/edi/list': '제출 내역',
  '/edi/upload': 'EDI 제출',
  '/settlement/list': '정산내역서',
}
const menuName = computed(() => menuNameMap[route.path] || '')

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
</script>

<template>
  <div class="layout">
    <SidebarMenu
      v-if="!['/login','/signup'].includes(route.path)"
      :visible="sidebarVisible"
      :user-info="userInfo"
      @menu-click="handleMenuClick"
    />
    <div v-if="sidebarVisible" class="sidebar-overlay" @click="sidebarVisible = false"></div>
    <TopbarMenu
      v-if="!['/login','/signup'].includes(route.path)"
      :menu-name="menuName"
      :company-name="userInfo?.company_name || ''"
      @logout="handleLogout"
      @profile="handleProfile"
    />
    <div class="main-content main-margin">
      <button v-if="!['/login','/signup'].includes(route.path)" class="menu-toggle" @click="sidebarVisible = !sidebarVisible">
        <i class="pi pi-bars"></i>
      </button>
      <RouterView />
    </div>
  </div>
</template>
