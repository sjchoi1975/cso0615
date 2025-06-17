<template>
  <div class="auth-root">
    <h2 class="auth-title">오티에프(OTF)</h2>
    <form @submit.prevent="login" class="auth-form">
      <label>아이디(이메일)</label>
      <input v-model="email" type="email" placeholder="이메일" class="input" required autofocus />
      <label>비밀번호</label>
      <input v-model="password" type="password" placeholder="비밀번호" class="input" required />
      <button type="submit" class="login-btn" :disabled="loading">로그인</button>
      <span class="signup-link" @click="goSignup">회원가입</span>
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
  try {
    loading.value = true;
    const { error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    });
    if (error) throw error;
    // 로그인 성공 후, role 등 정보 즉시 조회 및 반영
    const { data: member } = await supabase
      .from('members')
      .select('role, company_name')
      .eq('id_email', email.value)
      .single();
    if (member && window.setUserInfo) {
      window.setUserInfo(member);
    }
    if (member?.role === 'admin') {
      router.push('/');
    } else {
      router.push('/notice/list');
    }
  } catch (error) {
    alert('로그인 실패: ' + error.message);
  } finally {
    loading.value = false;
  }
};

const goSignup = () => {
  router.push('/signup');
};
</script>
