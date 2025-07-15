<template>
  <div 
    class="sidebar-container" 
  >
    <aside
      class="sidebar"
      :class="{ 'sidebar-mobile-open': visible }"
    >
      <div v-if="isMobile" class="mobile-sidebar-header">
        <span class="logo-text">Company</span>
      </div>
      <nav>
        <div
          v-for="item in menuItems"
          :key="item.label"
        >
          <RouterLink
            v-if="!item.onClick"
            :to="item.to"
            class="menu-item"
            @click="$emit('menu-click')"
          >
            <div class="menu-item-content">
              <font-awesome-icon :icon="item.icon" class="menu-icon-fa" />
              <span class="menu-label">{{ item.label }}</span>
            </div>
          </RouterLink>
          <a
            v-else
            href="#"
            class="menu-item"
            @click.prevent="item.onClick"
          >
            <div class="menu-item-content">
              <font-awesome-icon :icon="item.icon" class="menu-icon-fa" />
              <span class="menu-label">{{ item.label }}</span>
            </div>
          </a>
        </div>
        
        <!-- 매뉴얼 섹션 -->
        <div class="manual-section">
          <div class="manual-divider"></div>
          <div
            v-for="manual in manualItems"
            :key="manual.label"
          >
            <RouterLink
              :to="manual.to"
              class="menu-item manual-item"
              @click="$emit('menu-click')"
            >
              <div class="menu-item-content">
                <font-awesome-icon :icon="manual.icon" class="menu-icon-fa" />
                <span class="menu-label">{{ manual.label }}</span>
              </div>
            </RouterLink>
          </div>
        </div>
      </nav>
    </aside>
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
  { label: '공지사항 관리', icon: ['fas', 'bullhorn'], to: '/admin/notice/list' },
  { label: '회원 목록', icon: ['fas', 'users'], to: '/admin/members/list' },
  { label: '수수료율 관리', icon: ['fas', 'pills'], to: '/admin/products/list' },
  { label: '거래처 목록', icon: ['far', 'hospital'], to: '/admin/hospitals/list' },
  { label: '필터링 요청', icon: ['fas', 'filter'], to: '/admin/filter/list' },
  { label: '제약사 관리', icon: ['far', 'building'], to: '/admin/pharmaceutical-companies' },
  { label: '마감 일정 관리', icon: ['far', 'calendar-days'], to: '/admin/edi/months' },
  { label: 'EDI 증빙 파일', icon: ['far', 'file-lines'], to: '/admin/edi/dashboard' },
  { label: '정산내역서', icon: ['fas', 'credit-card'], to: '/admin/settlement/month' },
];

const goToEdiSubmit = async () => {
  // 1. 가장 최근 정산월 id 조회
  const today = new Date().toISOString().split('T')[0];
  const { data: months } = await supabase
    .from('edi_months')
    .select('id')
    .lte('start_date', today)
    .gte('end_date', today)
    .order('settlement_month', { ascending: false });
  const settlementMonthId = months && months.length > 0 ? months[0].id : null;
  // 무조건 EDI 제출 화면으로 이동
  router.push(settlementMonthId ? `/edi/submit/${settlementMonthId}` : '/edi/submit');
  emit('menu-click'); // 모바일에서 메뉴 닫기
};

const userMenu = [
  { label: '공지사항', icon: ['fas', 'bullhorn'], to: '/notice/list' },
  { label: '수수료율', icon: ['fas', 'pills'], to: '/products/list' },
  { label: '거래처', icon: ['far', 'hospital'], to: '/hospitals/list' },
  { label: '필터링 요청', icon: ['fas', 'filter'], to: '/filter/create' },
  { label: '필터링 내역', icon: ['fas', 'list-check'], to: '/filter/list' },
  { label: 'EDI 제출', icon: ['fas', 'upload'], onClick: goToEdiSubmit },
  { label: '정산내역서', icon: ['fas', 'credit-card'], to: '/settlement/month' },
];

