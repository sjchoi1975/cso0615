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
        <div style="display: flex; gap:1rem; align-items:center;">
          <Button
            icon="pi pi-file-excel"
            label="템플릿"
            class="btn-download-md"
            @click="downloadTemplate"
            iconPos="left"
            style="gap:0.5em;"
          />
          <Button
            icon="pi pi-upload"
            label="엑셀 등록"
            class="btn-add-md"
            @click="() => $refs.fileInput.click()"
            iconPos="left"
            style="gap:0.5em;"
          />
          <input
            ref="fileInput"
            type="file"
            accept=".xlsx,.xls"
            @change="uploadExcel"
            style="display:none;"
          />
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
            :value="settlements"
            :loading="loading"
            :paginator="false"
            scrollable
            :scrollHeight="tableScrollHeight"
            :style="{ width: tableConfig.tableWidth }"
          >
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
                <template v-else-if="col.field === 'price' || col.field === 'prescription_amount' || col.field === 'payment_amount'">
                  {{ formatCurrency(slotProps.data[col.field]) }}
                </template>
                <template v-else-if="col.field === 'quantity'">
                  {{ formatNumber(slotProps.data[col.field]) }}
                </template>
                <template v-else-if="col.field === 'commission_rate'">
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
  import * as XLSX from 'xlsx';
  import Paginator from 'primevue/paginator';
  import { useRoute } from 'vue-router';
  import { settlementMonthDetailTableConfig } from '@/config/tableConfig';
  import { getTableScrollHeight } from '@/utils/tableHeight';
  import Button from 'primevue/button';
  
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
  const route = useRoute();
  
  const isMobile = computed(() => window.innerWidth <= 768);
  const tableConfig = computed(() => isMobile.value ? settlementMonthDetailTableConfig.mobile : settlementMonthDetailTableConfig.pc);
  
  // 테이블 스크롤 높이 계산 (페이지네이터 있음)
  const tableScrollHeight = computed(() => getTableScrollHeight(true));
  
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
    if (!selectedMonth.value) {
      // 정산월이 없으면 데이터를 불러오지 않음
      settlements.value = [];
      totalCount.value = 0;
      return;
    }
    loading.value = true;
    let query = supabase.from('settlements').select('*', { count: 'exact' });
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
  
  onMounted(() => {
    const monthFromUrl = route.params.month;
    if (monthFromUrl) {
      selectedMonth.value = monthFromUrl;
      fetchSettlements();
      fetchFilterOptions();
    }
  });
  
  // 필터 변경 시 데이터 다시 불러오기
  watch([selectedPrescriptionMonth, selectedCompany, selectedHospital, selectedProduct], () => {
    if (route.params.month) {
        fetchSettlements();
    }
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
    const templateData = [
      {
        '업체명': '',
        '업체사업자등록번호': '123-45-67890', // 필수 예시
        '병의원': '',
        '병의원사업자등록번호': '',
        '처방월': '',
        '제약사': '',
        '제품명': '',
        '보험코드': '',
        '약가': '',
        '수량': '',
        '처방액': '',
        '수수료율': '',
        '지급액': '',
        '비고': ''
      }
    ];
    const ws = XLSX.utils.json_to_sheet(templateData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, '정산데이터 템플릿');
    XLSX.writeFile(wb, 'settlement_template.xlsx');
  };
  
  const uploadExcel = async (event) => {
    const file = event.target.files[0];
    if (!file) {
      return;
    }

    if (!selectedMonth.value) {
      alert('엑셀 파일을 등록하려면 먼저 정산월을 선택해야 합니다.');
      event.target.value = ''; // 파일 선택 초기화
      return;
    }
    
    const reader = new FileReader();
    reader.onload = async (e) => {
      const data = e.target.result;
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
  