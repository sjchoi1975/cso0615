<template>
  <div class="admin-filter-list-view page-container">
    <!-- Filter Card -->
    <div class="filter-card">
      <div class="filter-row">
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
        <button class="filter-reset-btn" @click="resetFilters" style="margin-left: 1rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" style="vertical-align: middle; margin-right: 2px;"><path fill="currentColor" d="M12 6V3L8 7l4 4V8c2.76 0 5 2.24 5 5a5 5 0 0 1-5 5a5 5 0 0 1-5-5H5a7 7 0 0 0 7 7a7 7 0 0 0 7-7c0-3.87-3.13-7-7-7z"/></svg>
            초기화
        </button>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}건의 요청</div>
      <div style="display: flex; gap:0.5rem; align-items:center;">
        <button class="btn-excell-download" @click="downloadExcel">엑셀 다운</button>
      </div>
    </div>

    <!-- Table Card -->
    <div class="table-card admin-filter-list-table">
      <DataTable 
        :value="requests" 
        :loading="loading" 
        :paginator="false" 
        scrollable 
        :scrollHeight="'calc(100vh - 204px)'"
        >
        <Column header="순번" :style="{ width: columnWidths.index }" :bodyStyle="{ textAlign: columnAligns.index }">
          <template #body="slotProps">{{ first + slotProps.index + 1 }}</template>
        </Column>
        <Column field="request_date" header="요청일시" :style="{ width: columnWidths.request_date }" :bodyStyle="{ textAlign: columnAligns.request_date }">
          <template #body="slotProps">
            {{ slotProps.data.request_date ? new Date(slotProps.data.request_date).toLocaleString('sv-SE').slice(0, 16) : '' }}
          </template>
        </Column>
        <Column field="member_name" header="업체명" :style="{ width: columnWidths.member_name }" :bodyStyle="{ textAlign: columnAligns.member_name }"></Column>
        <Column field="filter_type" header="구분" :style="{ width: columnWidths.filter_type }" :bodyStyle="{ textAlign: columnAligns.filter_type }">
          <template #body="slotProps">{{ slotProps.data.filter_type === 'new' ? '신규' : '이관' }}</template>
        </Column>
        <Column field="hospital_name" header="거래처명" :style="{ width: columnWidths.hospital_name }" :bodyStyle="{ textAlign: columnAligns.hospital_name }"></Column>
        <Column field="pharmaceutical_company_name" header="제약사" :style="{ width: columnWidths.pharmaceutical_company_name }" :bodyStyle="{ textAlign: columnAligns.pharmaceutical_company_name }"></Column>
        <Column field="user_remarks" header="요청비고" :style="{ width: columnWidths.user_remarks }" :bodyStyle="{ textAlign: columnAligns.user_remarks }">
          <template #body="slotProps">
            <span class="link" @click="openRemarksModal(slotProps.data.user_remarks)">{{ slotProps.data.user_remarks }}</span>
          </template>
        </Column>
        <Column field="status" header="처리결과" :style="{ width: columnWidths.status }" :bodyStyle="{ textAlign: columnAligns.status }">
          <template #body="slotProps">
            <select v-model="slotProps.data.status" 
                    @change="updateStatus(slotProps.data)" 
                    :class="['status-select', `status-select-${slotProps.data.status}`]">
              <option value="pending">대기</option>
              <option value="approved">승인</option>
              <option value="rejected">반려</option>
            </select>
          </template>
        </Column>
        <Column field="admin_comments" header="전달사항" :style="{ width: columnWidths.admin_comments }" :bodyStyle="{ textAlign: columnAligns.admin_comments }">
          <template #body="slotProps">
            <span class="link" @click="openAdminCommentsModal(slotProps.data)">
              {{ slotProps.data.admin_comments || '작성' }}
            </span>
          </template>
        </Column>
        <Column field="updated_at" header="처리일시" :style="{ width: columnWidths.updated_at }" :bodyStyle="{ textAlign: columnAligns.updated_at }">
           <template #body="slotProps">
            <span v-if="slotProps.data.updated_at && new Date(slotProps.data.updated_at).getTime() !== new Date(slotProps.data.request_date).getTime()">
              {{ new Date(slotProps.data.updated_at).toLocaleString('sv-SE').slice(0, 16) }}
            </span>
            <span v-else>-</span>
          </template>
        </Column>
      </DataTable>
      <div v-if="loading" class="table-loading-spinner-center">
        <img src="/spinner.svg" alt="로딩중" />
      </div>
    </div>
    
    <!-- Paginator -->
    <div class="fixed-paginator">
      <Paginator :rows="pageSize" :totalRecords="totalCount" :first="first" @page="onPageChange" />
    </div>

    <!-- Remarks Modal -->
    <div v-if="showRemarksModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">요청 비고</h3><button @click="closeRemarksModal" class="btn-close">×</button></div>
        <div class="modal-body"><div style="white-space: pre-line;">{{ currentRemark }}</div></div>
        <div class="modal-footer"><button @click="closeRemarksModal" class="btn-secondary">닫기</button></div>
      </div>
    </div>
    
    <!-- Admin Comments Modal -->
    <div v-if="showAdminCommentsModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">전달사항 작성/수정</h3><button @click="closeAdminCommentsModal" class="btn-close">×</button></div>
        <div class="modal-body">
          <textarea v-model="adminComments" class="input-field" rows="5" placeholder="전달사항을 입력하세요."></textarea>
        </div>
        <div class="modal-footer">
          <button @click="closeAdminCommentsModal" class="btn-secondary">취소</button>
          <button @click="saveAdminComments" class="btn-primary">저장</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import * as XLSX from 'xlsx';