const adminManualItems = [
  { label: '관리자 매뉴얼', icon: ['fas', 'book'], to: '/manual/admin' },
  { label: '이용자 매뉴얼', icon: ['fas', 'book-open'], to: '/manual/user' },
];

const userManualItems = [
  { label: '이용자 매뉴얼', icon: ['fas', 'book-open'], to: '/manual/user' },
];

const menuItems = computed(() => props.userInfo?.role === 'admin' ? adminMenu : userMenu);
const manualItems = computed(() => props.userInfo?.role === 'admin' ? adminManualItems : userManualItems);

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

const isMobile = ref(false);
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
/* 기본(데스크탑) 스타일 */
/* ========================================================================================================= */

.sidebar {
  width: 3rem;
  position: fixed;
  top: 3rem;
  height: calc(100vh - 3rem);
  background: #fff;
  border-right: 1px solid var(--gray-400);
  box-shadow: 2px 0 8px rgba(0,0,0,0.04);
  z-index: 900;
  transition: width 0.2s cubic-bezier(.4,0,.2,1);
  overflow-x: hidden;
  white-space: nowrap;
}

.sidebar nav {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.sidebar:hover {
  width: 15rem;
}

.menu-item {
  display: flex;
  align-items: center;
  padding: 0.8rem 0.6rem;
  color: #555;
  text-decoration: none;
  font-size: var(--font-size-110);
  font-weight: 500;
  transition: background 0.2s, color 0.2s;
}

.menu-icon-fa {
  margin-right: 0.8rem;
  font-size: var(--font-size-110);
  min-width: 24px;
  text-align: center;
}

.menu-item-content {
  display: flex;
  align-items: center;
  width: 100%;
}

.menu-item:hover {
  background: var(--primary-lightest);
  color: #222;
}

.menu-item.router-link-exact-active {
  background: var(--primary);
  color: #fff;
  font-weight: 500;
}

.menu-label {
  opacity: 0;
  transition: opacity 0.1s ease-in-out;
  flex-grow: 1;
}

.sidebar:hover .menu-label {
  opacity: 1;
}

.mobile-sidebar-header {
  display: none;
}

/* 매뉴얼 섹션 스타일 */
.manual-section {
  margin-top: auto;
  padding-top: 1rem;
}

.manual-divider {
  height: 1px;
  background: none;
  margin: 0.5rem 0.6rem;
  opacity: 0.5;
}

.manual-item {
  background-color: #f8f9fa;
  border-left: 0px solid #444;
}

.manual-item:hover {
  background: #ddd;
  color: #666;
  border-left-color: #888;
}

.manual-item.router-link-exact-active {
  background: #888;
  color: #fff;
  border-left-color: #666;
}

/* ========================================================================================================= */
/* 모바일 스타일 (900px 이하) */
/* ========================================================================================================= */

@media (max-width: 900px) {
  .sidebar {
    width: 60vw;
    height: 100vh;
    left: -60vw; /* 시작 위치 (화면 밖 왼쪽) */
    top: 0;
    transition: left 0.3s ease-in-out;
    box-shadow: none;
    padding-top: 3.6rem;
  }
  .menu-item {
    padding: 0.8rem 2rem;
  }
  .menu-item.router-link-exact-active {
    background: var(--primary);
    color: #fff;
    font-weight: 500;
  }
  .menu-item {
    font-size: var(--font-size-120);
  }
  .menu-icon-fa {
    font-size: var(--font-size-120);
  }
  /* 데스크탑 hover 기능 비활성화 */
  .sidebar:hover {
    width: 60vw;
  }
  .sidebar.sidebar-mobile-open {
    left: 0; /* 열렸을 때 위치 */
    box-shadow: 4px 0 12px rgba(0,0,0,0.1);
    z-index: 2000;
  }
  .menu-label {
    opacity: 1; /* 모바일에서 라벨 항상 표시 */
  }
}
</style>