<template>
  <div class="user-edi-submit-view page-container">
    <!-- 상단: 필터 -->
    <div class="filter-card">
      <div class="filter-row" style="display: flex; align-items: center; gap: 1rem;">
        <span>정산월</span>
        <select v-model="selectedPrescriptionMonth" class="input-120" :disabled="!selectedMonth">
          <option value="">전체</option>
          <option v-for="p in prescriptionMonthOptions" :key="p" :value="p">{{ p }}</option>
        </select>
        <span v-if="selectedMonth" style="font-size: 1.1rem;">
          제출 기간 : {{ formatDate(selectedMonth.start_date) }} ~ {{ formatDate(selectedMonth.end_date) }}
        </span>
      </div>
    </div>

    <!-- 제출 가능 기간일 때 -->
    <template v-if="isSubmissionPeriod">
      <div class="function-card" style="display: flex; justify-content: flex-end;">
        <Button 
          label="엑셀 다운로드" 
          icon="pi pi-download" 
          class="p-button-secondary"
          @click="downloadExcel"
        />
      </div>
      <div class="table-card">
        <DataTable 
          :value="mappedHospitals" 
          :loading="loading" 
          scrollable 
          :scrollHeight="'calc(100vh - 204px)'"
        >
          <Column header="No." headerStyle="width: 5%" bodyStyle="text-align: center">
            <template #body="slotProps">{{ slotProps.index + 1 }}</template>
          </Column>
          <Column field="hospital_name" header="거래처명" headerStyle="width: 20%" />
          <Column field="business_registration_number" header="사업자등록번호" headerStyle="width: 15%" />
          <Column field="director_name" header="원장명" headerStyle="width: 10%" />
          <Column field="address" header="주소" headerStyle="width: 20%" />
          <Column field="last_month_files" header="전월 제출 파일" headerStyle="width: 10%" />
          <Column field="current_month_files" header="당월 제출 파일" headerStyle="width: 10%" />
          <Column header="제출하기" headerStyle="width: 10%" bodyStyle="text-align: center">
            <template #body="slotProps">
              <Button icon="pi pi-plus" class="p-button-text" @click="goToFileDetail(slotProps.data)" />
            </template>
          </Column>
        </DataTable>
      </div>
    </template>
    
    <!-- 제출 가능 기간이 아닐 때 -->
    <div v-else class="notice-card">
      <div class="notice-icon"><i class="pi pi-info-circle"></i></div>
      <div class="notice-message">
        <h3>지금은 EDI 제출 기간이 아닙니다.</h3>
        <p>관리자가 설정한 제출 기간에만 파일을 제출할 수 있습니다.</p>
      </div>
    </div>

    <!-- 등록 모달 -->
    <Dialog v-model:visible="modalVisible" :header="modalHospital?.hospital_name || ''" :closable="false" style="min-width: 400px;">
      <div>
        <input type="file" multiple @change="onFileInputChange" />
        <ul style="margin-top: 1rem;">
          <li v-for="(file, idx) in modalFiles" :key="file.name + idx" style="display: flex; align-items: center; gap: 0.5rem;">
            <span>{{ file.name }}</span>
            <Button icon="pi pi-times" class="p-button-rounded p-button-text p-button-danger" @click="removeFile(idx)" />
          </li>
        </ul>
      </div>
      <template #footer>
        <Button label="취소" @click="closeModal" class="p-button-text" />
        <Button label="확인" @click="confirmUpload" :disabled="modalFiles.length === 0" />
      </template>
    </Dialog>

  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import { useToast } from 'primevue/usetoast';
import { useRouter } from 'vue-router';

const toast = useToast();
const router = useRouter();
const loading = ref(false);

const prescriptionMonthOptions = ref([]);
const selectedPrescriptionMonth = ref("");
const selectedMonth = ref(null);
const mappedHospitals = ref([]);
const userInfo = ref(null);

const modalVisible = ref(false);
const modalHospital = ref(null);
const modalFiles = ref([]);

const isSubmissionPeriod = computed(() => !!selectedMonth.value);

const fetchUserData = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    const { data: memberData, error } = await supabase
      .from('members')
      .select('*')
      .eq('id', user.id)
      .single();
    if (error) console.error('Error fetching member data:', error);
    else userInfo.value = memberData;
  }
};

