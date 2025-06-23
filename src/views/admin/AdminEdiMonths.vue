<template>
  <div class="admin-edi-months-view page-container">
    <!-- 상단: 필터 -->
    <div class="filter-card search-center-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <InputText v-model="filters['global'].value" placeholder="비고 내용 검색" class="input-search" />
        </span>
      </div>
    </div>

    <!-- 중간: 기능 버튼 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalRecords }}건</div>
      <Button label="신규 등록" icon="pi pi-plus" class="btn-add" @click="openModal(null)" />
    </div>

    <!-- 하단: 데이터 테이블 -->
    <div class="table-card">
      <DataTable 
        :value="tableData" 
        :loading="loading"
        v-model:filters="filters"
        :globalFilterFields="['remarks']"
        scrollable 
        scrollHeight="calc(100vh - 204px)"
        sortMode="multiple"
      >
        <Column 
          v-for="col in columns"
          :key="col.field"
          :field="col.field"
          :header="col.header"
          :sortable="col.sortable"
          :headerStyle="{ width: col.width }"
          :bodyStyle="{ 'text-align': col.align }"
        >
          <template #body="slotProps">
            <div v-if="col.field === 'index'">
              {{ totalRecords - slotProps.index }}
            </div>
            <div v-else-if="col.field === 'edit'">
              <Button icon="pi pi-pencil"
                class="p-button-rounded p-button-text btn-icon-edit"
                @click="openModal(slotProps.data)"
              />
            </div>
            <div v-else-if="col.field === 'delete'">
              <Button icon="pi pi-trash"
                class="p-button-rounded p-button-text btn-icon-danger"
                @click="confirmDelete(slotProps.data.id)"
              />
            </div>
            <div v-else>
              {{ slotProps.data[col.field] }}
            </div>
          </template>
        </Column>
      </DataTable>
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
              <label for="form-label">정산월 *</label>
              <date-picker 
                v-model:value="settlementMonth" 
                type="month" 
                format="YYYY-MM"
                value-type="format"
                class="input-mordal-datepicker"
              />
            </div>
            <div class="form-group">
              <label for="form-label">제출 시작일 *</label>
              <date-picker 
                v-model:value="currentItem.start_date" 
                type="date" 
                format="YYYY-MM-DD" 
                class="input-mordal-datepicker" 
                :lang="lang"
              />
            </div>
            <div class="form-group">
              <label for="form-label">제출 마감일 *</label>
              <date-picker 
                v-model:value="currentItem.end_date" 
                type="date" 
                format="YYYY-MM-DD" 
                class="input-mordal-datepicker" 
                :lang="lang"
              />
            </div>
            <div class="form-group">
              <label for="form-label">비고</label>
              <Textarea id="remarks"
                v-model="currentItem.remarks"
                rows="8"
                class="input-mordal"
                placeholder="회원 전달 사항을 입력하세요"
              />
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <Button label="취소" severity="secondary" @click="isModalVisible = false" class="btn-cancel"/>
          <Button label="저장" @click="saveItem" class="btn-add"/>
        </div>
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
import DatePicker from 'vue-datepicker-next';
import 'vue-datepicker-next/index.css';
import ko from 'vue-datepicker-next/locale/ko';

const data = ref([]);
const loading = ref(false);
const totalRecords = ref(0);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });

const columnDefs = [
  { field: 'index', header: '순번' },
  { field: 'settlement_month', header: '정산월' },
  { field: 'start_date', header: '제출 시작일' },
  { field: 'end_date', header: '제출 마감일' },
  { field: 'remarks', header: '비고' },
  { field: 'edit', header: '수정' },
  { field: 'delete', header: '삭제' },
];

const columnWidths = {
  index: '4%',
  settlement_month: '10%',
  start_date: '10%',
  end_date: '10%',
  remarks: '50%',
  edit: '8%',
  delete: '8%',
};

const columnAligns = {
  index: 'center',
  settlement_month: 'center',
  start_date: 'center',
  end_date: 'center',
  remarks: 'left',
  edit: 'center',
  delete: 'center',
};

const columnSortables = {
  settlement_month: false,
  start_date: false,
  end_date: false,
};

const columns = computed(() => {
  return columnDefs.map(col => ({
    ...col,
    width: columnWidths[col.field],
    align: columnAligns[col.field],
    sortable: columnSortables[col.field] || false,
  }));
});

const isModalVisible = ref(false);
const currentItem = ref({});
const isEditMode = ref(false);
const settlementMonth = ref('');

const lang = ko;

// 모달 표시 상태에 따라 body에 클래스를 토글
watch(isModalVisible, (isVisible) => {
  if (isVisible) {
    document.body.classList.add('modal-open');
  } else {
    document.body.classList.remove('modal-open');
  }
});

const modalTitle = computed(() => isEditMode.value ? 'EDI 제출월 수정' : 'EDI 제출월 등록');

const tableData = computed(() => data.value);

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

onMounted(fetchData);

const openModal = (item) => {
  if (item) {
    isEditMode.value = true;
    currentItem.value = { 
      ...item,
      start_date: new Date(item.start_date),
      end_date: new Date(item.end_date),
    };
    if (item.settlement_month) {
        settlementMonth.value = item.settlement_month;
    }
  } else {
    isEditMode.value = false;
    const today = new Date();
    const nextMonthDate = new Date(today.getFullYear(), today.getMonth() + 1, 1);
    const year = nextMonthDate.getFullYear();
    const month = String(nextMonthDate.getMonth() + 1).padStart(2, '0');
    settlementMonth.value = `${year}-${month}`;
    
    currentItem.value = {
      start_date: new Date(),
      end_date: new Date(),
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
  if (!settlementMonth.value) {
    alert('정산월이 지정되지 않았습니다.');
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
    settlement_month: settlementMonth.value,
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
</script>
