<template>
  <div class="admin-settlement-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <span class="hide-mobile">통합 검색</span>
        <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="업체, 거래처, 제약사, 제품명 입력" @keyup.enter="onSearch" />
        <div class="hide-mobile" style="display: flex; gap: 0.5rem; align-items: center;">
          <span>처방월</span>
          <select v-model="selectedPrescriptionMonth" class="input-120">
            <option value="">- 전체 -</option>
            <option v-for="p in prescriptionMonthOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <span>업체명</span>
          <select v-model="selectedCompany" class="input-180">
            <option value="">전체</option>
            <option v-for="c in companyOptions" :key="c" :value="c">{{ c }}</option>
          </select>
          <span>거래처</span>
          <select v-model="selectedHospital" class="input-240">
            <option value="">전체</option>
            <option v-for="h in hospitalOptions" :key="h" :value="h">{{ h }}</option>
          </select>
          <span>제품</span>
          <select v-model="selectedProduct" class="input-240">
            <option value="">전체</option>
            <option v-for="p in productOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <button type="button" class="btn-search" @click="onSearch" :disabled="!isSearchEnabled">검색</button>
          <button type="button" class="btn-reset" @click="onReset">
            <i class="pi pi-refresh" style="font-size: 1rem;"></i>
            초기화
          </button>
        </div>
        <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%; margin-top: 0.5rem;">
          <input v-model="search" class="input-search wide-mobile-search" placeholder="업체, 거래처, 제약사, 제품명 입력" @keyup.enter="onSearch"/>
          <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onClearSearch"
            style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          <i class="pi pi-search search-btn-icon" @click="isSearchEnabled && onSearch()"
            :class="{ 'disabled': !isSearchEnabled }"
            style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
        </div>
      </div>
    </div>
    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}건</div>
      <div style="display: flex; gap:1rem; align-items:center;">
        <Button icon="pi pi-file-excel" label="템플릿" class="btn-download-md" @click="downloadTemplate" iconPos="left" style="gap:0.5em;" />
        <Button icon="pi pi-upload" label="엑셀 등록" class="btn-add-md" @click="() => $refs.fileInput.click()" iconPos="left" style="gap:0.5em;" />
        <input ref="fileInput" type="file" accept=".xlsx,.xls" @change="uploadExcel" style="display:none;" />
        <Button icon="pi pi-download" label="다운로드" class="btn-download-md" @click="downloadExcel" iconPos="left" style="gap:0.5em;" />
        <Button icon="pi pi-trash" label="삭제" class="btn-delete-md" @click="deleteSelected" severity="danger" iconPos="left" style="gap:0.5em;" />
      </div>
    </div>
    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          v-if="!loading"
          :value="filteredList"
          :loading="false"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth, minWidth: isMobile ? tableConfig.tableStyle.minWidth : undefined }"
          dataKey="id"
          v-model:selection="selectedRows"
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
                :checked="selectedRows.length === filteredList.length && filteredList.length > 0"
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
            <template v-else-if="col.field === 'price' || col.field === 'prescription_amount' || col.field === 'payment_amount'">
              {{ formatCurrency(slotProps.data[col.field]) }}
            </template>
            <template v-else-if="col.field === 'quantity'">
              {{ formatNumber(slotProps.data[col.field]) }}
            </template>
            <template v-else-if="col.field === 'commission_rate'">
              {{ formatPercentage(slotProps.data[col.field]) }}
            </template>
            <template v-else-if="col.field === 'company_name'">
              <span class="table-title-link">{{ slotProps.data.company_name }}</span>
            </template>
            <template v-else-if="col.field === 'hospital_name'">
              <span class="table-title-link">{{ slotProps.data.hospital_name }}</span>
            </template>
            <template v-else-if="col.field === 'product_name'">
              <span class="table-title-link">{{ slotProps.data.product_name }}</span>
            </template>
            <template v-else>
              {{ slotProps.data[col.field] }}
            </template>
          </template>
        </Column>
        </DataTable>
      </div>
    </div>
    <!-- 하단 고정 페이지네이터 -->
    <div class="fixed-paginator">
      <Paginator
        :rows="pageSize"
        :totalRecords="totalCount"
        :first="first"
        :rowsPerPageOptions="[50, 100, 200, 500]"
        @page="onPageChange"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import * as XLSX from 'xlsx';
