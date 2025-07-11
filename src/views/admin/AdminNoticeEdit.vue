<template>
  <div class="board">
    <form @submit.prevent="onSubmit" class="board-form-720">
      <div style="margin-bottom: 1.5rem;">
        <label class="label-05rem">제목</label>
        <input 
          v-model="title" 
          ref="titleInput"
          class="input" 
          placeholder="제목을 입력하세요" 
          required 
        />
      </div>
      <div style="margin-bottom: 1.5rem;">
        <label class="label-05rem">중요 공지</label>
        <div class="checkbox-wrapper">
          <input 
            type="checkbox" 
            id="important" 
            v-model="isImportant" 
            class="checkbox-input"
          />
          <label for="important" class="label-09-666">중요 공지로 설정 (상단 고정)</label>
        </div>
      </div>
      <div style="margin-bottom: 2rem;">
        <label class="label-05rem">내용</label>
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
        <button type="button" class="btn-cancel" @click="goList" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :class="{ 'btn-disabled': loading || !canEdit }" style="flex:3;">
          수정
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const route = useRoute();
const router = useRouter();
const title = ref('');
const content = ref('');
const isImportant = ref(false);
const textarea = ref(null);
const titleInput = ref(null);
const loading = ref(false);

// 원본 데이터 저장
const originalData = ref({
  title: '',
  content: '',
  is_important: false
});

// 제목과 내용이 모두 입력되었는지 확인
const canSubmit = computed(() => {
  return title.value.trim().length > 0 && content.value.trim().length > 0;
});

// 변경사항이 있는지 확인
const hasChanges = computed(() => {
  return title.value !== originalData.value.title ||
         content.value !== originalData.value.content ||
         isImportant.value !== originalData.value.is_important;
});

// 수정 버튼 활성화 조건
const canEdit = computed(() => {
  return canSubmit.value && hasChanges.value;
});

const fetchNotice = async () => {
  const { data, error } = await supabase
    .from('notices')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    title.value = data.title;
    content.value = data.content;
    isImportant.value = data.is_important || false;
    
    // 원본 데이터 저장
    originalData.value = {
      title: data.title,
      content: data.content,
      is_important: data.is_important || false
    };
  }
};

onMounted(async () => {
  await fetchNotice();
  // 데이터 로드 후 제목 입력란에 포커스
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
  if (loading.value) return;
  if (!canEdit.value) {
    // 변경사항이 없거나 필수 필드가 비어있을 때
    if (!hasChanges.value) {
      alert('변경된 내용이 없습니다.');
    } else {
      alert('제목과 내용을 모두 입력하세요.');
    }
    return;
  }
  loading.value = true;
  try {
    const { error } = await supabase.from('notices').update({
      title: title.value,
      content: content.value,
      is_important: isImportant.value,
    }).eq('id', route.params.id);
    if (error) throw error;
    alert('수정되었습니다.');
    router.push('/admin/notices/list');
  } catch (e) {
    alert('수정 실패: ' + (e.message || e));
  } finally {
    loading.value = false;
  }
};
</script>
