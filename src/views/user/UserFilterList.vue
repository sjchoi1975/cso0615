<template>
  <div class="user-filter-list-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- Filter Card -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <!-- PC 화면: 통합검색+필터+버튼 -->
        <template v-if="!isMobile">
          <span class="hide-mobile">통합 검색</span>
          <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="거래처명, 제약사명 입력" @keyup.enter="onSearch" />
          <span class="hide-mobile">거래처</span>
          <select v-model="selectedHospital" class="input-180 hide-mobile">
            <option value="">- 전체 -</option>
            <option v-for="hospital in hospitalOptions" :key="hospital.id" :value="hospital.id">{{ hospital.hospital_name }}</option>
          </select>
          <span class="hide-mobile">제약사</span>
          <select v-model="selectedPharma" class="input-180 hide-mobile">
            <option value="">- 전체 -</option>
            <option v-for="pharma in pharmaOptions" :key="pharma.id" :value="pharma.id">{{ pharma.company_name }}</option>
          </select>
          <span class="hide-mobile">구분</span>
          <select v-model="selectedFilterType" class="filter-dropdown hide-mobile">
            <option value="">- 전체 -</option>
            <option value="new">신규</option>
            <option value="transfer">이관</option>
          </select>
          <span class="hide-mobile">상태</span>
          <select v-model="selectedStatus" class="filter-dropdown hide-mobile">
            <option value="">- 전체 -</option>
            <option value="pending">대기</option>
            <option value="approved">승인</option>
            <option value="rejected">반려</option>
          </select>
          <button type="button" class="btn-search hide-mobile" @click="onSearch" :disabled="!isSearchEnabled">검색</button>
          <button type="button" class="btn-reset hide-mobile" @click="onReset">
            <i class="pi pi-refresh" style="font-size: 1rem;"></i>
            초기화
          </button>
        </template>
        <!-- 모바일 화면: 통합검색+X+돋보기만 -->
        <template v-else>
          <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
            <input v-model="search" class="input-search wide-mobile-search" placeholder="거래처명, 제약사명 입력" @keyup.enter="onSearch"/>
            <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onReset"
              style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
            <i class="pi pi-search search-btn-icon" @click="search.length >= 2 && onSearch()"
              style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          </div>
        </template>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card custom-auto-height">
      <div class="total-count total-count-nowrap">총 {{ totalCount.toLocaleString() }}건</div>
      <div style="display: flex; gap:1rem; align-items:center;">
        <Button
          icon="pi pi-download"
          label="다운로드"
          class="btn-download-md"
          @click="downloadExcel"
          iconPos="left"
          style="gap:0.5em;"
        />
      </div>
    </div>

    <!-- Table Card -->
    <div class="table-card user-filter-list-table">
      <div :style="tableConfig.tableStyle">
        <DataTable 
          :value="requests" 
          :loading="false"
          :paginator="false"
          scrollable 
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth, minWidth: tableConfig.tableStyle.minWidth }"
        >
          <Column
            v-for="col in tableConfig.columns"
            :key="col.field"
            :field="col.field"
            :header="col.label"
            :sortable="col.sortable || false"
            :style="{ width: col.width, textAlign: col.align }"
            :bodyStyle="{ textAlign: col.align }"
          >
            <template #body="slotProps">
              <template v-if="col.field === 'index'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ first + slotProps.index + 1 }}
                </span>
              </template>
              <template v-else-if="col.field === 'filter_type'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ slotProps.data.filter_type === 'new' ? '신규' : '이관' }}
                </span>
              </template>
              <template v-else-if="col.field === 'status'">
                <select disabled :class="['status-select-user', `status-select-${slotProps.data.status}-user`]">
                  <option value="pending" :selected="slotProps.data.status === 'pending'">대기</option>
                  <option value="approved" :selected="slotProps.data.status === 'approved'">승인</option>
                  <option value="rejected" :selected="slotProps.data.status === 'rejected'">반려</option>
                </select>
              </template>
              <template v-else-if="col.field === 'admin_comments'">
                <span v-if="slotProps.data.admin_comments" class="link" 
                  @click="openAdminCommentsModal(slotProps.data.admin_comments)">
                  {{ slotProps.data.admin_comments }}
                </span>
              </template>
              <template v-else-if="col.field === 'user_remarks'">
                <span v-if="slotProps.data.user_remarks" class="link" 
                  @click="openUserRemarksModal(slotProps.data.user_remarks)">
                  {{ slotProps.data.user_remarks }}
                </span>
              </template>
              <template v-else-if="col.field === 'member_comments'">
                <span v-if="slotProps.data.member_comments" class="link" 
                  @click="openUserRemarksModal(slotProps.data.member_comments)">
                  {{ slotProps.data.member_comments }}
                </span>
              </template>
              <template v-else-if="col.field === 'updated_at'">
                <span v-if="slotProps.data.updated_at && new Date(slotProps.data.updated_at).getTime() !== new Date(slotProps.data.request_date).getTime()">
                  {{ formatDateTime(slotProps.data.updated_at, false) }}
                </span>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'request_date'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ formatDateTime(slotProps.data.request_date, false) }}
                </span>
              </template>
              <template v-else-if="col.field === 'processed_at'">
                <span v-if="slotProps.data.processed_at" :class="getStatusClass(slotProps.data.status)">
                  {{ formatDateTime(slotProps.data.processed_at, false) }}
                </span>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'created_at'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ formatDateTime(slotProps.data.created_at, false) }}
                </span>
              </template>
              <template v-else-if="col.field === 'member_biz_no'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ slotProps.data.member_biz_no }}
                </span>
              </template>
              <template v-else-if="col.field === 'hospita_biz_no'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ slotProps.data.hospita_biz_no }}
                </span>
              </template>
              <template v-else-if="col.field === 'hospita_director_name'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ slotProps.data.hospita_director_name }}
                </span>
              </template>
              <template v-else-if="col.field === 'hospita_address'">
                <span :class="getStatusClass(slotProps.data.status)">
                  {{ slotProps.data.hospita_address }}
                </span>
              </template>
              <template v-else-if="col.field === 'pharmacist_name'">
                <span :class="slotProps.data.status === 'rejected' ? 'rejected-cell' 
                  : slotProps.data.status === 'pending' ? 'pending-cell' 
                  : 'table-title'">{{ slotProps.data.pharmacist_name }}
                </span>
              </template>
              <template v-else-if="col.field === 'hospital_name'">
                <span :class="slotProps.data.status === 'rejected' ? 'rejected-cell' 
                  : slotProps.data.status === 'pending' ? 'pending-cell' 
                  : 'table-title-link'">{{ slotProps.data.hospital_name }}
                </span>
              </template>

              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>
    
    <!-- Paginator -->
    <div class="fixed-paginator">
      <Paginator :rows="pageSize" :totalRecords="totalCount" :first="first" @page="onPageChange" />
    </div>

    <!-- Admin Comments Modal -->
    <div v-if="showAdminCommentsModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">전달사항</h3></div>
        <div class="modal-body"><div style="white-space: pre-line;">{{ adminCommentsContent }}</div></div>
        <div class="modal-footer"><button @click="closeAdminCommentsModal" class="btn-cancel modal">닫기</button></div>
      </div>
    </div>
    <!-- User Remarks Modal -->
    <div v-if="showUserRemarksModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">요청사항</h3></div>
        <div class="modal-body"><div style="white-space: pre-line;">{{ userRemarksContent }}</div></div>
        <div class="modal-footer"><button @click="closeUserRemarksModal" class="btn-cancel modal">닫기</button></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import * as XLSX from 'xlsx';
import { userFilterRequestsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import { formatDateTime } from '@/utils/dateFormatter';
import Button from 'primevue/button';

const requests = ref([]);
const loading = ref(false);
const first = ref(0);
const totalCount = ref(0);
const pageSize = ref(100);

const search = ref('');
const selectedHospital = ref('');
const selectedPharma = ref('');
const selectedStatus = ref('');
const selectedFilterType = ref('');

const hospitalOptions = ref([]);
const pharmaOptions = ref([]);

const showAdminCommentsModal = ref(false);
const adminCommentsContent = ref('');
const showUserRemarksModal = ref(false);
const userRemarksContent = ref('');

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userFilterRequestsTableConfig.mobile : userFilterRequestsTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

// 상태에 따른 스타일 클래스 결정 함수
const getStatusClass = (status) => {
  if (status === 'rejected') return 'rejected-cell';
  if (status === 'pending') return 'pending-cell';
  return '';
};

const fetchDropdownOptions = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;

  const { data, error } = await supabase
    .from('admin_filter_list_view')
    .select('hospital_id, hospital_name, pharmacist_name')
    .eq('member_id', user.id);
  
  if (error) {
    console.error('Error fetching dropdown options:', error);
    return;
  }

  if (data) {
    console.log('드롭다운 데이터:', data); // 실제 데이터 확인용
    const uniqueHospitals = [...new Map(data.map(item => 
      [item.hospital_id, { id: item.hospital_id, hospital_name: item.hospital_name }]
    )).values()].filter(Boolean);
    hospitalOptions.value = uniqueHospitals.filter(h => h.id);

    // 제약사명 중복 제거 (pharmacist_name)
    const uniquePharmas = [...new Map(data.map(item => 
      [item.pharmacist_name, { id: item.pharmacist_name, company_name: item.pharmacist_name }]
    )).values()].filter(Boolean);
    pharmaOptions.value = uniquePharmas.filter(p => p.id);
  }
};

