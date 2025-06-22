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
        <button class="btn-add" @click="openCreateModal">거래처 등록</button>
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
        <Column header="사업자등록증" :style="{ width: columnWidths.license }" :bodyStyle="{ textAlign: columnAligns.license }">
          <template #body="slotProps">
            <Button v-if="slotProps.data.business_license_file" icon="pi pi-file" class="p-button-rounded p-button-text" @click="openFileModal(slotProps.data)" />
            <span v-else>-</span>
          </template>
        </Column>
        <Column field="registered_at" header="등록일자" :sortable="columnSortables.registered_at" :style="{ width: columnWidths.created_at }" :bodyStyle="{ textAlign: columnAligns.created_at }">
          <template #body="slotProps">
            {{ formatDate(slotProps.data.registered_at) }}
          </template>
        </Column>
        <Column header="등록자" :style="{ width: columnWidths.registrar }" :bodyStyle="{ textAlign: columnAligns.registrar }">
          <template #body="slotProps">
            {{ slotProps.data.registrar?.name }}
          </template>
        </Column>
        <Column header="수정" :style="{ width: columnWidths.edit }" :bodyStyle="{ textAlign: columnAligns.edit }">
          <template #body="slotProps">
            <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="openEditModal(slotProps.data)" />
          </template>
        </Column>
        <Column header="연결 해제" :style="{ width: columnWidths.delete }" :bodyStyle="{ textAlign: columnAligns.delete }">
          <template #body="slotProps">
            <Button icon="pi pi-unlink" class="p-button-rounded p-button-text btn-icon-danger" @click="deleteHospital(slotProps.data)" />
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
          <div class="form-group">
            <label class="form-label">사업자등록증</label>
            <input type="file" @change="onFileChange" style="position: relative; z-index: 1;" />
            <a v-if="isEdit && formData.business_license_file" :href="getPublicUrl(formData.business_license_file)" target="_blank" class="file-link">
              현재 파일 보기
            </a>
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

    <!-- File Viewer Modal -->
    <div v-if="showFileModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">사업자등록증 보기</h3>
          <button class="btn-close" @click="closeFileModal">×</button>
        </div>
        <div class="modal-body">
          <img v-if="fileUrl" :src="fileUrl" alt="사업자등록증" style="width: 100%;" />
          <p v-else>이미지를 불러올 수 없습니다.</p>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeFileModal">닫기</button>
          <a :href="fileUrl" download class="btn-primary" style="text-decoration: none;">다운로드</a>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">거래처 연결 해제</h3>
          <button class="btn-close" @click="closeDeleteModal">×</button>
        </div>
        <div class="modal-body">
          <p>
            <strong>'{{ hospitalToDelete?.hospital_name }}'</strong> 거래처와의 연결을 해제하시겠습니까?<br>
            (거래처 데이터는 삭제되지 않습니다.)
          </p>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeDeleteModal">취소</button>
          <button class="btn-danger" @click="confirmDelete" :disabled="loading">
            {{ loading ? '해제 중...' : '연결 해제' }}
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
import { v4 as uuidv4 } from 'uuid';

// Column definitions
const columnWidths = {
  index: '5%',
  hospital_name: '15%',
  business_registration_number: '10%',
  director_name: '10%',
  address: '19%',
  license: '8%',
  created_at: '10%',
  registrar: '10%',
  edit: '8%',
  delete: '8%'
};
const columnSortables = {
  hospital_name: true,
  business_registration_number: true,
  director_name: true,
  address: true,
  registered_at: true,
};
const columnAligns = {
  index: 'center',
  hospital_name: 'left',
  business_registration_number: 'center',
  director_name: 'center',
  address: 'left',
  license: 'center',
  created_at: 'center',
  registrar: 'center',
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

// Modal state
const showModal = ref(false);
const showDeleteModal = ref(false);
const showFileModal = ref(false);
const isEdit = ref(false);
const hospitalToDelete = ref(null);
const fileUrl = ref('');
const currentFilePath = ref(null);
const selectedFile = ref(null);
const formData = ref({
  id: null,
  hospital_name: '',
  business_registration_number: '',
  director_name: '',
  address: '',
  business_license_file: null
});

const isFormValid = computed(() => {
  return formData.value.hospital_name && formData.value.business_registration_number && formData.value.director_name && formData.value.address;
});

// 날짜 포맷팅 함수
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const year = date.getFullYear();
  const month = ('0' + (date.getMonth() + 1)).slice(-2);
  const day = ('0' + date.getDate()).slice(-2);
  return `${year}-${month}-${day}`;
};

