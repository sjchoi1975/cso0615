<template>
  <div class="sidebar-container" :class="{ 'mobile-visible': visible }">
    <aside
      class="sidebar"
      :class="{ 'sidebar-mobile-open': visible }"
      :style="isMobile && visible ? 'position: fixed; left: 0; top: 0; z-index: 2000;' : ''"
    >
      <div v-if="isMobile" class="mobile-sidebar-header">
        <span class="logo-text">Company</span>
      </div>
      <nav>
        <div
          v-for="item in menuItems"
          :key="item.label"
          class="menu-group-wrapper"
          @mouseenter="!isMobile && item.items ? onGroupEnter(item.label) : null"
          @mouseleave="!isMobile && item.items ? onGroupLeave() : null"
        >
          <div
            class="menu-item menu-group-label clickable"
            v-if="item.items"
            @click="isMobile ? toggleGroup(item.label) : null"
            :class="{ 'router-link-exact-active': activeGroup === item.label }"
          >
            <div class="menu-item-content">
              <i :class="item.icon"></i>
              <span class="menu-label">{{ item.label }}</span>
              <i 
                v-if="isMobile" 
                :class="expandedGroup === item.label ? 'pi pi-chevron-down' : 'pi pi-chevron-right'"
                style="margin-left: auto;"
              ></i>
            </div>
          </div>
          <div 
            v-if="item.items && (hoveredGroup === item.label || (isMobile && expandedGroup === item.label))"
            class="sub-menu-container"
          >
            <RouterLink
              v-for="sub in item.items"
              :key="sub.label"
              :to="sub.to"
              class="sub-menu-item menu-item"
              @click="handleSubMenuClick"
            >
              <div class="menu-item-content">
                <i :class="sub.icon"></i>
                <span>{{ sub.label }}</span>
              </div>
            </RouterLink>
          </div>
          <RouterLink
            v-else-if="!item.items"
            :to="item.to"
            class="menu-item"
            @click="$emit('menu-click')"
          >
            <div class="menu-item-content">
              <i :class="item.icon"></i>
              <span class="menu-label">{{ item.label }}</span>
            </div>
          </RouterLink>
        </div>
      </nav>
    </aside>
    <!-- 오버레이: 사이드바 오른쪽에만 표시 -->
    <div v-if="visible && isMobile" class="sidebar-overlay" @click="$emit('toggle')"></div>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { supabase } from '@/supabase';
import { useRouter, useRoute } from 'vue-router';

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  userInfo: {
    type: Object,
    default: () => ({})
  }
});
const emit = defineEmits(['toggle', 'menu-click']);

const route = useRoute();

const adminMenu = [
  // { label: '대시보드', icon: 'pi pi-home', to: '/' }, // 임시 히든 처리
  { label: '공지사항 관리', icon: 'pi pi-bell', items: [
      { label: '공지사항 목록', icon: 'pi pi-list', to: '/admin/notice/list' },
    ]
  },
  { label: '회원 관리', icon: 'pi pi-users', items: [
      { label: '회원 목록', icon: 'pi pi-list', to: '/admin/members/list' },
    ]
  },
  { label: '제품 관리', icon: 'pi pi-box', items: [
      { label: '수수료율 관리', icon: 'pi pi-list', to: '/admin/products/list' },
    ]
  },
  { label: '거래처 관리', icon: 'pi pi-building', items: [
      { label: '거래처 목록', icon: 'pi pi-list', to: '/admin/hospitals/list' },
    ]
  },
  { label: '필터링 관리', icon: 'pi pi-filter', items: [
      { label: '필터링 요청 목록', icon: 'pi pi-list', to: '/admin/filter/list' },
      { label: '제약사 관리', icon: 'pi pi-building', to: '/admin/pharmaceutical-companies' },
    ]
  },
  { label: 'EDI 파일 관리', icon: 'pi pi-file-excel', items: [
      { label: 'EDI 제출월 설정', icon: 'pi pi-calendar-plus', to: '/admin/edi/months' },
      { label: 'EDI 제출 목록', icon: 'pi pi-list', to: '/admin/edi/list' },
    ]
  },
  { label: '정산 관리', icon: 'pi pi-wallet', items: [
      { label: '월별 정산 현황', icon: 'pi pi-list', to: '/admin/settlement/list' },
    ]
  },
];
const userMenu = [
  { label: '공지사항', icon: 'pi pi-bell', to: '/notice/list' },
  { label: '수수료율', icon: 'pi pi-list', to: '/products/list' },
  { label: '거래처', icon: 'pi pi-building', to: '/hospitals/list' },
  { label: '필터링', icon: 'pi pi-filter', items: [
      { label: '필터링 요청', icon: 'pi pi-plus', to: '/filter/create' },
      { label: '요청 내역', icon: 'pi pi-list', to: '/filter/list' },
    ]
  },
  { label: 'EDI 제출', icon: 'pi pi-upload', items: [
      { label: 'EDI 제출', icon: 'pi pi-upload', to: '/edi/submit' },
      { label: '제출 내역', icon: 'pi pi-list', to: '/edi/list' },
    ]
  },
  { label: '정산내역서', icon: 'pi pi-wallet', to: '/settlement/list' },
];
const menuItems = computed(() => props.userInfo?.role === 'admin' ? adminMenu : userMenu);

