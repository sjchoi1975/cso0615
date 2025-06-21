<template>
  <div class="admin-edi-months-view page-container">
    <!-- 상단: 필터 -->
    <div class="filter-card search-center-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <InputText v-model="filters['global'].value" placeholder="정산월 검색" class="input-search wide-mobile-search" />
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
        :globalFilterFields="['settlement_month']"
        scrollable 
        scrollHeight="calc(100vh - 220px)"
      >
        <Column header="No." headerStyle="width: 5%" bodyStyle="text-align: center">
          <template #body="slotProps">
            {{ totalRecords - slotProps.index }}
          </template>
        </Column>
        <Column field="settlement_month" header="정산월" headerStyle="width: 15%" bodyStyle="text-align: center" />
        <Column field="start_date" header="제출 시작일" headerStyle="width: 20%" bodyStyle="text-align: center" />
        <Column field="end_date" header="제출 마감일" headerStyle="width: 20%" bodyStyle="text-align: center" />
        <Column field="remarks" header="비고" headerStyle="width: 25%" />
        <Column header="수정" headerStyle="width: 7.5%" bodyStyle="text-align: center">
          <template #body="slotProps">
            <Button icon="pi pi-pencil" class="p-button-rounded p-button-info p-button-text" @click="openModal(slotProps.data)" />
          </template>
        </Column>
        <Column header="삭제" headerStyle="width: 7.5%" bodyStyle="text-align: center">
          <template #body="slotProps">
            <Button icon="pi pi-trash" class="p-button-rounded p-button-danger p-button-text" @click="confirmDelete(slotProps.data.id)" />
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
          <table class="mordal-table">
            <colgroup>
              <col style="width: 120px;">
              <col>
            </colgroup>
            <tbody>
              <tr>
                <th>정산월</th>
                <td>
                  <div class="radio-group-row">
                    <Dropdown v-model="selectedYear"
                      :options="yearOptions" placeholder="연도 선택" style="flex: 1;" />
                    <Dropdown v-model="selectedMonth"
                      :options="monthOptions" placeholder="월 선택" style="flex: 1;" />
                  </div>
                </td>
              </tr>
              <tr>
                <th>제출 시작일</th>
                <td><Calendar id="startDate" 
                  v-model="currentItem.start_date" 
                  dateFormat="yy-mm-dd" 
                  showIcon style="width: 100%;" /></td>
              </tr>
              <tr>
                <th>제출 마감일</th>
                <td><Calendar id="endDate" 
                  v-model="currentItem.end_date" 
                  dateFormat="yy-mm-dd" 
                  showIcon style="width: 100%;" /></td>
              </tr>
              <tr>
                <th>비고</th>
                <td><Textarea id="remarks"
                  v-model="currentItem.remarks" rows="4" 
                  class="input-table" style="width: 100%;" /></td>
              </tr>
            </tbody>
          </table>
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
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Calendar from 'primevue/calendar';
import Textarea from 'primevue/textarea';
import Dropdown from 'primevue/dropdown';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";

const confirm = useConfirm();
const toast = useToast();

const data = ref([]);
const loading = ref(false);
const totalRecords = ref(0);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });

const isModalVisible = ref(false);
const currentItem = ref({});
const isEditMode = ref(false);

const selectedYear = ref(null);
const selectedMonth = ref(null);

const yearOptions = computed(() => {
  const currentYear = new Date().getFullYear();
  return Array.from({ length: 5 }, (_, i) => currentYear - i);
});
const monthOptions = computed(() => Array.from({ length: 12 }, (_, i) => i + 1));

const modalTitle = computed(() => isEditMode.value ? 'EDI 제출월 수정' : 'EDI 제출월 등록');

const tableData = computed(() => data.value);

const fetchData = async () => {
  loading.value = true;
  const { data: records, error, count } = await supabase
    .from('edi_submission_periods')
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
        const [year, month] = item.settlement_month.split('-').map(Number);
        selectedYear.value = year;
        selectedMonth.value = month;
    }
  } else {
    isEditMode.value = false;
    const today = new Date();
    const nextMonthDate = new Date(today.getFullYear(), today.getMonth() + 1, 1);
    
    selectedYear.value = nextMonthDate.getFullYear();
    selectedMonth.value = nextMonthDate.getMonth() + 1;
    
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
  if (!selectedYear.value || !selectedMonth.value) {
    toast.add({ severity: 'warn', summary: '경고', detail: '정산월의 연도와 월을 모두 선택하세요.', life: 3000 });
    return;
  }

  const settlementMonthStr = `${selectedYear.value}-${String(selectedMonth.value).padStart(2, '0')}`;
  
  const itemToSave = {
    ...currentItem.value,
    settlement_month: settlementMonthStr,
    start_date: formatDateToSupabase(currentItem.value.start_date),
    end_date: formatDateToSupabase(currentItem.value.end_date),
  };

  let error;
  if (isEditMode.value) {
    // Update
    ({ error } = await supabase.from('edi_submission_periods').update(itemToSave).eq('id', itemToSave.id));
  } else {
    // Create
    const { id, ...newItem } = itemToSave;
    ({ error } = await supabase.from('edi_submission_periods').insert([newItem]));
  }

  if (error) {
    toast.add({ severity: 'error', summary: '오류', detail: `저장 실패: ${error.message}`, life: 3000 });
  } else {
    toast.add({ severity: 'success', summary: '성공', detail: '성공적으로 저장되었습니다.', life: 3000 });
    isModalVisible.value = false;
    fetchData();
  }
};

const confirmDelete = (id) => {
  confirm.require({
    message: '이 항목을 삭제하시겠습니까?',
    header: '삭제 확인',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: '삭제',
    rejectLabel: '취소',
    accept: async () => {
      const { error } = await supabase.from('edi_submission_periods').delete().eq('id', id);
      if (error) {
        toast.add({ severity: 'error', summary: '오류', detail: '삭제 실패', life: 3000 });
      } else {
        toast.add({ severity: 'info', summary: '성공', detail: '삭제되었습니다.', life: 3000 });
        fetchData();
      }
    },
  });
};
</script>