// 오늘 날짜가 제출 유효기간(start_date~end_date)인 settlement_month만 옵션으로 제공
const fetchPrescriptionMonths = async () => {
  const today = new Date().toISOString().split('T')[0];
  const { data, error } = await supabase
    .from('edi_months')
    .select('*')
    .lte('start_date', today)
    .gte('end_date', today)
    .order('settlement_month', { ascending: false });
  if (!error && data && data.length > 0) {
    prescriptionMonthOptions.value = data.map(item => item.settlement_month);
    selectedPrescriptionMonth.value = data[0].settlement_month;
    selectedMonth.value = data[0];
  } else {
    prescriptionMonthOptions.value = [];
    selectedPrescriptionMonth.value = "";
    selectedMonth.value = null;
  }
};

const fetchMappedHospitals = async () => {
  if (!userInfo.value) return;
  loading.value = true;
  const { data, error } = await supabase
    .from('hospital_member_mappings')
    .select('hospitals (*)')
    .eq('member_id', userInfo.value.id);

  if (error) {
    console.error('Error fetching hospitals:', error);
  } else {
    mappedHospitals.value = data.map(item => ({
      ...item.hospitals,
      director_name: item.hospitals.director_name, // 원장명 필드명 수정
      last_month_files: '-', // TODO: 실제 파일 수 로직 구현 필요
      current_month_files: '-', // TODO: 실제 파일 수 로직 구현 필요
    }));
  }
  loading.value = false;
};

function openModal(hospital) {
  modalHospital.value = hospital;
  modalFiles.value = [];
  modalVisible.value = true;
}
function closeModal() {
  modalVisible.value = false;
  modalHospital.value = null;
  modalFiles.value = [];
}
function onFileInputChange(e) {
  const files = Array.from(e.target.files);
  modalFiles.value = modalFiles.value.concat(files);
  e.target.value = '';
}
function removeFile(idx) {
  modalFiles.value.splice(idx, 1);
}
async function confirmUpload() {
  if (!selectedMonth.value || !modalHospital.value || !userInfo.value) return;
  const companyId = userInfo.value.company_id;
  for (const file of modalFiles.value) {
    const filePath = `edi_files/${selectedMonth.value.settlement_month}/${companyId}/${modalHospital.value.id}/${file.name}`;
    const { error: uploadError } = await supabase.storage.from('edi_uploads').upload(filePath, file);
    if (uploadError) {
      toast.add({ severity: 'error', summary: '업로드 실패', detail: uploadError.message, life: 3000 });
      continue;
    }
    const { data: { publicUrl } } = supabase.storage.from('edi_uploads').getPublicUrl(filePath);
    const { error: dbError } = await supabase.from('edi_files').insert({
      submission_period_id: selectedMonth.value.id,
      company_member_id: userInfo.value.id,
      hospital_id: modalHospital.value.id,
      file_name: file.name,
      file_url: publicUrl,
      file_size_bytes: file.size,
      created_by: userInfo.value.id,
      settlement_month: selectedMonth.value.settlement_month,
    });
    if (dbError) {
      toast.add({ severity: 'error', summary: 'DB 저장 실패', detail: dbError.message, life: 3000 });
    }
  }
  toast.add({ severity: 'success', summary: '성공', detail: '파일이 성공적으로 제출되었습니다.', life: 3000 });
  closeModal();
  // TODO: 제출 내역 업데이트
}

const downloadExcel = () => {
  // TODO: 실제 엑셀 다운로드 구현
  alert('엑셀 다운로드 기능은 구현 예정입니다.');
};

const downloadExcelTemplate = () => {
  // TODO: 엑셀 양식 다운로드 로직
  alert('엑셀 양식 다운로드 기능은 구현 예정입니다.');
};

const formatDate = (dateString) => {
  if (!dateString) return '';
  const d = new Date(dateString);
  return `${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}.`;
};

function goToFileDetail(hospital) {
  if (!selectedMonth.value) return;
  router.push({ name: 'user-edi-file-detail', params: { settlementMonthId: selectedMonth.value.id, hospitalId: hospital.id } });
}

onMounted(async () => {
  await fetchUserData();
  await fetchPrescriptionMonths();
  if (isSubmissionPeriod.value) {
    await fetchMappedHospitals();
  }
});

</script>

<style scoped>
.submission-period-info {
  font-size: 0.9rem;
  color: var(--text-secondary);
}
.notice-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 3rem;
  background-color: var(--gray-100);
  border-radius: var(--border-radius-lg);
  margin-top: 1rem;
  height: 100%;
}
.notice-icon {
  font-size: 3rem;
  color: var(--primary-blue);
  margin-bottom: 1rem;
}
.notice-message h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.5rem;
  color: var(--text-primary);
}
.notice-message p {
  margin: 0;
  color: var(--text-secondary);
}
</style> 