import Paginator from 'primevue/paginator';
import { useRoute } from 'vue-router';
import { settlementMonthDetailTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import Button from 'primevue/button';

const settlements = ref([]);
const filteredList = ref([]);
const loading = ref(false);
const totalCount = ref(0);
const selectedPrescriptionMonth = ref('');
const selectedCompany = ref('');
const selectedHospital = ref('');
const selectedProduct = ref('');
const prescriptionMonthOptions = ref([]);
const companyOptions = ref([]);
const hospitalOptions = ref([]);
const productOptions = ref([]);
const pageSize = ref(100);
const first = ref(0);
const route = useRoute();

const selectedRows = ref([]);
const search = ref('');
const isSearched = ref(false);

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? settlementMonthDetailTableConfig.mobile : settlementMonthDetailTableConfig.pc);
const tableScrollHeight = computed(() => getTableScrollHeight(true));

// 검색 활성화 조건: 검색어 2글자 이상 or 세부 필터 중 하나라도 선택
const isSearchEnabled = computed(() => {
  return search.value.length >= 2 ||
    selectedPrescriptionMonth.value ||
    selectedCompany.value ||
    selectedHospital.value ||
    selectedProduct.value;
});

// 검색 실행
const onSearch = () => {
  if (!isSearchEnabled.value) return;
  isSearched.value = true;
  first.value = 0;
  fetchSettlements();
};

// 초기화
const onReset = () => {
  search.value = '';
  selectedPrescriptionMonth.value = '';
  selectedCompany.value = '';
  selectedHospital.value = '';
  selectedProduct.value = '';
  isSearched.value = false;
  first.value = 0;
  fetchSettlements();
};

// 검색어만 초기화 (모바일 X 버튼)
const onClearSearch = () => {
  if (isSearched.value) {
    onReset();
  } else {
    search.value = '';
  }
};

// 실제 필터링 함수 - 검색 버튼 클릭 시에만 적용하도록 변경
// const filterSettlements = () => {
//   let result = [...settlements.value];
//   // 통합검색
//   if (search.value.length >= 2) {
//     const keyword = search.value.toLowerCase();
//     result = result.filter(item => {
//       const company = (item.company_name || '').toLowerCase();
//       const hospital = (item.hospital_name || '').toLowerCase();
//       const pharma = (item.pharma_name || '').toLowerCase();
//       const product = (item.product_name || '').toLowerCase();
//       return company.includes(keyword) || hospital.includes(keyword) || pharma.includes(keyword) || product.includes(keyword);
//     });
//   }
//   // 세부 필터
//   if (selectedPrescriptionMonth.value) {
//     result = result.filter(item => item.prescription_month === selectedPrescriptionMonth.value);
//   }
//   if (selectedCompany.value) {
//     result = result.filter(item => item.company_name === selectedCompany.value);
//   }
//   if (selectedHospital.value) {
//     result = result.filter(item => item.hospital_name === selectedHospital.value);
//   }
//   if (selectedProduct.value) {
//     result = result.filter(item => item.product_name === selectedProduct.value);
//   }
//   filteredList.value = result;
//   totalCount.value = result.length;
// };

const setFilterOptions = () => {
  const data = settlements.value;
  prescriptionMonthOptions.value = [...new Set(data.map(item => item.prescription_month))].filter(Boolean).sort().reverse();
  companyOptions.value = [...new Set(data.map(item => item.company_name))].filter(Boolean).sort((a, b) => a.localeCompare(b, 'ko-KR'));
  hospitalOptions.value = [...new Set(data.map(item => item.hospital_name))].filter(Boolean).sort((a, b) => a.localeCompare(b, 'ko-KR'));
  productOptions.value = [...new Set(data.map(item => item.product_name))].filter(Boolean).sort((a, b) => a.localeCompare(b, 'ko-KR'));
};

const fetchSettlements = async () => {
  loading.value = true;
  const baseMonth = route.params.month;
  let query = supabase.from('settlements').select('*');
  if (baseMonth) query = query.eq('settlement_month', baseMonth);
  
  // 검색 버튼 클릭 시에만 필터 적용
  if (isSearched.value) {
    // 통합검색 (2글자 이상)
    if (search.value.length >= 2) {
      query = query.or(`company_name.ilike.%${search.value}%,hospital_name.ilike.%${search.value}%,pharma_name.ilike.%${search.value}%,product_name.ilike.%${search.value}%`);
    }
    // 세부 필터
    if (selectedPrescriptionMonth.value) query = query.eq('prescription_month', selectedPrescriptionMonth.value);
    if (selectedCompany.value) query = query.eq('company_name', selectedCompany.value);
    if (selectedHospital.value) query = query.eq('hospital_name', selectedHospital.value);
    if (selectedProduct.value) query = query.eq('product_name', selectedProduct.value);
  }
  
  const { data, error } = await query;
  if (error) {
    settlements.value = [];
    filteredList.value = [];
    totalCount.value = 0;
    prescriptionMonthOptions.value = [];
    companyOptions.value = [];
    hospitalOptions.value = [];
    productOptions.value = [];
  } else {
    settlements.value = data;
    filteredList.value = data;
    totalCount.value = data.length;
    setFilterOptions();
  }
  loading.value = false;
};

