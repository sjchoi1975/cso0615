<template>
  <div class="admin-settlement-view page-container">
    <!-- 필터카드 -->
    <div class="filter-card">
      <span>정산월</span>
      <select v-model="selectedMonth" class="filter-dropdown">
        <option value="">- 선택 -</option>
        <option v-for="m in monthOptions" :key="m" :value="m">{{ m }}</option>
      </select>
      <span>처방월</span>
      <select v-model="selectedPrescriptionMonth" class="filter-dropdown" :disabled="!selectedMonth">
        <option value="">전체</option>
        <option v-for="p in prescriptionMonthOptions" :key="p" :value="p">{{ p }}</option>
      </select>
      <span>병의원</span>
      <select v-model="selectedHospital" class="input-240" :disabled="!selectedMonth">
        <option value="">전체</option>
        <option v-for="h in hospitalOptions" :key="h" :value="h">{{ h }}</option>
      </select>
      <span>제품</span>
      <select v-model="selectedProduct" class="input-240" :disabled="!selectedMonth">
        <option value="">전체</option>
        <option v-for="p in productOptions" :key="p" :value="p">{{ p }}</option>
      </select>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div class="total-count">총 {{ totalCount }}건</div>
        <div style="display: flex; gap: 0.5rem;">
          <button class="btn-add" @click="downloadExcel">엑셀 다운로드</button>
        </div>
      </div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <DataTable 
        :value="settlements" 
        :loading="loading" 
        :paginator="false"
        scrollable 
        :scrollHeight="'calc(100vh - 220px)'">
        <template #empty>
          <div v-if="!loading">조회된 데이터가 없습니다.</div>
        </template>
        <Column header="순번" :headerStyle="{ width: columnWidths.index, textAlign: columnAligns.index }" :bodyStyle="{ textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ first + slotProps.index + 1 }}
          </template>
        </Column>
        <Column
          v-for="col in columns"
          :key="col.field"
          :field="col.field"
          :header="col.header"
          :headerStyle="{ width: columnWidths[col.field], textAlign: columnAligns[col.field] }"
          :bodyStyle="{ textAlign: columnAligns[col.field] }"
          :sortable="columnSortables[col.field]"
        >
          <template #body="slotProps" v-if="col.field === 'price'">
            {{ formatCurrency(slotProps.data[col.field]) }}
          </template>
          <template #body="slotProps" v-else-if="col.field === 'quantity'">
            {{ formatNumber(slotProps.data[col.field]) }}
          </template>
          <template #body="slotProps" v-else-if="col.field === 'prescription_amount'">
            {{ formatCurrency(slotProps.data[col.field]) }}
          </template>
          <template #body="slotProps" v-else-if="col.field === 'commission_rate'">
            {{ formatPercentage(slotProps.data[col.field]) }}
          </template>
          <template #body="slotProps" v-else-if="col.field === 'payment_amount'">
            {{ formatCurrency(slotProps.data[col.field]) }}
          </template>
        </Column>
      </DataTable>
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

const settlements = ref([]);
const loading = ref(false);
const totalCount = ref(0);
const selectedMonth = ref('');
const selectedPrescriptionMonth = ref('');
const selectedHospital = ref('');
const selectedProduct = ref('');
const monthOptions = ref([]);
const prescriptionMonthOptions = ref([]);
const hospitalOptions = ref([]);
const productOptions = ref([]);
const pageSize = ref(100);
const first = ref(0);

// 현재 로그인한 사용자의 사업자등록번호
const currentUserRegNo = ref('');

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchSettlements();
};

const columnWidths = {
  index: '4%',
  company_name: '7%',
  company_reg_no: '7%',
  hospital_name: '10%',
  hospital_reg_no: '7%',
  prescription_month: '5%',
  pharma_name: '7%',
  product_name: '11%',
  insurance_code: '6%',
  price: '5%',
  quantity: '5%',
  prescription_amount: '6%',
  commission_rate: '5%',
  payment_amount: '6%',
  remarks: '7%'
};
const columnSortables = {
  company_name: true,
  company_reg_no: true,
  hospital_name: true,
  hospital_reg_no: true,
  prescription_month: true,
  pharma_name: true,
  product_name: true,
  insurance_code: true,
  price: true,
  quantity: true,
  prescription_amount: true,
  commission_rate: true,
  payment_amount: true,
  remarks: false
};
const columnAligns = {
  index: 'center',
  company_name: 'left',
  company_reg_no: 'center',
  hospital_name: 'left',
  hospital_reg_no: 'center',
  prescription_month: 'center',
  pharma_name: 'left',
  product_name: 'left',
  insurance_code: 'center',
  price: 'right',
  quantity: 'right',
  prescription_amount: 'right',
  commission_rate: 'center',
  payment_amount: 'right',
  remarks: 'left'
};
const columns = [
  { field: 'company_name', header: '업체명' },
  { field: 'company_reg_no', header: '사업자등록번호' },
  { field: 'hospital_name', header: '병의원' },
  { field: 'hospital_reg_no', header: '사업자등록번호' },
  { field: 'prescription_month', header: '처방월' },
  { field: 'pharma_name', header: '제약사' },
  { field: 'product_name', header: '제품명' },
  { field: 'insurance_code', header: '보험코드' },
  { field: 'price', header: '약가' },
  { field: 'quantity', header: '수량' },
  { field: 'prescription_amount', header: '처방액' },
  { field: 'commission_rate', header: '수수료율' },
  { field: 'payment_amount', header: '지급액' },
  { field: 'remarks', header: '비고' }
];