const fetchRequests = async () => {
  loading.value = true;
  
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    loading.value = false;
    requests.value = [];
    totalCount.value = 0;
    return;
  }

  let query = supabase
    .from('admin_filter_list_view')
    .select(`*`, { count: 'exact' })
    .eq('member_id', user.id);

  // 통합검색: 거래처명, 제약사명(실제 컬럼명: hospital_name, pharmacist_name)
  if (search.value) {
    query = query.or(`hospital_name.ilike.%${search.value}%,pharmacist_name.ilike.%${search.value}%`);
  }
  if (selectedHospital.value) query = query.eq('hospital_id', selectedHospital.value);
  if (selectedPharma.value) query = query.eq('pharmacist_name', selectedPharma.value);
  if (selectedStatus.value) query = query.eq('status', selectedStatus.value);
  if (selectedFilterType.value) query = query.eq('filter_type', selectedFilterType.value);

  const from = first.value;
  const to = from + pageSize.value - 1;
  query = query.range(from, to);

  const { data, error, count } = await query;

  if (error) {
    alert('데이터 조회 실패: ' + error.message);
  } else {
    // 관리자와 동일한 정렬: 1. 미처리건(대기)이 위, 2. 각 그룹 내 최신순
    const sortedData = data.sort((a, b) => {
      if (a.status === 'pending' && b.status !== 'pending') return -1;
      if (a.status !== 'pending' && b.status === 'pending') return 1;
      const dateA = new Date(a.request_date);
      const dateB = new Date(b.request_date);
      return dateB - dateA;
    });
    requests.value = sortedData;
    totalCount.value = count || 0;
  }
  loading.value = false;
};

onMounted(() => {
    fetchRequests();
    fetchDropdownOptions();
});

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchRequests();
};

function openAdminCommentsModal(content) {
  adminCommentsContent.value = content;
  showAdminCommentsModal.value = true;
}
function closeAdminCommentsModal() {
  showAdminCommentsModal.value = false;
  adminCommentsContent.value = '';
}
function openUserRemarksModal(content) {
  userRemarksContent.value = content;
  showUserRemarksModal.value = true;
}
function closeUserRemarksModal() {
  showUserRemarksModal.value = false;
  userRemarksContent.value = '';
}

const downloadExcel = () => {
  const exportData = requests.value.map(row => ({
    '요청일시': formatDateTime(row.request_date, false),
    '구분': row.filter_type === 'new' ? '신규' : '이관',
    '거래처명': row.hospital_name,
    '제약사': row.pharmacist_name,
    '요청비고': row.user_remarks,
    '처리결과': row.status === 'pending' ? '대기' : row.status === 'approved' ? '승인' : '반려',
    '전달사항': row.admin_comments,
    '처리일시': row.updated_at && new Date(row.updated_at).getTime() !== new Date(row.request_date).getTime() ? formatDateTime(row.updated_at, false) : '-',
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '나의요청목록');
  XLSX.writeFile(wb, `my_requests_${new Date().toISOString().slice(0, 10)}.xlsx`);
};

const resetFilters = () => {
  search.value = '';
  selectedHospital.value = '';
  selectedPharma.value = '';
  selectedStatus.value = '';
  selectedFilterType.value = '';
};

const isSearched = ref(false);

const isSearchEnabled = computed(() =>
  search.value.length >= 2 ||
  selectedHospital.value ||
  selectedPharma.value ||
  selectedFilterType.value ||
  selectedStatus.value
);

const onSearch = () => {
  if (!isSearchEnabled.value) return;
  first.value = 0;
  isSearched.value = true;
  fetchRequests();
};

const onReset = () => {
  if (isSearched.value) {
    search.value = '';
    selectedHospital.value = '';
    selectedPharma.value = '';
    selectedStatus.value = '';
    selectedFilterType.value = '';
    first.value = 0;
    isSearched.value = false;
    fetchRequests();
  } else {
    search.value = '';
  }
};

</script>
