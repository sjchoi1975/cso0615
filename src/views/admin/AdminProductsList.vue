<template>
  <div class="admin-products-view page-container">
    <!-- 모바일 필터 카드 스크롤 처리 -->
    <div class="filter-card">
      <div class="filter-row">
        <span>기준월</span>
        <select v-model="currentMonth.value" class="input-120">
          <option v-for="m in monthOptions" :key="m" :value="m">
            {{ m.slice(0,4) + '년 ' + parseInt(m.slice(5,7)) + '월' }}
          </option>
        </select>
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="제약사, 제품명, 보험코드, 성분명 검색" class="input-search" />
        </span>
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
        <button class="btn-search-filter"
          @click="searchProducts" 
          :disabled="!isSearchActive" 
          style="margin-left: 2rem; 
          margin: 0rem">검색</button>
        <button class="filter-reset-btn"
          @click="resetFilters"
          style="margin-left: 0.5rem; display: flex; align-items: center; gap: 0.2rem;">
          <svg xmlns="http://www.w3.org/2000/svg"
          width="20" height="20" viewBox="0 0 24 24"
          style="vertical-align: middle; margin-right: 2px;">
          <path fill="currentColor" d="M12 6V3L8 7l4 4V8c2.76 0 5 2.24 5 5a5 5 0 0 1-5 5a5 5 0 0 1-5-5H5a7 7 0 0 0 7 7a7 7 0 0 0 7-7c0-3.87-3.13-7-7-7z"/></svg>
          초기화
        </button>
      </div>
    </div>

    <!-- 모바일 기능카드 스크롤 처리 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}개 제품</div>
      <div style="display: flex; gap:1rem; align-items:center;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운</button>
        <button class="btn-add" @click="downloadTemplate">템플릿</button>
        <label class="btn-add" style="margin-bottom:0; cursor:pointer;">
          엑셀 등록
          <input type="file" accept=".xlsx,.xls" @change="uploadExcel" style="display:none;" />
        </label>
        <button class="btn-add" @click="goToProductCreate">제품 등록</button>
        <button class="btn-danger" @click="deleteAllProducts">전체 삭제</button>
      </div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card admin-products-view-table">
      <DataTable
        :value="products"
        :loading="loading"
        :paginator="false"
        :rows="200"
        :rowsPerPageOptions="[100, 200, 500]"
        :totalRecords="totalCount"
        :first="first"
        @page="onPageChange"
        lazy
        responsiveLayout="scroll"
        scrollable
        :scrollHeight="'calc(100vh - 204px)'"
        ref="tableRef"
      >
        <Column header="순번"
          :style="{ width: columnWidths.index }"
          :bodyStyle="{ textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ first + slotProps.index + 1 }}
          </template>
        </Column>
        <Column field="pharmacist" header="제약사"
          :sortable="columnSortables.pharmacist"
          :style="{ width: columnWidths.pharmacist }"
          :bodyStyle="{ textAlign: columnAligns.pharmacist }">
          <template #body="slotProps">
            <span :title="slotProps.data.pharmacist">{{ slotProps.data.pharmacist }}</span>
          </template>
        </Column>
        <Column field="product_name" header="제품명"
          :sortable="columnSortables.product_name"
          :style="{ width: columnWidths.product_name }"
          :bodyStyle="{ textAlign: columnAligns.product_name }">
          <template #body="slotProps">
            <span :title="slotProps.data.product_name">{{ slotProps.data.product_name }}</span>
          </template>
        </Column>
        <Column field="insurance_code" header="보험코드"
          :sortable="columnSortables.insurance_code"
          :style="{ width: columnWidths.insurance_code }"
          :bodyStyle="{ textAlign: columnAligns.insurance_code }">
          <template #body="slotProps">
            {{ slotProps.data.insurance_code || '' }}
          </template>
        </Column>
        <Column field="price" header="단가"
          :sortable="columnSortables.price"
          :style="{ width: columnWidths.price }"
          :bodyStyle="{ textAlign: columnAligns.price }">
          <template #body="slotProps">
            {{ slotProps.data.price?.toLocaleString() }}
          </template>
        </Column>
        <Column field="commission_rate_a" header="수수료 A"
          :sortable="columnSortables.commission_rate_a"
          :style="{ width: columnWidths.commission_rate_a }"
          :bodyStyle="{ textAlign: columnAligns.commission_rate_a }">
          <template #body="slotProps">
            {{ formatCommissionRate(slotProps.data.commission_rate_a) }}
          </template>
        </Column>
        <Column field="commission_rate_b" header="수수료 B"
          :sortable="columnSortables.commission_rate_b"
          :style="{ width: columnWidths.commission_rate_b }"
          :bodyStyle="{ textAlign: columnAligns.commission_rate_b }">
          <template #body="slotProps">
            {{ formatCommissionRate(slotProps.data.commission_rate_b) }}
          </template>
        </Column>
        <Column field="commission_rate_c" header="수수료 C"
          :sortable="columnSortables.commission_rate_c"
          :style="{ width: columnWidths.commission_rate_c }"
          :bodyStyle="{ textAlign: columnAligns.commission_rate_c }">
          <template #body="slotProps">
            {{ formatCommissionRate(slotProps.data.commission_rate_c) }}
          </template>
        </Column>
        <Column field="Ingredient" header="성분명"
          :sortable="columnSortables.Ingredient"
          :style="{ width: columnWidths.Ingredient }"
          :bodyStyle="{ textAlign: columnAligns.Ingredient }">
          <template #body="slotProps">
            <span :title="slotProps.data.Ingredient">{{ slotProps.data.Ingredient }}</span>
          </template>
        </Column>
        <Column field="classification" header="분류"
          :sortable="columnSortables.classification"
          :style="{ width: columnWidths.classification }"
          :bodyStyle="{ textAlign: columnAligns.classification }">
          <template #body="slotProps">
            <span :title="slotProps.data.classification">{{ slotProps.data.classification }}</span>
          </template>
        </Column>
        <Column field="comparator" header="대조약"
          :sortable="columnSortables.comparator"
          :style="{ width: columnWidths.comparator }"
          :bodyStyle="{ textAlign: columnAligns.comparator }">
          <template #body="slotProps">
            <span :title="slotProps.data.comparator">{{ slotProps.data.comparator }}</span>
          </template>
        </Column>
        <Column field="reimbursement" header="급여"
          :sortable="columnSortables.reimbursement"
          :style="{ width: columnWidths.reimbursement }"
          :bodyStyle="{ textAlign: columnAligns.reimbursement }">
        </Column>
        <Column field="bioequivalence" header="생동"
          :sortable="columnSortables.bioequivalence"
          :style="{ width: columnWidths.bioequivalence }"
          :bodyStyle="{ textAlign: columnAligns.bioequivalence }">
        </Column>
        <Column field="Inhouse" header="인하우스"
          :sortable="columnSortables.Inhouse"
          :style="{ width: columnWidths.Inhouse }"
          :bodyStyle="{ textAlign: columnAligns.Inhouse }">
        </Column>
        <Column field="remarks" header="비고"
          :sortable="columnSortables.remarks"
          :style="{ width: columnWidths.remarks }"
          :bodyStyle="{ textAlign: columnAligns.remarks }">
          <template #body="slotProps">
            <span :title="slotProps.data.remarks">{{ slotProps.data.remarks }}</span>
          </template>
        </Column>
        <Column header="수정"
          :style="{ width: columnWidths.edit }"
          :bodyStyle="{ textAlign: columnAligns.edit }">
          <template #body="slotProps">
            <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="goToProductEdit(slotProps.data.id)" />
          </template>
        </Column>
        <Column header="삭제"
          :style="{ width: columnWidths.delete }"
          :bodyStyle="{ textAlign: columnAligns.delete }">
          <template #body="slotProps">
            <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="deleteProduct(slotProps.data.id)" />
          </template>
        </Column>
        <Column field="status" header="상태"
          :sortable="columnSortables.status"
          :style="{ width: columnWidths.status }"
          :bodyStyle="{ textAlign: columnAligns.status }">
          <template #body="slotProps">
            <div class="custom-toggle-wrap">
              <input 
                type="checkbox" 
                :id="'status-' + slotProps.data.id" 
                :checked="slotProps.data.status === 'active'" 
                @change="updateProductStatus(slotProps.data)"
                class="custom-toggle-checkbox"
              />
              <label :for="'status-' + slotProps.data.id" class="custom-toggle-label"></label>
            </div>
          </template>
        </Column>
      </DataTable>
      <div v-if="loading" class="table-loading-spinner-center">
        <img src="/spinner.svg" alt="로딩중" />
      </div>
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