const fetchHospitals = async (page = 0, rows = pageSize.value) => {
  loading.value = true;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    loading.value = false;
    return;
  }

  try {
    // 1. 사용자와 연결된 '매핑'을 먼저 조회합니다.
    const columnsToSelect = `
      mapping_id:id,
      hospitals (
        id,
        hospital_name,
        business_registration_number,
        director_name,
        address,
        business_license_file,
        registered_at,
        registrar:members!hospitals_registered_by_fkey(name)
      )
    `;

    let query = supabase
      .from('hospital_member_mappings')
      .select(columnsToSelect, { count: 'exact' })
      .eq('member_id', user.id);

    // 2. 검색어가 있는 경우, 연결된 hospitals 테이블을 기준으로 필터링합니다.
    if (search.value) {
      const keyword = `%${search.value}%`;
      query.or(
        `hospitals.hospital_name.ilike.${keyword},` +
        `hospitals.business_registration_number.ilike.${keyword},` +
        `hospitals.director_name.ilike.${keyword},` +
        `hospitals.address.ilike.${keyword}`
      );
    }
    
    // 3. 페이지네이션 및 정렬 적용
    const { data, error, count } = await query
      .order('registered_at', { foreignTable: 'hospitals', ascending: false })
      .range(page * rows, (page + 1) * rows - 1);

    if (error) throw error;

    // 4. 받아온 데이터를 화면에 맞는 형식으로 가공합니다.
    hospitals.value = data.map(item => ({
      ...item.hospitals,
      mapping_id: item.mapping_id // 연결 해제를 위해 매핑 ID도 저장
    }));
    totalCount.value = count || 0;

  } catch (error) {
    console.error('Error fetching hospitals:', error);
    alert('데이터를 불러오는 데 실패했습니다: ' + error.message);
  } finally {
    loading.value = false;
  }
};

const saveHospital = async () => {
  if (!isFormValid.value) {
    alert('모든 필수 항목을 입력해주세요.');
    return;
  }

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    alert('로그인이 필요합니다.');
    return;
  }

  loading.value = true;
  let filePath = (isEdit.value && formData.value.business_license_file) ? formData.value.business_license_file : null;

  if (selectedFile.value) {
    if (isEdit.value && formData.value.business_license_file) {
      await supabase.storage.from('hospital-biz-licenses').remove([formData.value.business_license_file]);
    }
    const file = selectedFile.value;
    const fileExt = file.name.split('.').pop();
    const fileName = `${uuidv4()}.${fileExt}`;
    const { data: uploadData, error: uploadError } = await supabase.storage.from('hospital-biz-licenses').upload(fileName, file);

    if (uploadError) {
      alert('파일 업로드에 실패했습니다: ' + uploadError.message);
      loading.value = false;
      return;
    }
    filePath = uploadData.path;
  }

  try {
    if (isEdit.value) {
      const dataToUpdate = {
        hospital_name: formData.value.hospital_name,
        business_registration_number: formData.value.business_registration_number,
        director_name: formData.value.director_name,
        address: formData.value.address,
        business_license_file: filePath,
        updated_at: new Date().toISOString(),
        updated_by: user.id
      };
      const { error } = await supabase.from('hospitals').update(dataToUpdate).eq('id', formData.value.id);
      if (error) throw error;
      alert('거래처 정보가 수정되었습니다.');
    } else {
      const dataToInsert = {
        hospital_name: formData.value.hospital_name,
        business_registration_number: formData.value.business_registration_number,
        director_name: formData.value.director_name,
        address: formData.value.address,
        business_license_file: filePath,
        registered_at: new Date().toISOString(),
        registered_by: user.id
      };
      const { data: newHospital, error: insertError } = await supabase.from('hospitals').insert(dataToInsert).select();
      if (insertError) throw insertError;

      const { error: mappingError } = await supabase.from('hospital_member_mappings').insert({ hospital_id: newHospital[0].id, member_id: user.id });
      if (mappingError) throw mappingError;

      alert('새로운 거래처가 등록되었습니다.');
    }
    
    closeModal();
    fetchHospitals(first.value, pageSize.value);
  } catch (error) {
    console.error('Error saving hospital:', error);
    alert('저장 실패: ' + error.message);
  } finally {
    loading.value = false;
  }
};

