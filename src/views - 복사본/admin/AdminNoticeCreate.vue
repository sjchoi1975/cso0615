<template>
  <div class="board">
    <h2 style="margin-bottom: 2rem;">공지사항 작성</h2>
    <form @submit.prevent="onSubmit">
      <div style="margin-bottom: 1.5rem;">
        <label style="margin-bottom: 0.75rem;">제목</label>
        <input 
          v-model="title" 
          ref="titleInput"
          class="input" 
          placeholder="제목을 입력하세요" 
          required 
        />
      </div>
      <div style="margin-bottom: 1.5rem;">
        <label style="margin-bottom: 0.75rem;">중요 공지</label>
        <div class="checkbox-wrapper">
          <input 
            type="checkbox" 
            id="important" 
            v-model="isImportant" 
            class="checkbox-input"
          />
          <label for="important" class="checkbox-label">중요 공지로 설정 (상단 고정)</label>
        </div>
      </div>
      <div style="margin-bottom: 2rem;">
        <label style="margin-bottom: 0.75rem;">내용</label>
        <textarea
          v-model="content"
          ref="textarea"
          rows="12"
          class="input"
          placeholder="내용을 입력하세요"
          style="resize: vertical; min-height: 20rem; width: 100%;"
          @input="autoResize"
          required
        ></textarea>
      </div>
      <div style="display: flex; gap: 1rem; justify-content: flex-end;">
        <button type="button" class="btn-cancel" @click="goList">취소</button>
        <button 
          type="submit" 
          class="btn-add" 
          :disabled="loading || !canSubmit"
          :class="{ 'btn-disabled': !canSubmit }"
        >
          작성
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const title = ref('');
const content = ref('');
const isImportant = ref(false);
const textarea = ref(null);
const titleInput = ref(null);
const router = useRouter();
const loading = ref(false);

// 제목과 내용이 모두 입력되었는지 확인
const canSubmit = computed(() => {
  return title.value.trim().length > 0 && content.value.trim().length > 0;
});

// 컴포넌트 마운트 시 제목 입력란에 포커스
onMounted(() => {
  if (titleInput.value) {
    titleInput.value.focus();
  }
});

const autoResize = () => {
  const el = textarea.value;
  if (el) {
    el.style.height = 'auto';
    el.style.height = el.scrollHeight + 'px';
  }
};

const goList = () => {
  router.push('/admin/notices/list');
};

const onSubmit = async () => {
  if (!title.value.trim() || !content.value.trim()) {
    alert('제목과 내용을 모두 입력하세요.');
    return;
  }
  loading.value = true;
  try {
    // 작성자 정보 가져오기
    const { data: { user } } = await supabase.auth.getUser();
    const author = user?.email || '';
    const { error } = await supabase.from('notices').insert({
      title: title.value,
      content: content.value,
      author,
      status: 'active',
      is_important: isImportant.value,
    });
    if (error) throw error;
    alert('공지사항이 등록되었습니다.');
    router.push('/admin/notices/list');
  } catch (e) {
    alert('등록 실패: ' + (e.message || e));
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.checkbox-wrapper {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.checkbox-input {
  width: 1.2rem;
  height: 1.2rem;
  cursor: pointer;
}

.checkbox-label {
  font-size: 0.9rem;
  color: #666;
  cursor: pointer;
}

.btn-disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