const columnWidths = {
  index: '4%',
  request_date: '10%',
  member_name: '12%',
  filter_type: '6%',
  hospital_name: '16%',
  pharmaceutical_company_name: '10%',
  user_remarks: '12%',
  status: '8%',
  admin_comments: '12%',
  updated_at: '10%',
};

const columnAligns = {
  index: 'center',
  request_date: 'center',
  member_name: 'left',
  filter_type: 'center',
  hospital_name: 'left',
  pharmaceutical_company_name: 'left',
  user_remarks: 'left',
  status: 'center',
  admin_comments: 'left',
  updated_at: 'center',
};

const requests = ref([]);
const loading = ref(false);
const first = ref(0);
const totalCount = ref(0);
const pageSize = ref(100);

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

// Fetch dropdown options
const fetchDropdownOptions = async () => {
  const { data: membersData } = await supabase.from('members').select('uid, company_name').eq('role', 'user').order('company_name');
  if (membersData) memberOptions.value = membersData;

  const { data: hospitalsData } = await supabase.from('hospitals').select('id, hospital_name').order('hospital_name');
  if (hospitalsData) hospitalOptions.value = hospitalsData;

  const { data: pharmaData } = await supabase.from('pharmaceutical_companies').select('id, company_name').order('company_name');
  if (pharmaData) pharmaOptions.value = pharmaData;
};

// Fetch data
const fetchRequests = async () => {
  loading.value = true;
  let query = supabase
    .from('admin_filter_list_view')
    .select(`*`, { count: 'exact' });

  if (selectedMember.value) query = query.eq('member_id', selectedMember.value);
  if (selectedHospital.value) query = query.eq('hospital_id', selectedHospital.value);
  if (selectedPharma.value) query = query.eq('pharmaceutical_company_id', selectedPharma.value);
  if (selectedStatus.value) query = query.eq('status', selectedStatus.value);
  if (selectedFilterType.value) query = query.eq('filter_type', selectedFilterType.value);

  const from = first.value;
  const to = from + pageSize.value - 1;
  query = query.range(from, to).order('is_processed', { ascending: true }).order('sort_date', { ascending: false });

  const { data, error, count } = await query;

  if (error) {
    alert('데이터 조회 실패: ' + error.message);
  } else {
    requests.value = data;
    totalCount.value = count || 0;
  }
  loading.value = false;
};

onMounted(() => {
    fetchRequests();
    fetchDropdownOptions();
});

watch([selectedMember, selectedHospital, selectedPharma, selectedStatus, selectedFilterType], () => {
  first.value = 0;
  fetchRequests();
});

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchRequests();
};

const updateStatus = async (request) => {
  const { error } = await supabase
    .from('filtering_requests')
    .update({ status: request.status, updated_at: new Date().toISOString() })
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
  const exportData = requests.value.map(row => ({
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

const resetFilters = () => {
  selectedMember.value = '';
  selectedHospital.value = '';
  selectedPharma.value = '';
  selectedStatus.value = '';
  selectedFilterType.value = '';
};

</script>
