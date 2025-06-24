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
      <div :style="tableConfig.tableStyle">
        <DataTable 
          :value="requests" 
          :loading="loading" 
          :paginator="false" 
          scrollable 
          :scrollHeight="'calc(100vh - 204px)'"
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
                {{ first + slotProps.index + 1 }}
              </template>
              <template v-else-if="col.field === 'filter_type'">
                {{ slotProps.data.filter_type === 'new' ? '신규' : '이관' }}
              </template>
              <template v-else-if="col.field === 'status'">
                <span :class="['status-badge', `status-badge-${slotProps.data.status}`]">
                  {{ slotProps.data.status === 'pending' ? '대기' : slotProps.data.status === 'approved' ? '승인' : '반려' }}
                </span>
              </template>
              <template v-else-if="col.field === 'admin_comments'">
                <span class="link" @click="openContentModal('전달사항', slotProps.data.admin_comments)">
                  {{ slotProps.data.admin_comments || '-' }}
                </span>
              </template>
              <template v-else-if="col.field === 'user_remarks'">
                <span class="link" @click="openContentModal('요청 비고', slotProps.data.user_remarks)">{{ slotProps.data.user_remarks }}</span>
              </template>
              <template v-else-if="col.field === 'updated_at'">
                <span v-if="slotProps.data.updated_at && new Date(slotProps.data.updated_at).getTime() !== new Date(slotProps.data.request_date).getTime()">
                  {{ new Date(slotProps.data.updated_at).toLocaleString('sv-SE').slice(0, 16) }}
                </span>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'request_date'">
                {{ slotProps.data.request_date ? new Date(slotProps.data.request_date).toLocaleString('sv-SE').slice(0, 16) : '' }}
              </template>
              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
          <div v-if="loading" class="table-loading-spinner-center">
            <img src="/spinner.svg" alt="로딩중" />
          </div>
        </DataTable>
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
import { ref, onMounted, watch, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import * as XLSX from 'xlsx';
import { userFilterRequestsTableConfig } from '@/config/tableConfig';

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

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userFilterRequestsTableConfig.mobile : userFilterRequestsTableConfig.pc);

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
