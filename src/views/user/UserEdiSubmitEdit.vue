<template>
  <div class="board">
    <form class="board-form" @submit.prevent="submitEdit">
      <!-- 파일 선택 -->
      <label class="title-sm">증빙 파일<span class="required">*</span></label>
      <input
        type="file"
        multiple
        @change="handleFileSelect"
        class="input"
      />
      <div
        v-if="selectedFiles.length > 0"
        class="selected-edi-file-list">
        <div
          v-for="(file, idx) in selectedFiles"
          :key="file.url || file.name"
          class="selected-edi-file-item">
          <span>{{ file.original_name || file.name }}</span>
          <button type="button"@click="removeFile(idx)"
            style="background: none; border: none; cursor: pointer; padding: 0; margin-left: 0.5rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" stroke="#dc3545" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><polyline points="3 6 5 6 21 6"/> <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/> <line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        </div>
      </div>

      <!-- 제약사 선택 -->
      <label class="title-sm" style="margin-top: 2rem;">제약사<span class="required">*</span>
      </label>
      <button type="button" class="btn-select-wide" @click="openPharmaModal">제약사 선택</button>
      <div
        v-if="selectedCompanies.length > 0"
        class="selected-pharmas-list">
        <div
          v-for="company in selectedCompanies"
          :key="company.id"
          class="selected-pharma-item">
          <span>{{ company.company_name }}</span>
          <button type="button" @click="removeCompany(company.id)"
            style="background: none; border: none; cursor: pointer; padding: 0; margin-left: 0.5rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#dc3545" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        </div>
      </div>

      <!-- 메모 -->
      <label class="title-sm" style="margin-top: 2rem;">특이 사항</label>
      <textarea v-model="memo" class="input" placeholder="" rows="6"></textarea>

      <div class="btn-row">
        <button type="button" class="btn-cancel" @click="goBack" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :disabled="isSubmitting || !selectedFiles.length || !selectedCompanies.length" style="flex:2;">{{ isSubmitting ? '수정 중...' : '수정' }}</button>
      </div>
    </form>

    <!-- 제약사 선택 모달 -->
    <div v-if="showCompanyModal" class="custom-modal-overlay">
      <div class="custom-modal-filtering">
        <div class="modal-header">
          <h3 class="modal-title">제약사 선택</h3>
          <input 
            v-model="companySearch" 
            class="input" 
            placeholder="제약사명으로 검색" 
            style="margin-top:0.75rem; margin-bottom:0.25rem;" 
          />
        </div>
        <div class="modal-body">
          <div class="selection-list-container">
            <div 
              v-for="company in filteredCompanies" 
              :key="company.id"
              class="pharma-modal-item"
              :class="{ selected: isPharmaSelectedInModal(company.id) }"
              @click="togglePharmaSelection(company)"
            >
              <span class="pharma-name">{{ company.company_name }}</span>
              <span v-if="isPharmaSelectedInModal(company.id)" class="check-icon">✓</span>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button 
            class="btn-cancel" 
            @click="closeModal" 
            style="flex:1;">
            취소
          </button>
          <button 
            class="btn-confirm" 
            @click="confirmSelection" 
            style="flex:3;">
            선택
          </button>
        </div>
      </div>
    </div>

    <!-- 전달사항 모달 -->
    <div v-if="showCommentDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">전달사항 확인</h3>
        </div>
        <div class="modal-body">
          <div class="comment-content">
            <template v-for="(company, index) in tempSelectedCompanies.filter(p => p.edi_comment)" :key="company.id">
              <p class="pharma-name">[{{ company.company_name }}]</p>
              <p class="comment-text">{{ company.edi_comment }}</p>
              <div v-if="index < tempSelectedCompanies.filter(p => p.edi_comment).length - 1" class="comment-divider"></div>
            </template>
          </div>
        </div>
        <div class="modal-footer">
          <button
            class="btn-cancel" 
            @click="confirmCommentDialog" 
            style="flex:1;">
            확인
          </button>
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
const submissionId = route.params.fileId; // 실제로는 submission_id

const selectedFiles = ref([]);
const companies = ref([]);
const selectedCompanies = ref([]);
const showCompanyModal = ref(false);
const memo = ref('');
const isSubmitting = ref(false);
const companySearch = ref('');
const hospitalName = ref('');

// 모달 관련 상태
const tempSelectedCompanies = ref([]);
const showCommentDialog = ref(false);

