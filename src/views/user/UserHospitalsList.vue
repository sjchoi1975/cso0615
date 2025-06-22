<template>
  <div class="page-container">
    <!-- Filter Card -->
    <div class="filter-card custom-auto-height">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="거래처명, 원장명, 사업자번호, 주소 검색" class="input-search" @keyup.enter="applySearch" />
        </span>
        <button class="btn-search" @click="applySearch">조회</button>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card custom-auto-height">
      <div class="total-count total-count-nowrap">총 {{ totalCount.toLocaleString() }}개 거래처</div>
      <div style="display: flex; gap:0.5rem; align-items:center;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운로드</button>
        <button class="btn-add" @click="openCreateModal">거래처 등록</button>
      </div>
    </div>

    <!-- Table Card -->
    <div class="table-card user-hospitals-view-table">
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
        <Column field="business_registration_number" header="사업자번호" :sortable="columnSortables.business_registration_number" :style="{ width: columnWidths.business_registration_number }" :bodyStyle="{ textAlign: columnAligns.business_registration_number }"></Column>
        <Column field="director_name" header="원장명" :sortable="columnSortables.director_name" :style="{ width: columnWidths.director_name }" :bodyStyle="{ textAlign: columnAligns.director_name }"></Column>
        <Column field="address" header="주소" :sortable="columnSortables.address" :style="{ width: columnWidths.address }" :bodyStyle="{ textAlign: columnAligns.address }"></Column>
        <Column header="사업자등록증" :style="{ width: columnWidths.license }" :bodyStyle="{ textAlign: columnAligns.license }">
          <template #body="slotProps">
            <Button v-if="slotProps.data.business_license_file" icon="pi pi-file" class="p-button-rounded p-button-text" @click="openFileModal(slotProps.data)" />
            <span v-else>-</span>
          </template>
        </Column>
        <Column field="registered_at" header="등록일자" :sortable="columnSortables.registered_at" :style="{ width: columnWidths.registered_at }" :bodyStyle="{ textAlign: columnAligns.registered_at }">
          <template #body="slotProps">
            {{ formatDate(slotProps.data.registered_at) }}
          </template>
        </Column>
        <Column field="creator_name" header="등록자" :style="{ width: columnWidths.creator_name }" :bodyStyle="{ textAlign: columnAligns.creator_name }">
          <template #body="slotProps">
            {{ slotProps.data.creator_name || '-' }}
          </template>
        </Column>
        <Column field="updated_at" header="수정일자" :sortable="columnSortables.updated_at" :style="{ width: columnWidths.updated_at }" :bodyStyle="{ textAlign: columnAligns.updated_at }">
          <template #body="slotProps">
            {{ slotProps.data.updated_at ? formatDate(slotProps.data.updated_at) : '-' }}
          </template>
        </Column>
        <Column field="updater_name" header="수정자" :style="{ width: columnWidths.updater_name }" :bodyStyle="{ textAlign: columnAligns.updater_name }">
          <template #body="slotProps">
            {{ slotProps.data.updater_name || '-' }}
          </template>
        </Column>
        <Column header="수정" :style="{ width: columnWidths.edit }" :bodyStyle="{ textAlign: columnAligns.edit }">
          <template #body="slotProps">
            <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="openEditModal(slotProps.data)" />
          </template>
        </Column>
        <Column header="삭제" :style="{ width: columnWidths.delete }" :bodyStyle="{ textAlign: columnAligns.delete }">
          <template #body="slotProps">
            <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="confirmDeleteMapping(slotProps.data)" />
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

    <!-- Hospital Create/Edit Dialog -->
    <Dialog v-model:visible="showModal" :header="isEdit ? '거래처 수정' : '거래처 등록'" :modal="true" :style="{ width: '500px' }">
      <div class="p-fluid">
        <div class="p-field">
          <label for="hospital_name">거래처명 *</label>
          <InputText id="hospital_name" v-model="formData.hospital_name" required />
        </div>
        <div class="p-field">
          <label for="biz_no">사업자등록번호 *</label>
          <InputText id="biz_no" v-model="formData.business_registration_number" required />
        </div>
        <div class="p-field">
          <label for="director">원장명 *</label>
          <InputText id="director" v-model="formData.director_name" required />
        </div>
        <div class="p-field">
          <label for="address">주소 *</label>
          <InputText id="address" v-model="formData.address" required />
        </div>
        <div class="p-field">
          <label for="license">사업자등록증</label>
          <FileUpload name="licenseFile" @select="onFileChange" :showUploadButton="false" :showCancelButton="false" :customUpload="true" accept="image/*,application/pdf">
             <template #empty>
                <p>파일을 여기에 끌어다 놓거나 선택하세요.</p>
             </template>
          </FileUpload>
          <a v-if="isEdit && formData.business_license_file" :href="getPublicUrl(formData.business_license_file)" target="_blank" class="file-link">
            현재 파일 보기
          </a>
        </div>
      </div>
      <template #footer>
        <Button label="취소" icon="pi pi-times" @click="closeModal" class="p-button-text"/>
        <Button :label="isEdit ? '수정' : '등록'" icon="pi pi-check" @click="saveHospital" :loading="loading" />
      </template>
    </Dialog>

    <!-- File Viewer Modal -->
    <div v-if="showFileModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">사업자등록증 보기</h3>
          <button class="btn-close" @click="closeFileModal">×</button>
        </div>
        <div class="modal-body">
          <object v-if="isPdfFile" :data="fileUrl" type="application/pdf" style="width: 100%; height: 70vh;">
            <p>PDF 뷰어를 로드할 수 없습니다. <a :href="fileUrl" target="_blank">여기서 다운로드</a>하여 확인해주세요.</p>
          </object>
          <img v-else :src="fileUrl" alt="사업자등록증" style="width: 100%; max-height: 70vh; object-fit: contain;" />
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeFileModal">닫기</button>
          <button class="btn-primary" @click="downloadFile">다운로드</button>
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
          <button class="btn-danger" @click="deleteMapping" :disabled="loading">
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
import Paginator from 'primevue/paginator';
import Dialog from 'primevue/dialog';
import InputText from 'primevue/inputtext';
import FileUpload from 'primevue/fileupload';
import * as XLSX from 'xlsx';
import { v4 as uuidv4 } from 'uuid';

