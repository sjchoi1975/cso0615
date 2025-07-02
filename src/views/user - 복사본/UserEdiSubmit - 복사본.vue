<template>
  <div class="user-edi-submit-view page-container">
    <!-- 제출 가능 기간일 때 -->
    <template v-if="isSubmissionPeriod">
      <!-- Filter Card -->
      <div class="filter-card custom-auto-height">
        <div class="filter-row">
          <div class="p-input-icon-right" style="width: 100%;">
            <input v-model="search" placeholder="거래처명, 원장명, 사업자번호, 주소 검색" class="input-search" />
          </div>
        </div>
      </div>
      
      <div class="function-card" style="display: flex; justify-content: flex-end;">
        <span v-if="selectedMonth" style="font-size: 1.1rem;">
          제출 기간 : {{ formatDate(selectedMonth.start_date) }} ~ {{ formatDate(selectedMonth.end_date) }}
        </span>
      </div>

      <div class="table-card">
        <DataTable 
          :value="mappedHospitals" 
          :loading="loading" 
          scrollable 
          :scrollHeight="'calc(100vh - 204px)'"
          :style="activeTableConfig.tableStyle"
        >
          <Column 
            v-for="col in activeTableConfig.columns" 
            :key="col.field" 
            :field="col.field" 
            :header="col.label" 
            :style="{ width: col.width }"
            :bodyStyle="{ 'text-align': col.align }"
            :sortable="col.sortable"
          >
            <template #body="slotProps">
              <span v-if="col.type === 'index'">{{ slotProps.index + 1 }}</span>
              <Button v-else-if="col.type === 'button'" icon="pi pi-upload" class="p-button-text" @click="goToFileDetail(slotProps.data)" />
              <span v-else>{{ slotProps.data[col.field] }}</span>
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
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import { useToast } from 'primevue/usetoast';
import { useRouter } from 'vue-router';
import { userEdiSubmitTableConfig as tableConfig } from '@/config/tableConfig';
import InputText from 'primevue/inputtext';

const toast = useToast();
const router = useRouter();
const loading = ref(false);

const screenWidth = ref(window.innerWidth);

const activeTableConfig = computed(() => {
  if (screenWidth.value <= 768 && tableConfig.mobile) {
    return tableConfig.mobile;
  }
  return tableConfig.pc;
});

const handleResize = () => {
  screenWidth.value = window.innerWidth;
};

const prescriptionMonthObjects = ref([]);
const selectedMonth = ref(null);
const allMappedHospitals = ref([]);
const mappedHospitals = ref([]);
const userInfo = ref(null);

const modalVisible = ref(false);
const modalHospital = ref(null);
const modalFiles = ref([]);

const search = ref('');

let debounceTimer = null;
watch(search, () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    applySearch();
  }, 300);
});

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

const fetchPrescriptionMonths = async () => {
  const today = new Date().toISOString().split('T')[0];
  const { data, error } = await supabase
    .from('edi_months')
    .select('*')
    .lte('start_date', today)
    .gte('end_date', today)
    .order('settlement_month', { ascending: false });
  if (!error && data && data.length > 0) {
    prescriptionMonthObjects.value = data;
    selectedMonth.value = data[0];
  } else {
    prescriptionMonthObjects.value = [];
    selectedMonth.value = null;
  }
};

const fetchMappedHospitals = async () => {
  if (!userInfo.value || !selectedMonth.value) {
    allMappedHospitals.value = [];
    return;
  }
  loading.value = true;
  
  const { data: hospitalMappings, error: hospitalError } = await supabase
    .from('hospital_member_mappings')
    .select('hospitals (*)')
    .eq('member_id', userInfo.value.id);

  if (hospitalError) {
    console.error('Error fetching hospitals:', hospitalError);
    allMappedHospitals.value = [];
    loading.value = false;
    return;
  }

  if (!hospitalMappings || hospitalMappings.length === 0) {
    allMappedHospitals.value = [];
    loading.value = false;
    return;
  }

  const hospitals = hospitalMappings.map(item => item.hospitals);
  const hospitalIds = hospitals.map(h => h.id);
  
  const currentMonthId = selectedMonth.value.id;
  const currentMonthStr = selectedMonth.value.settlement_month;
  const [year, month] = currentMonthStr.split('-').map(Number);
  const lastMonthDate = new Date(year, month - 2, 1);
  const lastMonthYear = lastMonthDate.getFullYear();
  const lastMonthMonth = (lastMonthDate.getMonth() + 1).toString().padStart(2, '0');
  const lastMonthStr = `${lastMonthYear}-${lastMonthMonth}`;

  const { data: lastMonthData } = await supabase.from('edi_months').select('id').eq('settlement_month', lastMonthStr).single();
  const lastMonthId = lastMonthData?.id;
  
  const periodIds = [currentMonthId];
  if (lastMonthId) periodIds.push(lastMonthId);

  const { data: files, error: filesError } = await supabase
    .from('edi_files')
    .select('hospital_id, submission_period_id')
    .in('hospital_id', hospitalIds)
    .in('submission_period_id', periodIds)
    .eq('is_deleted', false);

  if (filesError) {
    console.error('Error fetching file counts:', filesError);
  }
  
  const fileCounts = (files || []).reduce((acc, file) => {
    const key = `${file.hospital_id}-${file.submission_period_id}`;
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});

  allMappedHospitals.value = hospitals.map(hospital => {
    const currentMonthCount = fileCounts[`${hospital.id}-${currentMonthId}`] || 0;
    const lastMonthCount = lastMonthId ? (fileCounts[`${hospital.id}-${lastMonthId}`] || 0) : 0;

    return {
      ...hospital,
      last_month_files: lastMonthCount > 0 ? lastMonthCount : '-',
      current_month_files: currentMonthCount > 0 ? currentMonthCount : '-',
    };
  });
  
  applySearch();
  loading.value = false;
};

const applySearch = () => {
  const query = search.value.toLowerCase();
  if (!query) {
    mappedHospitals.value = [...allMappedHospitals.value];
    return;
  }
  mappedHospitals.value = allMappedHospitals.value.filter(h =>
    h.hospital_name?.toLowerCase().includes(query) ||
    h.director_name?.toLowerCase().includes(query) ||
    h.business_registration_number?.replace(/-/g, '').includes(query) ||
    h.address?.toLowerCase().includes(query)
  );
};

const clearSearch = () => {
  search.value = '';
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
  window.addEventListener('resize', handleResize);
  await fetchUserData();
  await fetchPrescriptionMonths();
  if (isSubmissionPeriod.value) {
    await fetchMappedHospitals();
  }
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
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