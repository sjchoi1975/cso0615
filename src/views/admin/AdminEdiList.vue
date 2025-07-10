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
              <template v-else-if="col.type === 'link'">
                <span class="link" @click="openFilePreview(slotProps.data)">
                  {{ slotProps.data[col.field] }}
                </span>
              </template>
              <template v-else-if="col.field === 'created_at'">
                {{ formatDateTime(slotProps.data.created_at) }}
              </template>
              <template v-else-if="col.field === 'pharmaceutical_companies'">
                {{ formatPharmaceuticalCompanies(slotProps.data.pharmaceutical_companies) }}
              </template>
              <template v-else-if="col.field === 'confirm'">
                <span :class="{ 'text-green-500': slotProps.data.confirm, 'text-red-500': !slotProps.data.confirm }">
                  {{ slotProps.data.confirm ? '확인' : '미확인' }}
                </span>
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

window.supabase = supabase;

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
  return companies.map(c => c.company_name).join(', ');
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
    .select('id, company_name')
    .order('company_name');
    
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
  
  // 제약사 목록 조회
  const { data: companies, error: companiesError } = await supabase
    .from('pharmaceutical_companies')
    .select('id, company_name')
    .order('company_name');
    
  if (companiesError) {
    console.error('Error fetching pharmaceutical companies:', companiesError);
    return;
  }
  pharmaceuticalCompanies.value = companies;

  // 현재 파일의 제약사 매핑 조회
  const { data: mappings, error: mappingsError } = await supabase
    .from('edi_file_companies')
    .select('company_id')
    .eq('edi_file_id', file.id);
    
  if (mappingsError) {
    console.error('Error fetching file companies:', mappingsError);
    return;
  }
  selectedCompanies.value = mappings.map(m => m.company_id);

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
      height: window.screen.height,
      x: Math.max(0, (window.screen.width - 1200) / 2),
      y: 0
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
    const response = await fetch('/src/views/admin/file-preview-template.html');
    const template = await response.text();
    
    filePreviewWindow.document.write(template);
    filePreviewWindow.document.close();
    
    filePreviewWindow.onload = () => {
      const currentIndex = files.value.findIndex(f => f.id === file.id);
      filePreviewWindow.initialize(files.value, currentIndex);
    };
    
    // 창이 닫힐 때 위치 저장
    filePreviewWindow.addEventListener('unload', () => {
      if (filePreviewWindow && !filePreviewWindow.closed) {
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

// 제약사 업데이트 함수 추가
const updatePharmaceuticalCompanies = async (fileId, companies) => {
  const { error } = await supabase
    .from('edi_files')
    .update({
      pharmaceutical_companies: {
        companies: companies.map(id => ({
          id,
          name: pharmaceuticalCompanies.value.find(c => c.id === id)?.company_name
        }))
      }
    })
    .eq('id', fileId);

  if (error) {
    console.error('Error updating pharmaceutical companies:', error);
    return false;
  }
  return true;
};

// 제약사 선택/해제 처리
const toggleCompany = async (companyId) => {
  const selectedIndex = selectedCompanies.value.findIndex(id => id === companyId);
  if (selectedIndex === -1) {
    selectedCompanies.value.push(companyId);
  } else {
    selectedCompanies.value.splice(selectedIndex, 1);
  }

  // 선택된 제약사와 미선택 제약사 목록 업데이트
  const selectedPharmaceuticals = pharmaceuticalCompanies.value
    .filter(company => selectedCompanies.value.includes(company.id));
  const unselectedPharmaceuticals = pharmaceuticalCompanies.value
    .filter(company => !selectedCompanies.value.includes(company.id));
  
  // 팝업 창의 목록 업데이트
  if (filePreviewWindow && !filePreviewWindow.closed) {
    filePreviewWindow.updateCompanies(selectedPharmaceuticals, unselectedPharmaceuticals);
  }
};

// 제약사 매핑 저장
const savePharmaceuticalCompanies = async () => {
  if (!selectedFile.value) return;

  try {
    // edi_file_companies 테이블에서 기존 매핑 삭제
    const { error: deleteError } = await supabase
      .from('edi_file_companies')
      .delete()
      .eq('edi_file_id', selectedFile.value.id);

    if (deleteError) throw deleteError;

    // 새로운 매핑 추가
    if (selectedCompanies.value.length > 0) {
      const { error: insertError } = await supabase
        .from('edi_file_companies')
        .insert(
          selectedCompanies.value.map(companyId => ({
            edi_file_id: selectedFile.value.id,
            company_id: companyId
          }))
        );

      if (insertError) throw insertError;
    }

    // 파일 미리보기 창 닫기
    if (filePreviewWindow && !filePreviewWindow.closed) {
      filePreviewWindow.close();
    }

    // 목록 새로고침
    await fetchFiles();

  } catch (error) {
    console.error('Error saving pharmaceutical companies:', error);
    alert('제약사 매핑 저장 중 오류가 발생했습니다.');
  }
};

onMounted(() => {
  fetchFiles();
  fetchDropdownOptions();
});

// 팝업창에서 호출할 수 있도록 함수를 window에 할당
window.getFilesForPopup = () => {
  return files.value;
};
window.fetchFiles = fetchFiles;

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

// 일괄 다운로드
const batchDownload = async () => {
  if (selectedFiles.value.length === 0) {
    alert('다운로드할 파일을 선택해주세요.');
    return;
  }

  loading.value = true;
  try {
    const zip = new JSZip();
    
    // 선택된 각 파일을 다운로드하여 ZIP에 추가
    for (const file of selectedFiles.value) {
      try {
        const response = await fetch(file.file_url);
        const blob = await response.blob();
        zip.file(file.file_name, blob);
      } catch (error) {
        console.error(`파일 다운로드 실패 (${file.file_name}):`, error);
      }
    }
    
    // ZIP 파일 생성 및 다운로드
    const content = await zip.generateAsync({ type: 'blob' });
    const url = window.URL.createObjectURL(content);
    const a = document.createElement('a');
    a.href = url;
    a.download = `EDI_files_${new Date().toISOString().slice(0, 10)}.zip`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    a.remove();
  } catch (error) {
    console.error('일괄 다운로드 실패:', error);
    alert('일괄 다운로드에 실패했습니다.');
  } finally {
    loading.value = false;
  }
};

// 엑셀 다운로드
const downloadExcel = () => {
  if (!files.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  const headers = [
    '순번', '업체명', '사업자번호', '대표자',
    '거래처명', '사업자번호', '원장명',
    '파일명', '제약사', '메모', '등록일시'
  ];
  
  const data = files.value.map((item, index) => [
    first.value + index + 1,
    item.company_name,
    item.member_biz_no,
    item.member_ceo_name,
    item.hospital_name,
    item.hospital_biz_no,
    item.director_name,
    item.file_name,
    formatPharmaceuticalCompanies(item.pharmaceutical_companies),
    item.memo,
    formatDateTime(item.created_at)
  ]);
  
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'EDI목록');
  
  // 컬럼 너비 설정
  ws['!cols'] = [
    { wch: 6 },  // 순번
    { wch: 15 }, // 업체명
    { wch: 12 }, // 사업자번호
    { wch: 10 }, // 대표자
    { wch: 20 }, // 거래처명
    { wch: 12 }, // 사업자번호
    { wch: 10 }, // 원장명
    { wch: 30 }, // 파일명
    { wch: 30 }, // 제약사
    { wch: 20 }, // 메모
    { wch: 16 }  // 등록일시
  ];
  
  const fileName = `EDI목록_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};

const downloadFile = async (file) => {
  if (!file.file_url) {
    alert('파일 URL이 없습니다.');
    return;
  }
  
  try {
    const response = await fetch(file.file_url);
    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = file.file_name || 'download';
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    a.remove();
  } catch (error) {
    console.error('파일 다운로드 실패:', error);
    alert('파일 다운로드에 실패했습니다.');
  }
};

</script>

<style scoped>
.custom-checkbox {
  width: 1.2rem !important;
  margin: 0 0.4rem;
  cursor: pointer;
}

:deep(.p-datatable .p-datatable-tbody > tr > td:first-child),
:deep(.p-datatable .p-datatable-thead > tr > th:first-child) {
  width: 3rem !important;
  min-width: 3rem !important;
  max-width: 3rem !important;
}

.link {
  color: #007bff;
  cursor: pointer;
  text-decoration: none;
}
.link:hover {
  text-decoration: underline;
}
</style>


