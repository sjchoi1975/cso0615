<template>
  <div class="admin-hospitals-view page-container">
    <!-- Filter Card -->
    <div class="filter-card custom-auto-height">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="병원명, 원장명, 사업자번호, 주소 검색" class="input-search" />
        </span>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card custom-auto-height">
      <div class="total-count total-count-nowrap">총 {{ totalCount.toLocaleString() }}개 병의원</div>
      <div style="display: flex; gap:0.5rem; align-items:center;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운</button>
        <button class="btn-add" @click="downloadTemplate">템플릿</button>
        <label class="btn-add" style="margin-bottom:0; cursor:pointer;">
          엑셀 등록
          <input type="file" accept=".xlsx,.xls" @change="uploadExcel" style="display:none;" />
        </label>
        <button class="btn-add" @click="openCreateModal">병원 등록</button>
        <button class="btn-danger" @click="deleteAllHospitals">전체 삭제</button>
      </div>
    </div>

    <!-- Table Card -->
    <div class="table-card admin-hospitals-view-table">
      <DataTable
        :value="hospitals"
        :loading="loading"
        :paginator="false"
        scrollable
        :scrollHeight="'calc(100vh - 220px)'"
        ref="tableRef"
      >
        <Column header="순번" :style="{ width: columnWidths.index }" :bodyStyle="{ textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ first + slotProps.index + 1 }}
          </template>
        </Column>
        <Column field="hospital_name" header="병원명" :sortable="columnSortables.hospital_name" :style="{ width: columnWidths.hospital_name }" :bodyStyle="{ textAlign: columnAligns.hospital_name }"></Column>
        <Column field="business_registration_number" header="사업자등록번호" :sortable="columnSortables.business_registration_number" :style="{ width: columnWidths.business_registration_number }" :bodyStyle="{ textAlign: columnAligns.business_registration_number }"></Column>
        <Column field="director_name" header="원장명" :sortable="columnSortables.director_name" :style="{ width: columnWidths.director_name }" :bodyStyle="{ textAlign: columnAligns.director_name }"></Column>
        <Column field="address" header="주소" :sortable="columnSortables.address" :style="{ width: columnWidths.address }" :bodyStyle="{ textAlign: columnAligns.address }"></Column>
        <Column field="created_at" header="등록일" :sortable="columnSortables.created_at" :style="{ width: columnWidths.created_at }" :bodyStyle="{ textAlign: columnAligns.created_at }">
          <template #body="slotProps">
            {{ new Date(slotProps.data.created_at).toLocaleDateString() }}
          </template>
        </Column>
        <Column header="관리" :style="{ width: columnWidths.manage }" :bodyStyle="{ textAlign: columnAligns.manage }">
          <template #body="slotProps">
            <button class="btn-edit" @click="openEditModal(slotProps.data)">수정</button>
            <button class="btn-delete" @click="deleteHospital(slotProps.data)">삭제</button>
          </template>
        </Column>
      </DataTable>
      <div v-if="loading" class="table-loading-spinner-center">
        <img src="/spinner.svg" alt="로딩중" />
      </div>
    </div>

    <!-- Paginator -->
    <div class="fixed-paginator">
      <Paginator
        :rows="pageSize"
        :totalRecords="totalCount"
        :first="first"
        :rowsPerPageOptions="[100, 200, 500]"
        @page="onPageChange"
      />
    </div>

    <!-- Hospital Create/Edit Modal -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">{{ isEdit ? '병원 수정' : '병원 등록' }}</h3>
          <button class="btn-close" @click="closeModal">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">병원명 *</label>
            <input v-model="formData.hospital_name" type="text" class="input-field" placeholder="병원명을 입력하세요" required />
          </div>
          <div class="form-group">
            <label class="form-label">사업자등록번호 *</label>
            <input v-model="formData.business_registration_number" type="text" class="input-field" placeholder="사업자등록번호를 입력하세요" required />
          </div>
          <div class="form-group">
            <label class="form-label">원장명 *</label>
            <input v-model="formData.director_name" type="text" class="input-field" placeholder="원장명을 입력하세요" required />
          </div>
          <div class="form-group">
            <label class="form-label">주소 *</label>
            <input v-model="formData.address" type="text" class="input-field" placeholder="주소를 입력하세요" required />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeModal">취소</button>
          <button class="btn-primary" @click="saveHospital" :disabled="!isFormValid || loading">
            {{ loading ? '저장 중...' : (isEdit ? '수정' : '등록') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import * as XLSX from 'xlsx';
import Paginator from 'primevue/paginator';

// Column definitions
const columnWidths = {
  index: '5%',
  hospital_name: '20%',
  business_registration_number: '15%',
  director_name: '15%',
  address: '25%',
  created_at: '10%',
  manage: '10%'
};
const columnSortables = {
  hospital_name: true,
  business_registration_number: true,
  director_name: true,
  address: true,
  created_at: true,
};
const columnAligns = {
  index: 'center',
  hospital_name: 'left',
  business_registration_number: 'center',
  director_name: 'left',
  address: 'left',
  created_at: 'center',
  manage: 'center'
};

// Component state
const hospitals = ref([]);
const loading = ref(false);
const search = ref('');
const first = ref(0);
const totalCount = ref(0);
const pageSize = ref(100);
const tableRef = ref(null);
const appliedSearch = ref('');

// Modal state
const showModal = ref(false);
const isEdit = ref(false);
const formData = ref({
  id: null,
  hospital_name: '',
  business_registration_number: '',
  director_name: '',
  address: ''
});
const isFormValid = computed(() => {
  return formData.value.hospital_name.trim() &&
         formData.value.business_registration_number.trim() &&
         formData.value.director_name.trim() &&
         formData.value.address.trim();
});

// Data fetching
const fetchHospitals = async (pageFirst = 0, pageRows = 100) => {
  loading.value = true;
  let query = supabase
    .from('hospitals')
    .select('*', { count: 'exact' });

  if (appliedSearch.value) {
    const keyword = `%${appliedSearch.value}%`;
    query = query.or(`hospital_name.ilike.${keyword},director_name.ilike.${keyword},business_registration_number.ilike.${keyword},address.ilike.${keyword}`);
  }

  const from = pageFirst;
  const to = from + pageRows - 1;
  query = query.range(from, to).order('created_at', { ascending: false });

  const { data, error, count } = await query;
  
  if (!error) {
    hospitals.value = data;
    totalCount.value = count || 0;
  } else {
    alert('데이터 로드 실패: ' + error.message);
  }
  loading.value = false;
};

onMounted(() => {
  fetchHospitals(0, pageSize.value);
});

// 실시간 검색을 위한 watch 추가
let debounceTimer = null;
watch(search, (newValue) => {
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    first.value = 0;
    appliedSearch.value = newValue.trim();
    fetchHospitals(0, pageSize.value);
  }, 300); // 300ms 디바운스
});

