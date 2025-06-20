<template>
  <div class="admin-settlement-view page-container">
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
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
import { useRoute } from 'vue-router';

const route = useRoute();
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
  hospital_name: '12%',
  hospital_reg_no: '9%',
  prescription_month: '6%',
  pharma_name: '9%',
  product_name: '12%',
  insurance_code: '7%',
  price: '5%',
  quantity: '5%',
  prescription_amount: '7%',
  commission_rate: '5%',
  payment_amount: '7%',
  remarks: '12%'
};
const columnSortables = {
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
  try {
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError) {
      console.error('Auth error:', authError);
      return;
    }
    
    if (user) {
      console.log('Current user ID:', user.id);
      console.log('Current user email:', user.email);
      
      // members 테이블에서 사용자 정보 조회
      const { data: profile, error: profileError } = await supabase
        .from('members')
        .select('*')
        .eq('id_email', user.email)
        .single();
      
      if (profileError) {
        console.error('Profile fetch error:', profileError);
        return;
      }
      
      if (profile) {
        currentUserRegNo.value = profile.biz_no;
        console.log('User profile:', profile);
        console.log('User biz_no:', profile.biz_no);
      } else {
        console.log('No profile found for user');
      }
    } else {
      console.log('No authenticated user');
    }
  } catch (error) {
    console.error('Error in getCurrentUser:', error);
  }
};

const fetchFilterOptions = async () => {
  console.log('Fetching filter options for user reg no:', currentUserRegNo.value);
  
  if (!currentUserRegNo.value) {
    console.log('No currentUserRegNo available, skipping filter options fetch');
    monthOptions.value = [];
    prescriptionMonthOptions.value = [];
    hospitalOptions.value = [];
    productOptions.value = [];
    return;
  }
  
  try {
    // 정산월 목록 조회
    const { data: months, error: monthsError } = await supabase
      .from('settlements')
      .select('settlement_month', { distinct: true })
      .eq('company_reg_no', currentUserRegNo.value);
    
    if (monthsError) {
      console.error('Error fetching months:', monthsError);
    } else {
      console.log('Months data:', months);
      monthOptions.value = months ? [...new Set(months.map(row => row.settlement_month))].sort().reverse() : [];
      console.log('Month options:', monthOptions.value);
    }
    
    // 정산월이 선택된 경우에만 나머지 옵션 조회
    if (selectedMonth.value) {
      console.log('Fetching options for selected month:', selectedMonth.value);
      
      // 처방월 옵션
      const { data: pres, error: presError } = await supabase
        .from('settlements')
        .select('prescription_month', { distinct: true })
        .eq('settlement_month', selectedMonth.value)
        .eq('company_reg_no', currentUserRegNo.value);
      
      if (presError) {
        console.error('Error fetching prescription months:', presError);
      } else {
        prescriptionMonthOptions.value = pres ? [...new Set(pres.map(row => row.prescription_month))].sort().reverse() : [];
        console.log('Prescription month options:', prescriptionMonthOptions.value);
      }
      
      // 병의원 옵션
      const { data: hospitals, error: hospitalsError } = await supabase
        .from('settlements')
        .select('hospital_name', { distinct: true })
        .eq('settlement_month', selectedMonth.value)
        .eq('company_reg_no', currentUserRegNo.value);
      
      if (hospitalsError) {
        console.error('Error fetching hospitals:', hospitalsError);
      } else {
        hospitalOptions.value = hospitals ? [...new Set(hospitals.map(row => row.hospital_name))].sort() : [];
        console.log('Hospital options:', hospitalOptions.value);
      }
      
      // 제품 옵션
      const { data: products, error: productsError } = await supabase
        .from('settlements')
        .select('product_name', { distinct: true })
        .eq('settlement_month', selectedMonth.value)
        .eq('company_reg_no', currentUserRegNo.value);
      
      if (productsError) {
        console.error('Error fetching products:', productsError);
      } else {
        productOptions.value = products ? [...new Set(products.map(row => row.product_name))].sort() : [];
        console.log('Product options:', productOptions.value);
      }
    } else {
      prescriptionMonthOptions.value = [];
      hospitalOptions.value = [];
      productOptions.value = [];
    }
  } catch (error) {
    console.error('Error in fetchFilterOptions:', error);
  }
};

const fetchSettlements = async () => {
  loading.value = true;
  settlements.value = [];
  totalCount.value = 0;

  // 둘 다 값이 있어야 조회
  if (!currentUserRegNo.value || !selectedMonth.value) {
    loading.value = false;
    return;
  }

  let query = supabase
    .from('settlements')
    .select('*', { count: 'exact' })
    .eq('company_reg_no', currentUserRegNo.value)
    .eq('settlement_month', selectedMonth.value);

  // (필요시 추가 필터)
  if (selectedPrescriptionMonth.value) {
    query = query.eq('prescription_month', selectedPrescriptionMonth.value);
  }
  if (selectedHospital.value) {
    query = query.eq('hospital_name', selectedHospital.value);
  }
  if (selectedProduct.value) {
    query = query.eq('product_name', selectedProduct.value);
  }

  // 페이지네이션 적용
  query = query.range(first.value, first.value + pageSize.value - 1);

  const { data, error, count } = await query;
  if (!error) {
    settlements.value = data || [];
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
  if (route.query.month) {
    selectedMonth.value = route.query.month;
  }
  await getCurrentUser();
});

watch(
  [selectedMonth, currentUserRegNo],
  ([month, regNo]) => {
    if (month && regNo) {
      fetchSettlements();
    }
  },
  { immediate: true }
);

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
