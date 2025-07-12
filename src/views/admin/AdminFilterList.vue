<template>
  <div class="admin-filter-list-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- Filter Card -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <span class="hide-mobile">통합 검색</span>
        <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="업체명, 거래처명, 제약사명 입력" />
        <div class="hide-mobile" style="display: flex; gap: 0.5rem; align-items: center;">
          <span>업체</span>
          <select v-model="selectedMember" class="input-180">
            <option value="">- 전체 -</option>
            <option v-for="member in memberOptions" :key="member.uid" :value="member.uid">{{ member.company_name }}</option>
          </select>
          <span>거래처</span>
          <select v-model="selectedHospital" class="input-180">
            <option value="">- 전체 -</option>
            <option v-for="hospital in hospitalOptions" :key="hospital.id" :value="hospital.id">{{ hospital.hospital_name }}</option>
          </select>
          <span>제약사</span>
          <select v-model="selectedPharma" class="input-180">
            <option value="">- 전체 -</option>
            <option v-for="pharma in pharmaOptions" :key="pharma.id" :value="pharma.id">{{ pharma.company_name }}</option>
          </select>
          <span>구분</span>
          <select v-model="selectedFilterType" class="filter-dropdown">
            <option value="">- 전체 -</option>
            <option value="new">신규</option>
            <option value="transfer">이관</option>
          </select>
          <span>상태</span>
          <select v-model="selectedStatus" class="filter-dropdown">
            <option value="">- 전체 -</option>
            <option value="pending">대기</option>
            <option value="approved">승인</option>
            <option value="rejected">반려</option>
          </select>
          <button type="button" class="btn-search" @click="onSearch" :disabled="!isSearchEnabled">검색</button>
          <button type="button" class="btn-reset" @click="onReset">
            <i class="pi pi-refresh" style="font-size: 1rem;"></i>
            초기화
          </button>
        </div>
        <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
          <input v-model="search" class="input-search wide-mobile-search" placeholder="업체명, 거래처명, 제약사명 입력" @keyup.enter="onSearch"/>
          <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onClearSearch"
            style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          <i class="pi pi-search search-btn-icon" @click="isSearchEnabled && onSearch()"
            :class="{ 'disabled': !isSearchEnabled }"
            style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
        </div>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}건</div>
      <div style="display: flex; gap:0.5rem; align-items:center;">
        <Button
          icon="pi pi-download"
          label="다운로드"
          class="btn-download-md"
          @click="downloadExcel"
          iconPos="left"
          style="gap:0.5rem;"
        />
      </div>
    </div>

    <!-- Table Card -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="filteredList"
          :loading="false"
          :paginator="false"
          scrollable
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth }"
        >
          <Column
            v-for="col in tableConfig.columns"
            :key="col.field"
            :field="col.field"
            :header="col.label"
            :sortable="col.sortable || false"
            :style="{ width: col.width, textAlign: col.align, whiteSpace: 'normal', overflow: 'visible', textOverflow: 'unset' }"
            :bodyStyle="{ textAlign: col.align, whiteSpace: 'normal', overflow: 'visible', textOverflow: 'unset' }"
          >
            <template #body="slotProps">
              <template v-if="col.field === 'index'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ first + slotProps.index + 1 }}</span>
              </template>
              <template v-else-if="col.field === 'request_date'">
                {{ formatDateTime(slotProps.data.request_date) }}
              </template>
              <template v-else-if="col.field === 'updated_at'">
                {{ formatDateTime(slotProps.data.updated_at) }}
              </template>
              <template v-else-if="col.field === 'filter_type'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ slotProps.data.filter_type === 'new' ? '신규' : '이관' }}</span>
              </template>
              <template v-else-if="col.field === 'status'">
                <select v-model="slotProps.data.status" @change="updateStatus(slotProps.data)" :class="['status-select', `status-select-${slotProps.data.status}`]">
                  <option value="pending">대기</option>
                  <option value="approved">승인</option>
                  <option value="rejected">반려</option>
                </select>
              </template>
              <template v-else-if="col.field === 'admin_comments'">
                <span class="link" @click="openAdminCommentsModal(slotProps.data)">
                  <template v-if="!slotProps.data.admin_comments">
                    <i class="pi pi-pencil" style="margin-right:8px;"></i>등록
                  </template>
                  <template v-else>
                    {{ slotProps.data.admin_comments }}
                  </template>
                </span>
              </template>
              <template v-else-if="col.field === 'user_remarks'">
                <span v-if="slotProps.data.user_remarks" class="link" @click="openRemarksModal(slotProps.data.user_remarks)">
                  {{ slotProps.data.user_remarks }}
                </span>
              </template>
              <template v-else-if="col.field === 'member_name'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected', 'table-title': slotProps.data.status !== 'rejected' }">{{ slotProps.data.member_name }}</span>
              </template>
              <template v-else-if="col.field === 'hospital_name'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected', 'table-title': slotProps.data.status !== 'rejected' }">{{ slotProps.data.hospital_name }}</span>
              </template>
              <template v-else-if="col.field === 'pharmacist_name'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected', 'table-title': slotProps.data.status !== 'rejected' }">{{ slotProps.data.pharmacist_name }}</span>
              </template>
              <template v-else-if="col.field === 'ceo_name'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ slotProps.data.ceo_name }}</span>
              </template>
              <template v-else-if="col.field === 'created_at'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ formatDateTime(slotProps.data.created_at) }}</span>
              </template>
              <template v-else-if="col.field === 'processed_at'">
                <span v-if="slotProps.data.processed_at">
                  {{ isMobile.value ? new Date(slotProps.data.processed_at).toISOString().slice(0, 10) : (new Date(slotProps.data.processed_at).getFullYear() + '-' + String(new Date(slotProps.data.processed_at).getMonth() + 1).padStart(2, '0') + '-' + String(new Date(slotProps.data.processed_at).getDate()).padStart(2, '0') + ' ' + String(new Date(slotProps.data.processed_at).getHours()).padStart(2, '0') + ':' + String(new Date(slotProps.data.processed_at).getMinutes()).padStart(2, '0')) }}
                </span>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'member_comments'">
                <span v-if="slotProps.data.member_comments" class="link" @click="openRemarksModal(slotProps.data.member_comments)">
                  {{ slotProps.data.member_comments }}
                </span>
              </template>
              <template v-else-if="col.field === 'member_biz_no'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ slotProps.data.member_biz_no }}</span>
              </template>
              <template v-else-if="col.field === 'hospita_biz_no'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ slotProps.data.hospita_biz_no }}</span>
              </template>
              <template v-else-if="col.field === 'hospita_director_name'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ slotProps.data.hospita_director_name }}</span>
              </template>
              <template v-else-if="col.field === 'hospita_address'">
                <span :class="{ 'rejected-cell': slotProps.data.status === 'rejected' }">{{ slotProps.data.hospita_address }}</span>
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

    <!-- Remarks Modal -->
    <div v-if="showRemarksModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">회원 요청사항</h3></div>
        <div class="modal-body"><div style="white-space: pre-line;">{{ currentRemark }}</div></div>
        <div class="modal-footer"><button @click="closeRemarksModal" class="btn-cancel modal">닫기</button></div>
      </div>
    </div>
    
    <!-- Admin Comments Modal -->
    <div v-if="showAdminCommentsModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">회원 전달사항</h3></div>
        <div class="modal-body">
          <textarea v-model="adminComments" class="input" rows="5" placeholder="전달사항을 입력하세요."></textarea>
        </div>
        <div class="modal-footer">
          <button @click="closeAdminCommentsModal" class="btn-cancel modal">취소</button>
          <button @click="saveAdminComments" class="btn-confirm modal">저장</button>
        </div>
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
import { filterRequestsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import Button from 'primevue/button';

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? filterRequestsTableConfig.mobile : filterRequestsTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const requests = ref([]);
const filteredList = ref([]);
const loading = ref(false);
const first = ref(0);
const totalCount = ref(0);
const pageSize = ref(100);

const search = ref('');
const isSearched = ref(false);

// Filter states
const selectedMember = ref('');
const selectedHospital = ref('');
const selectedPharma = ref('');
const selectedStatus = ref('');
const selectedFilterType = ref('');

// Dropdown options
const memberOptions = ref([]);
const hospitalOptions = ref([]);
const pharmaOptions = ref([]);

// Modals state
const showRemarksModal = ref(false);
const currentRemark = ref('');
const showAdminCommentsModal = ref(false);
const adminComments = ref('');
const selectedRequest = ref(null);

// 검색 활성화 조건
const isSearchEnabled = computed(() => {
  return search.value.length >= 2 || 
         selectedMember.value || 
         selectedHospital.value || 
         selectedPharma.value || 
         selectedStatus.value || 
         selectedFilterType.value;
});

// Fetch dropdown options
const fetchDropdownOptions = async () => {
  const { data, error } = await supabase
    .from('admin_filter_list_view')
    .select('member_id, member_name, hospital_id, hospital_name, pharmaceutical_company_id, pharmaceutical_company_name');

  if (error) {
    console.error('Error fetching dropdown options:', error);
    return;
  }

  if (data) {
    const uniqueMembers = [...new Map(data.map(item => 
      [item.member_id, { uid: item.member_id, company_name: item.member_name }]
    )).values()].filter(Boolean);
    memberOptions.value = uniqueMembers.filter(m => m.uid);

    const uniqueHospitals = [...new Map(data.map(item => 
      [item.hospital_id, { id: item.hospital_id, hospital_name: item.hospital_name }]
    )).values()].filter(Boolean);
    hospitalOptions.value = uniqueHospitals.filter(h => h.id);

    const uniquePharmas = [...new Map(data.map(item => 
      [item.pharmaceutical_company_id, { id: item.pharmaceutical_company_id, company_name: item.pharmaceutical_company_name }]
    )).values()].filter(Boolean);
    pharmaOptions.value = uniquePharmas.filter(p => p.id);
  }
};

// Fetch data
const fetchRequests = async () => {
  loading.value = true;
  let query = supabase
    .from('admin_filter_list_view')
    .select(`*`, { count: 'exact' });

  if (search.value) {
    query = query.or(`member_name.ilike.%${search.value}%,hospital_name.ilike.%${search.value}%,pharmacist_name.ilike.%${search.value}%`);
  }
  if (selectedMember.value) query = query.eq('member_id', selectedMember.value);
  if (selectedHospital.value) query = query.eq('hospital_id', selectedHospital.value);
  if (selectedPharma.value) query = query.eq('pharmaceutical_company_id', selectedPharma.value);
  if (selectedStatus.value) query = query.eq('status', selectedStatus.value);
  if (selectedFilterType.value) query = query.eq('filter_type', selectedFilterType.value);

  const from = first.value;
  const to = from + pageSize.value - 1;
  query = query.range(from, to);

  const { data, error, count } = await query;

  if (error) {
    alert('데이터 조회 실패: ' + error.message);
  } else {
    // 정렬: 1. 대기건 최우선, 2. 각 그룹 내에서 최신순
    const sortedData = data.sort((a, b) => {
      // 1. 대기건이 최우선
      if (a.status === 'pending' && b.status !== 'pending') return -1;
      if (a.status !== 'pending' && b.status === 'pending') return 1;
      
      // 2. 각 그룹 내에서 요청일시 기준 최신순
      const dateA = new Date(a.request_date);
      const dateB = new Date(b.request_date);
      return dateB - dateA; // 최신이 위로
    });

    requests.value = sortedData;
    filteredList.value = sortedData;
    totalCount.value = count || 0;
  }
  loading.value = false;
};

// 검색 실행
const onSearch = () => {
  if (!isSearchEnabled.value) return;
  isSearched.value = true;
  first.value = 0;
  fetchRequests();
};

// 초기화
const onReset = () => {
  search.value = '';
  selectedMember.value = '';
  selectedHospital.value = '';
  selectedPharma.value = '';
  selectedStatus.value = '';
  selectedFilterType.value = '';
  isSearched.value = false;
  first.value = 0;
  fetchRequests();
};

// 검색어만 초기화 (모바일 X 버튼)
const onClearSearch = () => {
  if (isSearched.value) {
    // 검색 후: 전체 초기화
    onReset();
  } else {
    // 검색 전: 검색어만 삭제
    search.value = '';
  }
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

const updateStatus = async (request) => {
  const { data: { user } } = await supabase.auth.getUser();
  const { error } = await supabase
    .from('filtering_requests')
    .update({ 
      status: request.status, 
      processed_at: new Date().toISOString(),
      processed_by: user.id
    })
    .eq('id', request.id);
  if (error) {
    alert('상태 업데이트 실패: ' + error.message);
  } else {
    alert('처리결과가 변경되었습니다.');
    fetchRequests();
  }
};

const openRemarksModal = (remarks) => {
  currentRemark.value = remarks;
  showRemarksModal.value = true;
};
const closeRemarksModal = () => showRemarksModal.value = false;

const openAdminCommentsModal = (request) => {
  selectedRequest.value = request;
  adminComments.value = request.admin_comments || '';
  showAdminCommentsModal.value = true;
};
const closeAdminCommentsModal = () => {
  showAdminCommentsModal.value = false;
  selectedRequest.value = null;
  adminComments.value = '';
};
const saveAdminComments = async () => {
  if (!selectedRequest.value) return;
  const { error } = await supabase
    .from('filtering_requests')
    .update({ admin_comments: adminComments.value, updated_at: new Date().toISOString() })
    .eq('id', selectedRequest.value.id);

  if (error) {
    alert('전달사항 저장 실패: ' + error.message);
  } else {
    alert('전달사항이 저장되었습니다.');
    closeAdminCommentsModal();
    fetchRequests();
  }
};

const downloadExcel = () => {
  const exportData = filteredList.value.map(row => ({
    '요청일시': new Date(row.request_date).toLocaleString('sv-SE').slice(0, 16),
    '업체명': row.member_name,
    '구분': row.filter_type === 'new' ? '신규' : '이관',
    '거래처명': row.hospital_name,
    '제약사': row.pharmaceutical_company_name,
    '요청비고': row.user_remarks,
    '처리결과': row.status === 'pending' ? '대기' : row.status === 'approved' ? '승인' : '반려',
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '필터링요청목록');
  XLSX.writeFile(wb, `필터링목록_${new Date().toISOString().slice(0, 10)}.xlsx`);
};

function formatDateTime(val) {
  if (!val) return '';
  const d = new Date(val);
  if (isNaN(d.getTime())) return '';
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  const hh = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd} ${hh}:${min}`;
}

</script>
