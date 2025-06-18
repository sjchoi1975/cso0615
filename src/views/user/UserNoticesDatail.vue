<template>
  <div class="board">
    <h2 style="margin-bottom: 2rem;">공지사항 상세</h2>
    <form>
      <div style="margin-bottom: 1.5rem;">
        <label style="margin-bottom: 0.75rem;">제목</label>
        <input 
          :value="notice?.title" 
          class="input no-pointer" 
          readonly
          tabindex="-1"
          style="background-color: #f9f9f9; cursor: not-allowed;"
        />
      </div>
      <div style="margin-bottom: 1.5rem;">
        <label style="margin-bottom: 0.75rem;">중요 공지</label>
        <div class="checkbox-wrapper">
          <input 
            type="checkbox" 
            id="important-detail" 
            :checked="notice?.is_important" 
            disabled
            class="checkbox-input"
          />
          <label for="important-detail" class="checkbox-label">중요 공지로 설정 (상단 고정)</label>
        </div>
      </div>
      <div style="margin-bottom: 2rem;">
        <label style="margin-bottom: 0.75rem;">내용</label>
        <textarea
          ref="textareaRef"
          :value="notice?.content"
          rows="12"
          class="input no-pointer"
          tabindex="-1"
          style="resize: vertical; min-height: 24rem; width: 100%; background-color: #f9f9f9; cursor: not-allowed;"
          readonly
        ></textarea>
      </div>
      <div style="margin-bottom: 1.5rem;">
        <label style="margin-bottom: 0.75rem;">작성일시</label>
        <input 
          :value="formatDate(notice?.created_at)" 
          class="input no-pointer" 
          readonly
          tabindex="-1"
          style="background-color: #f9f9f9; cursor: not-allowed;"
        />
      </div>
      <div style="margin-bottom: 1.5rem;">
        <label style="margin-bottom: 0.75rem;">작성자</label>
        <input 
          :value="notice?.author" 
          class="input no-pointer" 
          readonly
          tabindex="-1"
          style="background-color: #f9f9f9; cursor: not-allowed;"
        />
      </div>
      <div style="display: flex; gap: 1rem; justify-content: flex-end;">
        <button type="button" class="btn-cancel" @click="goList">목록</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const route = useRoute();
const router = useRouter();
const notice = ref(null);
const textareaRef = ref(null);

// 공지사항 불러오기
const fetchNotice = async () => {
  const { data, error } = await supabase
    .from('notices')
    .select('*')
    .eq('id', route.params.id)
    .single();
  
  if (!error && data) {
    notice.value = data;
    await nextTick();
    autoResize();
  } else {
    alert('공지사항을 찾을 수 없습니다.');
    goList();
  }
};

onMounted(fetchNotice);

// textarea 높이 자동 조정
const autoResize = () => {
  const el = textareaRef.value;
  if (el) {
    el.style.height = 'auto';
    el.style.height = el.scrollHeight + 'px';
  }
};

// 날짜 포맷팅 (한국시각)
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const koreanTime = new Date(date.getTime() + (9 * 60 * 60 * 1000)); // UTC+9
  return koreanTime.toISOString().slice(0, 16).replace('T', ' ');
};

const goList = () => {
  router.push('/notice/list');
};
</script>
