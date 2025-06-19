<template>
  <div class="admin-settlement-month-view page-container">
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
        <button class="btn-add" @click="openRegisterMonth">정산월 등록</button>
      </div>
    </div>

    <!-- 테이블카드 -->
    <div class="table-card">
      <DataTable :value="filteredMonthList" :loading="loading" :paginator="false" scrollable :scrollHeight="'calc(100vh - 220px)'">
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
              class="ellipsis-cell blue-underline"
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
        <Column header="삭제" :style="{ width: columnWidths.delete, textAlign: columnAligns.delete }">
          <template #body="slotProps">
            <button class="btn-delete-sm" @click="deleteMonth(slotProps.data)">삭제</button>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 정산월 등록 -->
    <div v-if="showRegisterDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <label class="modai-title">정산월 등록</label>
        <div class="modal-body">
          <label>정산월</label>
          <input type="month" v-model="newMonth" />
          <label style="margin-top:1rem;">전달사항</label>
          <textarea v-model="newNote" rows="12" style="width:100%; margin-bottom: 2.5rem;"></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeRegisterDialog">취소</button>
          <button class="btn-add" @click="registerMonth" :disabled="registerLoading">등록</button>
        </div>
      </div>
    </div>

    <!-- 전달사항 팝업 -->
    <div v-if="showNoteDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <label class="modai-title">전달사항</label>
        <div class="modal-body">
          <div v-if="!noteEditMode" style="white-space: pre-line;">{{ noteValue }}</div>
          <textarea v-else v-model="noteValue" rows="12" style="width:100%; margin-bottom:2.5rem;"></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-edit" v-if="!noteEditMode" @click="startEditNote">수정</button>
          <button class="btn-primary" v-if="!noteEditMode" @click="closeNoteDialog">확인</button>
          <button class="btn-cancel" v-if="noteEditMode" @click="cancelEditNote">취소</button>
          <button class="btn-add" v-if="noteEditMode" @click="saveNote">저장</button>
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

const showRegisterDialog = ref(false);
const newMonth = ref('');
const newNote = ref('');
const registerLoading = ref(false);

const selectedMonth = ref('');
const monthOptions = ref([]);

// 전달사항 팝업 상태
const showNoteDialog = ref(false);
const noteEditMode = ref(false);
const noteMonth = ref('');
const noteValue = ref('');
const noteOrigin = ref('');

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  settlement_month: '8%',
  note: '32%',
  company_name: '8%',
  hospital_name: '8%',
  prescription_count: '8%',
  prescription_amount: '8%',
  payment_amount: '8%',
  detail: '8%',
  delete: '8%'
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  settlement_month: 'center',
  note: 'left',
  company_name: 'center',
  hospital_name: 'center',
  prescription_count: 'center',
  prescription_amount: 'right',
  payment_amount: 'right',
  detail: 'center',
  delete: 'center'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  settlement_month: true,
  note: true,
  company_name: true,
  hospital_name: true,
  prescription_count: true,
  prescription_amount: true,
  payment_amount: true
};

// 컬럼 배열 한 곳에서 관리
const columns = [
  { field: 'settlement_month', header: '정산월' },
  { field: 'note', header: '전달사항' },
  { field: 'company_name', header: '정산업체' },
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
    monthOptions.value = data.map(row => row.settlement_month);
  }
};

// 필터링된 리스트
const filteredMonthList = computed(() => {
  if (!selectedMonth.value) return monthList.value;
  return monthList.value.filter(item => item.settlement_month === selectedMonth.value);
});

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

    // 2. settlements에서 모든 데이터 가져오기
    const { data: settlements, error: settlementsError } = await supabase
      .from('settlements')
      .select('*');
    if (settlementsError) throw settlementsError;

    // 3. 월별로 집계
    monthList.value = months.map(monthRow => {
      const month = monthRow.settlement_month;
      const rows = settlements.filter(r => r.settlement_month === month);
      const companySet = new Set(rows.map(r => r.company_name));
      const hospitalSet = new Set(rows.map(r => r.hospital_name));
      const prescription_count = rows.length;
      const prescription_amount = rows.reduce((sum, r) => sum + (Number(r.prescription_amount) || 0), 0);
      const payment_amount = rows.reduce((sum, r) => sum + (Number(r.payment_amount) || 0), 0);
      return {
        settlement_month: month,
        company_name: companySet.size,
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
  await fetchMonthOptions();
  await fetchMonthList();
});

const downloadExcel = () => {
  if (!monthList.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  const headers = [
    '정산월', '업체수', '병의원수', '처방건수', '처방액', '지급액', '전달사항'
  ];
  const data = monthList.value.map(item => [
    item.settlement_month,
    item.company_name,
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
const openRegisterMonth = () => {
  showRegisterDialog.value = true;
  newMonth.value = '';
  newNote.value = '';
};
const closeRegisterDialog = () => {
  showRegisterDialog.value = false;
};
const registerMonth = async () => {
  if (!newMonth.value) {
    alert('정산월을 선택하세요.');
    return;
  }
  registerLoading.value = true;
  try {
    // settlement_months 테이블에 insert
    const { error } = await supabase.from('settlement_months').insert({
      settlement_month: newMonth.value,
      note: newNote.value || null,
      created_at: new Date().toISOString(),
      // created_by: (추후 로그인 연동 시 추가)
    });
    if (error) throw error;
    alert('정산월이 등록되었습니다.');
    showRegisterDialog.value = false;
    fetchMonthList();
  } catch (e) {
    alert('등록 실패: ' + e.message);
  }
  registerLoading.value = false;
};
const openNotePopup = (row) => {
  noteMonth.value = row.settlement_month;
  noteValue.value = row.note;
  noteOrigin.value = row.note;
  noteEditMode.value = false;
  showNoteDialog.value = true;
};
const closeNoteDialog = () => {
  showNoteDialog.value = false;
  noteEditMode.value = false;
};
const startEditNote = () => {
  noteEditMode.value = true;
};
const cancelEditNote = () => {
  noteEditMode.value = false;
  noteValue.value = noteOrigin.value;
};
const saveNote = async () => {
  try {
    const { error } = await supabase
      .from('settlement_months')
      .update({ note: noteValue.value, updated_at: new Date().toISOString() })
      .eq('settlement_month', noteMonth.value);
    if (error) throw error;
    alert('전달사항이 저장되었습니다.');
    showNoteDialog.value = false;
    fetchMonthList();
  } catch (e) {
    alert('저장 실패: ' + e.message);
  }
  noteEditMode.value = false;
};
const goDetail = (row) => {
  // 상세화면(월별 상세)로 이동, 정산월 파라미터 전달
  router.push({ path: '/admin/settlement/list', query: { month: row.settlement_month } });
};
const deleteMonth = async (row) => {
  if (!confirm(`${row.settlement_month} 정산월을 삭제하시겠습니까?`)) return;
  try {
    const { error } = await supabase
      .from('settlement_months')
      .delete()
      .eq('settlement_month', row.settlement_month);
    if (error) throw error;
    alert('삭제되었습니다.');
    fetchMonthList();
    fetchMonthOptions && fetchMonthOptions(); // 옵션도 새로고침
  } catch (e) {
    alert('삭제 실패: ' + e.message);
  }
};
</script>

<style scoped>
.ellipsis-cell {
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  cursor: pointer;
  vertical-align: middle;
}
.blue-underline {
  border-bottom: 1.5px solid #1976d2;
  color: #1976d2;
}
</style>