// 컬럼 속성 정의
const columnWidths = {
  index: '4%',
  pharmacist: '6%',
  product_name: '10%',
  insurance_code: '5%',
  price: '4%',
  commission_rate_a: '4%',
  commission_rate_b: '4%',
  commission_rate_c: '4%',
  Ingredient: '10%',
  classification: '7%',
  comparator: '10%',
  reimbursement: '4%',
  bioequivalence: '4%',
  Inhouse: '4%',
  remarks: '8%',
  edit: '4%',
  delete: '4%',
  status: '4%'
};

const columnSortables = {
  index: false,
  pharmacist: true,
  product_name: true,
  insurance_code: true,
  price: true,
  commission_rate_a: true,
  commission_rate_b: true,
  commission_rate_c: true,
  Ingredient: false,
  classification: true,
  comparator: false,
  reimbursement: true,
  bioequivalence: true,
  Inhouse: true,
  remarks: false,
  edit: false,
  delete: false,
  status: true,
};

const columnAligns = {
  index: 'center',
  pharmacist: 'left',
  product_name: 'left',
  insurance_code: 'center',
  price: 'right',
  commission_rate_a: 'center',
  commission_rate_b: 'center',
  commission_rate_c: 'center',
  Ingredient: 'left',
  classification: 'left',
  comparator: 'left',
  reimbursement: 'center',
  bioequivalence: 'center',
  Inhouse: 'center',
  remarks: 'left',
  edit: 'center',
  delete: 'center',
  status: 'center'
};

