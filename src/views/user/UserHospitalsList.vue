<template>
  <div class="admin-hospitals-view page-container">
    <!-- Filter Card -->
    <div class="filter-card custom-auto-height">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="거래처명, 원장명, 사업자번호, 주소 검색" class="input-search" />
        </span>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card custom-auto-height">
      <div class="total-count total-count-nowrap">총 {{ totalCount.toLocaleString() }}개 거래처</div>
      <div style="display: flex; gap:0.5rem; align-items:center;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운</button>
        <button class="btn-add" @click="downloadTemplate">템플릿</button>
        <label class="btn-add" style="margin-bottom:0; cursor:pointer;">
          엑셀 등록
          <input type="file" accept=".xlsx,.xls" @change="uploadExcel" style="display:none;" />
        </label>
        <button class="btn-add" @click="openCreateModal">거래처 등록</button>
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
        <Column field="hospital_name" header="거래처명" :sortable="columnSortables.hospital_name" :style="{ width: columnWidths.hospital_name }" :bodyStyle="{ textAlign: columnAligns.hospital_name }"></Column>
        <Column field="business_registration_number" header="사업자등록번호" :sortable="columnSortables.business_registration_number" :style="{ width: columnWidths.business_registration_number }" :bodyStyle="{ textAlign: columnAligns.business_registration_number }"></Column>
        <Column field="director_name" header="원장명" :sortable="columnSortables.director_name" :style="{ width: columnWidths.director_name }" :bodyStyle="{ textAlign: columnAligns.director_name }"></Column>
        <Column field="address" header="주소" :sortable="columnSortables.address" :style="{ width: columnWidths.address }" :bodyStyle="{ textAlign: columnAligns.address }"></Column>
        <Column field="created_at" header="등록일자" :sortable="columnSortables.created_at" :style="{ width: columnWidths.created_at }" :bodyStyle="{ textAlign: columnAligns.created_at }">
          <template #body="slotProps">
            {{ formatDate(slotProps.data.created_at) }}
          </template>
        </Column>
        <Column header="수정" :style="{ width: columnWidths.edit }" :bodyStyle="{ textAlign: columnAligns.edit }">
          <template #body="slotProps">
            <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="openEditModal(slotProps.data)" />
          </template>
        </Column>
        <Column header="삭제" :style="{ width: columnWidths.delete }" :bodyStyle="{ textAlign: columnAligns.delete }">
          <template #body="slotProps">
            <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="deleteHospital(slotProps.data)" />
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
          <h3 class="modal-title">{{ isEdit ? '거래처 수정' : '거래처 등록' }}</h3>
          <button class="btn-close" @click="closeModal">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">거래처명 *</label>
            <input v-model="formData.hospital_name" type="text" class="input-field" placeholder="거래처명을 입력하세요" required />
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
import Button from 'primevue/button';
import * as XLSX from 'xlsx';
import Paginator from 'primevue/paginator';

// Column definitions
const columnWidths = {
  index: '5%',
  hospital_name: '20%',
  business_registration_number: '10%',
  director_name: '10%',
  address: '29%',
  created_at: '10%',
  edit: '8%',
  delete: '8%'
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
  director_name: 'center',
  address: 'left',
  created_at: 'center',
  edit: 'center',
  delete: 'center'
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

// 날짜 포맷팅 함수
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const year = date.getFullYear();
  const month = ('0' + (date.getMonth() + 1)).slice(-2);
  const day = ('0' + date.getDate()).slice(-2);
  return `${year}-${month}-${day}`;
};

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
    .from('hospital_member_mappings')
    .select(`
      *,
      hospitals (
        id,
        hospital_name,
        business_registration_number,
        director_name,
        address,
        registered_at
      )
    `, { count: 'exact' });

  if (appliedSearch.value) {
    const keyword = `%${appliedSearch.value}%`;
    query = query.or(`hospitals.hospital_name.ilike.${keyword},hospitals.director_name.ilike.${keyword},hospitals.business_registration_number.ilike.${keyword},hospitals.address.ilike.${keyword}`);
  }

  const from = pageFirst;
  const to = from + pageRows - 1;
  query = query.range(from, to).order('registered_at', { ascending: false });

  const { data, error, count } = await query;
  
  if (!error) {
    // hospital_member_mappings 데이터를 hospitals 형태로 변환
    hospitals.value = data.map(mapping => ({
      id: mapping.hospitals.id,
      hospital_name: mapping.hospitals.hospital_name,
      business_registration_number: mapping.hospitals.business_registration_number,
      director_name: mapping.hospitals.director_name,
      address: mapping.hospitals.address,
      created_at: mapping.hospitals.registered_at,
      mapping_id: mapping.id // 관계 ID 저장
    }));
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
    '거래처명': row.hospital_name,
    '사업자등록번호': row.business_registration_number,
    '원장명': row.director_name,
    '주소': row.address,
    '등록일': new Date(row.created_at).toLocaleDateString(),
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '거래처목록');
  XLSX.writeFile(wb, `hospitals_list_${new Date().toISOString().slice(0, 10)}.xlsx`);
};