onMounted(async () => {
  const hospitalId = route.params.hospitalId;
  if (hospitalId) {
    const { data } = await supabase.from('hospitals').select('hospital_name').eq('id', hospitalId).single();
    hospitalName.value = data?.hospital_name || '';
  }

  // submission_id 파싱: "settlementMonthId-memberId-hospitalId-submissionSeq"
  const submissionParts = submissionId.split('-');
  if (submissionParts.length < 4) {
    alert('잘못된 접근입니다.');
    router.back();
    return;
  }
  
  const submissionSeq = submissionParts[submissionParts.length - 1];
  
  // 현재 사용자 정보 가져오기
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    alert('로그인이 필요합니다.');
    return;
  }

  // 해당 제출의 파일 목록 조회
  const { data: filesData, error: filesError } = await supabase
    .from('edi_files')
    .select('id, file_url, file_name, original_file_name, file_size, memo')
    .eq('settlement_month_id', settlementMonthId)
    .eq('member_id', user.id)
    .eq('hospital_id', hospitalId)
    .eq('submission_seq', submissionSeq)
    .eq('is_deleted', false);

  if (filesError) {
    console.error('파일 데이터 로딩 실패:', filesError);
    alert('파일 정보를 불러오는데 실패했습니다.');
    return;
  }

  if (filesData && filesData.length > 0) {
    // 모든 파일을 로드
    selectedFiles.value = filesData.map(file => ({
      id: file.id,
      url: file.file_url,
      name: file.original_file_name || file.file_name,
      size: file.file_size
    }));
    // 첫 번째 파일의 메모를 기본값으로 사용
    memo.value = filesData[0].memo || '';
  } else {
    alert('파일 정보를 찾을 수 없습니다.');
    router.back();
    return;
  }

  // EDI가 활성화된 제약사만 조회
  const { data } = await supabase
    .from('pharmaceutical_companies')
    .select('id, company_name, edi_comment')
    .eq('edi_status', 'active')
    .order('company_name');
  companies.value = data || [];

  // 선택된 제약사 목록 (해당 제출의 모든 파일에서 중복 제거)
  const fileIds = filesData.map(f => f.id);
  const { data: companyRows } = await supabase
    .from('edi_file_companies')
    .select('company_id, pharmaceutical_companies(id, company_name, edi_comment)')
    .in('edi_file_id', fileIds);
  
  // 중복 제거하여 제약사 목록 생성
  const uniqueCompanies = new Map();
  (companyRows || []).forEach(c => {
    if (c.pharmaceutical_companies) {
      uniqueCompanies.set(c.company_id, {
        id: c.company_id,
        company_name: c.pharmaceutical_companies.company_name || '',
        edi_comment: c.pharmaceutical_companies.edi_comment || ''
      });
    }
  });
  
  selectedCompanies.value = Array.from(uniqueCompanies.values());
});

const filteredCompanies = computed(() => {
  let arr = companies.value;
  if (companySearch.value) {
    arr = arr.filter(c => c.company_name.includes(companySearch.value));
  }
  return [...arr].sort((a, b) => (a.company_name || '').localeCompare(b.company_name || '', 'ko'));
});

// 모달 관련 함수들
const openPharmaModal = () => {
  tempSelectedCompanies.value = [...selectedCompanies.value];
  showCompanyModal.value = true;
};

const closeModal = () => {
  showCompanyModal.value = false;
  companySearch.value = '';
};

const isPharmaSelectedInModal = (pharmaId) => {
  return tempSelectedCompanies.value.some(p => p.id === pharmaId);
};

const togglePharmaSelection = (company) => {
  const index = tempSelectedCompanies.value.findIndex(p => p.id === company.id);
  if (index > -1) {
    tempSelectedCompanies.value.splice(index, 1);
  } else {
    tempSelectedCompanies.value.push(company);
  }
};

const confirmSelection = () => {
  // 새로 선택된 제약사들만 확인
  const newSelectedPharmas = tempSelectedCompanies.value.filter(
    newPharma => !selectedCompanies.value.some(
      existingPharma => existingPharma.id === newPharma.id
    )
  );
  
  // 새로 선택된 제약사들 중 전달사항이 있는 것들을 확인
  const pharmasWithComments = newSelectedPharmas.filter(p => p.edi_comment);
  
  if (pharmasWithComments.length > 0) {
    // 전달사항이 있는 경우 모달 표시
    showCommentDialog.value = true;
  } else {
    // 전달사항이 없는 경우 바로 선택 완료
    selectedCompanies.value = [...tempSelectedCompanies.value];
    closeModal();
  }
};