// 현재 사용자 정보 가져오기
const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    const { data: profile } = await supabase
      .from('members')
      .select('biz_no')
      .eq('id', user.id)
      .single();
    
    if (profile) {
      currentUserRegNo.value = profile.biz_no;
      console.log('profile:', profile);
    }
    console.log('user.id:', user.id);
  }
};

const fetchFilterOptions = async () => {
  console.log('currentUserRegNo:', currentUserRegNo.value);
  const { data: months } = await supabase
    .from('settlements')
    .select('settlement_month', { distinct: true })
    .eq('company_reg_no', currentUserRegNo.value);
  console.log('months:', months);
  monthOptions.value = months ? [...new Set(months.map(row => row.settlement_month))].sort().reverse() : [];
  
  // 정산월이 선택된 경우에만 나머지 옵션 조회
  if (selectedMonth.value) {
    const { data: pres } = await supabase
      .from('settlements')
      .select('prescription_month', { distinct: true })
      .eq('settlement_month', selectedMonth.value)
      .eq('company_reg_no', currentUserRegNo.value);
    prescriptionMonthOptions.value = pres ? [...new Set(pres.map(row => row.prescription_month))].sort().reverse() : [];
    
    const { data: hospitals } = await supabase
      .from('settlements')
      .select('hospital_name', { distinct: true })
      .eq('settlement_month', selectedMonth.value)
      .eq('company_reg_no', currentUserRegNo.value);
    hospitalOptions.value = hospitals ? [...new Set(hospitals.map(row => row.hospital_name))].sort() : [];
    
    const { data: products } = await supabase
      .from('settlements')
      .select('product_name', { distinct: true })
      .eq('settlement_month', selectedMonth.value)
      .eq('company_reg_no', currentUserRegNo.value);
    productOptions.value = products ? [...new Set(products.map(row => row.product_name))].sort() : [];
  } else {
    prescriptionMonthOptions.value = [];
    hospitalOptions.value = [];
    productOptions.value = [];
  }
};

const fetchSettlements = async () => {
  loading.value = true;
  let query = supabase.from('settlements').select('*', { count: 'exact' });
  
  // 현재 사용자의 사업자등록번호와 일치하는 데이터만 조회
  query = query.eq('company_reg_no', currentUserRegNo.value);
  
  if (selectedMonth.value) query = query.eq('settlement_month', selectedMonth.value);
  if (selectedPrescriptionMonth.value) query = query.eq('prescription_month', selectedPrescriptionMonth.value);
  if (selectedHospital.value) query = query.eq('hospital_name', selectedHospital.value);
  if (selectedProduct.value) query = query.eq('product_name', selectedProduct.value);
  
  // 페이지네이션 적용
  query = query.range(first.value, first.value + pageSize.value - 1);
  
  const { data, error, count } = await query;
  if (!error) {
    settlements.value = data;
    totalCount.value = count || 0;
  } else {
    settlements.value = [];
    totalCount.value = 0;
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
    '정산월', '업체명', '업체사업자등록번호', '병의원', '병의원사업자등록번호', 
    '처방월', '제약사', '제품명', '보험코드', '약가', '수량', '처방액', '수수료율', '지급액', '비고'
  ];

  const data = settlements.value.map(item => [
    item.settlement_month,
    item.company_name,
    item.company_reg_no,
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
  await getCurrentUser();
});

// currentUserRegNo가 세팅된 후에만 필터 옵션 불러오기
watch(currentUserRegNo, (val) => {
  if (val) fetchFilterOptions();
});

// 정산월이 바뀌면 나머지 드롭다운 옵션도 새로 불러오고, 데이터도 자동 조회
watch(selectedMonth, () => {
  fetchFilterOptions();
  selectedPrescriptionMonth.value = '';
  selectedHospital.value = '';
  selectedProduct.value = '';
  if (selectedMonth.value) {
    fetchSettlements();
  } else {
    settlements.value = [];
    totalCount.value = 0;
  }
});

// 나머지 필터도 선택 즉시 자동 필터링
watch([selectedPrescriptionMonth, selectedHospital, selectedProduct], () => {
  if (selectedMonth.value) fetchSettlements();
});
</script>

<style scoped>
.table-card {
  margin-bottom: 2rem;
}
.table-container {
  margin-left: 3rem;
}
.fixed-paginator {
  position: fixed;
  left: 0;
  bottom: 0;
  width: 100%;
  background: #fff;
  z-index: 100;
  box-shadow: 0 -2px 8px rgba(0,0,0,0.04);
  padding: 8px 0;
}
</style>