const downloadTemplate = () => {
  const headers = ['거래처명', '사업자등록번호', '원장명', '주소'];
  const exampleRow = ['예시거래처', '123-45-67890', '홍길동', '서울시 강남구 테헤란로 123'];
  const ws = XLSX.utils.aoa_to_sheet([headers, exampleRow]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '거래처목록 템플릿');
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
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('사용자 정보를 찾을 수 없습니다.');

      const rowsToInsert = json.map(row => ({
        hospital_name: row['거래처명'],
        business_registration_number: row['사업자등록번호'] ? String(row['사업자등록번호']) : null,
        director_name: row['원장명'],
        address: row['주소'],
        registered_by: user.id
      })).filter(r => r.hospital_name && r.business_registration_number);

      if (rowsToInsert.length === 0) {
        alert('엑셀에 등록할 유효한 데이터가 없습니다. "거래처명"과 "사업자등록번호"는 필수입니다.');
        return;
      }

      loading.value = true;
      
      // hospitals 테이블에 거래처 추가
      const { data: hospitalResults, error: insertError } = await supabase
        .from('hospitals')
        .insert(rowsToInsert)
        .select();
      
      if (insertError) throw insertError;
      
      // hospital_member_mappings에 관계 추가
      const mappingRows = hospitalResults.map(hospital => ({
        member_id: user.id,
        hospital_id: hospital.id
      }));
      
      const { error: mappingError } = await supabase
        .from('hospital_member_mappings')
        .insert(mappingRows);
      
      if (mappingError) throw mappingError;
      
      loading.value = false;
      alert(`${rowsToInsert.length}개의 거래처가 성공적으로 등록되었습니다.`);
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
  if (!confirm(`현재 조건에 맞는 모든 거래처 데이터를 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) return;
  
  loading.value = true;
  
  try {
    // 현재 로그인한 사용자 ID 가져오기
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('사용자 정보를 찾을 수 없습니다.');
    
    let query = supabase
      .from('hospital_member_mappings')
      .delete()
      .eq('member_id', user.id);

    if (appliedSearch.value) {
      // 검색 조건이 있는 경우, 해당 조건에 맞는 거래처들의 관계만 삭제
      const keyword = `%${appliedSearch.value}%`;
      const { data: targetHospitals } = await supabase
        .from('hospitals')
        .select('id')
        .or(`hospital_name.ilike.${keyword},director_name.ilike.${keyword},business_registration_number.ilike.${keyword},address.ilike.${keyword}`);
      
      if (targetHospitals && targetHospitals.length > 0) {
        const hospitalIds = targetHospitals.map(h => h.id);
        query = supabase
          .from('hospital_member_mappings')
          .delete()
          .eq('member_id', user.id)
          .in('hospital_id', hospitalIds);
      }
    }
    
    const { error } = await query;
    
    if (error) throw error;
    
    alert('삭제 완료!');
    fetchHospitals(0, pageSize.value);
    
  } catch (error) {
    alert('삭제 실패: ' + error.message);
  } finally {
    loading.value = false;
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
  
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    alert('사용자 정보를 찾을 수 없습니다.');
    loading.value = false;
    return;
  }
  
  const hospitalData = {
    hospital_name: formData.value.hospital_name.trim(),
    business_registration_number: formData.value.business_registration_number.trim(),
    director_name: formData.value.director_name.trim(),
    address: formData.value.address.trim(),
  };

  try {
    if (isEdit.value) {
      // 수정
      Object.assign(hospitalData, {
        updated_at: new Date(),
        updated_by: user.id
      });
      const { error: updateError } = await supabase
        .from('hospitals')
        .update(hospitalData)
        .eq('id', formData.value.id);
      
      if (updateError) throw updateError;

    } else {
      // 등록
      Object.assign(hospitalData, {
        registered_by: user.id
      });
      const { data: hospitalResult, error: insertError } = await supabase
        .from('hospitals')
        .insert([hospitalData])
        .select();
      
      if (insertError) throw insertError;
      
      const { error: mappingError } = await supabase
        .from('hospital_member_mappings')
        .insert([{
          member_id: user.id,
          hospital_id: hospitalResult[0].id
        }]);
      
      if (mappingError) throw mappingError;
    }

    alert(`거래처 정보가 성공적으로 ${isEdit.value ? '수정' : '등록'}되었습니다.`);
    closeModal();
    fetchHospitals(first.value, pageSize.value);

  } catch (e) {
    alert('저장 실패: ' + e.message);
  } finally {
    loading.value = false;
  }
};

const deleteHospital = async (hospital) => {
  if (!confirm(`'${hospital.hospital_name}' 거래처을 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) return;

  loading.value = true;
  // hospital_member_mappings에서만 관계 삭제
  const { error } = await supabase
    .from('hospital_member_mappings')
    .delete()
    .eq('id', hospital.mapping_id);
  loading.value = false;

  if (error) {
    alert('삭제 실패: ' + error.message);
  } else {
    alert('삭제 완료!');
    fetchHospitals(first.value, pageSize.value);
  }
};
</script>
