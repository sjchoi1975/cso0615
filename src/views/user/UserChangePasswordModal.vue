<template>
  <div v-if="visible" class="custom-modal-overlay">
    <div class="custom-modal">
      <div class="modal-header">
        <h3 class="modal-title">비밀번호 변경</h3>
      </div>
      <div class="modal-body">
        <div class="form-grid">
          <div class="form-group">
            <label>현재 비밀번호</label>
            <input type="password" v-model="currentPw" class="input" autocomplete="current-password" />
          </div>
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
        <Button label="취소" class="btn-cancel modal" @click="onCancel" />
        <Button label="확인" class="btn-confirm modal" @click="onChangePw" :disabled="loading" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import Button from 'primevue/button';
import { supabase } from '@/supabase';

const props = defineProps({
  visible: Boolean
});
const emits = defineEmits(['close', 'success']);

const currentPw = ref('');
const newPw = ref('');
const newPwCheck = ref('');
const loading = ref(false);

watch(() => props.visible, (v) => {
  if (v) {
    currentPw.value = '';
    newPw.value = '';
    newPwCheck.value = '';
    loading.value = false;
  }
});

function onCancel() {
  emits('close');
}

async function onChangePw() {
  if (!currentPw.value || !newPw.value || !newPwCheck.value) {
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
  // Supabase: re-authenticate & update password
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (!user) {
    alert('로그인 정보가 없습니다. 다시 로그인해 주세요.');
    loading.value = false;
    return;
  }
  // 로그인 재확인
  const { error: signInError } = await supabase.auth.signInWithPassword({
    email: user.email,
    password: currentPw.value
  });
  if (signInError) {
    alert('현재 비밀번호가 올바르지 않습니다.');
    loading.value = false;
    return;
  }
  // 비밀번호 변경
  const { error: pwError } = await supabase.auth.updateUser({
    password: newPw.value
  });
  loading.value = false;
  if (pwError) {
    alert('비밀번호 변경에 실패했습니다.');
  } else {
    alert('비밀번호가 변경되었습니다.');
    emits('success');
    emits('close');
  }
}
</script>