onMounted(() => {
  fetchSettlements();
});

// 정산월 변경 시 필터 옵션 업데이트
watch(selectedPrescriptionMonth, async () => {
  selectedCompany.value = '';
  selectedHospital.value = '';
  selectedProduct.value = '';
  await fetchFilterOptions();
  await fetchSettlements();
});

// 필터 변경 시 데이터 다시 불러오기
watch(selectedCompany, async () => {
  selectedHospital.value = '';
  selectedProduct.value = '';
  await fetchFilterOptions();
  await fetchSettlements();
});
watch(selectedHospital, async () => {
  selectedProduct.value = '';
  await fetchFilterOptions();
  await fetchSettlements();
});

// 제품 선택 시 즉시 필터 적용 제거 - 검색 버튼 클릭 시에만 적용
// watch(selectedProduct, async () => {
//   await fetchSettlements();
// });

const totalQuantity = computed(() => settlements.value.reduce((sum, r) => sum + (Number(r.quantity) || 0), 0));
const totalPrescriptionAmount = computed(() => settlements.value.reduce((sum, r) => sum + (Number(r.prescription_amount) || 0), 0));
const totalPaymentAmount = computed(() => settlements.value.reduce((sum, r) => sum + (Number(r.payment_amount) || 0), 0));

// 포맷팅 함수들
const formatCurrency = (value) => {
  if (!value) return '0';
  return Math.round(Number(value)).toLocaleString('ko-KR');
};

const formatNumber = (value) => {
  if (!value) return '0';
  return Math.round(Number(value)).toLocaleString('ko-KR');
};

const formatPercentage = (value) => {
  if (!value) return '0%';
  return (Math.round(Number(value) * 1000) / 10).toFixed(1) + '%';
};

const editRow = (idx) => {
  // 인라인 편집 로직 (추후 구현)
  alert('인라인 편집 기능은 추후 구현 예정입니다.');
};
const deleteRow = async (id) => {
  if (!confirm('삭제하시겠습니까?')) return;
  await supabase.from('settlements').delete().eq('id', id);
  fetchSettlements();
};
const addRow = async () => {
  const { error } = await supabase.from('settlements').insert([newRow.value]);
  if (!error) {
    alert('추가되었습니다.');
    Object.keys(newRow.value).forEach(k => newRow.value[k] = '');
    fetchSettlements();
    fetchFilterOptions();
  } else {
    alert('추가 실패: ' + error.message);
  }
};

const downloadExcel = () => {
  const todayStr = new Date().toISOString().slice(0, 10);
  let monthLabel = selectedPrescriptionMonth.value;
  let fileMonth = '';
  if (monthLabel && monthLabel.length === 7) {
    const [y, m] = monthLabel.split('-');
    fileMonth = `${y}년 ${Number(m)}월`;
  } else {
    fileMonth = '전체';
  }
  const exportData = filteredList.value.map(row => ([
    selectedPrescriptionMonth.value,
    row.company_name,
    row.company_reg_no,
    row.hospital_name,
    row.hospital_reg_no,
    row.prescription_month,
    row.pharma_name,
    row.product_name,
    row.insurance_code,
    row.price ? Math.round(row.price) : 0,
    row.quantity ? Math.round(row.quantity) : 0,
    row.prescription_amount ? Math.round(row.prescription_amount) : 0,
    row.commission_rate ? Number(Number(row.commission_rate).toFixed(3)) : 0,
    row.payment_amount ? Math.round(row.payment_amount) : 0,
    row.remarks
  ]));
  const headers = [
    '정산월', '업체명', '업체사업자등록번호', '병의원', '병의원사업자등록번호', '처방월', '제약사', '제품명', '보험코드',
    '약가', '수량', '처방액', '수수료율', '지급액', '비고'
  ];
  const ws = XLSX.utils.aoa_to_sheet([headers, ...exportData]);

  // 셀 서식 지정: 약가, 수량, 처방액, 지급액(10,11,12,14번째 컬럼) -> '#,##0', 수수료율(13번째) -> '0.0%'
  const colFormats = [null, null, null, null, null, null, null, null, null, '#,##0', '#,##0', '#,##0', '0.0%', '#,##0', null];
  for (let r = 1; r <= exportData.length; r++) {
    // 약가, 수량, 처방액, 지급액
    ['J','K','L','N'].forEach((col, idx) => {
      const cell = ws[`${col}${r+1}`];
      if (cell) cell.z = '#,##0';
    });
    // 수수료율
    const percentCell = ws[`M${r+1}`];
    if (percentCell) percentCell.z = '0.0%';
  }

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '정산내역');
  XLSX.writeFile(wb, `정산내역서 - ${fileMonth}_${todayStr}.xlsx`);
};

