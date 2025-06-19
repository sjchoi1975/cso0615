<template>
  <div class="sidebar-container" :class="{ 'mobile-visible': visible }">
    <aside
      class="sidebar"
      :class="{ 'sidebar-mobile-open': visible }"
      :style="isMobile && visible ? 'position: fixed; left: 0; top: 0; z-index: 2000;' : ''"
    >
      <nav>
        <div
          v-for="item in menuItems"
          :key="item.label"
          class="menu-group-wrapper"
          @mouseenter="item.items ? onGroupEnter(item.label) : null"
          @mouseleave="item.items ? onGroupLeave() : null"
        >
          <div
            class="menu-item menu-group-label clickable"
            v-if="item.items"
          >
            <div class="menu-item-content">
              <i :class="item.icon"></i>
              <span class="menu-label">{{ item.label }}</span>
            </div>
          </div>
          <div v-if="item.items && hoveredGroup === item.label">
            <RouterLink
              v-for="sub in item.items"
              :key="sub.label"
              :to="sub.to"
              class="sub-menu-item menu-item"
              @click="$emit('menu-click')"
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
import { useRouter } from 'vue-router';

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

const adminMenu = [
  // { label: '대시보드', icon: 'pi pi-home', to: '/' }, // 임시 히든 처리
  { label: '공지사항 관리', icon: 'pi pi-bell', items: [
      { label: '공지사항 목록', icon: 'pi pi-list', to: '/admin/notice/list' },
    ]
  },
  { label: '회원 관리', icon: 'pi pi-users', items: [
      { label: '회원목록', icon: 'pi pi-list', to: '/admin/members/list' },
    ]
  },
  { label: '제품 관리', icon: 'pi pi-box', items: [
      { label: '요율표 관리', icon: 'pi pi-list', to: '/admin/products/list' },
    ]
  },
  { label: '필터링 관리', icon: 'pi pi-filter', items: [
      { label: '필터링 요청 목록', icon: 'pi pi-list', to: '/admin/filter/list' },
      { label: '제약사 관리', icon: 'pi pi-building', to: '/admin/pharmaceutical-companies' },
    ]
  },
  { label: 'EDI 파일 관리', icon: 'pi pi-file', items: [
      { label: 'EDI 제출 내역', icon: 'pi pi-list', to: '/admin/edi/list' },
    ]
  },
  { label: '정산 관리', icon: 'pi pi-wallet', items: [
      { label: '월별 정산 현황', icon: 'pi pi-list', to: '/admin/settlement/month' },
    ]
  },
];
const userMenu = [
  { label: '공지사항', icon: 'pi pi-bell', to: '/notice/list' },
  { label: '요율표', icon: 'pi pi-list', to: '/products/list' },
  { label: '필터링', icon: 'pi pi-filter', items: [
      { label: '신규 요청', icon: 'pi pi-plus', to: '/filter/create' },
      { label: '요청 내역', icon: 'pi pi-list', to: '/filter/list' },
    ]
  },
  { label: 'EDI 등록', icon: 'pi pi-upload', items: [
      { label: '신규 등록', icon: 'pi pi-plus', to: '/edi/upload' },
      { label: '등록 내역', icon: 'pi pi-list', to: '/edi/list' },
    ]
  },
  { label: '정산내역서', icon: 'pi pi-wallet', to: '/settlement/month' },
];
const menuItems = computed(() => props.userInfo?.role === 'admin' ? adminMenu : userMenu);

const hoveredGroup = ref(null);
const onGroupEnter = (label) => {
  hoveredGroup.value = label;
};
const onGroupLeave = () => {
  hoveredGroup.value = null;
};

const sidebarHover = ref(false);

const isMobile = ref(window.innerWidth <= 900);
const handleResize = () => {
  isMobile.value = window.innerWidth <= 900;
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

