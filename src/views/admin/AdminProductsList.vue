<template>
  <div class="admin-products-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
  <!-- 모바일 필터 카드 스크롤 처리 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <span class="hide-mobile">통합 검색</span>
        <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="제약사, 제품명, 보험코드, 성분명 입력" />
        <div class="hide-mobile" style="display: flex; gap: 0.5rem; align-items: center;">
          <span>기준월</span>
          <select v-model="currentMonth" class="input-120">
            <option v-for="m in monthOptions" :key="m" :value="m">
              {{ m.slice(0,4) + '년 ' + parseInt(m.slice(5,7)) + '월' }}
            </option>
          </select>
          <span>급여</span>
          <select v-model="reimbursement" class="input-100">
            <option value="">- 전체 -</option>
            <option value="급여">급여</option>
            <option value="비급여">비급여</option>
          </select>
          <span>상태</span>
          <select v-model="status" class="input-100">
            <option value="">- 전체 -</option>
            <option value="active">활성</option>
            <option value="inactive">비활성</option>
          </select>
          <button type="button" class="btn-search" @click="onSearch" :disabled="!isSearchEnabled">검색</button>
          <button type="button" class="btn-reset"  @click="onReset">
            <i class="pi pi-refresh" style="font-size: 1rem;"></i>
            초기화
          </button>
        </div>
        <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
          <input v-model="search" class="input-search wide-mobile-search" placeholder="제약사, 제품명, 보험코드, 성분명 입력" @keyup.enter="onSearch"/>
          <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onReset"
            style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          <i class="pi pi-search search-btn-icon" @click="isSearchEnabled && onSearch()"
            :class="{ 'disabled': !isSearchEnabled }"
            style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
        </div>
      </div>
    </div>
    
    <!-- 모바일 기능카드 스크롤 처리 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}개</div>
      <div style="display: flex; gap:1rem; align-items:center;">
        <Button
          icon="pi pi-file-excel"
          label="양식다운"
          class="btn-add-md"
          @click="downloadTemplate"
          iconPos="left"
          style="gap:0.5rem;"
        />
        <Button
          icon="pi pi-upload"
          label="엑셀 등록"
          class="btn-add-md"
          @click="() => $refs.fileInput.click()"
          iconPos="left"
          style="gap:0.5rem;"
        />
        <input
          ref="fileInput"
          type="file"
          accept=".xlsx,.xls"
          @change="uploadExcel"
          style="display:none;"
        />
        <Button
          icon="pi pi-download"
          label="다운로드"
          class="btn-download-md"
          @click="downloadExcel"
          iconPos="left"
          style="gap:0.5rem;"
        />
        <Button
          icon="pi pi-pencil"
          label="신규 등록"
          class="btn-add-md"
          @click="goToProductCreate"
          iconPos="left"
          style="gap:0.5rem;"
        />
        <Button
          icon="pi pi-trash"
          label="전체 삭제"
          class="btn-delete-md"
          @click="deleteAllProducts"
          iconPos="left"
          style="gap:0.5rem;"
        />
      </div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card admin-products-view-table">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="products"
          :loading="false"
          :paginator="false"
          :rows="200"
          :rowsPerPageOptions="[100, 200, 500]"
          :totalRecords="totalCount"
          :first="first"
          @page="onPageChange"
          lazy
          responsiveLayout="scroll"
          scrollable
          :scrollHeight="tableScrollHeight"
          ref="tableRef"
          :style="{ width: tableConfig.tableWidth }"
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
              <template v-else-if="col.format === 'number'">
                {{ slotProps.data[col.field]?.toLocaleString() }}
              </template>
              <template v-else-if="col.format === 'percent'">
                {{ formatCommissionRate(slotProps.data[col.field]) }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'edit'">
                <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="goToProductEdit(slotProps.data.id)" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'delete'">
                <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="deleteProduct(slotProps.data.id)" />
              </template>
              <template v-else-if="col.type === 'toggle' && col.field === 'status'">
                <input
                  type="checkbox"
                  :id="'status-' + slotProps.data.id"
                  :checked="slotProps.data.status === 'active'"
                  @change="updateProductStatus(slotProps.data)"
                  class="custom-toggle-checkbox"
                /><label :for="'status-' + slotProps.data.id" class="custom-toggle-label"></label>
              </template>
              <template v-else-if="col.field === 'product_name'">
                <span class="table-title-link">{{ slotProps.data.product_name }}</span>
              </template>
              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
      <div class="fixed-paginator">
        <Paginator
          :rows="pageSize"
          :totalRecords="totalCount"
          :first="first"
          :rowsPerPageOptions="[100, 200, 500]"
          @page="onPageChange"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, onUnmounted, nextTick, onActivated } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import dayjs from 'dayjs';
