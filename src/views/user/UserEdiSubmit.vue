<template>
  <div class="user-edi-submit-view page-container">
    <!-- 로딩 중일 때 또는 selectedMonth가 null일 때 -->
    <div v-if="loading || selectedMonth === null" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    
    <!-- 제출 가능 기간이 아닐 때 -->
    <div v-else-if="!isSubmissionPeriod" class="notice-card">
      <div class="notice-icon"><i class="pi pi-info-circle"></i></div>
      <div class="notice-message">
        <h3>지금은 EDI 제출 기간이 아닙니다.</h3>
        <p>관리자가 설정한 제출 기간에만 파일을 제출할 수 있습니다.</p>
      </div>
    </div>

    <!-- 제출 가능 기간일 때 -->
    <template v-else>
      <div class="fixed-header">
        <!-- Filter Card -->
        <div class="filter-card">
          <div class="filter-row filter-row-center">
            <span class="hide-mobile">통합 검색</span>
            <div>
              <input 
                v-model="search" 
                class="input-search wide-mobile-search"
                placeholder="거래처명, 원장명, 사업자번호, 주소 입력" 
              />
            </div>
          </div>
        </div>
        
        <div class="function-card" style="display: flex; justify-content: flex-end;">
          <span v-if="selectedMonth" style="font-size: 1.1rem;">
            제출 기간 :
            {{ selectedMonth.start_date ? new Date(selectedMonth.start_date).toISOString().slice(0,10) : '' }}
            ~
            {{ selectedMonth.end_date ? new Date(selectedMonth.end_date).toISOString().slice(0,10) : '' }}
            <span v-if="selectedMonth.end_date" class="badge-dn">
              D-{{ getRemainDays(selectedMonth.end_date) }}
            </span>
          </span>
        </div>
      </div>

      <div class="table-container">
        <DataTable 
          :value="mappedHospitals" 
          :loading="false"
          :paginator="false"
          scrollable
          scrollDirection="vertical"
          :scrollHeight="isSubmissionPeriod ? getTableScrollHeight(false) : undefined"
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

              <span v-if="col.field === 'hospital_name'">
                <div class="table-title">
                  {{ slotProps.data.hospital_name }}
                </div>
              </span>


              <span v-else-if="col.field === 'current_month_files' && slotProps.data.current_month_files != '-'">
                <span class="file-count-link" @click="goToFileDetail(slotProps.data)">
                  {{ slotProps.data.current_month_files }}
                </span>
              </span>
              <span v-else-if="col.field === 'prev_month_files'">
                <span v-if="slotProps.data.prev_month_files != '-'">{{ slotProps.data.prev_month_files }}</span>
                <span v-else>-</span>
              </span>
              <Button
                v-else-if="col.field === 'viewDetail'"
                icon="pi pi-list"
                class="p-button-text"
                @click="goToDetail(slotProps.data)"
                :disabled="!slotProps.data.current_month_files || slotProps.data.current_month_files === 0"
                :class="{ 'p-disabled': !slotProps.data.current_month_files || slotProps.data.current_month_files === 0 }"
                :style="(!slotProps.data.current_month_files || slotProps.data.current_month_files === 0) ? 'opacity: 0.4;' : ''"
              />
              <Button
                v-else-if="col.field === 'submit_button'"
                icon="pi pi-upload"
                class="p-button-text"
                @click="goToUpload(slotProps.data)"
              />
              <span v-else>{{ slotProps.data[col.field] }}</span>
            </template>
          </Column>
        </DataTable>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import { useToast } from 'primevue/usetoast';
import { useRouter } from 'vue-router';
import { userEdiSubmitTableConfig as tableConfig } from '@/config/tableConfig';
import InputText from 'primevue/inputtext';
import { getTableScrollHeight } from '@/utils/tableHeight';

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
  console.log('Today:', today);
  const { data, error } = await supabase
    .from('edi_months')
    .select('*')
    .lte('start_date', today)
    .gte('end_date', today)
    .order('settlement_month', { ascending: false });
  console.log('Prescription months data:', data);
  console.log('Error:', error);
  if (!error && data && data.length > 0) {
    prescriptionMonthObjects.value = data;
    selectedMonth.value = data[0];
  } else {
    prescriptionMonthObjects.value = [];
    selectedMonth.value = null;
  }
  loading.value = false;  // 여기에 loading 상태 해제 추가
};

