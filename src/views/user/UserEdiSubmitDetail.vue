<template>
  <div class="board">
    <form class="board-form" @submit.prevent="submit">

    <div v-if="loading">로딩 중...</div>
    <div v-else>
      <div v-if="fileHistory.length === 0">제출 이력이 없습니다.</div>
      <div v-for="(item, idx) in fileHistory" :key="item.id">

        <label
          class="title-sm"
          style="margin-top: 0rem; margin-bottom: 0.5rem;">
          제출파일
        </label>
        <ul style="font-size:1.1rem; margin-left:1rem; padding-left:1.2em;">
          <li v-for="file in item.files" :key="file.url" style="margin-bottom:0.35em;">
            <a :href="file.url" target="_blank">{{ file.original_name }}</a>
          </li>
        </ul>

        <label
          class="title-sm"
          style="margin-top: 2rem; margin-bottom: 0.5rem;">
          제약사
        </label>
        <ul style="font-size:1.1rem; margin-left:1rem; padding-left:1.2em;">
          <li v-for="c in item.companies" :key="c.id" style="margin-bottom:0.35em;">
            {{ c.name }}
          </li>
        </ul>

        <label
          class="title-sm" 
          style="margin-top: 2rem; margin-bottom: 0.5rem;">
          비고
        </label>                
        <div style="font-size:1.1rem; margin-left:1rem; margin-bottom:2.4rem; white-space:pre-line;">{{ item.memo || '-' }}</div>

        <label 
          class="title-sm" 
          style="margin-top: 2rem; margin-bottom: 0.5rem;">
          등록일시
        </label>
        <div style="font-size:1.1rem; margin-left:1rem;">{{ formatDate(item.created_at) }}</div>

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
  // edi_files 조회 (특정 월+병원)
  const { data: files, error } = await supabase
    .from('edi_files')
    .select('id, created_at, files, memo')
    .eq('settlement_month_id', settlementMonthId)
    .eq('hospital_id', hospitalId)
    .order('created_at', { ascending: false });

  if (error) {
    loading.value = false;
    return;
  }

  // 각 파일별로 연결된 제약사 조회
  const result = [];
  for (const file of files) {
    const { data: companies } = await supabase
      .from('edi_file_companies')
      .select('company_id, pharmaceutical_companies(company_name)')
      .eq('edi_file_id', file.id);
    result.push({
      ...file,
      files: Array.isArray(file.files) ? file.files : [],
      companies: (companies || []).map(c => ({
        id: c.company_id,
        name: c.pharmaceutical_companies?.company_name || ''
      }))
    });
  }
  fileHistory.value = result;
  loading.value = false;
});
</script>

