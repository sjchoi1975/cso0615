<template>  
  <div class="auth-root">
    <h2 class="login-title">Company</h2>
    <form @submit.prevent="login" class="login-form">
      <label>ID</label>
      <input v-model="email" 
        type="email" 
        placeholder="" 
        class="input-login" 
        required autofocus />
      <label style="margin-top: 1rem;">PW</label>
      <div class="input-eye-wrap">
        <input :type="showPassword ? 'text' : 'password'" 
          v-model="password" 
          placeholder="" 
          class="input-login" 
          required />
        <button type="button" 
          class="eye-btn" 
          @click="showPassword = !showPassword" 
          :aria-label="showPassword ? '비밀번호 숨기기' : '비밀번호 보기'">
          <span v-if="showPassword">
            <!-- eye-off SVG -->
            <svg xmlns="http://www.w3.org/2000/svg" 
              width="18" 
              height="18" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="currentColor" 
              stroke-width="2" 
              stroke-linecap="round" 
              stroke-linejoin="round">
              <path d="M17.94 17.94A10.06 10.06 0 0 1 12 20C7 20 2.73 16.11 1 12c.74-1.61 1.81-3.06 3.11-4.24M9.53 9.53A3.5 3.5 0 0 1 12 8.5c1.93 0 3.5 1.57 3.5 3.5 0 .47-.09.92-.26 1.33M14.47 14.47A3.5 3.5 0 0 1 12 15.5c-1.93 0-3.5-1.57-3.5-3.5 0-.47.09-.92.26-1.33"/>
              <line x1="1" y1="1" x2="23" y2="23"/>
            </svg>
          </span>
          <span v-else>
            <!-- eye SVG -->
            <svg xmlns="http://www.w3.org/2000/svg" 
              width="18" 
              height="18" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="currentColor" 
              stroke-width="2" 
              stroke-linecap="round" 
              stroke-linejoin="round">
              <path d="M1 12S5 5 12 5s11 7 11 7-4 7-11 7S1 12 1 12z"/>
              <circle cx="12" cy="12" r="3.5"/>
            </svg>
          </span>
        </button>
      </div>
      <button type="submit" class="login-btn" style="margin-top: 2rem;;">로그인</button>
      <span class="link" style="text-align: center; margin-top: 1.6rem;" @click="goSignup">회원가입</span>
    </form>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';

const email = ref('');
const password = ref('');
const loading = ref(false);
const router = useRouter();
const showPassword = ref(false);

const login = async () => {
  if (!email.value || !password.value) {
    alert('아이디와 비밀번호를 모두 입력해주세요.');
    return;
  }

  loading.value = true;
  try {
    // 1. 아이디(이메일) 존재 여부 확인 및 로그인 시도
    const { data: userCheck, error: userCheckError } = await supabase.auth.signInWithPassword({ email: email.value, password: password.value });
    if (userCheckError) {
      if (userCheckError.message.includes('Invalid login credentials')) {
        // 아이디 또는 비밀번호 오류 (구분 없이 안내)
        alert('아이디 또는 비밀번호가 일치하지 않습니다.');
      } else {
        alert('로그인 실패: ' + userCheckError.message);
      }
      return;
    }
    // 2. members 테이블에서 approval, role, company_name 조회
    const { data: memberRows, error: memberError } = await supabase.from('members').select('approval, role, company_name').eq('id_email', email.value).maybeSingle();
    if (memberError || !memberRows) {
      alert('회원 정보 조회 실패');
      return;
    }
    if (memberRows.approval !== 'approved') {
      alert('미인증 회원입니다. 관리자에게 문의해주세요.');
      return;
    }
    // 3. role 정보를 전역에 즉시 반영 (window.setUserInfo 등)
    if (window.setUserInfo) {
      window.setUserInfo(memberRows);
    }
    // 4. role에 따라 이동
    if (memberRows.role === 'admin') {
      router.push('/admin/notice/list');
    } else {
      router.push('/notice/list');
    }
  } finally {
    loading.value = false;
  }
};

const goSignup = () => {
  router.push('/signup');
};
</script>
