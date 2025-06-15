<script setup>
import { computed } from 'vue';
const props = defineProps({
  visible: Boolean,
  isAdmin: Boolean
});
const emit = defineEmits(['toggle']);

const adminMenu = [
  { label: '대시보드', icon: 'pi pi-home', to: '/' },
  { label: '공지사항 관리', icon: 'pi pi-bell', to: '/notice-admin' },
  { label: '회원 관리', icon: 'pi pi-users', to: '/members' },
  { label: '요율표 관리', icon: 'pi pi-list', to: '/rate-admin' },
  { label: '필터링 관리', icon: 'pi pi-filter', to: '/filter-admin' },
  { label: 'EDI 파일 관리', icon: 'pi pi-file', to: '/edi-admin' },
  { label: '정산 관리', icon: 'pi pi-wallet', to: '/settlement-admin' },
];
const userMenu = [
  { label: '대시보드', icon: 'pi pi-home', to: '/' },
  { label: '공지사항', icon: 'pi pi-bell', to: '/notice' },
  { label: '요율표', icon: 'pi pi-list', to: '/rate' },
  { label: '필터링', icon: 'pi pi-filter', to: '/filter' },
  { label: 'EDI 제출', icon: 'pi pi-upload', to: '/edi' },
  { label: '정산내역서', icon: 'pi pi-wallet', to: '/settlement' },
];
const menuItems = computed(() => props.isAdmin ? adminMenu : userMenu);
</script>

<template>
  <aside :class="['sidebar', { open: visible }]">
    <div class="sidebar-header">
      <span class="logo">CSO</span>
      <button class="close-btn" @click="$emit('toggle')">
        <i class="pi pi-times"></i>
      </button>
    </div>
    <nav class="menu-list">
      <RouterLink v-for="item in menuItems" :key="item.label" :to="item.to" class="menu-item" @click="$emit('toggle')">
        <i :class="item.icon"></i>
        <span>{{ item.label }}</span>
      </RouterLink>
    </nav>
  </aside>
</template>

<style scoped>
.sidebar {
  width: 220px;
  background: #fff;
  border-right: 1px solid #eee;
  min-height: 100vh;
  position: fixed;
  left: 0;
  top: 0;
  z-index: 1000;
  transform: translateX(-100%);
  transition: transform 0.3s;
  box-shadow: 2px 0 8px rgba(0,0,0,0.04);
}
.sidebar.open {
  transform: translateX(0);
}
.sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  border-bottom: 1px solid #eee;
}
.logo {
  font-weight: bold;
  font-size: 1.2rem;
  color: #2c3e50;
}
.close-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
}
.menu-list {
  display: flex;
  flex-direction: column;
  margin-top: 1rem;
}
.menu-item {
  display: flex;
  align-items: center;
  padding: 0.8rem 1.2rem;
  color: #333;
  text-decoration: none;
  font-size: 1rem;
  transition: background 0.2s;
}
.menu-item i {
  margin-right: 0.8rem;
  font-size: 1.2rem;
}
.menu-item.router-link-exact-active {
  background: #f0f4ff;
  color: #1976d2;
}
.menu-item:hover {
  background: #f5f5f5;
}
@media (max-width: 900px) {
  .sidebar {
    position: fixed;
    height: 100vh;
    z-index: 2000;
    width: 70vw;
    min-width: 180px;
    max-width: 320px;
  }
}
</style> 