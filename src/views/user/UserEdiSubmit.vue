<template>
  <div class="user-edi-submit-view page-container">
    <!-- 로딩 중일 때만 스피너 -->
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 제출 가능 기간이 아닐 때(정산월 없음 포함) -->
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
            <!-- PC 화면: 통합검색+버튼 -->
            <template v-if="screenWidth > 768">
              <span class="hide-mobile">통합 검색</span>
              <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="거래처명, 원장명, 사업자등록번호, 주소 입력" @keyup.enter="onSearch" />
              <button type="button" class="btn-search hide-mobile" @click="onSearch" :disabled="search.length < 2">검색</button>
              <button type="button" class="btn-reset hide-mobile" @click="onReset">
                <i class="pi pi-refresh" style="font-size: 1rem;"></i>
                초기화
              </button>
            </template>
            <!-- 모바일 화면: 통합검색+X+돋보기만 -->
            <template v-else>
              <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
                <input v-model="search" class="input-search wide-mobile-search" placeholder="거래처명, 원장명, 사업자등록번호, 주소 입력" @keyup.enter="onSearch"/>
                <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onReset"
                  style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
                <i class="pi pi-search search-btn-icon" @click="search.length >= 2 && onSearch()"
                  style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
              </div>
            </template>
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
                <!-- PC: 거래처명만 표시 -->
                <div v-if="screenWidth > 768" class="table-title">
                  {{ slotProps.data.hospital_name }}
                </div>

                <!-- 모바일: 거래처명 + 주소 + 사업자번호/원장명 -->
                <div v-else class="mobile-hospital-info">
                  <div class="table-title">{{ slotProps.data.hospital_name }}</div>
                  <div class="hospital-address">{{ slotProps.data.address }}</div>
                  <div class="hospital-details">
                    {{ slotProps.data.business_registration_number }} / {{ slotProps.data.director_name }}
                  </div>
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
              <span v-else-if="col.field === 'viewDetail'" 
                    @click="(!slotProps.data.submission_count || slotProps.data.submission_count === 0) ? null : goToDetail(slotProps.data)"
                    class="edi-icon"
                    :class="{ 'inactive-icon': !slotProps.data.submission_count || slotProps.data.submission_count === 0 }"
                    :title="(!slotProps.data.submission_count || slotProps.data.submission_count === 0) ? '제출 이력이 없습니다' : '상세 보기'">
                <i class="pi pi-list"></i>
              </span>
              <span v-else-if="col.field === 'submit_button'"
                    @click="goToUpload(slotProps.data)"
                    class="edi-icon"
                    title="파일 제출">
                <i class="pi pi-upload"></i>
              </span>
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
const isSearched = ref(false);

const onSearch = () => {
  if (search.value.length < 2) return;
  isSearched.value = true;
  applySearch();
};

const onReset = () => {
  if (isSearched.value) {
    search.value = '';
    isSearched.value = false;
    applySearch();
  } else {
    search.value = '';
  }
};

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

  // edi_files 테이블에서 직접 파일 개수 조회
  const { data: fileCounts, error: fileCountError } = await supabase
    .from('edi_files')
    .select('hospital_id')
    .eq('settlement_month_id', currentMonthId)
    .eq('member_id', userInfo.value.id)
    .eq('is_deleted', false)
    .in('hospital_id', hospitalIds);

  if (fileCountError) {
    console.error('Error fetching file counts:', fileCountError);
  }

  // 병원별 파일 개수 계산
  const fileCountByHospital = {};
  fileCounts?.forEach(file => {
    fileCountByHospital[file.hospital_id] = (fileCountByHospital[file.hospital_id] || 0) + 1;
  });

  // edi_list_user_view에서 제출 단위별로 조회 (확인 여부 체크용)
  const { data: submissions, error: submissionError } = await supabase
    .from('edi_list_user_view')
    .select('*')
    .eq('settlement_month_id', currentMonthId)
    .eq('member_id', userInfo.value.id)
    .in('hospital_id', hospitalIds);

  if (submissionError) {
    console.error('Error fetching EDI submissions:', submissionError);
  }

  allMappedHospitals.value = hospitalMappings.map(mapping => {
    const hospital = mapping.hospitals;
    const hospitalSubmissions = submissions?.filter(sub => sub.hospital_id === mapping.hospital_id) || [];
    
    // 실제 파일 개수
    const totalFiles = fileCountByHospital[mapping.hospital_id] || 0;
    
    // 확인 여부 체크
    const isConfirmed = hospitalSubmissions.some(sub => sub.confirm) || false;
    
    return {
      ...hospital,
      current_month_files: totalFiles > 0 ? totalFiles : '-',
      prev_month_files: '-', // 전월은 항상 "-"
      confirm: isConfirmed,
      submission_count: hospitalSubmissions.length
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

.p-button.p-disabled {
  opacity: 0.4;
}
</style> 