const fetchMappedHospitals = async () => {
  if (!userInfo.value || !selectedMonth.value) {
    allMappedHospitals.value = [];
    return;
  }
  loading.value = true;
  
  const { data: hospitalMappings, error: hospitalError } = await supabase
    .from('hospital_member_mappings')
    .select('hospital_id, hospitals (*)')
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

  // 거래처명으로 정렬
  const hospitals = hospitalMappings
    .map(item => item.hospitals)
    .sort((a, b) => a.hospital_name.localeCompare(b.hospital_name, 'ko'));

  const hospitalIds = hospitalMappings.map(h => h.hospital_id);
  const currentMonthId = selectedMonth.value.id;

  // edi_files에서 settlement_month_id, member_id, hospital_id 기준으로 조회
  const { data: ediFiles, error: ediError } = await supabase
    .from('edi_files')
    .select('id, hospital_id, member_id, settlement_month_id, confirm')
    .eq('settlement_month_id', currentMonthId)
    .eq('member_id', userInfo.value.id)
    .in('hospital_id', hospitalIds);

  if (ediError) {
    console.error('Error fetching EDI files:', ediError);
  }

  allMappedHospitals.value = hospitalMappings.map(mapping => {
    const hospital = mapping.hospitals;
    const fileCount = ediFiles?.filter(file => file.hospital_id === mapping.hospital_id).length || 0;
    const isConfirmed = ediFiles?.some(file => file.hospital_id === mapping.hospital_id && file.confirm) || false;
    return {
      ...hospital,
      current_month_files: fileCount > 0 ? fileCount : '-',
      prev_month_files: fileCount > 0 ? fileCount : '-', // 전월 제출 파일 수 추가
      confirm: isConfirmed
    };
  });

  applySearch();
  loading.value = false;
};

const applySearch = () => {
  const query = search.value.toLowerCase();
  if (!query) {
    mappedHospitals.value = [...allMappedHospitals.value].sort((a, b) => a.hospital_name.localeCompare(b.hospital_name, 'ko'));
    return;
  }
  mappedHospitals.value = allMappedHospitals.value.filter(h =>
    h.hospital_name?.toLowerCase().includes(query) ||
    h.director_name?.toLowerCase().includes(query) ||
    h.business_registration_number?.replace(/-/g, '').includes(query) ||
    h.address?.toLowerCase().includes(query)
  ).sort((a, b) => a.hospital_name.localeCompare(b.hospital_name, 'ko'));
};

const clearSearch = () => {
  search.value = '';
};

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
  router.push({ path: `/edi/submit/${selectedMonth.value.id}/${hospital.id}` });
}

function goToDetail(row) {
  console.log('goToDetail 호출', row, selectedMonth.value);
  if (!selectedMonth.value || !row.id) return;
  const path = `/edi/submit/${selectedMonth.value.id}/${row.id}/detail`;
  console.log('이동 경로:', path);
  router.push(path);
}

function getRemainDays(endDate) {
  const today = new Date();
  const end = new Date(endDate);
  // 00:00:00 기준으로 맞추기
  today.setHours(0,0,0,0);
  end.setHours(0,0,0,0);
  const diff = Math.ceil((end - today) / (1000 * 60 * 60 * 24));
  return diff >= 0 ? diff : 0;
}

function goToUpload(row) {
  if (!selectedMonth.value || !row.id) return;
  router.push(`/edi/submit/${selectedMonth.value.id}/${row.id}`);
}

onMounted(async () => {
  window.addEventListener('resize', handleResize);
  await fetchUserData();
  await fetchPrescriptionMonths();
  await fetchMappedHospitals();
  // 자동 리다이렉트 코드 제거 (아래 코드 삭제)
  // if (selectedMonth.value && mappedHospitals.value.length > 0) {
  //   const settlementMonth = selectedMonth.value.settlement_month;
  //   const hospitalId = mappedHospitals.value[0].id;
  //   router.replace(`/edi/submit/${settlementMonth}/${hospitalId}`);
  // }
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});

</script>

<style scoped>
.page-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.fixed-header {
  flex-shrink: 0;
}


.table-card {
  height: 100%;
}

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
  height: calc(100vh - 200px);
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
.p-button.p-disabled {
  opacity: 0.4;
}
</style> 