<template>
  <!-- <div class="admin-products-view page-container"> -->
  <div class="page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <span class="hide-mobile">통합 검색</span>        
        <span>
          <input
            v-model="search"
            class="input-search wide-mobile-search"
            placeholder="제약사, 제품명, 보험코드, 성분명 입력"
          />
        </span>
      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}개</div>
      <div style="display: flex; gap:1rem; align-items:center;">
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
    
    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="products"
          :loading="false"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="tableScrollHeight"
          ref="tableRef"
          :style="{ width: tableConfig.tableWidth, minWidth: tableConfig.tableStyle.minWidth }"
          lazy
        >
          <Column
            v-for="col in tableConfig.columns"
            :key="col.field"
            :field="col.field"
            :header="col.label"
            :sortable="col.sortable || false"
            :style="{ width: col.width, textAlign: col.align }"
            :bodyStyle="{ textAlign: col.align }"
            :frozen="col.frozen"
          >
            <template #body="slotProps">
              <template v-if="col.field === 'index'">
                {{ first + slotProps.index + 1 }}
              </template>
              <template v-else-if="col.field === 'commission_rate'">
                {{ formatCommissionRate(getUserCommission(slotProps.data)) }}
              </template>
              <template v-else-if="col.field === 'price'">
                {{ slotProps.data.price != null ? slotProps.data.price.toLocaleString() : '' }}
              </template>
              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
        </DataTable>
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
import { ref, onMounted, computed, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import Button from 'primevue/button';
import { userProductsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';

const search = ref('');
const appliedSearch = ref('');
const products = ref([]);
const loading = ref(false);
const first = ref(0);
const pageSize = ref(200);
const totalCount = ref(0);
const tableRef = ref(null);
const userGrade = ref('');

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userProductsTableConfig.mobile : userProductsTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

let latestMonth = null;
let debounceTimer = null;

const fetchProducts = async (pageFirst = 0, pageRows = 200) => {
  loading.value = true;
  if (!latestMonth) {
    const { data: monthData, error: monthError } = await supabase
      .from('products')
      .select('base_month')
      .order('base_month', { ascending: false })
      .limit(1);
    if (monthError) {
      console.error('Error fetching latest month:', monthError);
      loading.value = false;
      return;
    }
    latestMonth = monthData && monthData.length > 0 ? monthData[0].base_month : null;
  }

  if (!latestMonth) {
    products.value = [];
    totalCount.value = 0;
    loading.value = false;
    return;
  }

  let query = supabase
    .from('products')
    .select('*', { count: 'exact' })
    .eq('base_month', latestMonth)
    .eq('status', 'active');

  if (appliedSearch.value) {
    const searchTerms = appliedSearch.value.split(',').map(term => term.trim()).filter(term => term);
    if (searchTerms.length > 0) {
      searchTerms.forEach(term => {
        const orFilter = `or(pharmacist.ilike.%${term}%,product_name.ilike.%${term}%,insurance_code.ilike.%${term}%,Ingredient.ilike.%${term}%)`;
        query = query.or(orFilter);
      });
    }
  }

  query = query.range(pageFirst, pageFirst + pageRows - 1).order('pharmacist', { ascending: true });

  const { data, error, count } = await query;

  if (error) {
    console.error('Error fetching products:', error);
    products.value = [];
    totalCount.value = 0;
  } else {
    products.value = data;
    totalCount.value = count || 0;
  }

  loading.value = false;
};

watch(search, (newVal) => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    const searchTerm = newVal.trim();
    if (searchTerm.length >= 2 || searchTerm.length === 0) {
      appliedSearch.value = searchTerm;
      first.value = 0;
      fetchProducts(0, pageSize.value);
    }
  }, 300); // 300ms 디바운스
});

onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    const { data: memberData, error: memberError } = await supabase
      .from('members')
      .select('grade')
      .eq('id', user.id)
      .single();
    if (memberError) console.error('Error fetching user grade:', memberError);
    else userGrade.value = memberData.grade;
  }
  fetchProducts(first.value, pageSize.value);
});

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchProducts(event.first, event.rows);
};

const resetFilters = () => {
  search.value = '';
};

function getUserCommission(product) {
  if (!userGrade.value) return null;
  switch (userGrade.value.toUpperCase()) {
    case 'A': return product.commission_rate_a;
    case 'B': return product.commission_rate_b;
    case 'C': return product.commission_rate_c;
    default: return null;
  }
}

const formatCommissionRate = (rate) => {
  if (rate === null || typeof rate === 'undefined' || isNaN(rate)) {
    return '';
  }
  const percentage = parseFloat(rate) * 100;
  return `${Number(percentage.toFixed(1))}%`;
};

function downloadExcel() {
  // 1. 테이블 데이터 준비
  const exportData = products.value.map((item, idx) => ({
    '순번': idx + 1,
    '제약사': item.pharmacist,
    '제품명': item.product_name,
    '성분명': item.Ingredient,
    '약가': item.price,
    '수수료율': formatCommissionRate(getUserCommission(item)),
    '급여': item.benefit,
    '보험코드': item.insurance_code,
    '분류명': item.category,
    '대조약': item.reference_drug,
    '생동': item.bioequivalence,
    '자사/위탁': item.own_or_consign,
    '비고': item.note,
  }));

  // 2. 워크시트/워크북 생성
  const worksheet = XLSX.utils.json_to_sheet(exportData);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, '수수료율');

  // 3. 엑셀 파일로 변환 및 다운로드
  const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
  const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });
  saveAs(blob, '수수료율_다운로드.xlsx');
}
</script>
