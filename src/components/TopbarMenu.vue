<template>
  <header class="topbar">
    <div class="left">
      <button v-if="showBack" class="menu-toggle show-back" @click="onLeftClick">
        <i class="pi pi-arrow-left"></i>
      </button>
      <button v-else-if="!hideMenuToggle" class="menu-toggle" @click="$emit('toggle-sidebar')">
        <i class="pi pi-bars"></i>
      </button>
      <span class="logo-title" v-if="showLogo">Company</span>
      <span class="menu-title">{{ menuName }}</span>
    </div>
    <div class="right">
      <div class="profile-dropdown-wrapper" ref="dropdownRef">
        <!-- PC/모바일 모두: 동그라미+첫글자 -->
        <span class="profile-circle profile-trigger" @click="toggleDropdown">
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


<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
const props = defineProps({
  menuName: String,
  companyName: String,
  showLogo: {
    type: Boolean,
    default: true
  },
  hideMenuToggle: {
    type: Boolean,
    default: false
  },
  showBack: {
    type: Boolean,
    default: false
  }
});
const emit = defineEmits(['logout', 'profile', 'toggle-sidebar']);
const router = useRouter();
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
const onLeftClick = () => {
  console.log('백키 클릭', props.showBack, window.history.length);
  if (props.showBack) {
    window.history.length > 1 ? router.back() : router.push('/edi/submit');
  } else {
    emit('toggle-sidebar');
  }
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
  n = n.replace(/^(\(주\)|주식회사|\(유\)|유한회사|\(합\)|합자회사|\(유한\)|유한회사|\(재\)|재단법인|\(사\)|사단법인|\(공\)|공사|\(재단\)|재단|\(협\)|협동조합|\(조합\)|조합|\(학교\)|학교|\(의료\)|의료법인|\(법\)|법인|\(비영리\)|비영리법인|비영리법인|\(주식회사\)|\(유한회사\)|\(합자회사\)|\(재단법인\)|\(사단법인\)|\(공사\)|\(협동조합\)|\(조합\)|\(학교\)|\(의료법인\)|\(법인\)|\(비영리법인\)|\(비영리\))\s*/,'');
  n = n.trim();
  return n[0] ? n[0].toUpperCase() : '';
}
const companyInitial = computed(() => getFirstChar(props.companyName));
console.log('showBack', props.showBack);
</script>



<style scoped>

/* ========================================================================================================= */
/* 탑바 스타일
/* ========================================================================================================= */

.topbar {
  position: fixed;
  width: 100vw !important;
  height: 3.0rem !important;
  background: #fff !important;
  padding: 0.5rem 1rem !important;
  box-shadow: 0 1px 2px rgba(0,0,0,0.1) !important;
  border-bottom: 1px solid var(--gray-400) !important;
  display: flex !important;
  justify-content: space-between !important;
  align-items: center !important;
  z-index: 1000 !important;
}


/* 탑바 로고명 ======================================== */
.topbar .logo-title {
  font-weight: bold !important;
  font-size: var(--font-size-140) !important;
  color: #222 !important;
  margin-right: 2rem !important;
  white-space: nowrap !important;
}


/* 탑바 메뉴(경로)명 =================================== */
.topbar .menu-title {
  font-size: var(--font-size-130) !important;
  color: #222 !important;
  font-weight: 600 !important;
  padding-left: 0rem !important;
  white-space: nowrap !important;
}


/* 모바일 메뉴 햄버거 버튼 */
.menu-toggle {
  display: none; /* 데스크톱에서는 숨김 */
  background: none !important;
  border: none !important;
  font-size: 1.4rem;
  color: #222;
  cursor: pointer;
  margin-top: 0.5rem;
  margin-right: 0.5rem;
 }

@media (max-width: 900px) {
  .menu-toggle {
    display: inline-block; /* 모바일에서 보임 */
  }

  .topbar .menu-title {
    font-size: var(--font-size-130) !important;
    color: #222 !important;
    padding-left: 0 !important; /* 햄버거 버튼이 있으므로 패딩 제거 */
    white-space: nowrap !important;
  }
}

@media (max-width: 900px) {
  .topbar .logo-title {
    display: none !important;
  }

  .menu-toggle {
    display: block !important;
    position: static !important; /* absolute에서 변경 */
    top: auto !important;
    left: auto !important;
    z-index: 1300;
  }
}

@media (min-width: 901px) {
  .menu-toggle {
    display: none;
  }
}


/* 프로필 - 동그라미 스타일 */
.profile-circle {
  display: inline-flex !important;
  align-items: center !important;
  justify-content: center !important;
  margin-right: 0 !important;
  width: 2.2rem !important;
  height: 2.2rem !important;
  border-radius: 50% !important;
  background: var(--primary) !important;
  color: #fff !important;
  border: none !important;
  font-size: var(--font-size-base) !important;
  text-decoration: none !important;
  box-sizing: border-box !important;
  transition: background 0.2s, color 0.2s !important;
}

.profile-trigger {
  cursor: pointer;
  font-weight: 400 !important;
  font-size: var(--font-size-base) !important;
  margin-right: 2rem !important;
}

@media (max-width: 900px) {
  .profile-dropdown-box {
    min-width: 120px !important;
    right: 0 !important;
    left: auto !important;
  }
  .profile-trigger {
    margin-right: 0 !important;
    font-size: var(--font-size-base) !important;
  }
}


/* 탑바 프로필 드롭다운 ================================ */
.profile-dropdown-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.profile-dropdown-box {
  position: absolute !important;
  right: 0 !important;
  top: 120% !important;
  min-width: 140px !important;
  background: #fff !important;
  border-radius: var(--border-radius) !important;
  box-shadow: 0 4px 16px rgba(0,0,0,0.10) !important;
  padding: 0.5rem 0 !important;
  z-index: 3000 !important;
  display: flex !important;
  flex-direction: column !important;
  gap: 0.2rem !important;
}

.dropdown-item {
  display: flex !important;
  align-items: center !important;
  gap: 0.75rem !important;
  padding: 0.5rem 1rem !important;
  background: none !important;
  border: none !important;
  width: 100% !important;
  font-size: var(--font-size-base) !important;
  color: #222 !important;
  cursor: pointer !important;
  transition: background 0.2s !important;
}

.dropdown-item:hover {
  background: #f4f6fa !important;
}



/* 사용 여부 확인 요망 ========================== */

.topbar .right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.topbar .company-name {
  font-size: var(--font-size-110) !important;
  font-weight: 400 !important;
  color: #999;
}

.topbar .profile-menu {
  display: flex;
  gap: 0.5rem;
}

.topbar .profile-btn,
.topbar .logout-btn {
  background: none;
  border: none;
  padding: 0.5rem;
  cursor: pointer;
  color: #666;
  transition: color 0.2s;
}

.topbar .profile-btn:hover,
.topbar .logout-btn:hover {
  color: #333;
}

@media (max-width: 768px) {
  .topbar {
    padding: 0.5rem 2rem 0.5rem 1rem !important;
  }
  .topbar .left h1 {
    font-size: var(--font-size-120) !important;
  }
}

.topbar .left {
  display: flex;
  align-items: center;
}

.menu-toggle.show-back {
  display: inline-block !important;
}
@media (min-width: 901px) {
  .menu-toggle:not(.show-back) {
    display: none !important;
  }
}


</style>

