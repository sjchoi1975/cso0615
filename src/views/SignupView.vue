<template>
  <div class="auth-root">
    <form @submit.prevent="signup" class="board-form">
      <h2 class="Signup-title">회원가입</h2>
      <div class="form-grid">
        <div class="form-group">
          <label class="label">아이디<span class="required">*</span></label>
          <input v-model="idEmail" 
            type="email" 
            placeholder="이메일" 
            class="input" 
            required />
        </div>
        <div class="form-group">
          <label class="label">비밀번호<span class="required">*</span></label>
          <div class="input-eye-wrap">
            <input :type="showPassword ? 'text' : 'password'" 
              v-model="password" 
              placeholder="최소 6자 이상" 
              class="input" 
              required minlength="6" />
            <button type="button" 
              class="eye-btn" @click="showPassword = !showPassword" 
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
        </div>
        <div class="form-group">
          <label class="label">비밀번호 확인<span class="required">*</span></label>
          <div class="input-eye-wrap">
            <input :type="showConfirmPassword ? 'text' : 'password'" 
              v-model="confirmPassword" 
              placeholder="비밀번호 재입력" 
              class="input" 
              required minlength="6" 
              :class="{ 'password-mismatch': showPasswordMismatch }" />
            <button type="button" class="eye-btn" 
              @click="showConfirmPassword = !showConfirmPassword" 
              :aria-label="showConfirmPassword ? '비밀번호 숨기기' : '비밀번호 보기'">
              <span v-if="showConfirmPassword">
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
          <div v-if="showPasswordMismatch" class="txt-90-danger">
            비밀번호가 일치하지 않습니다.
          </div>
        </div>
        <div class="form-group">
          <label class="label">회사명<span class="required">*</span></label>
          <input v-model="companyName" placeholder="" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">대표자명<span class="required">*</span></label>
          <input v-model="ceoName" placeholder="" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">사업자등록번호<span class="required">*</span></label>
          <input v-model="bizNo" placeholder="숫자만 입력" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">주소</label>
          <input v-model="address" placeholder="" class="input" />
        </div>
        <div class="form-group">
          <label class="label">CSO 신고번호</label>
          <input v-model="csoRegistNo" placeholder="숫자와 - (하이픈)만 입력" class="input" />
        </div>
        <div class="form-group">
          <label class="label">담당자명</label>
          <input v-model="managerName" placeholder="" class="input" />
        </div>
        <div class="form-group">
          <label class="label">휴대폰 번호</label>
          <input v-model="handphone" placeholder="숫자만 입력" class="input" />
        </div>
        <div class="form-group">
          <label class="label">이메일(연락용)</label>
          <input v-model="contactEmail" type="email" placeholder="" class="input" />
        </div>
      </div>
      <div class="btn-row">
        <button type="button" class="btn-cancel" @click="goLogin" style="flex:1;">취소</button>
        <button type="submit" class="btn-signup" :disabled="loading" style="flex:3;">회원가입</button>
      </div>
    </form>
  </div>
</template>

<script setup>
  import { ref, watch, computed } from 'vue';
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
  const showPasswordMismatch = ref(false);
  const showPassword = ref(false);
  const showConfirmPassword = ref(false);

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

// 비밀번호 확인 실시간 검증
watch([password, confirmPassword], ([newPassword, newConfirmPassword]) => {
  if (newConfirmPassword && newPassword !== newConfirmPassword) {
    showPasswordMismatch.value = true;
  } else {
    showPasswordMismatch.value = false;
  }
});

const signup = async () => {
  if (password.value !== confirmPassword.value) {
    showPasswordMismatch.value = true;
    return;
  }
  
  // 비밀번호 길이 검증
  if (password.value.length < 6) {
    alert('비밀번호는 최소 6자 이상이어야 합니다.');
    return;
  }

  // 사업자등록번호 10자리 검증
  const bizNoDigits = bizNo.value.replace(/\D/g, '');
  if (bizNoDigits.length !== 10) {
    alert('사업자등록번호는 10자리 숫자여야 합니다.');
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
