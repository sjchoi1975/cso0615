<template>
  <div class="board">
    <form class="board-form" @submit.prevent="submitEdit">
      <!-- 파일 선택 -->
      <label class="title-sm">파일 선택<span class="required">*</span></label>
      <input type="file" multiple @change="handleFileSelect" class="input" style="margin-bottom:0rem;" />
      <ul v-if="selectedFiles.length > 0" style="margin-bottom:1.5rem; padding-left:0; list-style:none;">
        <li
          v-for="(file, idx) in selectedFiles"
          :key="file.url || file.name"
          class="selected-edi-file"
          style="display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; background: #eaf6fd; margin-bottom: 0rem;"
        >
          <span>{{ file.original_name || file.name }}</span>
          <button
            type="button"
            @click="removeFile(idx)"
            style="background: none; border: none; cursor: pointer; padding: 0; margin-left: 0.5rem;"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" stroke="#dc3545" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24">
              <polyline points="3 6 5 6 21 6"/>
              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/>
              <line x1="10" y1="11" x2="10" y2="17"/>
              <line x1="14" y1="11" x2="14" y2="17"/>
            </svg>
          </button>
        </li>
      </ul>

      <!-- 제약사 선택 -->
      <label class="title-sm" style="margin-top: 2rem;">제약사 선택<span class="required">*</span></label>
      <button type="button" class="btn-select-wide" @click="showCompanyModal = true">제약사 선택</button>
      <div v-if="selectedCompanies.length > 0" class="selected-pharmas-list" style="margin-bottom: 0rem;">
        <div v-for="company in selectedCompanies" :key="company.id" class="selected-pharma-item" style="display: flex; align-items: center; justify-content: space-between; gap: 0.5rem;">
          <span>{{ company.company_name }}</span>
          <button type="button" @click="removeCompany(company.id)" style="background: none; border: none; cursor: pointer; padding: 0; margin-left: 0.5rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#dc3545" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        </div>
      </div>

      <!-- 메모 -->
      <label class="title-sm" style="margin-top: 2rem;">메모</label>
      <textarea v-model="memo" class="input" placeholder="요청 메모를 입력해 주세요." rows="8"></textarea>

      <div style="display: flex; gap: 0.5rem; margin-top: 1.2rem;">
        <button type="button" class="btn-cancel" @click="goBack" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :disabled="isSubmitting || !selectedFiles.length || !selectedCompanies.length" style="flex:2;">{{ isSubmitting ? '수정 중...' : '수정' }}</button>
      </div>
    </form>

    <!-- 제약사 선택 모달 -->
    <div v-if="showCompanyModal" class="custom-modal-overlay">
      <div class="custom-modal-filtering">
        <div class="modal-header">
          <h3 class="modal-title">제약사 선택</h3>
          <input v-model="companySearch" class="input" placeholder="제약사명으로 검색" style="margin-top:0.8rem; margin-bottom:0.2rem;" />
        </div>
        <div class="modal-body">
          <div class="selection-list-container">
            <div v-for="company in filteredCompanies" :key="company.id" class="pharma-modal-item" :class="{ selected: isCompanySelected(company.id) }" @click="toggleCompanySelection(company)">
              <span class="pharma-name">{{ company.company_name }}</span>
              <span v-if="isCompanySelected(company.id)" class="check-icon">✓</span>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showCompanyModal = false" style="flex:1;">취소</button>
          <button class="btn-confirm" @click="showCompanyModal = false" style="flex:2;">선택</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import { useRouter, useRoute } from 'vue-router';

const route = useRoute();
const router = useRouter();
const settlementMonthId = route.params.settlementMonthId;
const hospitalId = route.params.hospitalId;
const fileId = route.params.fileId;

const selectedFiles = ref([]);
const companies = ref([]);
const selectedCompanies = ref([]);
const showCompanyModal = ref(false);
const memo = ref('');
const isSubmitting = ref(false);
const companySearch = ref('');

function handleFileSelect(e) {
  const newFiles = Array.from(e.target.files);
  selectedFiles.value = [...selectedFiles.value, ...newFiles];
}

onMounted(async () => {
  // 기존 데이터 불러오기
  const { data: fileRow } = await supabase.from('edi_files').select('files, memo').eq('id', fileId).single();
  selectedFiles.value = fileRow?.files || [];
  memo.value = fileRow?.memo || '';

  // 제약사 전체 목록
  const { data } = await supabase.from('pharmaceutical_companies').select('id, company_name').order('company_name');
  companies.value = data || [];

  // 선택된 제약사 목록
  const { data: companyRows } = await supabase.from('edi_file_companies').select('company_id, pharmaceutical_companies(company_name)').eq('edi_file_id', fileId);
  selectedCompanies.value = (companyRows || []).map(c => ({ id: c.company_id, company_name: c.pharmaceutical_companies?.company_name || '' }));
});

const filteredCompanies = computed(() => {
  let arr = companies.value;
  if (companySearch.value) {
    arr = arr.filter(c => c.company_name.includes(companySearch.value));
  }
  return [...arr].sort((a, b) => (a.company_name || '').localeCompare(b.company_name || '', 'ko'));
});

function isCompanySelected(id) {
  return selectedCompanies.value.some(c => c.id === id);
}
function toggleCompanySelection(company) {
  const idx = selectedCompanies.value.findIndex(c => c.id === company.id);
  if (idx > -1) selectedCompanies.value.splice(idx, 1);
  else selectedCompanies.value.push(company);
}
function removeCompany(id) {
  selectedCompanies.value = selectedCompanies.value.filter(c => c.id !== id);
}
function goBack() {
  router.back();
}
function removeFile(idx) {
  selectedFiles.value.splice(idx, 1);
}

async function submitEdit() {
  if (!selectedFiles.value.length || !selectedCompanies.value.length) return;
  isSubmitting.value = true;
  // 파일 정보는 이미 업로드된 상태라고 가정 (수정 시 파일 추가/삭제만 반영)
  const { error: fileError } = await supabase.from('edi_files').update({
    files: selectedFiles.value,
    memo: memo.value
  }).eq('id', fileId);
  if (fileError) {
    alert('DB 저장 실패');
    isSubmitting.value = false;
    return;
  }
  // 제약사 매핑 갱신: 기존 삭제 후 새로 추가
  await supabase.from('edi_file_companies').delete().eq('edi_file_id', fileId);
  for (const company of selectedCompanies.value) {
    await supabase.from('edi_file_companies').insert({
      edi_file_id: fileId,
      company_id: company.id
    });
  }
  alert('수정 완료!');
  isSubmitting.value = false;
  router.back();
}
</script>
