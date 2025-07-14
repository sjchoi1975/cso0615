<template>
  <div class="custom-modal-overlay">
    <div class="custom-modal">
      <div class="modal-header">
        <h3 class="modal-title">비밀번호 재설정</h3>
      </div>
      <div class="modal-body">
        <div class="form-grid">
          <div class="form-group">
            <label>새 비밀번호</label>
            <input type="password" v-model="newPw" class="input" autocomplete="new-password" />
          </div>
          <div class="form-group">
            <label>새 비밀번호 확인</label>
            <input type="password" v-model="newPwCheck" class="input" autocomplete="new-password" />
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <Button label="취소" class="btn-cancel modal" @click="goLogin"/>
        <Button label="확인" class="btn-confirm modal" @click="onChangePw" :disabled="loading" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';

const newPw = ref('');
const newPwCheck = ref('');
const loading = ref(false);
const router = useRouter();

function goLogin() {
  router.replace('/login');
}

async function onChangePw() {
  if (!newPw.value || !newPwCheck.value) {
    alert('모든 항목을 입력해 주세요.');
    return;
  }
  if (newPw.value.length < 6) {
    alert('새 비밀번호는 6자 이상이어야 합니다.');
    return;
  }
  if (newPw.value !== newPwCheck.value) {
    alert('새 비밀번호가 일치하지 않습니다.');
    return;
  }
  loading.value = true;
  // Supabase updateUser (recovery token이 URL에 있음)
  const { error } = await supabase.auth.updateUser({ password: newPw.value });
  loading.value = false;
  if (error) {
    alert('비밀번호 재설정에 실패했습니다. 링크가 만료되었거나 유효하지 않습니다.');
  } else {
    alert('비밀번호가 재설정되었습니다. 다시 로그인해 주세요.');
    router.replace('/login');
  }
}
</script>