import { useRouter } from 'vue-router';
import * as XLSX from 'xlsx';
import Paginator from 'primevue/paginator';
import Button from 'primevue/button';
import AdminProductsCreate from './AdminProductsCreate.vue';
import AdminProductsEdit from './AdminProductsEdit.vue';
import { productsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const router = useRouter();

const search = ref('');
const reimbursement = ref('');
const status = ref('');
const currentMonth = ref('');
const defaultMonth = ref(''); // 기본 기준월 저장
const monthOptions = ref([]);
const products = ref([]);
const loading = ref(false);
const totalCount = ref(0);
const first = ref(0);
const pageSize = ref(200);
const isSearched = ref(false);

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? productsTableConfig.mobile : productsTableConfig.pc);
const tableRef = ref(null);
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const isSearchEnabled = computed(() => {
  // 검색어 2글자 이상 또는 세부 필터(기준월 변경, 급여, 상태) 중 하나라도 선택 시 활성화
  const isMonthChanged = currentMonth.value !== defaultMonth.value;
  return search.value.length >= 2 || isMonthChanged || !!reimbursement.value || !!status.value;
});

const fetchMonthOptions = async () => {
  // product_months 테이블에서 기준월 목록 불러오기
  const { data, error } = await supabase
    .from('product_months')
    .select('base_month')
    .order('base_month', { ascending: false });

  if (error) {
    console.error("Error fetching month options:", error);
  } else {
    const uniqueMonths = [...new Set(data.map(row => row.base_month).filter(m => m))];
    monthOptions.value = uniqueMonths;
    if (uniqueMonths.length > 0) {
      currentMonth.value = uniqueMonths[0];
      defaultMonth.value = uniqueMonths[0]; // 기본값 저장
    }
  }
};

// 최초 200개만 불러오기 (선택된 기준월만)
const fetchInitialProducts = async () => {
  loading.value = true;
  let query = supabase.from('products').select('*', { count: 'exact' });
  if (currentMonth.value) {
    query = query.eq('base_month', currentMonth.value);
  }
  query = query.range(0, pageSize.value - 1);
  const { data, count, error } = await query;
  if (!error) {
    products.value = data;
    totalCount.value = count;
  }
  loading.value = false;
};

// 검색/필터 시 전체 결과 받아오기 (선택된 기준월만)
const fetchFilteredProducts = async () => {
  loading.value = true;
  let query = supabase.from('products').select('*', { count: 'exact' });
  if (currentMonth.value) {
    query = query.eq('base_month', currentMonth.value);
  }
  if (status.value) {
    query = query.eq('status', status.value);
  }
  if (reimbursement.value) {
    query = query.eq('reimbursement', reimbursement.value);
  }
  if (search.value.length >= 2) {
    const keyword = search.value.toLowerCase();
    query = query.or(`pharmacist.ilike.%${keyword}%,product_name.ilike.%${keyword}%,insurance_code.ilike.%${keyword}%,Ingredient.ilike.%${keyword}%`);
  }
  const { data, count, error } = await query;
  if (!error) {
    products.value = data.slice(0, pageSize.value); // 200개만 화면에
    totalCount.value = count;
  }
  loading.value = false;
};

onMounted(async () => {
  await fetchMonthOptions();
  await fetchInitialProducts();
});

function onSearch() {
  if (!isSearchEnabled.value) return;
  isSearched.value = true;
  fetchFilteredProducts();
}
function onReset() {
  if (isSearched.value) {
    search.value = '';
    reimbursement.value = '';
    status.value = '';
    currentMonth.value = defaultMonth.value; // 기본값으로 복원
    isSearched.value = false;
    fetchInitialProducts();
  } else {
    search.value = '';
  }
}

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchProducts(event.first, event.rows);
  search.value = '';
  reimbursement.value = '';
  status.value = '';
  searchProducts();
};

const isSearchActive = computed(() => {
  return true;
});

const searchProducts = () => {
  // `watch`가 모든 필터 변경을 감지하므로 이 함수는 더 이상 필요하지 않습니다.
  // first.value = 0;
  // fetchProducts(0, pageSize.value);
};

const resetFilters = () => {
  if (monthOptions.value.length > 0) {
    currentMonth.value = monthOptions.value[0];
  }
  search.value = '';
  reimbursement.value = '';
  status.value = '';
};

const goToProductCreate = () => {
  router.push('/admin/products/create');
};

const goToProductEdit = (id) => {
  router.push(`/admin/products/edit/${id}`);
};

const deleteProduct = async (id) => {
  if (!confirm('정말로 이 제품을 삭제하시겠습니까?')) {
    return;
  }
  
  const { error } = await supabase
    .from('products')
    .delete()
    .eq('id', id);

  if (error) {
    alert('제품 삭제 중 오류가 발생했습니다: ' + error.message);
  } else {
    alert('제품이 성공적으로 삭제되었습니다.');
    await fetchProducts(first.value, pageSize.value);
  }
};

const updateProductStatus = async (product) => {
  const newStatus = product.status === 'active' ? 'inactive' : 'active';
  try {
    const { error } = await supabase
      .from('products')
      .update({ status: newStatus })
      .eq('id', product.id);
    if (error) throw error;
    product.status = newStatus;
  } catch (err) {
    console.error('상태 업데이트 오류:', err);
    alert(`오류가 발생했습니다: ${err.message}`);
  }
};

