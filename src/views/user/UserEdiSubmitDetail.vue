<template>
  <div class="board">
    <form class="board-form" @submit.prevent="submit">

    <div v-if="loading">로딩 중...</div>
    <div v-else>
      <div v-for="(item, idx) in fileHistory" :key="item.id">

        <label class="title-sm">증빙 파일</label>
        <div class="selected-edi-file-list">
          <div
            v-for="file in item.files"
            :key="file.id"
            class="selected-edi-file-item">
            <span><a :href="file.file_url" target="_blank">{{ file.original_file_name }}</a></span>
          </div>
        </div>

        <label class="title-sm" style="margin-top: 2rem;">제약사</label>
        <div class="selected-pharmas-list">
          <div
            v-for="company in item.companies"
            :key="company.id"
            class="selected-pharma-item">
            <span>{{ company.company_name }}</span>
          </div>
        </div>

        <label class="title-sm" style="margin-top: 2rem;">특이 사항</label>
        <textarea 
          class="input" 
          placeholder="" 
          rows="6" 
          readonly
          :value="item.memo || ''"
          style="background-color: #f8f9fa; resize: none;">
        </textarea>

        <div style="margin-top: 2rem; margin-bottom: 2rem; display: flex; align-items: center; gap: 0.3rem;">
          <label class="title-sm">등록 일시 : {{ formatDate(item.created_at) }}</label>
        </div>

        <div style="display: flex; justify-content: flex-end; margin-top: 0.5rem;">
          <button type="button" class="btn-warning" style="padding: 0.5rem 1rem !important;" @click="goToEdit(item.id)">수정하기</button>
        </div>
        <hr style="margin-top: 2rem; margin-bottom: 2rem;" v-if="idx < fileHistory.length - 1" />
      </div>
    </div>

    <!-- 하단 버튼 영역 추가 -->
    <div style="display: flex; gap: 0.5rem; margin-top: 2rem;">
      <button
        type="button" 
        class="btn-cancel" 
        @click="goBack" 
        style="flex:1;">
        목록
      </button>
      <button 
       type="button" 
       class="btn-confirm" 
       @click="goUpload" 
       style="flex:3;">
       추가제출
      </button>
    </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { supabase } from '@/supabase';
import { useRouter, useRoute } from 'vue-router';

const fileHistory = ref([]);
const loading = ref(true);
const router = useRouter();
const route = useRoute();
const settlementMonthId = route.params.settlementMonthId;
const hospitalId = route.params.hospitalId;
const hospitalName = ref('');

function formatDate(dateStr) {
  const d = new Date(dateStr);
  return d.toLocaleString();
}

function goToEdit(fileId) {
  router.push(`/edi/submit/${settlementMonthId}/${hospitalId}/${fileId}/edit`);
}

// 목록으로 이동 (뒤로가기)
function goBack() {
  router.back();
}

// 추가제출 화면으로 이동
function goUpload() {
  router.push(`/edi/submit/${settlementMonthId}/${hospitalId}`);
}

onMounted(async () => {
  if (hospitalId) {
    const { data } = await supabase.from('hospitals').select('hospital_name').eq('id', hospitalId).single();
    hospitalName.value = data?.hospital_name || '';
  }
  // 로그인 사용자 id 가져오기
  const { data: { user } } = await supabase.auth.getUser();
  const userId = user?.id;
  
  // edi_list_user_view에서 제출 단위별로 조회
  const { data: submissions, error } = await supabase
    .from('edi_list_user_view')
    .select('*')
    .eq('settlement_month_id', settlementMonthId)
    .eq('hospital_id', hospitalId)
    .eq('member_id', userId)
    .order('submission_seq', { ascending: false });

  if (error) {
    console.error('Error fetching submissions:', error);
    loading.value = false;
    return;
  }

  // 제출 단위별로 데이터 정리
  fileHistory.value = (submissions || []).map(submission => ({
    id: submission.submission_id,
    submission_seq: submission.submission_seq,
    created_at: submission.created_at,
    memo: submission.memo,
    files: submission.files || [],
    companies: submission.companies || []
  }));
  
  loading.value = false;
});
</script>

