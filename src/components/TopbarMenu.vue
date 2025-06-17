<script setup>
import { ref, computed } from 'vue';
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
// 드롭다운 외부 클릭 시 닫기
const dropdownRef = ref(null);
if (typeof window !== 'undefined') {
  window.addEventListener('click', (e) => {
    if (dropdownOpen.value && dropdownRef.value && !dropdownRef.value.contains(e.target)) {
      dropdownOpen.value = false;
    }
  });
}
// 모바일 여부
const isMobile = ref(false);
if (typeof window !== 'undefined') {
  const checkMobile = () => {
    isMobile.value = window.innerWidth <= 900;
  };
  checkMobile();
  window.addEventListener('resize', checkMobile);
}
// 업체명에서 접두어 제거 후 첫글자 추출
function getFirstChar(name) {
  if (!name) return '';
  let n = name.trim();
  n = n.replace(/^(\(주\)|주식회사|\(유\)|유한회사|\(합\)|합자회사|\(유한\)|유한회사|\(재\)|재단법인|\(사\)|사단법인|\(공\)|공사|\(재단\)|재단|\(협\)|협동조합|\(조합\)|조합|\(학교\)|학교|\(의료\)|의료법인|\(법\)|법인|\(비영리\)|비영리법인|\(비영리법인\)|\(주식회사\)|\(유한회사\)|\(합자회사\)|\(재단법인\)|\(사단법인\)|\(공사\)|\(협동조합\)|\(조합\)|\(학교\)|\(의료법인\)|\(법인\)|\(비영리법인\)|\(비영리\))\s*/,'');
  n = n.trim();
  return n[0] ? n[0].toUpperCase() : '';
}
const companyInitial = computed(() => getFirstChar(props.companyName));
</script>

<template>
  <header class="topbar">
    <div class="left">
      <span class="logo-title">Company</span>
      <span class="menu-title">{{ menuName }}</span>
    </div>
    <div class="right">
      <div class="profile-dropdown-wrapper" ref="dropdownRef">
        <!-- PC: 업체명 전체, 모바일: 동그라미+첫글자 -->
        <span v-if="!isMobile" class="company-name profile-trigger" @click="toggleDropdown">
          {{ companyName }}
        </span>
        <span v-else class="profile-circle profile-trigger" @click="toggleDropdown">
          {{ companyInitial }}
        </span>
        <div v-if="dropdownOpen" class="profile-dropdown-box">
          <button class="dropdown-item" @click="onProfile">
            <i class="pi pi-user"></i>
            <span>내 정보</span>
          </button>
          <button class="dropdown-item" @click="onLogout">
            <i class="pi pi-sign-out"></i>
            <span>로그아웃</span>
          </button>
        </div>
      </div>
    </div>
  </header>
</template>
