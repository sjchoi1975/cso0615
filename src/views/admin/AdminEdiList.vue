<template>
  <div class="admin-edi-list-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- Filter Card -->
    <div class="filter-card">
      <div class="filter-row">
          <span>정산월</span>
          <select v-model="selectedMonth" class="input-120">
            <option value="">- 전체 -</option>
            <option v-for="month in monthOptions" :key="month" :value="month">{{ month }}</option>
          </select>
        <div class="hide-mobile">
          <span>업체</span>
          <select v-model="selectedCompany" class="input-180">
            <option value="">- 전체 -</option>
            <option v-for="company in companyOptions" :key="company.member_id" :value="company.member_id">{{ company.company_name }}</option>
          </select>
          <span>거래처</span>
          <select v-model="selectedHospital" class="input-180">
            <option value="">- 전체 -</option>
            <option v-for="hospital in hospitalOptions" :key="hospital.hospital_id" :value="hospital.hospital_id">{{ hospital.hospital_name }}</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card">
      <div class="total-count">
        총 {{ totalCount.toLocaleString() }}개 중 {{ selectedFiles.length }}개 선택
      </div>
      <div style="display: flex; gap: 1rem; align-items:center;">
        <Button
          icon="pi pi-check-square"
          :label="selectAllText"
          class="btn-selectall-md"
          @click="toggleSelectAll"
          iconPos="left"
          style="gap:0.5em;"
        />
        <Button
          icon="pi pi-download"
          label="일괄 다운로드"
          class="btn-download-all-md"
          @click="batchDownload"
          :disabled="selectedFiles.length === 0"
          iconPos="left"
          style="gap:0.5em;"
        />
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
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          v-model:selection="selectedFiles"
          :value="files"
          :loading="false"
          :paginator="false"
          scrollable
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth }"
          dataKey="edi_id"
        >
          <Column selectionMode="multiple" :style="{width: '4%'}" :bodyStyle="{textAlign: 'center'}"></Column>
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
               <template v-else-if="col.field === 'created_at'">
                {{ formatDateTime(slotProps.data.created_at) }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'proof_file'">
                <Button icon="pi pi-file" class="p-button-rounded p-button-text" @click="openFileInNewTab(slotProps.data.file_url)" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'download'">
                <Button icon="pi pi-download" class="p-button-rounded p-button-text" @click="downloadFile(slotProps.data)" />
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
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import Button from 'primevue/button';
import * as XLSX from 'xlsx';
import JSZip from 'jszip';
import { adminEdiListTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? adminEdiListTableConfig.mobile : adminEdiListTableConfig.pc);
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const files = ref([]);
const loading = ref(false);
const first = ref(0);
const totalCount = ref(0);
const pageSize = ref(100);
const selectedFiles = ref([]);

const selectedMonth = ref('');
const selectedCompany = ref('');
const selectedHospital = ref('');

const monthOptions = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);

const formatDateTime = (dateTime) => {
  if (!dateTime) return '-';
  return new Date(dateTime).toLocaleString('sv-SE').slice(0, 16);
};

const fetchDropdownOptions = async () => {
  const { data, error } = await supabase.from('admin_edi_list_view').select('settlement_month, member_id, company_name, hospital_id, hospital_name');
  if (error) {
    console.error('Error fetching dropdown options:', error);
    return;
  }

  if (data) {
    monthOptions.value = [...new Set(data.map(item => item.settlement_month))].filter(Boolean).sort().reverse();
    companyOptions.value = [...new Map(data.map(item => [item.member_id, { member_id: item.member_id, company_name: item.company_name }])).values()].filter(c => c.member_id);
    hospitalOptions.value = [...new Map(data.map(item => [item.hospital_id, { hospital_id: item.hospital_id, hospital_name: item.hospital_name }])).values()].filter(h => h.hospital_id);
  }
};

const fetchFiles = async () => {
  loading.value = true;
  let query = supabase.from('admin_edi_list_view').select('*', { count: 'exact' });

  if (selectedMonth.value) query = query.eq('settlement_month', selectedMonth.value);
  if (selectedCompany.value) query = query.eq('member_id', selectedCompany.value);
  if (selectedHospital.value) query = query.eq('hospital_id', selectedHospital.value);

  const from = first.value;
  const to = from + pageSize.value - 1;
  query = query.range(from, to).order('created_at', { ascending: false });

  const { data, error, count } = await query;

  if (error) {
    if (error.code === '42P01') {
       alert('데이터 조회 실패: "admin_edi_list_view"가 존재하지 않습니다. 관리자에게 문의하여 데이터베이스 뷰를 생성해주세요.');
    } else {
       alert('데이터 조회 실패: ' + error.message);
    }
  } else {
    files.value = data;
    totalCount.value = count || 0;
  }
  loading.value = false;
};

