<template>
  <div class="admin-settlement-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <!-- PC 화면: 통합검색+필터+버튼 -->
        <template v-if="!isMobile">
          <span class="hide-mobile">통합 검색</span>
          <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="거래처, 제약사명 입력" @keyup.enter="onSearch" />
          <span class="hide-mobile">처방월</span>
          <select v-model="selectedPrescriptionMonth" class="input-120 hide-mobile" :disabled="!selectedMonth">
            <option value="">- 전체 -</option>
            <option v-for="p in prescriptionMonthOptions" :key="p" :value="p">{{ formatPrescriptionMonth(p) }}</option>
          </select>
          <span class="hide-mobile">거래처</span>
          <select v-model="selectedHospital" class="input-180 hide-mobile" :disabled="!selectedMonth">
            <option value="">- 전체 -</option>
            <option v-for="h in hospitalOptions" :key="h" :value="h">{{ h }}</option>
          </select>
          <span class="hide-mobile">제약사</span>
          <select v-model="selectedPharma" class="input-180 hide-mobile" :disabled="!selectedMonth">
            <option value="">- 전체 -</option>
            <option v-for="p in pharmaOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <button type="button" class="btn-search hide-mobile" @click="onSearch" :disabled="!isSearchEnabled">검색</button>
          <button type="button" class="btn-reset hide-mobile" @click="onReset">
            <i class="pi pi-refresh" style="font-size: 1rem;"></i>
            초기화
          </button>
        </template>
        <!-- 모바일 화면: 통합검색+X+돋보기만 -->
        <template v-else>
          <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
            <input v-model="search" class="input-search wide-mobile-search" placeholder="거래처, 제약사명 입력" @keyup.enter="onSearch"/>
            <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onReset"
              style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
            <i class="pi pi-search search-btn-icon" @click="search.length >= 2 && onSearch()"
              style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          </div>
        </template>
      </div>
    </div>
    
    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
      <div style="display: flex; gap: 1rem; align-items:center;">
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
      <div :style="isMobile ? tableConfig.tableStyle : {}">
        <DataTable
          :value="filteredList"
          :loading="loading"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth, minWidth: isMobile ? tableConfig.tableStyle.minWidth : undefined }"
        >
        <template #empty>
            <div v-if="!loading">조회된 데이터가 없습니다.</div>
          </template>

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
              <template v-else-if="col.field === 'hospital_name'">
                <span class="table-title">{{ slotProps.data.hospital_name }}</span>
              </template>

              <template v-else-if="col.field === 'pharma_name'">
                {{ slotProps.data.pharma_name }}
              </template>
              <template v-else-if="col.field === 'product_name'">
                <span class="table-title">{{ slotProps.data.product_name }}</span>
              </template>
              <template v-else-if="col.format === 'number'">
                {{ formatNumber(slotProps.data[col.field]) }}
              </template>
              <template v-else-if="col.format === 'currency'">
                {{ formatCurrency(slotProps.data[col.field]) }}
              </template>
               <template v-else-if="col.format === 'percent'">
                {{ formatPercentage(slotProps.data[col.field]) }}
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
import Paginator from 'primevue/paginator';
import * as XLSX from 'xlsx';
import { useRoute } from 'vue-router';
import { userSettlementMonthDetailTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import Button from 'primevue/button';

const route = useRoute();
const settlements = ref([]);
const filteredList = ref([]);
const loading = ref(false);
const totalCount = ref(0);
const selectedMonth = ref(route.query.month || '');
const selectedPrescriptionMonth = ref('');
const selectedPharma = ref('');
const selectedHospital = ref('');
const monthOptions = ref([]);
const prescriptionMonthOptions = ref([]);
const hospitalOptions = ref([]);
const pharmaOptions = ref([]);
const pageSize = ref(100);
const first = ref(0);
const currentUserBizNo = ref(route.query.biz_no || '');
const search = ref('');
const isSearched = ref(false);
const isSearchEnabled = computed(() =>
  search.value.length >= 2 ||
  selectedPrescriptionMonth.value ||
  selectedPharma.value ||
  selectedHospital.value
);

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchSettlements();
};

const onSearch = () => {
  if (!isSearchEnabled.value) return;
  first.value = 0;
  isSearched.value = true;
  // 검색 버튼 클릭 시에만 필터링 적용
  fetchSettlements();
};

const onReset = () => {
  if (isSearched.value) {
    search.value = '';
    selectedPrescriptionMonth.value = '';
    selectedPharma.value = '';
    selectedHospital.value = '';
    first.value = 0;
    isSearched.value = false;
    // 전체 데이터로 초기화
    fetchSettlements();
  } else {
    search.value = '';
  }
};

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userSettlementMonthDetailTableConfig.mobile : userSettlementMonthDetailTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const normalizeBizNo = (val) => (val || '').replaceAll('-', '').replaceAll(' ', '').trim();

// 필터 옵션 설정 함수 추가
const setFilterOptions = () => {
  const data = settlements.value;
  
  // 처방월 옵션
  prescriptionMonthOptions.value = [...new Set(data.map(item => item.prescription_month))].filter(Boolean).sort().reverse();
  
  // 거래처 옵션 (hospital_name 기준으로 유니크하게)
  hospitalOptions.value = [...new Set(data.map(item => item.hospital_name))].filter(Boolean).sort((a, b) => a.localeCompare(b, 'ko-KR'));
  
  // 제약사 옵션 (pharma_name 기준으로 유니크하게)
  pharmaOptions.value = [...new Set(data.map(item => item.pharma_name))].filter(Boolean).sort((a, b) => a.localeCompare(b, 'ko-KR'));
};