// Event handlers
const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchHospitals(event.first, event.rows);
};

const downloadExcel = () => {
  const exportData = hospitals.value.map((row, index) => ({
    '순번': first.value + index + 1,
    '병원명': row.hospital_name,
    '사업자등록번호': row.business_registration_number,
    '원장명': row.director_name,
    '주소': row.address,
    '등록일': new Date(row.created_at).toLocaleDateString(),
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '병의원목록');
  XLSX.writeFile(wb, `hospitals_list_${new Date().toISOString().slice(0, 10)}.xlsx`);
};

const downloadTemplate = () => {
  const headers = ['병원명', '사업자등록번호', '원장명', '주소'];
  const exampleRow = ['예시병원', '123-45-67890', '홍길동', '서울시 강남구 테헤란로 123'];
  const ws = XLSX.utils.aoa_to_sheet([headers, exampleRow]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '병원목록 템플릿');
  XLSX.writeFile(wb, `hospitals_template_${new Date().toISOString().slice(0,10)}.xlsx`);
};

const uploadExcel = async (e) => {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = async (evt) => {
    try {
    const data = evt.target.result;
    const workbook = XLSX.read(data, { type: 'binary' });
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const json = XLSX.utils.sheet_to_json(sheet);
      
      const rowsToInsert = json.map(row => ({
        hospital_name: row['병원명'],
        business_registration_number: row['사업자등록번호'] ? String(row['사업자등록번호']) : null,
        director_name: row['원장명'],
        address: row['주소'],
      })).filter(r => r.hospital_name && r.business_registration_number);

      if (rowsToInsert.length === 0) {
        alert('엑셀에 등록할 유효한 데이터가 없습니다. "병원명"과 "사업자등록번호"는 필수입니다.');
      return;
    }

      loading.value = true;
      const { error } = await supabase.from('hospitals').insert(rowsToInsert);
      loading.value = false;

      if (error) throw error;
      
      alert(`${rowsToInsert.length}개의 병원이 성공적으로 등록되었습니다.`);
      fetchHospitals(first.value, pageSize.value);

    } catch (error) {
      loading.value = false;
      alert('엑셀 등록 실패: ' + error.message);
    } finally {
      e.target.value = '';
    }
  };
  reader.readAsBinaryString(file);
};

const deleteAllHospitals = async () => {
  if (!confirm(`현재 조건에 맞는 모든 병원 데이터를 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) return;
  
  loading.value = true;
  let query = supabase.from('hospitals').delete();

  if (appliedSearch.value) {
    const keyword = `%${appliedSearch.value}%`;
    query = query.or(`hospital_name.ilike.${keyword},director_name.ilike.${keyword},business_registration_number.ilike.${keyword},address.ilike.${keyword}`);
  }
  
  const { error } = await query;
  loading.value = false;

  if (error) {
    alert('삭제 실패: ' + error.message);
  } else {
    alert('삭제 완료!');
    fetchHospitals(0, pageSize.value);
  }
};

// CRUD operations
const openCreateModal = () => {
  isEdit.value = false;
  formData.value = {
    id: null,
    hospital_name: '',
    business_registration_number: '',
    director_name: '',
    address: ''
  };
  showModal.value = true;
};

const openEditModal = (hospital) => {
  isEdit.value = true;
  formData.value = { ...hospital };
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
};

const saveHospital = async () => {
  if (!isFormValid.value) {
    alert('모든 필수 항목을 입력해주세요.');
    return;
  }
  loading.value = true;
  
  const hospitalData = {
    hospital_name: formData.value.hospital_name.trim(),
    business_registration_number: formData.value.business_registration_number.trim(),
    director_name: formData.value.director_name.trim(),
    address: formData.value.address.trim(),
  };

  try {
    let error;
    if (isEdit.value) {
      const { error: updateError } = await supabase
        .from('hospitals')
        .update(hospitalData)
        .eq('id', formData.value.id);
      error = updateError;
    } else {
      const { error: insertError } = await supabase
        .from('hospitals')
        .insert([hospitalData]);
      error = insertError;
    }

    if (error) throw error;
    
    alert(`병원 정보가 성공적으로 ${isEdit.value ? '수정' : '등록'}되었습니다.`);
    closeModal();
    fetchHospitals(first.value, pageSize.value);

  } catch (e) {
    alert('저장 실패: ' + e.message);
  } finally {
    loading.value = false;
  }
};

const deleteHospital = async (hospital) => {
  if (!confirm(`'${hospital.hospital_name}' 병원을 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) return;

  loading.value = true;
  const { error } = await supabase.from('hospitals').delete().eq('id', hospital.id);
  loading.value = false;

  if (error) {
    alert('삭제 실패: ' + error.message);
  } else {
    alert('삭제 완료!');
    fetchHospitals(first.value, pageSize.value);
  }
};
</script>

<style scoped>
.btn-edit {
  margin-right: 0.5rem;
}
.custom-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.custom-modal {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.3);
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #e5e7eb;
}
.modal-title {
  font-size: 1.25rem;
  font-weight: 600;
}
.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
}
.modal-body {
  padding: 1.5rem;
}
.form-group {
  margin-bottom: 1rem;
}
.form-label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}
.input-field {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 4px;
}
.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
  padding: 1rem 1.5rem;
  border-top: 1px solid #e5e7eb;
}
.btn-secondary {
  padding: 0.5rem 1rem;
  background: #6b7280;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.btn-primary {
  padding: 0.5rem 1rem;
  background: #10b981;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.btn-primary:disabled {
  background: #9ca3af;
  cursor: not-allowed;
}
</style>
