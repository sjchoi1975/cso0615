<script setup>
import { RouterLink, RouterView } from 'vue-router'
import HelloWorld from './components/HelloWorld.vue'
import { ref } from 'vue'
import SidebarMenu from './components/SidebarMenu.vue'

// 임시: 관리자/회원 구분 (추후 로그인 연동)
const isAdmin = ref(true) // true: 관리자, false: 회원
const sidebarVisible = ref(true)
</script>

<template>
  <div class="layout">
    <SidebarMenu :visible="sidebarVisible" :is-admin="isAdmin" @toggle="sidebarVisible = !sidebarVisible" />
    <div class="main-content">
      <button class="menu-toggle" @click="sidebarVisible = !sidebarVisible">
        <i class="pi pi-bars"></i>
      </button>
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
header {
  line-height: 1.5;
  max-height: 100vh;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

nav {
  width: 100%;
  font-size: 12px;
  text-align: center;
  margin-top: 2rem;
}

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }

  nav {
    text-align: left;
    margin-left: -1rem;
    font-size: 1rem;

    padding: 1rem 0;
    margin-top: 1rem;
  }
}

.layout {
  display: flex;
  min-height: 100vh;
}
.main-content {
  flex: 1;
  padding: 1.5rem;
  transition: margin-left 0.3s;
}
.menu-toggle {
  display: none;
  position: fixed;
  top: 1rem;
  left: 1rem;
  z-index: 1001;
  background: #fff;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}
@media (max-width: 900px) {
  .layout {
    flex-direction: column;
  }
  .main-content {
    padding: 1rem;
  }
  .menu-toggle {
    display: block;
  }
}
</style>
