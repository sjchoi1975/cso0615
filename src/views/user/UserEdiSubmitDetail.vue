<template>
  <div class="board">
    <div class="board-form-720">
    <!-- 파일 업로드 섹션 -->

    <div class="file-upload-header">
        <label class="title-md">파일 선택 (최대 20개)</label>
      </div>
      <div class="file-input-row">
        <button type="button" class="btn-secondary" @click="triggerFileInput">파일 찾기</button>
        <span class="txt-sm-gray">등록 가능 파일: PDF, JPG, PNG, DOC, DOCX, XLS, XLSX</span>
      </div>
      <input 
        type="file" 
        ref="fileInput" 
        @change="handleFileSelect" 
        multiple 
        hidden 
        accept=".pdf, .jpg, .png, .doc, .docx, .xls, .xlsx"
      />

      <!-- 업로드할 파일 목록 -->
      <div v-if="selectedFiles.length > 0" class="file-list-container">
        <label class="title-md">선택된 파일</label>
        <ul class="file-list">
          <li v-for="(file, index) in selectedFiles" :key="index" class="file-item">
            <span>{{ file.name }}</span>
            <Button icon="pi pi-trash" class="p-button-rounded p-button-text p-button-danger" @click="removeSelectedFile(index)" />
          </li>
        </ul>
      </div>
      

      <!-- 등록된 파일 목록 -->
      <div v-if="registeredFiles.length > 0" class="file-list-container" style="margin-top: 2rem;">
        <label class="title-md">등록된 파일</label>
        <ul class="file-list">
          <li v-for="file in registeredFiles" :key="file.id" class="file-item">
            <a :href="file.file_url" target="_blank" class="file-link">{{ file.file_name }}</a>
            <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="deleteRegisteredFile(file)" />
          </li>
        </ul>
      </div>
      <!-- 하단 버튼 -->
      <div class="form-actions-bottom">
        <button type="button" class="btn-cancel" @click="goBack" style="flex:1;">취소</button>
        <button type="submit" class="btn-add" :disabled="isSubmitting || selectedFiles.length === 0"
          :class="{ 'btn-disabled': isSubmitting || selectedFiles.length === 0 }"
          @click="submitFiles" style="flex:1;">
          제출
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import Button from 'primevue/button';

const route = useRoute();
const router = useRouter();

const settlementMonthId = route.params.settlementMonthId;
const hospitalId = route.params.hospitalId;

const settlementMonthLabel = ref('');
const registeredFiles = ref([]);
const selectedFiles = ref([]);
const fileInput = ref(null);
const isSubmitting = ref(false);

const triggerFileInput = () => {
  fileInput.value.click();
};

const handleFileSelect = (event) => {
  const newFiles = Array.from(event.target.files);
  const totalFiles = selectedFiles.value.length + newFiles.length;

  if (totalFiles > 20) {
    alert('파일은 최대 20개까지 선택할 수 있습니다.');
    // 필요한 경우 초과된 파일은 제외하고 추가하는 로직을 넣을 수 있습니다.
    return;
  }
  selectedFiles.value.push(...newFiles);
  event.target.value = ''; // 동일한 파일 다시 선택 가능하도록 초기화
};

const removeSelectedFile = (index) => {
  selectedFiles.value.splice(index, 1);
};

const fetchRegisteredFiles = async () => {
  const { data, error } = await supabase
    .from('edi_files')
    .select('*')
    .eq('submission_period_id', settlementMonthId)
    .eq('hospital_id', hospitalId)
    .eq('is_deleted', false)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('등록된 파일 조회 실패:', error);
    return;
  }
  registeredFiles.value = data;
};

const fetchSettlementMonth = async () => {
  const { data } = await supabase.from('edi_months').select('settlement_month').eq('id', settlementMonthId).single();
  settlementMonthLabel.value = data ? data.settlement_month : '';
};

