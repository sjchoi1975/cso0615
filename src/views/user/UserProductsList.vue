<template>
  <div class="admin-products-view page-container">
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row flex-row">
        <span class="p-input-icon-left">
          <input
            :value="search"
            @input="onInput"
            @compositionstart="onCompositionStart"
            @compositionupdate="onCompositionUpdate"
            @compositionend="onCompositionEnd"
            @keyup.enter="searchProducts"
            class="input-search"
            style="border-radius: 2px 0 0 2px !important; border-right: none !important;"
            placeholder="제약사, 제품명, 보험코드, 성분명 검색"
          />
          <button
            class="btn-search-filter" 
            style="border-radius: 0 2px 2px 0 !important;"
            @click="searchProducts" 
            :disabled="!isSearchActive"
            >검색</button>
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
      <div class="total-count">총 {{ totalCount.toLocaleString() }}개 제품</div>
      <div style="display: flex; gap:0.5rem; align-items:center;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운</button>
      </div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="products"
          :loading="loading"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="'calc(100vh - 204px)'"
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
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import { userProductsTableConfig } from '@/config/tableConfig';

const search = ref('');
const composingValue = ref('');
const isComposing = ref(false);
const appliedSearch = ref('');
const products = ref([]);
const loading = ref(false);
const first = ref(0);
const pageSize = ref(100);
const totalCount = ref(0);
const tableRef = ref(null);
const userGrade = ref('');

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userProductsTableConfig.mobile : userProductsTableConfig.pc);

let latestMonth = null;

const fetchProducts = async (pageFirst = 0, pageRows = 100) => {
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

const isSearchActive = computed(() => {
  const value = search.value.trim();
  if (/[가-힣]/.test(value)) {
    return value.length >= 2;
  }
  return value.length >= 3;
});

const searchProducts = () => {
  appliedSearch.value = search.value.trim();
  first.value = 0;
  fetchProducts(first.value, pageSize.value);
};

const resetFilters = () => {
  search.value = '';
  searchProducts();
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
  // 엑셀 다운로드 로직 (필요시 구현)
}

function onInput(e) {
  if (!isComposing.value) {
    search.value = e.target.value;
  }
}

function onCompositionStart() {
  isComposing.value = true;
}

function onCompositionUpdate(e) {
  composingValue.value = e.target.value;
}

function onCompositionEnd(e) {
  isComposing.value = false;
  search.value = e.target.value;
  composingValue.value = '';
}
</script>
