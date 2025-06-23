<template>
    <div class="admin-settlement-view page-container">
      <!-- 상단: 필터카드 -->
      <div class="filter-card">
        <div class="filter-row">
          <span>처방월</span>
          <select v-model="selectedPrescriptionMonth" class="input-120">
            <option value="">전체</option>
            <option v-for="p in prescriptionMonthOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <span>업체명</span>
          <select v-model="selectedCompany" class="input-240">
            <option value="">전체</option>
            <option v-for="c in companyOptions" :key="c" :value="c">{{ c }}</option>
          </select>
          <span>병의원</span>
          <select v-model="selectedHospital" class="input-240">
            <option value="">전체</option>
            <option v-for="h in hospitalOptions" :key="h" :value="h">{{ h }}</option>
          </select>
          <span>제품</span>
          <select v-model="selectedProduct" class="input-240">
            <option value="">전체</option>
            <option v-for="p in productOptions" :key="p" :value="p">{{ p }}</option>
          </select>
        </div>
      </div>
  
      <!-- 중간: 기능카드 -->
      <div class="function-card">
        <div class="total-count">총 {{ totalCount.toLocaleString() }}건</div>
        <div style="display: flex; gap:0.5rem; align-items:center;">
          <button class="btn-add" @click="downloadExcel">엑셀 다운</button>
          <button class="btn-add" @click="downloadTemplate">템플릿</button>
          <label class="btn-add" style="margin-bottom:0; cursor:pointer;">
            엑셀 등록
            <input type="file" accept=".xlsx,.xls" @change="uploadExcel" style="display:none;" />
          </label>
        </div>
      </div>
  
      <!-- 하단: 테이블카드 -->
      <div class="table-card">
        <DataTable 
          :value="settlements" 
          :loading="loading" 
          :paginator="false"
          scrollable 
          :scrollHeight="'calc(100vh - 204px)'">
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
  import * as XLSX from 'xlsx';
  import Paginator from 'primevue/paginator';
  import { useRoute } from 'vue-router';
  
  const settlements = ref([]);
  const loading = ref(false);
  const totalCount = ref(0);
  const selectedMonth = ref('');
  const selectedPrescriptionMonth = ref('');
  const selectedCompany = ref('');
  const selectedHospital = ref('');
  const selectedProduct = ref('');
  const monthOptions = ref([]);
  const prescriptionMonthOptions = ref([]);
  const companyOptions = ref([]);
  const hospitalOptions = ref([]);
  const productOptions = ref([]);
  const pageSize = ref(100);
  const first = ref(0);
  
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
  
  const route = useRoute();
  
  const fetchFilterOptions = async () => {
    // 정산월 목록
    const { data: months } = await supabase.from('settlements').select('settlement_month', { distinct: true });
    monthOptions.value = months ? [...new Set(months.map(row => row.settlement_month))].sort().reverse() : [];
    // 정산월이 선택된 경우에만 나머지 옵션 조회
    if (selectedMonth.value) {
      const { data: pres } = await supabase.from('settlements').select('prescription_month', { distinct: true }).eq('settlement_month', selectedMonth.value);
      prescriptionMonthOptions.value = pres ? [...new Set(pres.map(row => row.prescription_month))].sort().reverse() : [];
      const { data: companies } = await supabase.from('settlements').select('company_name', { distinct: true }).eq('settlement_month', selectedMonth.value);
      companyOptions.value = companies ? [...new Set(companies.map(row => row.company_name))].sort() : [];
      const { data: hospitals } = await supabase.from('settlements').select('hospital_name', { distinct: true }).eq('settlement_month', selectedMonth.value);
      hospitalOptions.value = hospitals ? [...new Set(hospitals.map(row => row.hospital_name))].sort() : [];
      const { data: products } = await supabase.from('settlements').select('product_name', { distinct: true }).eq('settlement_month', selectedMonth.value);
      productOptions.value = products ? [...new Set(products.map(row => row.product_name))].sort() : [];
    } else {
      prescriptionMonthOptions.value = [];
      companyOptions.value = [];
      hospitalOptions.value = [];
      productOptions.value = [];
    }
  };
  
  const fetchSettlements = async () => {
    loading.value = true;
    let query = supabase.from('settlements').select('*', { count: 'exact' });
    if (selectedMonth.value) query = query.eq('settlement_month', selectedMonth.value);
    if (selectedPrescriptionMonth.value) query = query.eq('prescription_month', selectedPrescriptionMonth.value);
    if (selectedCompany.value) query = query.eq('company_name', selectedCompany.value);
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
  
  onMounted(async () => {
    // URL 파라미터로 month가 있으면 selectedMonth에 세팅
    if (route.query.month) {
      selectedMonth.value = route.query.month;
    }
    await getCurrentUser();
    fetchFilterOptions();
  });
  
  // 정산월이 바뀌면 나머지 드롭다운 옵션도 새로 불러오고, 데이터도 자동 조회
  watch(selectedMonth, () => {
    fetchFilterOptions();
    selectedPrescriptionMonth.value = '';
    selectedCompany.value = '';
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
  watch([selectedPrescriptionMonth, selectedCompany, selectedHospital, selectedProduct], () => {
    if (selectedMonth.value) fetchSettlements();
  });
  
  const totalQuantity = computed(() => settlements.value.reduce((sum, r) => sum + (Number(r.quantity) || 0), 0));
  const totalPrescriptionAmount = computed(() => settlements.value.reduce((sum, r) => sum + (Number(r.prescription_amount) || 0), 0));
  const totalPaymentAmount = computed(() => settlements.value.reduce((sum, r) => sum + (Number(r.payment_amount) || 0), 0));
  
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
  
  const editRow = (idx) => {
    // 인라인 편집 로직 (추후 구현)
    alert('인라인 편집 기능은 추후 구현 예정입니다.');
  };
  const deleteRow = async (id) => {
    if (!confirm('삭제하시겠습니까?')) return;
    await supabase.from('settlements').delete().eq('id', id);
    fetchSettlements();
  };
  const addRow = async () => {
    const { error } = await supabase.from('settlements').insert([newRow.value]);
    if (!error) {
      alert('추가되었습니다.');
      Object.keys(newRow.value).forEach(k => newRow.value[k] = '');
      fetchSettlements();
      fetchFilterOptions();
    } else {
      alert('추가 실패: ' + error.message);
    }
  };
  
  const downloadExcel = () => {
    const todayStr = new Date().toISOString().slice(0, 10);
    let monthLabel = selectedMonth.value;
    let fileMonth = '';
    if (monthLabel && monthLabel.length === 7) {
      const [y, m] = monthLabel.split('-');
      fileMonth = `${y}년 ${Number(m)}월`;
    } else {
      fileMonth = '전체';
    }
    const exportData = settlements.value.map(row => ({
      '정산월': selectedMonth.value,
      '업체명': row.company_name,
      '업체사업자등록번호': row.company_reg_no,
      '병의원': row.hospital_name,
      '병의원사업자등록번호': row.hospital_reg_no,
      '처방월': row.prescription_month,
      '제약사': row.pharma_name,
      '제품명': row.product_name,
      '보험코드': row.insurance_code,
      '약가': row.price,
      '수량': row.quantity,
      '처방액': row.prescription_amount,
      '수수료율': row.commission_rate,
      '지급액': row.payment_amount,
      '비고': row.remarks
    }));
    const ws = XLSX.utils.json_to_sheet(exportData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, '정산내역');
    XLSX.writeFile(wb, `정산내역서 - ${fileMonth}_${todayStr}.xlsx`);
  };
  
  const downloadTemplate = () => {
    const headers = [
      //'정산월',  // 정산월 컬럼 제거
      '업체명', '업체사업자등록번호', '병의원', '병의원사업자등록번호', '처방월',
      '제약사', '제품명', '보험코드', '약가', '수량', '처방액', '수수료율', '지급액', '비고'
    ];
    const exampleRow = [
      // '',
      '', '', '', '', '', '', '', '', '', '', '', '', '', ''
    ];
    const ws = XLSX.utils.aoa_to_sheet([headers, exampleRow]);
    // 합계행 등은 필요시 추가
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, '정산내역');
    XLSX.writeFile(wb, '정산내역서_일괄등록양식.xlsx');
  };
  
  const uploadExcel = async (e) => {
    console.log('selectedMonth:', selectedMonth.value)
    if (!selectedMonth.value) {
      alert('정산월을 먼저 선택하세요.');
      return;
    }
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
        settlement_month: selectedMonth.value,
        company_name: row['업체명'] || '',
        company_reg_no: row['업체사업자등록번호'] || '',
        hospital_name: row['병의원'] || '',
        hospital_reg_no: row['병의원사업자등록번호'] || '',
        prescription_month: row['처방월'] || '',
        pharma_name: row['제약사'] || '',
        product_name: row['제품명'] || '',
        insurance_code: row['보험코드'] || '',
        price: row['약가'] || null,
        quantity: row['수량'] || null,
        prescription_amount: row['처방액'] || null,
        commission_rate: row['수수료율'] || null,
        payment_amount: row['지급액'] || null,
        remarks: row['비고'] || ''
      }));
      const validRows = rows.filter(r => r.company_name && r.hospital_name && r.product_name);
      if (validRows.length === 0) {
        alert('엑셀에 등록할 데이터가 없습니다.');
        return;
      }
      const { error } = await supabase.from('settlements').insert(validRows);
      if (error) {
        alert('엑셀 등록 실패: ' + error.message);
      } else {
        alert('엑셀 등록 성공!');
        fetchSettlements();
        fetchFilterOptions();
      }
    };
    reader.readAsBinaryString(file);
  };

  const onPageChange = (event) => {
    first.value = event.first;
    pageSize.value = event.rows;
    fetchSettlements();
  };
  </script>
  