<template>
  <div class="auth-root">
    <h2 class="Signup-title">회원가입</h2>
    <form @submit.prevent="signup" class="auth-form">
      <label>아이디(이메일)</label>
      <input v-model="idEmail" type="email" placeholder="이메일" class="input" required />
      <label>비밀번호</label>
      <input v-model="password" type="password" placeholder="비밀번호" class="input" required />
      <label>비밀번호 확인</label>
      <input v-model="confirmPassword" type="password" placeholder="비밀번호 확인" class="input" required />
      <label>회사명</label>
      <input v-model="companyName" placeholder="회사명" class="input" required />
      <label>대표자명</label>
      <input v-model="ceoName" placeholder="대표자명" class="input" required />
      <label>사업자번호</label>
      <input v-model="bizNo" placeholder="사업자번호" class="input" required />
      <label>주소</label>
      <input v-model="address" placeholder="주소" class="input" required />
      <label>CSO 신고번호</label>
      <input v-model="csoRegistNo" placeholder="CSO 신고번호" class="input" required />
      <label>담당자명</label>
      <input v-model="managerName" placeholder="담당자명" class="input" required />
      <label>휴대폰번호</label>
      <input v-model="handphone" placeholder="휴대폰번호" class="input" required />
      <label>이메일(연락용)</label>
      <input v-model="contactEmail" type="email" placeholder="이메일(연락용)" class="input" required />
      <div style="display: flex; gap: 0.5rem; margin-top: 1.2rem;">
        <button type="button" class="cancel-btn" @click="goLogin" style="flex:1;">취소</button>
        <button type="submit" class="signup-btn" :disabled="loading" style="flex:1;">회원가입</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';

const idEmail = ref('');
const password = ref('');
const confirmPassword = ref('');
const companyName = ref('');
const ceoName = ref('');
const bizNo = ref('');
const address = ref('');
const csoRegistNo = ref('');
const managerName = ref('');
const handphone = ref('');
const contactEmail = ref('');
const loading = ref(false);
const router = useRouter();

const signup = async () => {
  if (password.value !== confirmPassword.value) {
    alert('비밀번호가 일치하지 않습니다.');
    return;
  }
  try {
    loading.value = true;
    const { data, error } = await supabase.auth.signUp({
      email: idEmail.value,
      password: password.value,
      options: { data: {
        company_name: companyName.value,
        ceo_name: ceoName.value,
        biz_no: bizNo.value,
        address: address.value,
        cso_regist_no: csoRegistNo.value,
        manager_name: managerName.value,
        handphone: handphone.value,
        contact_email: contactEmail.value,
        role: 'user'
      } }
    });
    if (error) throw error;
    // members 테이블에도 insert
    const { error: insertError } = await supabase.from('members').insert({
      id_email: idEmail.value,
      company_name: companyName.value,
      ceo_name: ceoName.value,
      biz_no: bizNo.value,
      address: address.value,
      cso_regist_no: csoRegistNo.value,
      manager_name: managerName.value,
      handphone: handphone.value,
      email: contactEmail.value,
      role: 'user',
      approval: 'unapproved'
    });
    if (insertError) {
      alert('members 테이블 insert 실패: ' + insertError.message);
      return;
    }
    alert('회원가입 성공! 관리자 인증 후 로그인 가능합니다.');
    router.push('/login');
  } catch (error) {
    alert('회원가입 실패: ' + error.message);
  } finally {
    loading.value = false;
  }
};

const goLogin = () => {
  router.push('/login');
};
</script>
