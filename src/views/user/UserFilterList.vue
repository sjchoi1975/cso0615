<template>
  <div class="user-filter-list-view page-container">
    <!-- Filter Card -->
    <div class="filter-card custom-auto-height">
      <div class="filter-row">
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
    <div class="function-card custom-auto-height">
      <div class="total-count total-count-nowrap">총 {{ totalCount.toLocaleString() }}건의 요청</div>
      <div style="display: flex; gap:0.5rem; align-items:center;">
        <button class="btn-excell-download" @click="downloadExcel">엑셀 다운</button>
      </div>
    </div>

    <!-- Table Card -->
    <div class="table-card user-filter-list-table">
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
        <Column field="filter_type" header="구분" :style="{ width: columnWidths.filter_type }" :bodyStyle="{ textAlign: columnAligns.filter_type }">
          <template #body="slotProps">{{ slotProps.data.filter_type === 'new' ? '신규' : '이관' }}</template>
        </Column>
        <Column field="hospital_name" header="거래처명" :style="{ width: columnWidths.hospital_name }" :bodyStyle="{ textAlign: columnAligns.hospital_name }"></Column>
        <Column field="pharmaceutical_company_name" header="제약사" :style="{ width: columnWidths.pharmaceutical_company_name }" :bodyStyle="{ textAlign: columnAligns.pharmaceutical_company_name }"></Column>
        <Column field="status" header="처리결과" :style="{ width: columnWidths.status }" :bodyStyle="{ textAlign: columnAligns.status }">
          <template #body="slotProps">
            <span :class="['status-badge', `status-badge-${slotProps.data.status}`]">
              {{ slotProps.data.status === 'pending' ? '대기' : slotProps.data.status === 'approved' ? '승인' : '반려' }}
            </span>
          </template>
        </Column>
        <Column field="admin_comments" header="전달사항" :style="{ width: columnWidths.admin_comments }" :bodyStyle="{ textAlign: columnAligns.admin_comments }">
          <template #body="slotProps">
            <span class="link" @click="openContentModal('전달사항', slotProps.data.admin_comments)">
              {{ slotProps.data.admin_comments || '-' }}
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
        <Column field="user_remarks" header="요청비고" :style="{ width: columnWidths.user_remarks }" :bodyStyle="{ textAlign: columnAligns.user_remarks }">
          <template #body="slotProps">
            <span class="link" @click="openContentModal('요청 비고', slotProps.data.user_remarks)">{{ slotProps.data.user_remarks }}</span>
          </template>
        </Column>
        <Column field="request_date" header="요청일시" :style="{ width: columnWidths.request_date }" :bodyStyle="{ textAlign: columnAligns.request_date }">
          <template #body="slotProps">
            {{ slotProps.data.request_date ? new Date(slotProps.data.request_date).toLocaleString('sv-SE').slice(0, 16) : '' }}
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

    <!-- Content Modal -->
    <div v-if="showContentModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">{{ modalTitle }}</h3><button @click="closeContentModal" class="btn-close">×</button></div>
        <div class="modal-body"><div style="white-space: pre-line;">{{ modalContent }}</div></div>
        <div class="modal-footer"><button @click="closeContentModal" class="btn-secondary">닫기</button></div>
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
  filter_type: '4%',
  hospital_name: '18%',
  pharmaceutical_company_name: '10%',
  status: '8%',
  admin_comments: '18%',
  updated_at: '10%',
  user_remarks: '18%',
  request_date: '10%'
};

const columnAligns = {
  index: 'center',
  filter_type: 'center',
  hospital_name: 'left',
  pharmaceutical_company_name: 'left',
  status: 'center',
  admin_comments: 'left',
  updated_at: 'center',
  user_remarks: 'left',
  request_date: 'center'
};

const requests = ref([]);
const loading = ref(false);
const first = ref(0);
const totalCount = ref(0);
const pageSize = ref(100);

const selectedHospital = ref('');
const selectedPharma = ref('');
const selectedStatus = ref('');
const selectedFilterType = ref('');

const hospitalOptions = ref([]);
const pharmaOptions = ref([]);

const showContentModal = ref(false);
const modalTitle = ref('');
const modalContent = ref('');

const fetchDropdownOptions = async () => {
  const { data: hospitalsData } = await supabase.from('hospitals').select('id, hospital_name').order('hospital_name');
  if (hospitalsData) hospitalOptions.value = hospitalsData;

  const { data: pharmaData } = await supabase.from('pharmaceutical_companies').select('id, company_name').order('company_name');
  if (pharmaData) pharmaOptions.value = pharmaData;
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

watch([selectedHospital, selectedPharma, selectedStatus, selectedFilterType], () => {
  first.value = 0;
  fetchRequests();
});

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchRequests();
};

const openContentModal = (title, content) => {
  modalTitle.value = title;
  modalContent.value = content;
  showContentModal.value = true;
};
const closeContentModal = () => showContentModal.value = false;

const downloadExcel = () => {
  const exportData = requests.value.map(row => ({
    '요청일시': new Date(row.request_date).toLocaleString('sv-SE').slice(0, 16),
    '구분': row.filter_type === 'new' ? '신규' : '이관',
    '거래처명': row.hospital_name,
    '제약사': row.pharmaceutical_company_name,
    '요청비고': row.user_remarks,
    '처리결과': row.status === 'pending' ? '대기' : row.status === 'approved' ? '승인' : '반려',
    '전달사항': row.admin_comments,
    '처리일시': row.updated_at && new Date(row.updated_at).getTime() !== new Date(row.request_date).getTime() ? new Date(row.updated_at).toLocaleString('sv-SE').slice(0, 16) : '-',
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '나의요청목록');
  XLSX.writeFile(wb, `my_requests_${new Date().toISOString().slice(0, 10)}.xlsx`);
};

const resetFilters = () => {
  selectedHospital.value = '';
  selectedPharma.value = '';
  selectedStatus.value = '';
  selectedFilterType.value = '';
};

</script>
