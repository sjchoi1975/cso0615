<template>
  <div class="admin-products-view page-container">
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row flex-row">
        <span class="search-label">통합 검색</span>
        <span class="p-input-icon-left search-input-wrap">
          <input v-model="search" placeholder="제약사, 제품명, 보험코드, 성분명 검색" class="input-search" />
          <button class="btn-add search-btn" @click="searchProducts" :disabled="!isSearchActive">검색</button>
        </span>
        <button class="filter-reset-btn icon-reset"
          @click="resetFilters"
          title="초기화">
          <svg xmlns="http://www.w3.org/2000/svg"
          width="20" height="20" viewBox="0 0 24 24"
          style="vertical-align: middle;">
          <path fill="currentColor" d="M12 6V3L8 7l4 4V8c2.76 0 5 2.24 5 5a5 5 0 0 1-5 5a5 5 0 0 1-5-5H5a7 7 0 0 0 7 7a7 7 0 0 0 7-7c0-3.87-3.13-7-7-7z"/></svg>
          초기화
        </button>
      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div class="total-count">총 {{ totalCount.toLocaleString() }}개 제품</div>
        <div style="display: flex; gap:0.5rem; align-items:center;">
          <button class="btn-add" @click="downloadExcel">엑셀 다운</button>
        </div>
      </div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <DataTable
        :value="filteredProducts"
        :loading="loading"
        paginator
        :rows="100"
        :rowsPerPageOptions="[100, 200, 500]"
        :totalRecords="totalCount"
        :first="first"
        @page="onPageChange"
        scrollable
        :scrollHeight="'calc(100vh - 240px)'"
        ref="tableRef"
        lazy
      >
        <Column header="순번" :style="{ width: columnWidths.index }" :bodyStyle="{ textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ first + slotProps.index + 1 }}
          </template>
        </Column>
        <Column field="pharmacist" header="제약사" :style="{ width: columnWidths.pharmacist }" :bodyStyle="{ textAlign: columnAligns.pharmacist }">
          <template #body="slotProps">
            <span :title="slotProps.data.pharmacist">{{ slotProps.data.pharmacist }}</span>
          </template>
        </Column>
        <Column field="classification" header="분류명" :style="{ width: columnWidths.classification }" :bodyStyle="{ textAlign: columnAligns.classification }">
          <template #body="slotProps">
            <span :title="slotProps.data.classification">{{ slotProps.data.classification }}</span>
          </template>
        </Column>
        <Column field="product_name" header="제품명" :style="{ width: columnWidths.product_name }" :bodyStyle="{ textAlign: columnAligns.product_name }">
          <template #body="slotProps">
            <span :title="slotProps.data.product_name">{{ slotProps.data.product_name }}</span>
          </template>
        </Column>
        <Column field="insurance_code" header="보험코드" :style="{ width: columnWidths.insurance_code }" :bodyStyle="{ textAlign: columnAligns.insurance_code }">
          <template #body="slotProps">
            {{ slotProps.data.insurance_code || '' }}
          </template>
        </Column>
        <Column field="price" header="약가" :style="{ width: columnWidths.price }" :bodyStyle="{ textAlign: columnAligns.price }">
          <template #body="slotProps">
            {{ slotProps.data.price != null ? slotProps.data.price.toLocaleString() : '' }}
          </template>
        </Column>
        <Column field="commission_rate" header="수수료율" :style="{ width: columnWidths.commission_rate }" :bodyStyle="{ textAlign: columnAligns.commission_rate }">
          <template #body="slotProps">
            {{ getUserCommission(slotProps.data) }}
          </template>
        </Column>
        <Column field="Ingredient" header="성분" :style="{ width: columnWidths.Ingredient }" :bodyStyle="{ textAlign: columnAligns.Ingredient }">
          <template #body="slotProps">
            <span :title="slotProps.data.Ingredient">{{ slotProps.data.Ingredient }}</span>
          </template>
        </Column>
        <Column field="comparator" header="대조약" :style="{ width: columnWidths.comparator }" :bodyStyle="{ textAlign: columnAligns.comparator }">
          <template #body="slotProps">
            <span :title="slotProps.data.comparator">{{ slotProps.data.comparator }}</span>
          </template>
        </Column>
        <Column field="reimbursement" header="급여" :style="{ width: columnWidths.reimbursement }" :bodyStyle="{ textAlign: columnAligns.reimbursement }">
          <template #body="slotProps">
            {{ slotProps.data.reimbursement }}
          </template>
        </Column>
        <Column field="bioequivalence" header="생동" :style="{ width: columnWidths.bioequivalence }" :bodyStyle="{ textAlign: columnAligns.bioequivalence }">
          <template #body="slotProps">
            {{ slotProps.data.bioequivalence }}
          </template>
        </Column>
        <Column field="Inhouse" header="자사/위탁" :style="{ width: columnWidths.Inhouse }" :bodyStyle="{ textAlign: columnAligns.Inhouse }">
          <template #body="slotProps">
            {{ slotProps.data.Inhouse }}
          </template>
        </Column>
        <Column field="remarks" header="비고" :style="{ width: columnWidths.remarks }" :bodyStyle="{ textAlign: columnAligns.remarks }">
          <template #body="slotProps">
            <span :title="slotProps.data.remarks">{{ slotProps.data.remarks }}</span>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';

