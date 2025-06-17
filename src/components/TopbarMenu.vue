<script setup>
import { ref } from 'vue';
const props = defineProps({
  menuName: String,
  companyName: String
});
const emit = defineEmits(['logout', 'profile']);
const dropdownOpen = ref(false);
const toggleDropdown = () => {
  dropdownOpen.value = !dropdownOpen.value;
};
const onLogout = () => {
  emit('logout');
  dropdownOpen.value = false;
};
const onProfile = () => {
  emit('profile');
  dropdownOpen.value = false;
};
</script>

<template>
  <header class="topbar">
    <div class="left">
      <span class="logo-title">OTF</span>
      <span class="menu-title">{{ menuName }}</span>
    </div>
    <div class="right">
      <span class="company-name">{{ companyName }}</span>
      <div class="profile-menu">
        <button class="profile-btn" @click="$emit('profile')">
          <i class="pi pi-user"></i>
        </button>
        <button class="logout-btn" @click="$emit('logout')">
          <i class="pi pi-sign-out"></i>
        </button>
      </div>
    </div>
  </header>
</template>
