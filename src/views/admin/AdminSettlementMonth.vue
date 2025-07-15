<template>
  <div class="admin-settlement-month-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <div class="filter-card">
      <div class="filter-row">
        <span>정산월</span>
        <select v-model="selectedMonth" class="input-120">
          <option value="">- 전체 -</option>
          <option v-for="m in monthOptions" :key="m" :value="m">
            {{ m.slice(0,4) + '년 ' + parseInt(m.slice(5,7)) + '월' }}
          </option>
        </select>
      </div>
    </div>
    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
      <div style="display: flex; gap: 1rem;">
        <Button
          icon="pi pi-download"
          label="다운로드"
          class="btn-download-md"
          @click="downloadExcel"
          iconPos="left"
          style="gap:0.5em;"
        />
        <Button
          icon="pi pi-pencil"
          label="정산월 등록"
          class="btn-add-md"
          @click="openRegisterMonth"
          iconPos="left"
          style="gap:0.5em;"
        />
      </div>
    </div>

    <!-- 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="filteredMonthList"
          :loading="false"
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
                {{ slotProps.index + 1 }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'edit'">
                <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="openRegisterMonth(slotProps.data, true)" v-tooltip.top="'수정'" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'delete'">
                <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="deleteMonth(slotProps.data)" v-tooltip.top="'삭제'" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'detail'">
                <button class="p-button p-button-text p-button-rounded icon-only-btn" @click="goDetail(slotProps.data)" v-tooltip.top="'상세보기'">
                  <i class="pi pi-list" style="font-size: 1.2rem; color: #4B5563;"></i>
                </button>
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'share'">
                <button class="p-button p-button-text p-button-rounded icon-only-btn" @click="goToShare(slotProps.data)" v-tooltip.top="'공유 화면'">
                  <i class="pi pi-share-alt" style="font-size: 1.2rem; color: #1976d2;"></i>
                </button>
              </template>
              <template v-else-if="col.field === 'prescription_amount'">
                {{ Number(slotProps.data.prescription_amount).toLocaleString() }}
              </template>
              <template v-else-if="col.field === 'total_amount'">
                {{ Number(slotProps.data.total_amount).toLocaleString() }}
              </template>
              <template v-else-if="col.field === 'note'">
                <span v-if="slotProps.data.note" class="link" @click="openNotePopup(slotProps.data)" style="cursor: pointer;" :title="slotProps.data.note">
                  {{ slotProps.data.note }}
                </span>
              </template>
              <template v-else-if="col.field === 'settlement_month'">
                <span class="table-title-link">{{ formatSettlementMonth(slotProps.data.settlement_month) }}</span>
              </template>
              <template v-else>
                {{ slotProps.data[col.field] }}
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- 정산월 등록/수정 모달 -->
    <div v-if="showRegisterDialog" class="custom-modal-overlay" @click.self="closeRegisterDialog">
      <div class="custom-modal">
        <div class="modal-header">
          <div class="modal-title">{{ isEditMode ? '정산월 수정' : '정산월 등록' }}</div>
        </div>
        <div class="modal-body">
          <div class="form-grid">
            <div class="form-group">
              <label>정산월</label>
              <select v-model="newMonth" class="input" :disabled="isEditMode">
                <option value="">- 선택 -</option>
                <option v-for="opt in registerMonthOptions" :key="opt" :value="opt">
                  {{ opt.slice(0,4) + '년 ' + parseInt(opt.slice(5,7)) + '월' }}
                </option>
              </select>
            </div>
            <div class="form-group">
              <label>전달사항</label>
              <Textarea id="note"
                v-model="newNote"
                rows="8"
                class="input"
                placeholder="회원 전달 사항을 입력하세요"
              />
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeRegisterDialog">취소</button>
          <button class="btn-confirm modal" @click="registerMonth" :disabled="registerLoading">저장</button>
        </div>
      </div>
    </div>
    
    <!-- 전달사항 팝업 모달 -->
    <div v-if="showNoteDialog" class="custom-modal-overlay" @click.self="closeNoteDialog">
      <div class="custom-modal">
        <div class="modal-header">
          <div class="modal-title">전달사항</div>
        </div>
        <div class="modal-body">
          <div style="white-space: pre-line;">{{ noteValue }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeNoteDialog">닫기</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import * as XLSX from 'xlsx';
import Button from 'primevue/button';
import Datepicker from 'vue3-datepicker';
import { settlementMonthTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import Textarea from 'primevue/textarea';

const router = useRouter();

const monthList = ref([]); // 월별 현황 데이터
const loading = ref(false);
const totalCount = ref(0);

const showRegisterDialog = ref(false);
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

const newMonth = ref("");

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? settlementMonthTableConfig.mobile : settlementMonthTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 없음)
const tableScrollHeight = computed(() => getTableScrollHeight(false, 40));

// 필터링된 리스트
const filteredMonthList = computed(() => {
  if (!selectedMonth.value) return monthList.value;
  return monthList.value.filter(item => item.settlement_month === selectedMonth.value);
});

// DB에서 정산월 목록을 불러오는 함수
const fetchMonthOptions = async () => {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('settlement_month')
    .order('settlement_month', { ascending: false });
  if (!error && data) {
    const unique = Array.from(new Set(data.map(row => row.settlement_month)));
    monthOptions.value = unique;
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
        prescription_amount: Math.round(prescription_amount),
        total_amount: Math.round(payment_amount),
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
    '정산월', '업체수', '병의원수', '처방건수', '처방액', '정산금액', '전달사항'
  ];
  const data = monthList.value.map(item => [
    item.settlement_month,
    item.company_name,
    item.hospital_name,
    item.prescription_count,
    item.prescription_amount ? Math.round(item.prescription_amount).toLocaleString() : '0',
    item.total_amount ? Math.round(item.total_amount).toLocaleString() : '0',
    item.note ? item.note.replace(/\n/g, '\\n') : ''
  ]);
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '월별정산현황');
  const fileName = `월별정산현황_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};

const registerMonthOptions = computed(() => {
  const today = new Date();
  const arr = [];
  for (let i = 1; i >= -3; i--) {
    const d = new Date(today.getFullYear(), today.getMonth() + i, 1);
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    arr.push(`${year}-${month}`); // 'YYYY-MM'
  }
  return arr;
});

const isEditMode = ref(false);
const openRegisterMonth = (row, edit = false) => {
  showRegisterDialog.value = true;
  isEditMode.value = edit;
  if (edit && row) {
    // 수정 모드: 기존 데이터 설정
    newMonth.value = row.settlement_month;
    newNote.value = row.note || '';
  } else {
    // 등록 모드: 초기화
    newMonth.value = "";
    newNote.value = '';
  }
};
const closeRegisterDialog = () => {
  showRegisterDialog.value = false;
  // 모달 닫을 때 상태 초기화
  isEditMode.value = false;
  newMonth.value = "";
  newNote.value = '';
};
const registerMonth = async () => {
  if (!newMonth.value) {
    alert('정산월을 선택하세요.');
    return;
  }
  registerLoading.value = true;
  try {
    const formattedMonth = newMonth.value;

    if (isEditMode.value) {
      // 수정 모드: update 쿼리 사용
      const { error } = await supabase
        .from('settlement_months')
        .update({
          note: newNote.value || null,
          updated_at: new Date().toISOString(),
          // updated_by: (추후 로그인 연동 시 추가)
        })
        .eq('settlement_month', formattedMonth);
      
      if (error) throw error;
      alert('정산월이 수정되었습니다.');
    } else {
      // 등록 모드: insert 쿼리 사용
      const { error } = await supabase.from('settlement_months').insert({
        settlement_month: formattedMonth,
        note: newNote.value || null,
        created_at: new Date().toISOString(),
        // created_by: (추후 로그인 연동 시 추가)
      });
      if (error) throw error;
      alert('정산월이 등록되었습니다.');
    }
    
    showRegisterDialog.value = false;
    fetchMonthList();
  } catch (e) {
    alert(isEditMode.value ? '수정 실패: ' + e.message : '등록 실패: ' + e.message);
  }
  registerLoading.value = false;
};
const goDetail = (data) => {
  router.push(`/admin/settlement/month/${data.settlement_month}`);
};
const openUploadDialog = (data) => {
  // TODO: 등록(업로드) 관련 로직 구현
  alert(`${data.settlement_month} 정산 데이터 등록 로직을 여기에 추가해야 합니다.`);
};
const deleteMonth = async (row) => {
  if (!confirm(`${row.settlement_month} 정산월을 삭제하시겠습니까?\n\n※ 주의: 해당 정산월의 모든 관련 데이터(정산내역, 공유설정 등)가 함께 삭제됩니다.`)) return;
  
  try {
    // 트랜잭션을 사용하여 모든 관련 데이터를 안전하게 삭제
    const { data, error } = await supabase.rpc('delete_settlement_month_with_related_data', {
      target_settlement_month: row.settlement_month
    });
    
    if (error) {
      console.error('정산월 삭제 RPC 오류:', error);
      throw new Error(`정산월 삭제 실패: ${error.message}`);
    }

    alert('정산월과 관련된 모든 데이터가 성공적으로 삭제되었습니다.');
    fetchMonthList();
    fetchMonthOptions && fetchMonthOptions(); // 옵션도 새로고침
  } catch (e) {
    console.error('정산월 삭제 중 오류 발생:', e);
    alert('삭제 실패: ' + e.message);
  }
};

// 공지사항 팝업 열기
const openNotePopup = (row) => {
  noteValue.value = row.note;
  showNoteDialog.value = true;
};

// 공지사항 팝업 닫기
const closeNoteDialog = () => {
  showNoteDialog.value = false;
};

// monthOptions가 변경될 때마다 selectedMonth의 기본값을 전체로 설정
watch(monthOptions, (opts) => {
  if (opts && opts.length > 0) {
    selectedMonth.value = ''; // 기본값을 전체로 설정
  }
}, { immediate: true });

function goToShare(row) {
  router.push({ name: 'AdminSettlementMonthShare', params: { month: row.settlement_month } });
}

// 정산월 포맷 함수 (2025-05 → 2025년 5월)
const formatSettlementMonth = (settlementMonth) => {
  if (!settlementMonth) return '';
  const year = settlementMonth.slice(0, 4);
  const month = parseInt(settlementMonth.slice(5, 7));
  return `${year}년 ${month}월`;
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
.icon-only-btn,
.icon-only-btn:enabled:hover,
.icon-only-btn:enabled:focus {
  background: transparent !important;
  border: none !important;
  box-shadow: none !important;
}

.p-button.icon-only-btn:disabled {
  opacity: 0.4;
}
</style>
