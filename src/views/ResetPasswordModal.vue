<template>
  <div v-if="visible" class="custom-modal-overlay">
    <div class="custom-modal">
      <div class="modal-header">
        <h3 class="modal-title">비밀번호 재설정</h3>
      </div>
      <div class="modal-body">
        <div style="margin-bottom: 1rem;">비밀번호 재설정 링크를 보내드리겠습니다.</div>
        <input type="email" v-model="inputEmail" class="input" placeholder="가입 아이디(이메일 주소) 입력" style="width: 100%; margin-bottom: 1rem;" />
        <div v-if="errorMsg" class="password-error">{{ errorMsg }}</div>
        <div class="btn-row" style="justify-content: flex-end !important;">
          <Button label="취소" class="btn-cancel modal" @click="onCancel"/>
          <Button label="이메일 받기" class="btn-confirm modal" @click="onSend" :disabled="!isEmailValid || loading" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue';
import Button from 'primevue/button';
import { supabase } from '@/supabase';

const props = defineProps({
  visible: Boolean
});
const emits = defineEmits(['close']);

const inputEmail = ref('');
const errorMsg = ref('');
const loading = ref(false);

const isEmailValid = computed(() => {
  return /^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}$/.test(inputEmail.value);
});

watch(() => props.visible, (v) => {
  if (v) {
    inputEmail.value = '';
    errorMsg.value = '';
    loading.value = false;
  }
});

function onCancel() {
  emits('close');
}

async function onSend() {
  errorMsg.value = '';
  if (!isEmailValid.value) return;
  loading.value = true;
  // 이메일 존재 여부 확인
  const { data: member } = await supabase
    .from('members')
    .select('id_email')
    .eq('id_email', inputEmail.value)
    .single();
  if (!member) {
    loading.value = false;
    emits('close');
    alert('가입하신 아이디(이메일) 정보가 존재하지 않습니다.');
    return;
  }
  // Supabase reset password (이메일 한글 제목/내용)
  const { error: resetError } = await supabase.auth.resetPasswordForEmail(inputEmail.value, {
    redirectTo: window.location.origin + '/reset-password',
  });
  loading.value = false;
  emits('close');
  if (resetError) {
    alert('이메일 발송에 실패했습니다. 잠시 후 다시 시도해 주세요.');
  } else {
    alert('비밀번호 재설정 링크가 발송되었습니다. 이메일을 확인해 주세요.');
  }
}
</script>