const fetchSettlements = async () => {
  console.log('상세페이지_fetchSettlements 호출됨.');
  if (!currentUserBizNo.value) {
    console.log('상세페이지_currentUserBizNo가 설정되지 않아 조회를 중단합니다.');
    loading.value = false;
    return;
  }
  const normBizNo = normalizeBizNo(currentUserBizNo.value);
  console.log(`상세페이지_데이터 조회 시작. 정산월: ${selectedMonth.value}, 사업자번호: ${normBizNo}`);
  loading.value = true;
  let query = supabase
    .from('settlements')
    .select('*', { count: 'exact' })
    .eq('company_reg_no', currentUserBizNo.value.trim());

  if (selectedMonth.value) query = query.eq('settlement_month', selectedMonth.value);
  
  // 검색 버튼 클릭 시에만 필터 적용
  if (isSearched.value) {
    // 통합검색 (2글자 이상)
    if (search.value.length >= 2) {
      query = query.or(`hospital_name.ilike.%${search.value}%,pharma_name.ilike.%${search.value}%`);
    }
    // 세부 필터
    if (selectedPrescriptionMonth.value) query = query.eq('prescription_month', selectedPrescriptionMonth.value);
    if (selectedPharma.value) query = query.eq('pharma_name', selectedPharma.value);
    if (selectedHospital.value) query = query.eq('hospital_name', selectedHospital.value);
  }

  query = query.range(first.value, first.value + pageSize.value - 1).order('prescription_month', { ascending: false });

  console.log('상세페이지_Supabase 쿼리 실행...');
  const { data, error, count } = await query;
  if (error) {
    console.error('상세페이지_settlements 조회 에러:', error);
    settlements.value = [];
    totalCount.value = 0;
    filteredList.value = [];
    prescriptionMonthOptions.value = [];
    hospitalOptions.value = [];
    pharmaOptions.value = [];
  } else {
    console.log('상세페이지_쿼리 성공. 조회된 데이터 수:', data.length, '전체 개수:', count);
    settlements.value = data;
    totalCount.value = count || 0;
    filteredList.value = data;
    
    // 검색 결과를 기반으로 필터 옵션 업데이트
    setFilterOptions();
  }
  loading.value = false;
};

// 엑셀 다운로드
const downloadExcel = () => {
  if (settlements.value.length === 0) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }

  const headers = [
    '병의원', '병의원사업자등록번호', 
    '처방월', '제약사', '제품명', '보험코드', '약가', '수량', '처방액', '수수료율', '지급액', '비고'
  ];

  const data = settlements.value.map(item => [
    item.hospital_name,
    item.hospital_reg_no,
    item.prescription_month,
    item.pharma_name,
    item.product_name,
    item.insurance_code,
    item.price,
    item.quantity,
    item.prescription_amount,
    item.commission_rate,
    item.payment_amount,
    item.remarks
  ]);

  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '정산내역서');
  
  const fileName = `정산내역서_${selectedMonth.value || '전체'}_${new Date().toISOString().slice(0, 10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};

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
  return Math.round(Number(value) * 100) + '%';
};

onMounted(async () => {
  fetchSettlements();
  // fetchFilterOptions && fetchFilterOptions(); // 이 부분은 제거하고 검색 결과를 기반으로 필터 옵션 업데이트
});

// watch(selectedMonth, () => {
//   // 정산월 변경 시 하위 필터 옵션 다시 로드
//   fetchFilterOptions();
// });

// const fetchFilterOptions = async () => {
//   if (!currentUserBizNo.value || !selectedMonth.value) return;

//   // 처방월 목록
//   const { data: prescriptionMonths } = await supabase
//     .from('settlements')
//     .select('prescription_month')
//     .eq('company_reg_no', currentUserBizNo.value)
//     .eq('settlement_month', selectedMonth.value);
//   prescriptionMonthOptions.value = prescriptionMonths ? [...new Set(prescriptionMonths.map(row => row.prescription_month))].sort().reverse() : [];
  
//   // 병의원 목록
//   const { data: hospitals } = await supabase
//     .from('settlements')
//     .select('hospital_name')
//     .eq('company_reg_no', currentUserBizNo.value)
//     .eq('settlement_month', selectedMonth.value);
//   hospitalOptions.value = hospitals ? [...new Set(hospitals.map(row => row.hospital_name))].sort() : [];

//   // 제품 목록
//   const { data: products } = await supabase
//     .from('settlements')
//     .select('product_name')
//     .eq('company_reg_no', currentUserBizNo.value)
//     .eq('settlement_month', selectedMonth.value);
//   productOptions.value = products ? [...new Set(products.map(row => row.product_name))].sort() : [];
// };

// 처방월 포맷 함수 (2025-05 → 2025년 5월)
const formatPrescriptionMonth = (prescriptionMonth) => {
  if (!prescriptionMonth) return '';
  const year = prescriptionMonth.slice(0, 4);
  const month = parseInt(prescriptionMonth.slice(5, 7));
  return `${year}년 ${month}월`;
};
</script>

<style scoped>
</style>