// Column definitions
const columnWidths = {
  index: '4%',
  hospital_name: '16%',
  business_registration_number: '8%',
  director_name: '8%',
  address: '18%',
  license: '6%',
  registered_at: '6%',
  creator_name: '8%',
  updated_at: '6%',
  updater_name: '8%',
  edit: '6%',
  delete: '6%',
};

const columnSortables = {
  hospital_name: true,
  business_registration_number: true,
  director_name: true,
  address: true,
  registered_at: true,
  updated_at: true,
};

const columnAligns = {
  index: 'center',
  hospital_name: 'left',
  business_registration_number: 'center',
  director_name: 'center',
  address: 'left',
  license: 'center',
  registered_at: 'center',
  creator_name: 'center',
  updated_at: 'center',
  updater_name: 'center',
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
const appliedSearch = ref('');
const currentFilePath = ref(null);

// Modal state
const showModal = ref(false);
const showDeleteModal = ref(false);
const showFileModal = ref(false);
const isEdit = ref(false);
const hospitalToDelete = ref(null);
const fileUrl = ref('');
const selectedFile = ref(null);
const currentHospital = ref(null);
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

const isPdfFile = computed(() => {
  if (!currentFilePath.value) return false;
  const extension = currentFilePath.value.split('.').pop()?.toLowerCase();
  return extension === 'pdf';
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

// 데이터 조회
const fetchHospitals = async (pageFirst = 0, pageRows = 100) => {
    loading.value = true;
    try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            hospitals.value = [];
            totalCount.value = 0;
            loading.value = false;
            return;
        }

        let query = supabase
            .from('hospital_member_mappings')
            .select(`
                id,
                hospital:hospitals!inner (
                    *,
                    creator:registered_by ( company_name ),
                    updater:updated_by ( company_name )
                )
            `, { count: 'exact' })
            .eq('member_id', user.id);

        if (appliedSearch.value) {
            const keyword = `%${appliedSearch.value}%`;
            query = query.or(
                `hospital_name.ilike.${keyword},director_name.ilike.${keyword},business_registration_number.ilike.${keyword},address.ilike.${keyword}`,
                { referencedTable: 'hospitals' }
            );
        }

        const from = pageFirst;
        const to = from + pageRows - 1;

        const { data, error, count } = await query.range(from, to).order('created_at', { ascending: false });

        if (error) throw error;
        
        hospitals.value = data.map(item => ({
            ...item.hospital,
            creator_name: item.hospital.creator ? item.hospital.creator.company_name : '-',
            updater_name: item.hospital.updater ? item.hospital.updater.company_name : '-',
            mapping_id: item.id
        }));
        totalCount.value = count || 0;

    } catch (error) {
        console.error('Error fetching hospitals:', error);
        alert('데이터를 불러오는 데 실패했습니다: ' + error.message);
        hospitals.value = [];
        totalCount.value = 0;
    } finally {
        loading.value = false;
    }
};

const getPublicUrl = (filePath) => {
  if (!filePath) return '';
  const { data } = supabase.storage.from('hospital-biz-licenses').getPublicUrl(filePath);
  return data.publicUrl;
};

// 모달 및 파일 관련 함수
const onFileChange = (event) => {
  // PrimeVue FileUpload의 event.files는 배열입니다.
  const files = event.files;
  if (files.length > 0) {
    selectedFile.value = files[0];
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
    const fileName = `${user.id}/${uuidv4()}.${fileExt}`;
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
      const { error } = await supabase.from('hospitals').update({
        hospital_name: formData.value.hospital_name,
        business_registration_number: formData.value.business_registration_number,
        director_name: formData.value.director_name,
        address: formData.value.address,
        business_license_file: filePath,
        updated_at: new Date().toISOString(),
        updated_by: user.id
      }).eq('id', formData.value.id);
      if (error) throw error;
      alert('거래처 정보가 수정되었습니다.');
    } else {
      const { data: newHospital, error: insertError } = await supabase.from('hospitals').insert({
        hospital_name: formData.value.hospital_name,
        business_registration_number: formData.value.business_registration_number,
        director_name: formData.value.director_name,
        address: formData.value.address,
        business_license_file: filePath,
        registered_by: user.id
      }).select('id').single();
      if (insertError) throw insertError;

      const { error: mappingError } = await supabase.from('hospital_member_mappings').insert({
        hospital_id: newHospital.id,
        member_id: user.id
      });
      if (mappingError) throw mappingError;

      alert('새로운 거래처가 등록 및 연결되었습니다.');
    }
    closeModal();
    fetchHospitals();
  } catch (error) {
    console.error('Error saving hospital:', error);
    alert('저장 실패: ' + error.message);
  } finally {
    loading.value = false;
  }
};

