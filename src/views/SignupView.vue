<template>
  <div class="auth-root">
    <h2 class="Signup-title">회원가입</h2>
    <form @submit.prevent="signup" class="auth-form">
      <label>아이디<span class="required">*</span></label>
      <input v-model="idEmail" type="email" placeholder="이메일" class="input" required />
      <label>비밀번호 <span class="required">*</span></label>
      <input v-model="password" type="password" placeholder="" class="input" required />
      <label>비밀번호 확인 <span class="required">*</span></label>
      <input v-model="confirmPassword" type="password" placeholder="" class="input" required />
      <label>회사명 <span class="required">*</span></label>
      <input v-model="companyName" placeholder="" class="input" required />
      <label>대표자명 <span class="required">*</span></label>
      <input v-model="ceoName" placeholder="" class="input" required />
      <label>사업자등록번호 <span class="required">*</span></label>
      <input v-model="bizNo" placeholder="" class="input" required />
      <label>주소</label>
      <input v-model="address" placeholder="" class="input" />
      <label>CSO 신고번호</label>
      <input v-model="csoRegistNo" placeholder="" class="input" />
      <label>담당자명</label>
      <input v-model="managerName" placeholder="" class="input" />
      <label>휴대폰 번호</label>
      <input v-model="handphone" placeholder="" class="input" />
      <label>이메일(연락용)</label>
      <input v-model="contactEmail" type="email" placeholder="" class="input" />
      <div style="display: flex; gap: 0.5rem; margin-top: 1.2rem;">
        <button type="button" class="cancel-btn" @click="goLogin" style="flex:1;">취소</button>
        <button type="submit" class="signup-btn" :disabled="loading" style="flex:1;">회원가입</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
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

// 사업자등록번호 자동 하이픈 추가
watch(bizNo, (newValue) => {
  // 숫자 이외의 문자를 모두 제거
  const digits = newValue.replace(/\D/g, '');
  
  // 길이에 따라 하이픈 추가
  let formatted = '';
  if (digits.length > 0) {
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 5) {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3)}`;
    } else {
      // 10자리까지만 입력받음
      formatted = `${digits.slice(0, 3)}-${digits.slice(3, 5)}-${digits.slice(5, 10)}`;
    }
  }
  
  // 값이 변경되었을 때만 업데이트하여 무한 루프 방지
  if (formatted !== bizNo.value) {
    bizNo.value = formatted;
  }
});

// 휴대폰 번호 자동 하이픈 추가
watch(handphone, (newValue) => {
  const digits = newValue.replace(/\D/g, '');
  let formatted = '';

  if (digits.length > 0) {
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3)}`;
    } else {
      // 11자리까지만 입력받음
      formatted = `${digits.slice(0, 3)}-${digits.slice(3, 7)}-${digits.slice(7, 11)}`;
    }
  }

  if (formatted !== handphone.value) {
    handphone.value = formatted;
  }
});

const signup = async () => {
  if (password.value !== confirmPassword.value) {
    alert('비밀번호가 일치하지 않습니다.');
    return;
  }
  
  // 필수 항목 유효성 검사
  if (!idEmail.value || !password.value || !companyName.value || !ceoName.value || !bizNo.value) {
    alert('필수 항목(*)을 모두 입력해주세요.');
    return;
  }

  try {
    loading.value = true;
    const { data, error } = await supabase.auth.signUp({
      email: idEmail.value,
      password: password.value
    });
    if (error) throw error;
    if (!data.user) throw new Error("사용자 생성에 실패했습니다.");

    // members 테이블에도 insert
    const { error: insertError } = await supabase.from('members').insert({
      id: data.user.id, // auth.users.id와 members.id를 동기화
      id_email: idEmail.value,
      company_name: companyName.value,
      ceo_name: ceoName.value,
      biz_no: bizNo.value,
      address: address.value || null,
      cso_regist_no: csoRegistNo.value || null,
      manager_name: managerName.value || null,
      handphone: handphone.value || null,
      email: contactEmail.value || null,
      role: 'user',
      approval: 'unapproved'
    });
    if (insertError) {
      alert('회원 정보 저장에 실패했습니다: ' + insertError.message);
      // 가입 시도한 auth.users 레코드 삭제 필요 (롤백)
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