onMounted(() => {
  fetchFiles();
  fetchDropdownOptions();
});

let debounceTimer = null;
watch([selectedMonth, selectedCompany, selectedHospital], () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    first.value = 0;
    fetchFiles();
  }, 300);
});

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  selectedCompany.value = '';
  selectedHospital.value = '';
  fetchFiles();
};

const openFileInNewTab = (fileUrl) => {
  if (!fileUrl) {
    alert('파일 경로가 유효하지 않습니다.');
    return;
  }
  window.open(fileUrl, '_blank');
};

const selectAllText = computed(() => {
  return selectedFiles.value.length === files.value.length && files.value.length > 0 ? '모두 해제' : '모두 선택';
});

const toggleSelectAll = () => {
  if (selectedFiles.value.length === files.value.length) {
    selectedFiles.value = [];
  } else {
    selectedFiles.value = [...files.value];
  }
};

const batchDownload = async () => {
  if (selectedFiles.value.length === 0) {
    alert('다운로드할 파일을 선택해주세요.');
    return;
  }

  const zip = new JSZip();
  const promises = selectedFiles.value.map(async (file) => {
    try {
      const response = await fetch(file.file_url);
      if (!response.ok) {
        throw new Error(`Failed to fetch ${file.file_url}`);
      }
      const blob = await response.blob();
      
      const companyName = file.company_name || '업체명';
      const hospitalName = file.hospital_name || '거래처명';
      const settlementMonth = file.settlement_month || '정산월';
      
      const url = new URL(file.file_url);
      const path = decodeURIComponent(url.pathname);
      const extension = path.substring(path.lastIndexOf('.'));
      const newFilename = `${companyName}_${hospitalName}_${settlementMonth}${extension}`;

      zip.file(newFilename, blob);
    } catch (error) {
      console.error('Error processing file for zipping:', error);
    }
  });

  await Promise.all(promises);

  zip.generateAsync({ type: 'blob' }).then((content) => {
    const link = document.createElement('a');
    link.href = URL.createObjectURL(content);
    link.download = `edi_files_${new Date().toISOString().slice(0,10)}.zip`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  });
};

const downloadFile = async (item) => {
  if (!item.file_url) {
    alert('파일 경로가 유효하지 않습니다.');
    return;
  }
  try {
    const response = await fetch(item.file_url);
    if (!response.ok) {
      throw new Error('파일을 가져오는 데 실패했습니다.');
    }
    const blob = await response.blob();
    
    const companyName = item.company_name || '업체명';
    const hospitalName = item.hospital_name || '거래처명';
    const settlementMonth = item.settlement_month || '정산월';
    
    const url = new URL(item.file_url);
    const path = decodeURIComponent(url.pathname);
    const extension = path.substring(path.lastIndexOf('.'));

    const newFilename = `${companyName}_${hospitalName}_${settlementMonth}${extension}`;

    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = newFilename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  } catch (error) {
    console.error('Error downloading file:', error);
    alert('파일 다운로드에 실패했습니다: ' + error.message);
  }
};

const downloadExcel = () => {
  const exportData = files.value.map((row, index) => ({
    '순번': first.value + index + 1,
    '업체명': row.company_name,
    '업체 사업자번호': row.member_biz_no,
    '업체 대표자': row.member_ceo_name,
    '거래처명': row.hospital_name,
    '거래처 사업자번호': row.hospital_biz_no,
    '거래처 원장명': row.director_name,
    '거래처 주소': row.hospital_address,
    '파일명': row.file_name,
    '등록일시': formatDateTime(row.created_at),
    '등록자': row.created_by_name,
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'EDI 증빙파일 목록');
  XLSX.writeFile(wb, `edi_files_${new Date().toISOString().slice(0, 10)}.xlsx`);
};

</script>

<style scoped>
/* PrimeVue DataTable Checkbox Style Override */
::v-deep(.p-datatable .p-checkbox-box.p-highlight) {
  background: #3B82F6 !important;
  border-color: #3B82F6 !important;
}

/* Hide the checkmark icon when selected */
::v-deep(.p-datatable .p-checkbox-box.p-highlight .p-checkbox-icon) {
  visibility: hidden;
}
</style>
