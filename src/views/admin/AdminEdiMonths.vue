<template>
  <div class="admin-edi-months-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span >정산월</span>
        <select v-model="selectedFilterMonth" class="input-120">
          <option value="">- 전체 -</option>
          <option v-for="m in filterMonthOptions" :key="m" :value="m">
            {{ m.slice(0,4) + '년 ' + parseInt(m.slice(5,7)) + '월' }}
          </option>
        </select>
      </div>
    </div>

    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalRecords }}건</div>
      <Button
        icon="pi pi-pencil"
        label="신규 등록"
        class="btn-add-md"
        @click="openModal(null)"
        iconPos="left"
        style="gap:0.5em;"
      />
    </div>

    <!-- 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="tableData"
          :loading="false"
          :paginator="false"
          v-model:filters="filters"
          :globalFilterFields="['remarks']"
          scrollable
          :scrollHeight="tableScrollHeight"
          sortMode="multiple"
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
                {{ totalRecords - slotProps.index }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'edit'">
                <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="openModal(slotProps.data)" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'delete'">
                <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="confirmDelete(slotProps.data.id)" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'detail'">
                <button class="p-button p-button-text p-button-rounded icon-only-btn" @click="goDetail(slotProps.data)" v-tooltip.top="'상세보기'">
                  <i class="pi pi-list" style="font-size: 1.2rem; color: #4B5563;"></i>
                </button>
              </template>
              <template v-else-if="col.field === 'settlement_month'">
                <span class="table-title">{{ formatSettlementMonth(slotProps.data.settlement_month) }}</span>
              </template>
              <template v-else-if="col.field === 'remarks'">
                <span v-if="slotProps.data.remarks" class="link" @click="openNoticeModal(slotProps.data.remarks)">
                  {{ slotProps.data.remarks }}
                </span>
              </template>
              <template v-else>
                {{ slotProps.data[col.field] }}
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>
    
    <!-- 등록/수정 모달 -->
    <div v-if="isModalVisible" class="custom-modal-overlay" @click.self="isModalVisible = false">
      <div class="custom-modal">
        <div class="modal-header">
          <div class="modal-title">{{ modalTitle }}</div>
        </div>
        <div class="modal-body">
          <div class="form-grid">
            <div class="form-group">
              <label>정산월<span class="required">*</span></label>
              <select v-model="newMonth" class="input">
                <option value="">- 선택 -</option>
                <option v-for="opt in registerMonthOptions" :key="opt" :value="opt">
                  {{ opt.slice(0,4) + '년 ' + parseInt(opt.slice(5,7)) + '월' }}
                </option>
              </select>
            </div>
            <div class="form-group">
              <label>제출 시작일<span class="required">*</span></label>
              <Datepicker 
                v-model="currentItem.start_date"
                :locale="ko"
                class="input"
              />
            </div>
            <div class="form-group">
              <label>제출 마감일<span class="required">*</span></label>
              <Datepicker 
                v-model="currentItem.end_date"
                :locale="ko"
                class="input"
              />
            </div>
            <div class="form-group">
              <label>공지사항</label>
              <Textarea id="remarks"
                v-model="currentItem.remarks"
                rows="8"
                class="input"
                placeholder="회원 전달 사항을 입력하세요"
              />
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="isModalVisible = false">취소</button>
          <button class="btn-confirm modal" @click="saveItem">저장</button>
        </div>
      </div>
    </div>
    
    <!-- 공지사항 모달 -->
    <div v-if="showNoticeModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">공지사항</h3></div>
        <div class="modal-body"><div style="white-space: pre-line;">{{ noticeContent }}</div></div>
        <div class="modal-footer"><button @click="closeNoticeModal" class="btn-cancel modal">닫기</button></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import Datepicker from 'vue3-datepicker';
import ko from 'date-fns/locale/ko';
import { ediMonthsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const data = ref([]);
const loading = ref(false);
const totalRecords = ref(0);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? ediMonthsTableConfig.mobile : ediMonthsTableConfig.pc);

const isModalVisible = ref(false);
const currentItem = ref({});
const isEditMode = ref(false);

// 오늘 날짜 기준
const today = new Date()

// 다음달(기본값)
const defaultMonth = new Date(today.getFullYear(), today.getMonth() + 1, 1)

// 1. 정산월 옵션 생성 (year-month 포맷)
const registerMonthOptions = computed(() => {
  const today = new Date();
  const arr = [];
  for (let i = 1; i >= -3; i--) {
    const d = new Date(today.getFullYear(), today.getMonth() + i, 1);
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    arr.push(`${year}-${month}`);
  }
  return arr;
});

// 2. 등록/수정용 v-model 변수 선언
const newMonth = ref("");

// 모달 표시 상태에 따라 body에 클래스를 토글
watch(isModalVisible, (isVisible) => {
  if (isVisible) {
    document.body.classList.add('modal-open');
  } else {
    document.body.classList.remove('modal-open');
  }
});

const modalTitle = computed(() => isEditMode.value ? 'EDI 마감 일정 수정' : 'EDI 마감 일정 등록');

const filterMonthOptions = ref([]);
const selectedFilterMonth = ref('');

const fetchFilterMonthOptions = async () => {
  const { data, error } = await supabase
    .from('edi_months')
    .select('settlement_month')
    .order('settlement_month', { ascending: false });
  if (!error && data) {
    // 중복 제거 + 최신순
    const unique = Array.from(new Set(data.map(row => row.settlement_month)));
    filterMonthOptions.value = unique;
    selectedFilterMonth.value = '';
  }
};

const tableData = computed(() => {
  if (!selectedFilterMonth.value) return data.value;
  return data.value.filter(item => item.settlement_month === selectedFilterMonth.value);
});

const fetchData = async () => {
  loading.value = true;
  const { data: records, error, count } = await supabase
    .from('edi_months')
    .select('*', { count: 'exact' })
    .order('settlement_month', { ascending: false });

  if (error) {
    console.error('Error fetching data:', error);
  } else {
    data.value = records;
    totalRecords.value = count;
  }
  loading.value = false;
};

onMounted(() => {
  fetchData();
  fetchFilterMonthOptions();
});

const openModal = (item) => {
  if (item) {
    isEditMode.value = true;
    currentItem.value = { 
      ...item,
      start_date: new Date(item.start_date),
      end_date: new Date(item.end_date),
    };
    if (item.settlement_month) {
      newMonth.value = item.settlement_month;
    }
  } else {
    isEditMode.value = false;
    newMonth.value = "";
    const today = new Date();
    currentItem.value = {
      start_date: new Date(today.getFullYear(), today.getMonth(), today.getDate() + 3),
      end_date: new Date(today.getFullYear(), today.getMonth(), today.getDate() + 17),
      remarks: '',
    };
  }
  isModalVisible.value = true;
};

const formatDateToSupabase = (date) => {
  if (!date) return null;
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const saveItem = async () => {
  if (!newMonth.value) {
    alert('정산월을 선택하세요.');
    return;
  }
  if (!currentItem.value.start_date) {
    alert('제출 시작일이 지정되지 않았습니다.');
    return;
  }
  if (!currentItem.value.end_date) {
    alert('제출 마감일이 지정되지 않았습니다.');
    return;
  }
  
  const confirmMessage = isEditMode.value ? '해당 정산월 정보를 수정하시겠습니까?' : '신규 정산월 정보를 등록하시겠습니까?';
  if (!window.confirm(confirmMessage)) {
    return;
  }

  const itemToSave = {
    ...currentItem.value,
    settlement_month: newMonth.value,
    start_date: formatDateToSupabase(currentItem.value.start_date),
    end_date: formatDateToSupabase(currentItem.value.end_date),
  };

  let error;
  if (isEditMode.value) {
    // Update
    ({ error } = await supabase.from('edi_months').update(itemToSave).eq('id', itemToSave.id));
  } else {
    // Create
    const { id, ...newItem } = itemToSave;
    ({ error } = await supabase.from('edi_months').insert([newItem]));
  }

  if (error) {
    if (error.message.includes('edi_months_settlement_month_key')) {
      alert('이미 동일한 정산월이 등록되어 있습니다.');
    } else {
      alert(`저장 실패: ${error.message}`);
    }
  } else {
    alert('성공적으로 저장되었습니다.');
    isModalVisible.value = false;
    fetchData();
  }
};

const confirmDelete = (id) => {
  if (window.confirm('해당 정산월 정보를 삭제하시겠습니까?')) {
    deleteItem(id);
  }
};

const deleteItem = async (id) => {
  const { error } = await supabase.from('edi_months').delete().eq('id', id);
  if (error) {
    alert(`삭제 실패: ${error.message}`);
  } else {
    alert('삭제되었습니다.');
    fetchData();
  }
}

// 테이블 스크롤 높이 계산 (페이지네이터 없음)
const tableScrollHeight = computed(() => getTableScrollHeight(false, 40));

const showNoticeModal = ref(false);
const noticeContent = ref('');
function openNoticeModal(content) {
  noticeContent.value = content;
  showNoticeModal.value = true;
}
function closeNoticeModal() {
  showNoticeModal.value = false;
  noticeContent.value = '';
}

// 정산월 포맷 함수 (2025-06 → 2025년 6월)
const formatSettlementMonth = (settlementMonth) => {
  if (!settlementMonth) return '';
  const year = settlementMonth.slice(0, 4);
  const month = parseInt(settlementMonth.slice(5, 7));
  return `${year}년 ${month}월`;
};
</script>

<style>
.ellipsis-cell {
  max-width: 400px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  display: block;
}
</style>