// 전달사항 확인 후 선택 완료
const confirmCommentDialog = () => {
  showCommentDialog.value = false;
  selectedCompanies.value = [...tempSelectedCompanies.value];
  closeModal();
};

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
  
  try {
    const { data: { user } } = await supabase.auth.getUser();
    const memberId = user?.id;
    
    // submission_id 파싱
    const submissionParts = submissionId.split('-');
    const submissionSeq = submissionParts[submissionParts.length - 1];
    
    // 현재 제출의 모든 파일 조회
    const { data: currentFiles } = await supabase
      .from('edi_files')
      .select('id')
      .eq('settlement_month_id', settlementMonthId)
      .eq('member_id', memberId)
      .eq('hospital_id', hospitalId)
      .eq('submission_seq', submissionSeq)
      .eq('is_deleted', false);
    
    if (!currentFiles || currentFiles.length === 0) {
      alert('수정할 파일을 찾을 수 없습니다.');
      isSubmitting.value = false;
      return;
    }
    
    const fileIds = currentFiles.map(f => f.id);
    
    // 새로운 파일이 업로드된 경우 처리
    if (selectedFiles.value[0] && !selectedFiles.value[0].url) {
      // 새 파일 업로드
      const file = selectedFiles.value[0];
      const ext = file.name.split('.').pop();
      const safeName = `edi_${Date.now()}_${Math.random().toString(36).substring(7)}.${ext}`;
      const filePath = `edi_files/${safeName}`;
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('edi-uploads')
        .upload(filePath, file);

      if (uploadError) {
        console.error('파일 업로드 실패:', uploadError);
        alert('파일 업로드에 실패했습니다.');
        isSubmitting.value = false;
        return;
      }

      const fileUrl = supabase.storage.from('edi-uploads').getPublicUrl(filePath).data.publicUrl;
      
      // 첫 번째 파일 정보 업데이트
      const { error: fileError } = await supabase
        .from('edi_files')
        .update({
          file_url: fileUrl,
          file_name: safeName,
          original_file_name: file.name,
          file_size: file.size,
          memo: memo.value,
          updated_by: memberId,
          updated_at: new Date().toISOString()
        })
        .eq('id', fileIds[0]);

      if (fileError) {
        console.error('EDI 파일 수정 실패:', fileError);
        alert('EDI 파일 정보 수정에 실패했습니다.');
        isSubmitting.value = false;
        return;
      }
    } else {
      // 메모만 업데이트
      const { error: memoError } = await supabase
        .from('edi_files')
        .update({
          memo: memo.value,
          updated_by: memberId,
          updated_at: new Date().toISOString()
        })
        .in('id', fileIds);

      if (memoError) {
        console.error('메모 수정 실패:', memoError);
        alert('메모 수정에 실패했습니다.');
        isSubmitting.value = false;
        return;
      }
    }

    // 기존 제약사 매핑 삭제
    const { error: deleteError } = await supabase
      .from('edi_file_companies')
      .delete()
      .in('edi_file_id', fileIds);

    if (deleteError) {
      console.error('기존 제약사 매핑 삭제 실패:', deleteError);
      alert('제약사 매핑 수정에 실패했습니다.');
      isSubmitting.value = false;
      return;
    }

    // 새로운 제약사 매핑 생성 (모든 파일에 동일하게 적용)
    for (const fileId of fileIds) {
      for (const company of selectedCompanies.value) {
        const { error: mappingError } = await supabase
          .from('edi_file_companies')
          .insert({
            edi_file_id: fileId,
            company_id: company.id,
            created_by: memberId,
            updated_by: memberId
          });

        if (mappingError) {
          console.error('제약사 매핑 추가 실패:', mappingError, company);
          alert(`제약사 매핑 추가 실패: ${company.company_name}`);
          // 매핑 실패는 경고만 표시하고 계속 진행
        }
      }
    }

    alert('수정이 완료되었습니다.');
    router.back();
  } catch (error) {
    console.error('수정 중 오류 발생:', error);
    alert('수정 중 오류가 발생했습니다.');
  } finally {
    isSubmitting.value = false;
  }
}
</script>