const downloadTemplate = () => {
  const templateData = [
    {
      '업체명': '',
      '업체사업자등록번호': '123-45-67890', // 필수 예시
      '병의원': '',
      '병의원사업자등록번호': '',
      '처방월': '',
      '제약사': '',
      '제품명': '',
      '보험코드': '',
      '약가': '',
      '수량': '',
      '처방액': '',
      '수수료율': '',
      '지급액': '',
      '비고': ''
    }
  ];
  const ws = XLSX.utils.json_to_sheet(templateData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '정산데이터 템플릿');
  XLSX.writeFile(wb, 'settlement_template.xlsx');
};

const uploadExcel = async (event) => {
  const file = event.target.files[0];
  if (!file) {
    return;
  }

  const reader = new FileReader();
  reader.onload = async (e) => {
    const data = e.target.result;
    const workbook = XLSX.read(data, { type: 'binary' });
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const json = XLSX.utils.sheet_to_json(sheet);
    const rows = json.map(row => ({
      settlement_month: route.params.month,
      company_name: row['업체명'] || '',
      company_reg_no: row['업체사업자등록번호'] || '',
      hospital_name: row['병의원'] || '',
      hospital_reg_no: row['병의원사업자등록번호'] || '',
      prescription_month: row['처방월'] || '',
      pharma_name: row['제약사'] || '',
      product_name: row['제품명'] || '',
      insurance_code: row['보험코드'] || '',
      price: row['약가'] ? Number(Number(row['약가']).toFixed(2)) : null,
      quantity: row['수량'] ? Number(Number(row['수량']).toFixed(2)) : null,
      prescription_amount: row['처방액'] ? Number(Number(row['처방액']).toFixed(2)) : null,
      commission_rate: row['수수료율'] ? Number(Number(row['수수료율']).toFixed(3)) : null,
      payment_amount: row['지급액'] ? Number(Number(row['지급액']).toFixed(2)) : null,
      remarks: row['비고'] || ''
    }));
    const validRows = rows.filter(r => r.company_name && r.hospital_name && r.product_name);
    if (validRows.length === 0) {
      alert('엑셀에 등록할 데이터가 없습니다.');
      return;
    }
    const { error } = await supabase.from('settlements').insert(validRows);
    if (error) {
      alert('엑셀 등록 실패: ' + error.message);
    } else {
      alert('엑셀 등록 성공!');
      fetchSettlements();
      fetchFilterOptions();
    }
  };
  reader.readAsBinaryString(file);
};

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchSettlements();
};

const selectAllText = computed(() => {
  return selectedRows.value.length === filteredList.value.length && filteredList.value.length > 0 ? '모두 해제' : '모두 선택';
});

const toggleSelectAll = () => {
  if (selectedRows.value.length === filteredList.value.length) {
    filteredList.value.forEach(row => row._selected = false);
    selectedRows.value = [];
  } else {
    filteredList.value.forEach(row => row._selected = true);
    selectedRows.value = [...filteredList.value];
  }
};

const deleteSelected = async () => {
  if (selectedRows.value.length === 0) {
    alert('삭제할 항목을 선택하세요.');
    return;
  }
  if (!confirm('정말 삭제하시겠습니까?')) return;
  const ids = selectedRows.value.map(row => row.id);
  const { error } = await supabase
    .from('settlements')
    .delete()
    .in('id', ids);
  if (error) {
    alert('삭제 중 오류가 발생했습니다.');
  } else {
    alert('삭제가 완료되었습니다.');
    fetchSettlements();
    selectedRows.value = [];
  }
};

const onRowSelectChange = (row) => {
  if (row._selected) {
    if (!selectedRows.value.includes(row)) selectedRows.value.push(row);
  } else {
    selectedRows.value = selectedRows.value.filter(r => r.id !== row.id);
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
</style>
  