const router = useRouter();

const currentMonth = ref({ value: '' });
const monthOptions = ref([]);

const search = ref('');
const reimbursement = ref('');
const status = ref('');

const appliedMonth = ref('');
const appliedSearch = ref('');
const appliedReimbursement = ref('');
const appliedStatus = ref('');

const products = ref([]);
const loading = ref(false);
const totalCount = ref(0);
const first = ref(0);
const pageSize = ref(200);

const fetchMonthOptions = async () => {
  const { data, error } = await supabase
    .from('products')
    .select('base_month')
    .order('base_month', { ascending: false });

  if (error) {
    console.error("Error fetching month options:", error);
  } else {
    const uniqueMonths = [...new Set(data.map(row => row.base_month).filter(m => m))];
    monthOptions.value = uniqueMonths;
    if (uniqueMonths.length > 0 && !currentMonth.value.value) {
      currentMonth.value.value = uniqueMonths[0];
      appliedMonth.value = uniqueMonths[0];
    }
  }
};

onMounted(async () => {
  await fetchMonthOptions();
  fetchProducts(0, pageSize.value);
});

onActivated(async () => {
  await fetchProducts(first.value, pageSize.value);
});

watch(
  () => currentMonth.value.value,
  (newValue, oldValue) => {
    if (newValue !== oldValue) {
      fetchProducts(0, pageSize.value);
    }
  }
);

const tableRef = ref(null);
const scrollPosition = ref(0);

