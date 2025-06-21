<template>
  <div class="user-edi-submit-view page-container">
    <!-- 상단: 필터 -->
    <div class="filter-card">
      <div class="filter-row">
        <Dropdown 
          v-model="selectedPeriod" 
          :options="availablePeriods" 
          optionLabel="settlement_month" 
          placeholder="제출할 정산월을 선택하세요"
          style="width: 250px;"
          :disabled="!isSubmissionPeriod"
        />
      </div>
    </div>

    <!-- 제출 가능 기간일 때 -->
    <template v-if="isSubmissionPeriod">
      <div class="function-card">
        <div>
          <span v-if="selectedPeriod" class="submission-period-info">
            제출 기간: {{ formatDate(selectedPeriod.start_date) }} ~ {{ formatDate(selectedPeriod.end_date) }}
          </span>
        </div>
        <Button 
          label="엑셀 양식 다운로드" 
          icon="pi pi-download" 
          class="p-button-secondary"
          @click="downloadExcelTemplate" 
        />
      </div>

      <div class="table-card">
        <DataTable :value="mappedHospitals" :loading="loading" scrollable scrollHeight="calc(100vh - 250px)">
          <Column header="No." headerStyle="width: 5%" bodyStyle="text-align: center">
            <template #body="slotProps">{{ slotProps.index + 1 }}</template>
          </Column>
          <Column field="hospital_name" header="병의원명" headerStyle="width: 30%" />
          <Column field="business_registration_number" header="사업자등록번호" headerStyle="width: 20%" />
          <Column field="last_month_files" header="전월 제출 파일" headerStyle="width: 15%">
            <!-- TODO: 전월 파일 표시 -->
          </Column>
          <Column field="current_month_files" header="당월 제출 파일" headerStyle="width: 15%">
            <!-- TODO: 당월 파일 표시 -->
          </Column>
          <Column header="제출하기" headerStyle="width: 15%" bodyStyle="text-align: center">
            <template #body="slotProps">
              <FileUpload 
                mode="basic" 
                name="edi_file" 
                :url="uploadUrl"
                :auto="true"
                :customUpload="true" 
                @uploader="onUpload($event, slotProps.data)"
                chooseLabel="파일 선택"
                :disabled="!selectedPeriod"
              />
            </template>
          </Column>
        </DataTable>
      </div>
    </template>
    
    <!-- 제출 가능 기간이 아닐 때 -->
    <div v-else class="notice-card">
      <div class="notice-icon"><i class="pi pi-info-circle"></i></div>
      <div class="notice-message">
        <h3>지금은 EDI 증빙자료 제출 기간이 아닙니다.</h3>
        <p>관리자가 설정한 제출 기간에만 파일을 제출할 수 있습니다.</p>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import FileUpload from 'primevue/fileupload';
import { useToast } from 'primevue/usetoast';

const toast = useToast();
const loading = ref(false);

const availablePeriods = ref([]);
const selectedPeriod = ref(null);
const mappedHospitals = ref([]);
const userInfo = ref(null);

const isSubmissionPeriod = computed(() => availablePeriods.value.length > 0);
const uploadUrl = ref(''); // Dummy URL

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

const fetchAvailablePeriods = async () => {
  const today = new Date().toISOString().split('T')[0];
  const { data, error } = await supabase
    .from('edi_submission_periods')
    .select('*')
    .lte('start_date', today)
    .gte('end_date', today);
  
  if (error) console.error('Error fetching periods:', error);
  else {
    availablePeriods.value = data;
    if (data.length > 0) {
      selectedPeriod.value = data[0]; // 자동으로 첫번째 기간 선택
    }
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
    mappedHospitals.value = data.map(item => item.hospitals);
  }
  loading.value = false;
};

const onUpload = async (event, hospital) => {
  if (!selectedPeriod.value) {
    toast.add({ severity: 'warn', summary: '경고', detail: '정산월을 먼저 선택해주세요.', life: 3000 });
    return;
  }
  const file = event.files[0];
  const companyId = userInfo.value?.company_id; // members 테이블에 company_id가 있다는 가정
  if (!companyId) {
     toast.add({ severity: 'error', summary: '오류', detail: '사용자 정보에서 회사 ID를 찾을 수 없습니다.', life: 3000 });
     return;
  }

  const filePath = `edi_files/${selectedPeriod.value.settlement_month}/${companyId}/${hospital.id}/${file.name}`;

  const { error: uploadError } = await supabase.storage.from('edi_uploads').upload(filePath, file);

  if (uploadError) {
    toast.add({ severity: 'error', summary: '업로드 실패', detail: uploadError.message, life: 3000 });
    return;
  }

  const { data: { publicUrl } } = supabase.storage.from('edi_uploads').getPublicUrl(filePath);

  const { error: dbError } = await supabase.from('edi_files').insert({
    submission_period_id: selectedPeriod.value.id,
    company_member_id: userInfo.value.id,
    hospital_id: hospital.id,
    file_name: file.name,
    file_url: publicUrl,
    file_size_bytes: file.size,
    created_by: userInfo.value.id,
  });

  if (dbError) {
    toast.add({ severity: 'error', summary: 'DB 저장 실패', detail: dbError.message, life: 3000 });
  } else {
    toast.add({ severity: 'success', summary: '성공', detail: '파일이 성공적으로 제출되었습니다.', life: 3000 });
    // TODO: 제출 내역 업데이트
  }
};

const downloadExcelTemplate = () => {
  // TODO: 엑셀 양식 다운로드 로직
  alert('엑셀 양식 다운로드 기능은 구현 예정입니다.');
};

const formatDate = (dateString) => {
  if (!dateString) return '';
  return new Date(dateString).toLocaleDateString();
}

onMounted(async () => {
  await fetchUserData();
  await fetchAvailablePeriods();
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