const openCreateModal = () => {
  isEdit.value = false;
  formData.value = { id: null, hospital_name: '', business_registration_number: '', director_name: '', address: '', business_license_file: null };
  selectedFile.value = null;
  showModal.value = true;
};

const openEditModal = (hospital) => {
  isEdit.value = true;
  formData.value = { ...hospital };
  selectedFile.value = null;
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
};

const deleteHospital = async (hospital) => {
  hospitalToDelete.value = hospital;
  showDeleteModal.value = true;
};

const confirmDelete = async () => {
  if (!hospitalToDelete.value || !hospitalToDelete.value.mapping_id) {
    alert('삭제할 항목의 정보가 올바르지 않습니다.');
    return;
  }
  loading.value = true;
  try {
    // 이제 hospitalToDelete.value에 있는 mapping_id를 사용합니다.
    await supabase.from('hospital_member_mappings').delete().eq('id', hospitalToDelete.value.mapping_id);
    alert('거래처와의 연결이 해제되었습니다.');
    fetchHospitals(first.value, pageSize.value);
  } catch (error) {
    console.error('Error unmapping hospital:', error);
    alert('연결 해제 실패: ' + error.message);
  } finally {
    loading.value = false;
    closeDeleteModal();
  }
};

const closeDeleteModal = () => {
  showDeleteModal.value = false;
  hospitalToDelete.value = null;
};

const openFileModal = async (hospital) => {
  if (!hospital.business_license_file) return;
  currentFilePath.value = hospital.business_license_file;
  const { data, error } = await supabase.storage.from('hospital-biz-licenses').createSignedUrl(currentFilePath.value, 60);
  if (error) {
    alert('파일 보기 링크 생성에 실패했습니다: ' + error.message);
    return;
  }
  fileUrl.value = data.signedUrl;
  showFileModal.value = true;
};

const closeFileModal = () => {
  showFileModal.value = false;
  fileUrl.value = '';
  currentFilePath.value = null;
};

const downloadFile = async () => {
  if (!currentFilePath.value) return;
  try {
    const { data: blob, error } = await supabase.storage.from('hospital-biz-licenses').download(currentFilePath.value);
    if (error) throw error;
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = currentFilePath.value.split('/').pop();
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);
  } catch (error) {
    console.error('Download failed:', error);
    alert('파일 다운로드에 실패했습니다: ' + error.message);
  }
};

const onFileChange = (event) => {
  const files = event.target.files;
  if (files.length > 0) {
    selectedFile.value = files[0];
  }
};

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchHospitals(event.page, event.rows);
};

let searchTimeout;
watch(search, (newValue) => {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    fetchHospitals(0, pageSize.value);
  }, 500);
});

onMounted(() => {
  fetchHospitals(0, pageSize.value);
});
</script>

<style>
.file-link {
  display: inline-block;
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: #007bff;
}
</style>