const fetchProducts = async (pageFirst = 0, pageRows = 200) => {
  loading.value = true;
  let query = supabase
    .from('products')
    .select('*', { count: 'exact' });

  // 기준월 필터
  if (appliedMonth.value) {
    query = query.eq('base_month', appliedMonth.value);
  }
  
  // 상태 필터
  if (appliedStatus.value) {
    query = query.eq('status', appliedStatus.value);
  }

  // 급여 필터
  if (appliedReimbursement.value) {
    query = query.eq('reimbursement', appliedReimbursement.value);
  }

  // 쉼표로 구분된 AND 조건 검색
  if (appliedSearch.value) {
    const searchTerms = appliedSearch.value.split(',').map(term => term.trim()).filter(term => term);
    if (searchTerms.length > 0) {
      const orConditions = searchTerms.map(term => 
        `pharmacist.ilike.%${term}%,product_name.ilike.%${term}%,insurance_code.ilike.%${term}%,Ingredient.ilike.%${term}%`
      ).join(',');
      
      searchTerms.forEach(term => {
        const orFilter = `or(pharmacist.ilike.%${term}%,product_name.ilike.%${term}%,insurance_code.ilike.%${term}%,Ingredient.ilike.%${term}%)`;
        query = query.or(orFilter);
      });
    }
  }

  // 페이지네이션
  query = query.range(pageFirst, pageFirst + pageRows - 1);

  // 데이터 정렬 (옵션)
  query = query.order('id', { ascending: false });

  const { data, error, count } = await query;

  if (error) {
    console.error("Error fetching products:", error);
    products.value = [];
    totalCount.value = 0;
  } else {
    products.value = data;
    totalCount.value = count;
  }
  loading.value = false;
};

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
  const value = search.value.trim();
  let searchValid = false;
  if (/[가-힣]/.test(value)) {
    searchValid = value.length >= 2;
  } else if (value.length > 0) {
    searchValid = value.length >= 3;
  }
  return (
    searchValid ||
    reimbursement.value !== appliedReimbursement.value ||
    status.value !== appliedStatus.value ||
    currentMonth.value.value !== appliedMonth.value
  );
});

const searchProducts = () => {
  appliedMonth.value = currentMonth.value.value;
  appliedSearch.value = search.value;
  appliedReimbursement.value = reimbursement.value;
  appliedStatus.value = status.value;
  fetchProducts(0, pageSize.value);
};

const resetFilters = async () => {
  currentMonth.value.value = monthOptions.value[0] || '';
  search.value = '';
  reimbursement.value = '';
  status.value = '';
  searchProducts();
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
      base_month: row['기준월'] ? String(row['기준월']).slice(0, 7) : currentMonth.value.value,
      pharmacist: row['제약사'] || '',
      classification: row['분류명'] || '',
      product_name: row['제품명'] || '',
      insurance_code: row['보험코드'] !== undefined && row['보험코드'] !== null ? String(row['보험코드']).padStart(9, '0') : '',
      price: row['약가'] || null,
      commission_rate_a: row['수수료A'] ? parseFloat(row['수수료A']) : null,
      commission_rate_b: row['수수료B'] ? parseFloat(row['수수료B']) : null,
      commission_rate_c: row['수수료C'] ? parseFloat(row['수수료C']) : null,
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

  let query = supabase.from('products').delete().eq('base_month', currentMonth.value.value);
  if (appliedSearch.value) {
    const keyword = appliedSearch.value.toLowerCase();
    query = query.or(`pharmacist.ilike.%${keyword}%,product_name.ilike.%${keyword}%,insurance_code.ilike.%${keyword}%,Ingredient.ilike.%${keyword}%`);
  }
  if (appliedReimbursement.value) {
    query = query.eq('reimbursement', appliedReimbursement.value);
  }
  if (appliedStatus.value) {
    query = query.eq('status', appliedStatus.value);
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
