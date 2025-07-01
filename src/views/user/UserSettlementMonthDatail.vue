<template>
  <div class="admin-settlement-view page-container">
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span>처방월</span>
        <select v-model="selectedPrescriptionMonth" class="input-120" :disabled="!selectedMonth">
          <option value="">전체</option>
          <option v-for="p in prescriptionMonthOptions" :key="p" :value="p">{{ p }}</option>
        </select>
        <div class="hide-mobile">
        <span>병의원</span>
        <select v-model="selectedHospital" class="input-180" :disabled="!selectedMonth">
          <option value="">전체</option>
          <option v-for="h in hospitalOptions" :key="h" :value="h">{{ h }}</option>
        </select>
        <span>제품</span>
        <select v-model="selectedProduct" class="input-180" :disabled="!selectedMonth">
          <option value="">전체</option>
          <option v-for="p in productOptions" :key="p" :value="p">{{ p }}</option>
        </select>
        </div>
      </div> 
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
      <div style="display: flex; gap: 0.5rem;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운로드</button>
      </div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <div :style="isMobile ? tableConfig.tableStyle : {}">
        <DataTable
          :value="settlements"
          :loading="loading"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth, minWidth: isMobile ? tableConfig.tableStyle.minWidth : '100%' }"
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

const route = useRoute();
const settlements = ref([]);
const loading = ref(false);
const totalCount = ref(0);
const selectedMonth = ref(route.params.month || '');
const selectedPrescriptionMonth = ref('');
const selectedHospital = ref('');
const selectedProduct = ref('');
const monthOptions = ref([]);
const prescriptionMonthOptions = ref([]);
const hospitalOptions = ref([]);
const productOptions = ref([]);
const pageSize = ref(100);
const first = ref(0);
const currentUserBizNo = ref('');

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchSettlements();
};

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userSettlementMonthDetailTableConfig.mobile : userSettlementMonthDetailTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const fetchSettlements = async () => {
  console.log('상세페이지_fetchSettlements 호출됨.');
  if (!currentUserBizNo.value) {
    console.log('상세페이지_currentUserBizNo가 설정되지 않아 조회를 중단합니다.');
    loading.value = false;
    return;
  }
  console.log(`상세페이지_데이터 조회 시작. 정산월: ${selectedMonth.value}, 사업자번호: ${currentUserBizNo.value}`);
  loading.value = true;
  let query = supabase
    .from('settlements')
    .select('*', { count: 'exact' })
    .like('company_reg_no', `%${currentUserBizNo.value}%`);

  if (selectedMonth.value) query = query.eq('settlement_month', selectedMonth.value);
  if (selectedPrescriptionMonth.value) query = query.eq('prescription_month', selectedPrescriptionMonth.value);
  if (selectedHospital.value) query = query.eq('hospital_name', selectedHospital.value);
  if (selectedProduct.value) query = query.eq('product_name', selectedProduct.value);

  query = query.range(first.value, first.value + pageSize.value - 1).order('prescription_month', { ascending: false });

  console.log('상세페이지_Supabase 쿼리 실행...');
  const { data, error, count } = await query;
  if (error) {
    console.error('상세페이지_settlements 조회 에러:', error);
    settlements.value = [];
    totalCount.value = 0;
  } else {
    console.log('상세페이지_쿼리 성공. 조회된 데이터 수:', data.length, '전체 개수:', count);
    settlements.value = data;
    totalCount.value = count || 0;
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
  console.log('상세페이지_컴포넌트 마운트됨. 유저 정보 조회 시작...');
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    console.log('상세페이지_로그인 유저 확인:', user.email);
    const { data: member, error } = await supabase
      .from('members')
      .select('biz_no')
      .eq('id_email', user.email)
      .single();

    if (error) {
       console.error("상세페이지_멤버 정보 조회 에러:", error);
       loading.value = false;
       return;
    }

    if (member) {
      currentUserBizNo.value = member.biz_no;
      console.log('상세페이지_currentUserBizNo 설정됨:', currentUserBizNo.value);
      fetchSettlements();
      fetchFilterOptions();
    } else {
      console.error("상세페이지_사용자의 멤버 프로필을 찾을 수 없습니다.");
      loading.value = false;
    }
  } else {
    console.error("상세페이지_로그인된 사용자가 없습니다.");
    loading.value = false;
  }
});

watch([selectedPrescriptionMonth, selectedHospital, selectedProduct], () => {
  first.value = 0; // 필터 변경 시 첫 페이지로
  fetchSettlements();
});

watch(selectedMonth, () => {
  // 정산월 변경 시 하위 필터 옵션 다시 로드
  fetchFilterOptions();
});

const fetchFilterOptions = async () => {
  if (!currentUserBizNo.value || !selectedMonth.value) return;

  // 처방월 목록
  const { data: prescriptionMonths } = await supabase
    .from('settlements')
    .select('prescription_month')
    .eq('company_reg_no', currentUserBizNo.value)
    .eq('settlement_month', selectedMonth.value);
  prescriptionMonthOptions.value = prescriptionMonths ? [...new Set(prescriptionMonths.map(row => row.prescription_month))].sort().reverse() : [];
  
  // 병의원 목록
  const { data: hospitals } = await supabase
    .from('settlements')
    .select('hospital_name')
    .eq('company_reg_no', currentUserBizNo.value)
    .eq('settlement_month', selectedMonth.value);
  hospitalOptions.value = hospitals ? [...new Set(hospitals.map(row => row.hospital_name))].sort() : [];

  // 제품 목록
  const { data: products } = await supabase
    .from('settlements')
    .select('product_name')
    .eq('company_reg_no', currentUserBizNo.value)
    .eq('settlement_month', selectedMonth.value);
  productOptions.value = products ? [...new Set(products.map(row => row.product_name))].sort() : [];
};
</script>
