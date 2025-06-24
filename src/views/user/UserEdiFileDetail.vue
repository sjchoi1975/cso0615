<template>
  <div class="edi-file-detail-page page-container" style="padding-left: 0;">
    <div style="margin-bottom: 1rem;">
      <input type="file" multiple @change="onFileInputChange" />
      <Button label="업로드" :disabled="filesToUpload.length === 0" @click="uploadFiles" style="margin-left: 1rem;" />
    </div>
    <h3>등록된 파일 목록</h3>
    <ul>
      <li v-for="file in fileList" :key="file.id" style="display: flex; align-items: center; gap: 1rem;">
        <span>{{ file.file_name }}</span>
        <a :href="file.file_url" target="_blank">다운로드</a>
        <Button icon="pi pi-times" class="p-button-rounded p-button-text p-button-danger" @click="deleteFile(file)" />
      </li>
    </ul>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import Button from 'primevue/button';
import { useToast } from 'primevue/usetoast';

const route = useRoute();
const router = useRouter();
const toast = useToast();

const settlementMonthId = route.params.settlementMonthId;
const hospitalId = route.params.hospitalId;

const settlementMonthLabel = ref('');
const hospitalName = ref('');
const fileList = ref([]);
const filesToUpload = ref([]);

const fetchMeta = async () => {
  // 정산월 정보
  const { data: month } = await supabase.from('edi_months').select('*').eq('id', settlementMonthId).single();
  settlementMonthLabel.value = month ? month.settlement_month : '';
  // 병의원 정보
  const { data: hospital } = await supabase.from('hospitals').select('*').eq('id', hospitalId).single();
  hospitalName.value = hospital ? hospital.hospital_name : '';
};

const fetchFiles = async () => {
  const { data, error } = await supabase
    .from('edi_files')
    .select('*')
    .eq('submission_period_id', settlementMonthId)
    .eq('hospital_id', hospitalId)
    .order('created_at', { ascending: false });
  if (!error && data) fileList.value = data;
};

function onFileInputChange(e) {
  filesToUpload.value = Array.from(e.target.files);
  e.target.value = '';
}

async function uploadFiles() {
  if (filesToUpload.value.length === 0) return;
  const user = (await supabase.auth.getUser()).data.user;
  const companyId = user?.id || 'unknown';
  for (const file of filesToUpload.value) {
    const filePath = `edi_files/${settlementMonthLabel.value}/${companyId}/${hospitalId}/${file.name}`;
    const { error: uploadError } = await supabase.storage.from('edi_uploads').upload(filePath, file);
    if (uploadError) {
      toast.add({ severity: 'error', summary: '업로드 실패', detail: uploadError.message, life: 3000 });
      continue;
    }
    const { data: { publicUrl } } = supabase.storage.from('edi_uploads').getPublicUrl(filePath);
    const { error: dbError } = await supabase.from('edi_files').insert({
      submission_period_id: settlementMonthId,
      company_member_id: companyId,
      hospital_id: hospitalId,
      file_name: file.name,
      file_url: publicUrl,
      file_size_bytes: file.size,
      created_by: companyId,
      settlement_month: settlementMonthLabel.value,
    });
    if (dbError) {
      toast.add({ severity: 'error', summary: 'DB 저장 실패', detail: dbError.message, life: 3000 });
    }
  }
  toast.add({ severity: 'success', summary: '성공', detail: '파일이 성공적으로 업로드되었습니다.', life: 3000 });
  filesToUpload.value = [];
  fetchFiles();
}

async function deleteFile(file) {
  // Supabase Storage에서 삭제
  const path = `edi_files/${settlementMonthLabel.value}/${file.company_member_id}/${hospitalId}/${file.file_name}`;
  await supabase.storage.from('edi_uploads').remove([path]);
  // DB에서 삭제
  await supabase.from('edi_files').delete().eq('id', file.id);
  toast.add({ severity: 'success', summary: '삭제 완료', detail: '파일이 삭제되었습니다.', life: 2000 });
  fetchFiles();
}

function goBack() {
  window.history.length > 1 ? router.back() : router.push('/edi/submit');
}

onMounted(async () => {
  await fetchMeta();
  await fetchFiles();
});
</script>

<style scoped>
/* 사이드바, Company 등 숨김 처리 (상위 레이아웃에서 적용 시 필요) */
/* .sidebar-menu, .topbar-company { display: none !important; } */
</style> 