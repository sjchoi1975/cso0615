<template>
  <div class="user-settlement-month-view page-container">
    <div class="filter-card">
      <div class="filter-row">
        <span>정산월</span>
        <select v-model="selectedMonth" class="input-120">
          <option value="">전체</option>
          <option v-for="m in monthOptions" :key="m" :value="m">{{ m }}</option>
        </select>
      </div>
    </div>
    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
      <div style="display: flex; gap: 0.5rem;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운로드</button>
      </div>
    </div>

    <!-- 테이블카드 -->
    <div class="table-card user-settlement-month">
      <DataTable 
        :value="filteredMonthList"
        :loading="loading" 
        :paginator="false"
        scrollable 
        :scrollHeight="'calc(100vh - 204px)'"
        >
        <template #empty>
          <div v-if="!loading">조회된 데이터가 없습니다.</div>
        </template>
        <Column header="순번" :style="{ width: columnWidths.index, textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ slotProps.index + 1 }}
          </template>
        </Column>
        <Column
          v-for="col in columns"
          :key="col.field"
          :field="col.field"
          :header="col.header"
          :sortable="columnSortables[col.field] || false"
          :headerStyle="{ width: columnWidths[col.field], textAlign: columnAligns[col.field] }"
          :bodyStyle="{ textAlign: columnAligns[col.field] }"
        >
          <template v-if="col.field === 'note'" #body="slotProps">
            <span
              class="link"
              :title="slotProps.data.note"
              @click="openNotePopup(slotProps.data)"
            >
              {{ slotProps.data.note }}
            </span>
          </template>
        </Column>
        <Column header="상세" :style="{ width: columnWidths.detail, textAlign: columnAligns.detail }">
          <template #body="slotProps">
            <button class="btn-detail" @click="goDetail(slotProps.data)">상세</button>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 전달사항 팝업 -->
    <div v-if="showNoteDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <label class="modai-title">전달사항</label>
        <div class="modal-body">
          <div style="white-space: pre-line;">{{ noteValue }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-primary" @click="closeNoteDialog">확인</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import * as XLSX from 'xlsx';

const router = useRouter();

const monthList = ref([]); // 월별 현황 데이터
const loading = ref(false);
const totalCount = ref(0);

const selectedMonth = ref('');
const monthOptions = ref([]);

// 전달사항 팝업 상태
const showNoteDialog = ref(false);
const noteValue = ref('');

const currentUserRegNo = ref('');

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  settlement_month: '10%',
  note: '36%',
  hospital_name: '10%',
  prescription_count: '10%',
  prescription_amount: '10%',
  payment_amount: '10%',
  detail: '10%'
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  settlement_month: 'center',
  note: 'left',
  hospital_name: 'center',
  prescription_count: 'center',
  prescription_amount: 'right',
  payment_amount: 'right',
  detail: 'center'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  settlement_month: true,
  note: true,
  hospital_name: true,
  prescription_count: true,
  prescription_amount: true,
  payment_amount: true
};

// 컬럼 배열 한 곳에서 관리 (정산업체 제거)
const columns = [
  { field: 'settlement_month', header: '정산월' },
  { field: 'note', header: '전달사항' },
  { field: 'hospital_name', header: '병의원' },
  { field: 'prescription_count', header: '처방건수' },
  { field: 'prescription_amount', header: '처방액' },
  { field: 'payment_amount', header: '지급액' }
];

// 정산월 목록 불러오기 (settlement_months 테이블)
const fetchMonthOptions = async () => {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('settlement_month')
    .order('settlement_month', { ascending: false });
  if (!error && data) {
    const unique = Array.from(new Set(data.map(row => row.settlement_month)));
    monthOptions.value = [''].concat(unique);
  }
};

// 필터링된 리스트
const filteredMonthList = computed(() => {
  if (!selectedMonth.value) return monthList.value;
  return monthList.value.filter(item => item.settlement_month === selectedMonth.value);
});

// 현재 로그인한 사용자의 사업자등록번호 가져오기
const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    const { data: profile } = await supabase
      .from('members')
      .select('*')
      .eq('id_email', user.email)
      .single();
    if (profile) {
      currentUserRegNo.value = profile.biz_no;
    }
  }
};

// 월별 현황 데이터 불러오기
const fetchMonthList = async () => {
  loading.value = true;
  monthList.value = [];
  try {
    // 1. settlement_months에서 모든 정산월 가져오기
    const { data: months, error: monthsError } = await supabase
      .from('settlement_months')
      .select('*')
      .order('settlement_month', { ascending: false });
    if (monthsError) throw monthsError;
    if (!months) return;

    // 2. settlements에서 내 사업자등록번호만 필터
    const { data: settlements, error: settlementsError } = await supabase
      .from('settlements')
      .select('*')
      .eq('company_reg_no', currentUserRegNo.value);
    if (settlementsError) throw settlementsError;

    // 3. 월별로 집계
    monthList.value = months.map(monthRow => {
      const month = monthRow.settlement_month;
      const rows = settlements.filter(r => r.settlement_month === month);
      const hospitalSet = new Set(rows.map(r => r.hospital_name));
      const prescription_count = rows.length;
      const prescription_amount = rows.reduce((sum, r) => sum + (Number(r.prescription_amount) || 0), 0);
      const payment_amount = rows.reduce((sum, r) => sum + (Number(r.payment_amount) || 0), 0);
      return {
        settlement_month: month,
        hospital_name: hospitalSet.size,
        prescription_count: prescription_count ? prescription_count.toLocaleString() : '0',
        prescription_amount: prescription_amount ? prescription_amount.toLocaleString() : '0',
        payment_amount: payment_amount ? payment_amount.toLocaleString() : '0',
        note: monthRow.note || '',
      };
    });
    totalCount.value = monthList.value.length;
  } catch (e) {
    alert('월별 현황 데이터 조회 실패: ' + e.message);
  }
  loading.value = false;
};

onMounted(async () => {
  await getCurrentUser();
  await fetchMonthOptions();
  await fetchMonthList();
  // 기본값을 전체로 설정
  selectedMonth.value = '';
});

const downloadExcel = () => {
  if (!monthList.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  const headers = [
    '정산월', '병의원수', '처방건수', '처방액', '지급액', '전달사항'
  ];
  const data = monthList.value.map(item => [
    item.settlement_month,
    item.hospital_name,
    item.prescription_count,
    item.prescription_amount,
    item.payment_amount,
    item.note ? item.note.replace(/\n/g, '\\n') : ''
  ]);
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '월별정산현황');
  const fileName = `월별정산현황_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};
const openNotePopup = (row) => {
  noteValue.value = row.note;
  showNoteDialog.value = true;
};
const closeNoteDialog = () => {
  showNoteDialog.value = false;
};
const goDetail = (row) => {
  // 상세화면(월별 상세)로 이동, 정산월 파라미터 전달
  router.push({ path: '/settlement/list', query: { month: row.settlement_month } });
};
</script>
