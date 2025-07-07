<template>
  <div>
    <h2>제출 이력</h2>
    <div v-if="loading">로딩 중...</div>
    <div v-else>
      <div v-if="fileHistory.length === 0">제출 이력이 없습니다.</div>
      <div v-for="item in fileHistory" :key="item.id" class="history-item">
        <div><strong>등록일시:</strong> {{ formatDate(item.created_at) }}</div>
        <div><strong>파일:</strong>
          <ul>
            <li v-for="file in item.files" :key="file.url">
              <a :href="file.url" target="_blank">{{ file.name }}</a>
            </li>
          </ul>
        </div>
        <div><strong>제약사:</strong> {{ item.companies.map(c => c.name).join(', ') }}</div>
        <div><strong>비고:</strong> {{ item.memo || '-' }}</div>
        <hr />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { supabase } from '@/supabase';

const fileHistory = ref([]);
const loading = ref(true);

function formatDate(dateStr) {
  const d = new Date(dateStr);
  return d.toLocaleString();
}

onMounted(async () => {
  loading.value = true;
  // edi_files 조회 (예: 본인 제출 이력만)
  const { data: files, error } = await supabase
    .from('edi_files')
    .select('id, created_at, files, memo')
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
      .select('company_id, pharmaceutical_companies(name)')
      .eq('edi_file_id', file.id);
    result.push({
      ...file,
      files: Array.isArray(file.files) ? file.files : [],
      companies: (companies || []).map(c => ({
        id: c.company_id,
        name: c.pharmaceutical_companies?.name || ''
      }))
    });
  }
  fileHistory.value = result;
  loading.value = false;
});
</script>

<style scoped>
.history-item {
  margin-bottom: 24px;
}
</style> 