const search = ref('');
const products = ref([]);
const loading = ref(false);
const first = ref(0);
const pageSize = ref(100);
const totalCount = ref(0);
const tableRef = ref(null);

// 사용자 등급 예시 (실제 로그인 정보 연동시 교체)
const userGrade = ref('A');

const columnWidths = {
  index: '4%',
  pharmacist: '8%',
  classification: '10%',
  product_name: '13%',
  insurance_code: '6%',
  price: '5%',
  commission_rate: '5%',
  Ingredient: '14%',
  comparator: '12%',
  reimbursement: '5%',
  bioequivalence: '5%',
  Inhouse: '5%',
  remarks: '8%'
};
const columnAligns = {
  index: 'center',
  pharmacist: 'left',
  classification: 'left',
  product_name: 'left',
  insurance_code: 'center',
  price: 'right',
  commission_rate: 'center',
  Ingredient: 'left',
  comparator: 'left',
  reimbursement: 'center',
  bioequivalence: 'center',
  Inhouse: 'center',
  remarks: 'left'
};

let latestMonth = null;

const fetchProducts = async (pageFirst = 0, pageRows = 100) => {
  loading.value = true;
  // 최신 월 구하기 (최초 1회만)
  if (!latestMonth) {
    const { data: monthData } = await supabase
      .from('product_months')
      .select('base_month')
      .order('base_month', { ascending: false })
      .limit(1);
    latestMonth = monthData && monthData.length > 0 ? monthData[0].base_month : null;
  }
  if (!latestMonth) {
    products.value = [];
    totalCount.value = 0;
    loading.value = false;
    return;
  }
  // 서버 페이지네이션 + 검색
  let query = supabase
    .from('products')
    .select('*', { count: 'exact' })
    .eq('base_month', latestMonth)
    .eq('status', 'active');
  if (search.value.trim()) {
    const keyword = search.value.trim();
    query = query.or(
      `pharmacist.ilike.%${keyword}%,product_name.ilike.%${keyword}%,insurance_code.ilike.%${keyword}%,Ingredient.ilike.%${keyword}%`
    );
  }
  query = query.range(pageFirst, pageFirst + pageRows - 1);
  const { data, error, count } = await query;
  if (!error) {
    products.value = data;
    totalCount.value = count || 0;
  }
  loading.value = false;
};

onMounted(() => {
  fetchProducts(first.value, pageSize.value);
});

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchProducts(event.first, event.rows);
};

const filteredProductsAll = computed(() => {
  let filtered = products.value;
  if (search.value) {
    const keyword = search.value.toLowerCase();
    filtered = filtered.filter(
      p =>
        (p.pharmacist && p.pharmacist.toLowerCase().includes(keyword)) ||
        (p.product_name && p.product_name.toLowerCase().includes(keyword)) ||
        (p.insurance_code && p.insurance_code.toLowerCase().includes(keyword)) ||
        (p.Ingredient && p.Ingredient.toLowerCase().includes(keyword))
    );
  }
  return filtered;
});

const filteredProducts = computed(() => {
  return filteredProductsAll.value.slice(first.value, first.value + pageSize.value);
});

const isSearchActive = computed(() => search.value.trim().length > 0);

const searchProducts = () => {
  first.value = 0;
  fetchProducts(first.value, pageSize.value);
};

const resetFilters = () => {
  search.value = '';
  first.value = 0;
  fetchProducts(first.value, pageSize.value);
};

function getUserCommission(row) {
  if (userGrade.value === 'A') return row.commission_rate_a != null ? (row.commission_rate_a * 100).toFixed(1).replace(/\.0$/, '') + '%' : '';
  if (userGrade.value === 'B') return row.commission_rate_b != null ? (row.commission_rate_b * 100).toFixed(1).replace(/\.0$/, '') + '%' : '';
  if (userGrade.value === 'C') return row.commission_rate_c != null ? (row.commission_rate_c * 100).toFixed(1).replace(/\.0$/, '') + '%' : '';
  return '';
}

function downloadExcel() {
  // 엑셀 다운로드 로직은 기존과 동일하게 구현
}
</script>

<style scoped>
.flex-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.search-input-wrap {
  display: flex;
  flex: 2;
  min-width: 0;
}
.input-search {
  flex: 1;
  border-radius: 4px 0 0 4px;
  border-right: none;
  height: 40px;
  font-size: 1rem;
  padding: 0.5rem 0.7rem;
}
.search-btn {
  border-radius: 0 4px 4px 0;
  border-left: none;
  height: 40px;
  font-size: 1rem;
  padding: 0 1.2rem;
  margin-left: 0;
  flex: none;
  display: flex;
  align-items: center;
  justify-content: center;
}
.icon-reset {
  min-width: 60px;
  padding: 0.5rem 0.7rem;
  margin-left: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
}
.icon-reset svg {
  margin-right: 4px;
}

@media (max-width: 600px) {
  .search-label {
    display: none !important;
  }
  .filter-row.flex-row {
    flex-wrap: nowrap;
    gap: 0.3rem;
  }
  .search-input-wrap {
    flex: 2;
  }
  .input-search {
    font-size: 1rem;
    padding: 0.5rem 0.5rem;
    height: 38px;
  }
  .search-btn {
    font-size: 1rem;
    padding: 0 1rem;
    height: 38px;
  }
  .icon-reset {
    min-width: 48px;
    padding: 0.5rem 0.5rem;
    margin-left: 0.3rem;
    font-size: 1rem;
  }
}
</style>