const activeGroup = computed(() => {
  const currentPath = route.path;
  for (const group of menuItems.value) {
    if (group.items && group.items.some(subItem => currentPath.startsWith(subItem.to))) {
      return group.label;
    }
  }
  return null;
});

const hoveredGroup = ref(null);
const expandedGroup = ref(null);

const onGroupEnter = (label) => {
  hoveredGroup.value = label;
};

const onGroupLeave = () => {
  hoveredGroup.value = null;
};

const toggleGroup = (label) => {
  if (expandedGroup.value === label) {
    expandedGroup.value = null;
  } else {
    expandedGroup.value = label;
  }
};

const handleSubMenuClick = () => {
  emit('menu-click');
  // 모바일에서 하위 메뉴 클릭 시 메뉴 닫기
  if (isMobile.value) {
    expandedGroup.value = null;
  }
};

const sidebarHover = ref(false);

const isMobile = ref(window.innerWidth <= 900);
const handleResize = () => {
  isMobile.value = window.innerWidth <= 900;
  // 데스크톱으로 변경 시 확장된 그룹 초기화
  if (!isMobile.value) {
    expandedGroup.value = null;
  }
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

const router = useRouter();
const onLogout = async () => {
  await supabase.auth.signOut();
  router.push('/login');
};

const isAdmin = computed(() => props.userInfo?.role === 'admin');
</script>



<style scoped>
/* ========================================================================================================= */
/* 사이드바 스타일
/* ========================================================================================================= */
.sidebar {
  width: 3rem !important;
  position: fixed;
  top: 3rem !important; /* 탑바 아래에서 시작 */
  min-height: calc(100vh - 3.0rem) !important;
  background: #fff !important;
  border-right: 1px solid var(--gray-400) !important;
  box-shadow: 2px 0 8px rgba(0,0,0,0.04) !important;
  z-index: 900 !important;
  transition: width 0.2s cubic-bezier(.4,0,.2,1) !important;
  overflow-x: hidden !important;
}

.sidebar:hover {
  width: 15rem !important;
}

.menu-item {
  display: flex;
  align-items: center !important;
  padding: 0.8rem 0.6rem !important;
  color: #222 !important;
  text-decoration: none !important;
  font-size: var(--font-size-110) !important;
  font-weight: 500 !important;
  transition: background 0.2s, color 0.2s !important;
  white-space: nowrap !important;
}

.menu-item i {
  margin-right: 0.8rem;
  font-size: var(--font-size-110) !important;
  font-weight: 500 !important;
  min-width: 24px !important;
  text-align: center !important;
}

.menu-label {
  opacity: 1 !important;
  pointer-events: auto !important;
  transition: opacity 0.2s !important;
}

@media (min-width: 901px) {
  .menu-label {
    opacity: 0 !important;
    pointer-events: none !important;
  }
  .sidebar:hover .menu-label {
    opacity: 1 !important;
    pointer-events: auto !important;
  }
}

.menu-item.router-link-exact-active {
  background: var(--primary) !important;
  color: #fff !important;
}

.menu-item:hover {
  background: var(--primary-light) !important;
  color: var(--text-primary) !important;
}

.menu-group-label.clickable {
  cursor: pointer !important;
}

.sub-menu-item {
  padding-left: 3.2rem !important;
  font-size: var(--font-size-base) !important;
}

/* 모바일 사이드바(접힘/펼침) ================= */
@media (max-width: 900px) {
  .sidebar {
    top: 0 !important;
    width: 0 !important;
    min-width: 0 !important;
    max-width: 0 !important;
    overflow: hidden !important;
    transition: width 0.2s;
  }
  .sidebar.sidebar-mobile-open {
    top: 0 !important;
    width: 60vw !important;
    min-width: 60vw !important;
    max-width: 60vw !important;
    height: 100vh !important;
    position: fixed !important;
    z-index: 2000 !important;
  }
}

.sub-menu-container {
  transition: all 0.3s ease;
}

.menu-group-label .menu-item-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.menu-group-label .pi-chevron-right,
.menu-group-label .pi-chevron-down {
  transition: transform 0.3s ease;
}

@media (max-width: 900px) {
  .sub-menu-item {
    padding-left: 2rem;
  }
}

/* 모바일 사이드바 헤더 */
.mobile-sidebar-header {
  padding: 0.5rem 1rem;
  text-align: center;
  border-bottom: 1px solid rgba(222, 226, 230, 0.5);
  background: var(--gray-200) !important;
  height: 3rem;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0rem;
}

.logo-text {
  font-size: 1.5rem !important;
  font-weight: 600 !important;
    color: #333 !important;
}
</style>