// 검색 적용
const applySearch = () => {
  first.value = 0;
  appliedSearch.value = search.value;
  fetchHospitals(0, pageSize.value);
};

// 페이지 변경
const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchHospitals(event.first, event.rows);
};

// 파일 모달 열기
const openFileModal = async (hospital) => {
  if (!hospital.business_license_file) return;
  currentHospital.value = hospital;
  currentFilePath.value = hospital.business_license_file;
  const { data, error } = await supabase.storage.from('hospital-biz-licenses').createSignedUrl(currentFilePath.value, 60);
  if (error) {
    alert('파일 보기 링크 생성에 실패했습니다: ' + error.message);
    return;
  }
  fileUrl.value = data.signedUrl;
  showFileModal.value = true;
};

// 파일 모달 닫기
const closeFileModal = () => {
  showFileModal.value = false;
  fileUrl.value = '';
  currentFilePath.value = null;
  currentHospital.value = null;
};

// 파일 다운로드
const downloadFile = async () => {
  if (!currentFilePath.value || !currentHospital.value) {
    alert('다운로드할 파일 정보가 없습니다.');
    return;
  }
  try {
    const { data: blob, error } = await supabase.storage.from('hospital-biz-licenses').download(currentFilePath.value);
    if (error) throw error;

    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    
    const fileExtension = currentFilePath.value.split('.').pop();
    a.download = `${currentHospital.value.hospital_name}_사업자등록증.${fileExtension}`;
    
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);
  } catch (error) {
    console.error('Download failed:', error);
    alert('파일 다운로드에 실패했습니다: ' + error.message);
  }
};

const downloadExcel = async () => {
    loading.value = true;
    try {
        const { data: allData, error } = await supabase
            .from('user_hospitals_view')
            .select('*')
            .order('registered_at', { ascending: false });

        if (error) throw error;

        const formattedData = allData.map((item, index) => ({
            '순번': index + 1,
            '거래처명': item.hospital_name,
            '사업자등록번호': item.business_registration_number,
            '원장명': item.director_name,
            '주소': item.address,
            '등록일자': formatDate(item.registered_at),
            '등록자': item.creator_name || 'N/A',
            '수정일자': item.updated_at ? formatDate(item.updated_at) : '-',
            '수정자': item.updater_name || 'N/A'
        }));

        const worksheet = XLSX.utils.json_to_sheet(formattedData);
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, '거래처 목록');
        XLSX.writeFile(workbook, `거래처목록_${formatDate(new Date())}.xlsx`);

    } catch (err) {
        alert('엑셀 다운로드 중 오류가 발생했습니다: ' + err.message);
    } finally {
        loading.value = false;
    }
};

// 삭제 확인 모달 열기
const confirmDeleteMapping = (hospital) => {
  hospitalToDelete.value = hospital;
  showDeleteModal.value = true;
};

// 삭제 모달 닫기
const closeDeleteModal = () => {
  showDeleteModal.value = false;
  hospitalToDelete.value = null;
};

// 매핑 삭제
const deleteMapping = async () => {
  if (!hospitalToDelete.value) return;
  loading.value = true;
  try {
    const { error } = await supabase
      .from('hospital_member_mappings')
      .delete()
      .eq('id', hospitalToDelete.value.mapping_id);
    
    if (error) throw error;
    
    alert('거래처 연결이 해제되었습니다.');
    fetchHospitals();

  } catch (error) {
    alert('연결 해제 중 오류가 발생했습니다: ' + error.message);
  } finally {
    loading.value = false;
    closeDeleteModal();
  }
};

onMounted(() => {
  fetchHospitals();
});

watch(search, (newValue) => {
  if (newValue === '') {
    applySearch();
  }
});

</script>
