<template>
  <div class="auth-root">
    <h2 class="login-title">Company</h2>
    <form @submit.prevent="login" class="auth-form">
      <label>ID</label>
      <input v-model="email" type="email" placeholder="이메일" class="input" required autofocus />
      <label>PW</label>
      <input v-model="password" type="password" placeholder="비밀번호" class="input" required />
      <button type="submit" class="login-btn" :disabled="loading">로그인</button>
      <span class="link" style="text-align: center; margin-top: 1rem;" @click="goSignup">회원가입</span>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';

const email = ref('');
const password = ref('');
const loading = ref(false);
const router = useRouter();

const login = async () => {
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
