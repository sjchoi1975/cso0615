<template>
  <div class="user-products-view page-container">
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row" style="gap: 0.5rem; align-items: center;">
        <span style="margin-right: 0.25rem;">검색</span>
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="제약사, 제품명, 보험코드, 성분명 검색" class="input-search" />
        </span>
      </div>
    </div>
    <!-- 하단: 테이블카드 -->
    <div class="data-card">
      <div style="display: flex; align-items: center; justify-content: flex-start; margin-bottom: 0.5rem;">
        <div class="month-selector">
          <button v-if="hasPrevMonth" class="month-nav" @click="goToPrevMonth">&lt;</button>
          <span style="margin: 0 0.5rem;" class="selected-month">{{ displayMonth }}</span>
          <button v-if="hasNextMonth" class="month-nav" @click="goToNextMonth">&gt;</button>
        </div>
      </div>
      <div class="table-scroll-x">
        <DataTable
          :value="pagedProducts"
          :loading="loading"
          :paginator="false"
          responsiveLayout="scroll"
          scrollable
          :scrollHeight="'calc(100vh - 250px)'"
        >
          <Column header="순번"
            :style="{ width: columnWidths.index }"
            :bodyStyle="{ textAlign: columnAligns.index }">
            <template #body="slotProps">
              {{ first + slotProps.index + 1 }}
            </template>
          </Column>
          <Column field="pharmacist" header="제약사*"
            :sortable="columnSortables.pharmacist"
            :style="{ width: columnWidths.pharmacist }"
            :bodyStyle="{ textAlign: columnAligns.pharmacist }">
            <template #body="slotProps">
              <span :title="slotProps.data.pharmacist">{{ slotProps.data.pharmacist }}</span>
            </template>
          </Column>
          <Column field="classification" header="분류명"
            :sortable="columnSortables.classification"
            :style="{ width: columnWidths.classification }"
            :bodyStyle="{ textAlign: columnAligns.classification }">
            <template #body="slotProps">
              <span :title="slotProps.data.classification">{{ slotProps.data.classification }}</span>
            </template>
          </Column>
          <Column field="product_name" header="제품명*"
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
          </Column>
          <Column field="price" header="약가"
            :sortable="columnSortables.price"
            :style="{ width: columnWidths.price }"
            :bodyStyle="{ textAlign: columnAligns.price }">
            <template #body="slotProps">
              {{ slotProps.data.price != null ? slotProps.data.price.toLocaleString() : '' }}
            </template>
          </Column>
          <Column field="commission_rate" header="수수료율"
            :style="{ width: '6%' }"
            :bodyStyle="{ textAlign: 'center' }">
            <template #body="slotProps">
              {{ getUserCommission(slotProps.data) }}
            </template>
          </Column>
          <Column field="Ingredient" header="성분"
            :sortable="columnSortables.Ingredient"
            :style="{ width: columnWidths.Ingredient }"
            :bodyStyle="{ textAlign: columnAligns.Ingredient }">
            <template #body="slotProps">
              <span :title="slotProps.data.Ingredient">{{ slotProps.data.Ingredient }}</span>
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
          <Column field="Inhouse" header="자사/위탁"
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
        </DataTable>
      </div>
      <Paginator
        :rows="rows"
        :totalRecords="filteredProducts.length"
        :first="first"
        @page="onPageChange"
        :rowsPerPageOptions="[20, 50, 100]"
        style="margin-top: 12px;"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import dayjs from 'dayjs';

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  pharmacist: '6%',
  classification: '8%',
  product_name: '10%',
  insurance_code: '6%',
  price: '4%',
  Ingredient: '13%',
  comparator: '10%',
  reimbursement: '4%',
  bioequivalence: '4%',
  Inhouse: '4%',
  remarks: '10%'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  index: false,
  pharmacist: true,
  classification: true,
  product_name: true,
  insurance_code: true,
  price: true,
  Ingredient: true,
  comparator: true,
  reimbursement: true,
  bioequivalence: true,
  Inhouse: true,
  remarks: true
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  pharmacist: 'left',
  classification: 'left',
  product_name: 'left',
  insurance_code: 'center',
  price: 'right',
  Ingredient: 'left',
  comparator: 'left',
  reimbursement: 'center',
  bioequivalence: 'center',
  Inhouse: 'center',
  remarks: 'left'
};

const products = ref([]);
const loading = ref(false);
const search = ref('');
const currentMonth = ref('');
const first = ref(0);
const rows = ref(100);

// 연월 관련
const today = dayjs();
currentMonth.value = today.format('YYYY-MM');

const displayMonth = computed(() => {
  const [y, m] = currentMonth.value.split('-');
  return `${y}년 ${parseInt(m)}월`;
});

const hasPrevMonth = computed(() => {
  return currentMonth.value > '2020-01';
});
const hasNextMonth = computed(() => {
  return currentMonth.value < today.format('YYYY-MM');
});
const goToPrevMonth = () => {
  currentMonth.value = dayjs(currentMonth.value + '-01').subtract(1, 'month').format('YYYY-MM');
};
const goToNextMonth = () => {
  currentMonth.value = dayjs(currentMonth.value + '-01').add(1, 'month').format('YYYY-MM');
};

const fetchProducts = async () => {
  loading.value = true;
  let query = supabase.from('products').select('*').eq('base_month', currentMonth.value).eq('status', 'active').order('registered_at', { ascending: false });
  const { data, error } = await query;
  if (!error) {
    products.value = data;
  }
  loading.value = false;
};

onMounted(fetchProducts);
watch(currentMonth, fetchProducts);

const userGrade = ref('A'); // TODO: 실제 로그인 유저의 등급으로 대체

const filteredProducts = computed(() => {
  let result = products.value;
  if (search.value) {
    const keyword = search.value.toLowerCase();
    result = result.filter(p =>
      (p.pharmacist && p.pharmacist.toLowerCase().includes(keyword)) ||
      (p.product_name && p.product_name.toLowerCase().includes(keyword)) ||
      (p.insurance_code && p.insurance_code.toLowerCase().includes(keyword)) ||
      (p.Ingredient && p.Ingredient.toLowerCase().includes(keyword))
    );
  }
  return result;
});

const pagedProducts = computed(() => {
  return filteredProducts.value.slice(first.value, first.value + rows.value);
});

function onPageChange(e) {
  first.value = e.first;
  rows.value = e.rows;
}

function getUserCommission(row) {
  if (userGrade.value === 'A') return row.commission_rate_a != null ? (row.commission_rate_a * 100).toFixed(1).replace(/\.0$/, '') + '%' : '';
  if (userGrade.value === 'B') return row.commission_rate_b != null ? (row.commission_rate_b * 100).toFixed(1).replace(/\.0$/, '') + '%' : '';
  if (userGrade.value === 'C') return row.commission_rate_c != null ? (row.commission_rate_c * 100).toFixed(1).replace(/\.0$/, '') + '%' : '';
  return '';
}
</script>

<style scoped>
.table-scroll-x {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  width: 360%;
}
</style>