const submitFiles = async () => {
  if (selectedFiles.value.length === 0) {
    alert('제출할 파일을 선택하세요.');
    return;
  }
  isSubmitting.value = true;
  
  const { data: { user } } = await supabase.auth.getUser();

  for (const file of selectedFiles.value) {
    const filePath = `edi_files/${settlementMonthLabel.value}/${user.id}/${hospitalId}/${Date.now()}_${file.name}`;
    const { data: uploadData, error: uploadError } = await supabase.storage.from('edi-uploads').upload(filePath, file);

    if (uploadError) {
      alert(`파일 업로드 실패: ${file.name}`);
      console.error('Upload Error:', uploadError.message);
      continue;
    }
    
    // 업로드 성공 후 반환된 경로로 공개 URL 생성
    const { data: { publicUrl } } = supabase.storage.from('edi-uploads').getPublicUrl(uploadData.path);
    
    const { error: insertError } = await supabase.from('edi_files').insert({
      submission_period_id: settlementMonthId,
      member_id: user.id,
      hospital_id: hospitalId,
      file_name: file.name,
      file_url: publicUrl, // 공개 URL 저장
      file_size_bytes: file.size,
    });

    if (insertError) {
      alert(`DB 기록 실패: ${file.name}`);
      console.error('Insert Error:', insertError.message);
      isSubmitting.value = false;
      return; // 에러 발생 시 중단
    }
  }

  alert('파일이 성공적으로 제출되었습니다.');
  selectedFiles.value = [];
  isSubmitting.value = false;
  await fetchRegisteredFiles();
  router.push('/edi/submit'); // 목록 페이지로 이동
};

const deleteRegisteredFile = async (file) => {
  if (!confirm(`'${file.file_name}' 파일을 삭제하시겠습니까?`)) {
    return;
  }
  
  // Storage에서 파일 삭제
  if (file.file_url) {
    // public URL에서 스토리지 경로 추출
    const urlParts = file.file_url.split('/edi-uploads/');
    if (urlParts.length > 1) {
      const storagePath = urlParts[1];
      const { error: removeError } = await supabase.storage.from('edi-uploads').remove([storagePath]);
      if (removeError) {
        alert('스토리지에서 파일을 삭제하는 데 실패했습니다.');
        console.error('Storage Delete Error:', removeError.message);
        return;
      }
    }
  }

  // DB에서 파일 정보 삭제 (소프트 삭제로 변경)
  const { error: dbError } = await supabase
    .from('edi_files')
    .update({ is_deleted: true })
    .eq('id', file.id);

  if (dbError) {
    alert('데이터베이스에서 파일 정보를 삭제하는 데 실패했습니다.');
    console.error('DB Delete Error:', dbError.message);
    return;
  }

  alert('파일이 성공적으로 삭제되었습니다.');
  await fetchRegisteredFiles();
};

const goBack = () => {
  router.back();
};

onMounted(async () => {
  await fetchSettlementMonth();
  await fetchRegisteredFiles();
});
</script>

<style scoped>
.file-upload-section {
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  padding: 1.5rem;
}

.file-upload-header {
  display: block;
  margin-bottom: 0.5rem;
}

/* 파일 선택라벨 */
.file-upload-header label {
  font-weight: 500;
  font-size: 1rem;
}

.file-input-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}


.file-list-container {
  margin-top: 1.5rem;
}

/* 파일 목록(선택된 파일) 라벨 */
.file-list-container label {
  font-weight: 500;
  font-size: 1rem;
  display: block;
  margin-bottom: 0.75rem;
  border-bottom: 1px solid #eee;
  padding-bottom: 0.5rem;
}

.file-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.file-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.file-list .file-item:last-child {
  border-bottom: none;
}

.file-link {
  color: #007bff;
  text-decoration: underline;
  cursor: pointer;
}

.form-actions-bottom {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1rem;
  padding-top: 1.5rem;
  border-top: 1px solid #f0f0f0;
}
</style> 