const downloadExcel = () => {
  const todayStr = dayjs().format('YYYY-MM-DD');
  const exportData = products.value.map(row => ({
    '제약사': row.pharmacist,
    '분류명': row.classification,
    '제품명': row.product_name,
    '보험코드': row.insurance_code,
    '약가': row.price,
    '수수료A': row.commission_rate_a != null ? row.commission_rate_a : '',
    '수수료B': row.commission_rate_b != null ? row.commission_rate_b : '',
    '수수료C': row.commission_rate_c != null ? row.commission_rate_c : '',
    '성분': row.Ingredient,
    '대조약': row.comparator,
    '급여': row.reimbursement,
    '생동': row.bioequivalence,
    '자사/위탁': row.Inhouse,
    '비고': row.remarks,
    '상태': row.status === 'active' ? '활성' : '비활성',
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '제품목록');
  XLSX.writeFile(wb, `요율표_${todayStr}.xlsx`);
};

const downloadTemplate = () => {
  const headers = [
    '기준월',
    '제약사', '분류명', '제품명', '보험코드', '약가',
    '수수료A', '수수료B', '수수료C', '성분',
    '대조약',
    '급여',
    '생동', '자사/위탁', '비고', '상태'
  ];
  const exampleRow = [
    '2025-05', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''
  ];
  const ws = XLSX.utils.aoa_to_sheet([headers, exampleRow]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '템플릿');
  const todayStr = dayjs().format('YYYY-MM-DD');
  XLSX.writeFile(wb, `요율표_template_${todayStr}.xlsx`);
};

const uploadExcel = async (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = async (evt) => {
    const data = evt.target.result;
    const workbook = XLSX.read(data, { type: 'binary' });
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const json = XLSX.utils.sheet_to_json(sheet);
    const rows = json.map(row => ({
      base_month: row['기준월'] ? String(row['기준월']).slice(0, 7) : currentMonth.value,
      pharmacist: row['제약사'] || '',
      classification: row['분류명'] || '',
      product_name: row['제품명'] || '',
      insurance_code: row['보험코드'] !== undefined && row['보험코드'] !== null ? String(row['보험코드']).padStart(9, '0') : '',
      price: row['약가'] || null,
      commission_rate_a: row['수수료A'] ? parseFloat(parseFloat(row['수수료A']).toFixed(3)) : null,
      commission_rate_b: row['수수료B'] ? parseFloat(parseFloat(row['수수료B']).toFixed(3)) : null,
      commission_rate_c: row['수수료C'] ? parseFloat(parseFloat(row['수수료C']).toFixed(3)) : null,
      Ingredient: row['성분'] || '',
      comparator: row['대조약'] || '',
      reimbursement: row['급여'] || '',
      bioequivalence: row['생동'] || '',
      Inhouse: row['자사/위탁'] || '',
      remarks: row['비고'] || '',
      status: row['상태'] === '비활성' ? 'inactive' : 'active',
      registered_at: new Date().toISOString()
    }));
    const validRows = rows.filter(r => r.pharmacist && r.product_name);
    if (validRows.length === 0) {
      alert('엑셀에 등록할 데이터가 없습니다.');
      return;
    }
    const { error } = await supabase.from('products').insert(validRows);
    if (error) {
      alert('엑셀 등록 실패: ' + error.message);
      console.error('엑셀 등록 실패:', error);
    } else {
      alert('엑셀 등록 성공!');
      fetchProducts(first.value, pageSize.value);
    }
  };
  reader.readAsBinaryString(file);
};

const deleteAllProducts = async () => {
  if (!confirm(`현재 조건에 맞는 모든 제품(${totalCount.value}개)을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) return;
  loading.value = true;

  let query = supabase.from('products').delete().eq('base_month', currentMonth.value);
  if (search.value) {
    const keyword = search.value.toLowerCase();
    query = query.or(`pharmacist.ilike.%${keyword}%,product_name.ilike.%${keyword}%,insurance_code.ilike.%${keyword}%,Ingredient.ilike.%${keyword}%`);
  }
  if (reimbursement.value) {
    query = query.eq('reimbursement', reimbursement.value);
  }
  if (status.value) {
    query = query.eq('status', status.value);
  }
  const { error } = await query;
  loading.value = false;
  if (error) {
    alert('삭제 실패: ' + error.message);
  } else {
    alert('삭제 완료!');
    fetchProducts(first.value, pageSize.value);
  }
};

const getStatusClass = (status) => {
  return status === 'active' ? 'status-active' : 'status-inactive';
};

const formatCommissionRate = (rate) => {
  if (rate === null || typeof rate === 'undefined' || isNaN(rate)) {
    return '';
  }
  const percentage = parseFloat(rate) * 100;
  // 소수점 1자리까지 반올림하고 불필요한 0을 제거
  return `${Number(percentage.toFixed(1))}%`;
};
</script>
