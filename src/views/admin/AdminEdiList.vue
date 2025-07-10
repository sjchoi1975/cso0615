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
          v-if="!loading"
          :value="files"
          :loading="false"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth, minWidth: isMobile ? tableConfig.tableStyle.minWidth : undefined }"
          dataKey="edi_id"
          v-model:selection="selectedFiles"
        >
          <Column headerStyle="width: 3rem" :bodyStyle="{ textAlign: 'center' }">
            <template #body="slotProps">
              <input
                type="checkbox"
                v-model="slotProps.data._selected"
                @change="onRowSelectChange(slotProps.data)"
                class="custom-checkbox"
              />
            </template>
            <template #header>
              <input
                type="checkbox"
                :checked="selectedFiles.length === files.length && files.length > 0"
                @change="toggleSelectAll"
                class="custom-checkbox"
              />
            </template>
          </Column>
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
              <template v-else-if="col.field === 'pharmaceutical_companies'">
                {{ formatPharmaceuticalCompanies(slotProps.data.pharmaceutical_companies) }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'proof_file'">
                <Button icon="pi pi-file" class="p-button-rounded p-button-text" @click="openFilePreview(slotProps.data)" />
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

// 체크박스 선택 관련 데이터
const selectedFiles = ref([]);

// 체크박스 선택 처리 함수
const onRowSelectChange = (row) => {
  const index = selectedFiles.value.findIndex(item => item.edi_id === row.edi_id);
  if (index === -1) {
    selectedFiles.value.push(row);
  } else {
    selectedFiles.value.splice(index, 1);
  }
};

// 전체 선택/해제 토글
const toggleSelectAll = () => {
  if (selectedFiles.value.length === files.value.length) {
    selectedFiles.value = [];
    files.value.forEach(file => file._selected = false);
  } else {
    selectedFiles.value = [...files.value];
    files.value.forEach(file => file._selected = true);
  }
};

const selectedMonth = ref('');
const selectedCompany = ref('');
const selectedHospital = ref('');

const monthOptions = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);

// 파일 미리보기 관련
const selectedFile = ref(null);
const pharmaceuticalCompanies = ref([]);
const selectedCompanies = ref([]);
let filePreviewWindow = null;

// 창 위치와 크기 저장 (단순히 마지막 상태만 저장)
const lastWindowState = ref({
  width: 1200,
  height: 800,
  x: undefined,
  y: undefined
});

const formatDateTime = (dateTime) => {
  if (!dateTime) return '-';
  return new Date(dateTime).toLocaleString('sv-SE').slice(0, 16);
};

const formatPharmaceuticalCompanies = (companies) => {
  if (!companies || !Array.isArray(companies)) return '-';
  return companies.map(c => c.name).join(', ');
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
    files.value = [];
    totalCount.value = 0;
  } else {
    files.value = data.map(file => ({
      ...file,
      _selected: selectedFiles.value.some(selected => selected.edi_id === file.edi_id)
    }));
    totalCount.value = count || 0;
  }
  loading.value = false;
};

// 제약사 목록 조회
const fetchPharmaceuticalCompanies = async () => {
  const { data, error } = await supabase
    .from('pharmaceutical_companies')
    .select('id, name')
    .order('name');
    
  if (error) {
    console.error('Error fetching pharmaceutical companies:', error);
    return;
  }
  
  pharmaceuticalCompanies.value = data;
};

// 파일별 제약사 매핑 조회
const fetchFileCompanies = async (fileId) => {
  const { data, error } = await supabase
    .from('edi_file_companies')
    .select('company_id')
    .eq('edi_file_id', fileId);
    
  if (error) {
    console.error('Error fetching file companies:', error);
    return;
  }
  
  selectedCompanies.value = data.map(d => d.company_id);
};

const openFilePreview = async (file) => {
  selectedFile.value = file;
  await fetchPharmaceuticalCompanies();
  await fetchFileCompanies(file.id);
  
  // 이미 열린 창이 있다면 현재 위치 저장하고 닫기
  if (filePreviewWindow && !filePreviewWindow.closed) {
    try {
      lastWindowState.value = {
        width: filePreviewWindow.outerWidth,
        height: filePreviewWindow.outerHeight,
        x: filePreviewWindow.screenX,
        y: filePreviewWindow.screenY
      };
      filePreviewWindow.close();
    } catch (e) {
      console.error('Error saving window state:', e);
    }
  }
  
  // 저장된 위치가 없으면 기본값 설정
  if (lastWindowState.value.x === undefined || lastWindowState.value.y === undefined) {
    lastWindowState.value = {
      width: 1200,
      height: 800,
      x: Math.max(0, (window.screen.width - 1200) / 2),
      y: Math.max(0, (window.screen.height - 800) / 2)
    };
  }

  const windowFeatures = [
    `width=${lastWindowState.value.width}`,
    `height=${lastWindowState.value.height}`,
    `left=${lastWindowState.value.x}`,
    `top=${lastWindowState.value.y}`,
    'resizable=yes',
    'scrollbars=yes',
    'status=no',
    'menubar=no',
    'toolbar=no',
    'location=no'
  ].join(',');

  filePreviewWindow = window.open('', '_blank', windowFeatures);
  
  if (filePreviewWindow) {
    const selectedPharmaceuticals = pharmaceuticalCompanies.value
      .filter(company => selectedCompanies.value.includes(company.id));
    const unselectedPharmaceuticals = pharmaceuticalCompanies.value
      .filter(company => !selectedCompanies.value.includes(company.id));
    
    // HTML 템플릿 불러오기
    const response = await fetch('/file-preview-template.html');
    const template = await response.text();
    
    // 템플릿 작성
    filePreviewWindow.document.write(template);
    filePreviewWindow.document.close();
    
    // 데이터 업데이트
    filePreviewWindow.updateFileInfo(file);
    filePreviewWindow.updateCompanies(selectedPharmaceuticals, unselectedPharmaceuticals);
    
    // 창이 닫힐 때 위치 저장
    filePreviewWindow.addEventListener('unload', () => {
      if (!filePreviewWindow.closed) {
        try {
          lastWindowState.value = {
            width: filePreviewWindow.outerWidth,
            height: filePreviewWindow.outerHeight,
            x: filePreviewWindow.screenX,
            y: filePreviewWindow.screenY
          };
        } catch (e) {
          console.error('Error saving window state on unload:', e);
        }
      }
    });
  }
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

const selectAllText = computed(() => {
  return selectedFiles.value.length === files.value.length && files.value.length > 0 ? '모두 해제' : '모두 선택';
});

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

</script>

<style scoped>
.custom-checkbox {
  width: 1.2rem !important;
  height: 1.2rem !important;
  margin: 0.4rem;
  cursor: pointer;
}

:deep(.p-datatable .p-datatable-tbody > tr > td:first-child),
:deep(.p-datatable .p-datatable-thead > tr > th:first-child) {
  width: 3rem !important;
  min-width: 3rem !important;
  max-width: 3rem !important;
}
</style>


