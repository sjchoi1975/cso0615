<template>
  <div class="admin-hospitals-view page-container">
    <!-- Filter Card -->
    <div class="filter-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="거래처명, 원장명, 사업자번호, 주소 검색" class="input-search" />
        </span>
      </div>
    </div>

    <!-- Function Card -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}개 거래처</div>
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
        <Column header="사업자등록증" :style="{ width: columnWidths.license }" :bodyStyle="{ textAlign: columnAligns.license }">
          <template #body="slotProps">
            <Button v-if="slotProps.data.business_license_file" icon="pi pi-file" class="p-button-rounded p-button-text" @click="openFileModal(slotProps.data)" />
            <span v-else>-</span>
          </template>
        </Column>
        <Column header="연결회원" :style="{ width: columnWidths.member_count }" :bodyStyle="{ textAlign: columnAligns.member_count }">
          <template #body="slotProps">
            <span v-if="slotProps.data.member_count > 0" class="member-count">
              {{ slotProps.data.member_count }}명
            </span>
            <span v-else>-</span>
          </template>
        </Column>
        <Column header="연결 업체" :style="{ width: columnWidths.mapped_members }" :bodyStyle="{ textAlign: columnAligns.mapped_members }">
          <template #body="slotProps">
            <div v-if="slotProps.data.mapped_members && slotProps.data.mapped_members.length > 0">
              <div v-for="(company, index) in slotProps.data.mapped_members" :key="index">
                {{ company }}
              </div>
            </div>
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

    <!-- 거래처 등록, 수정 모달 -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">{{ isEdit ? '거래처 수정' : '거래처 등록' }}</h3>
        </div>

        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">거래처명 *</label>
            <input v-model="formData.hospital_name" type="text" class="input-mordal" placeholder="거래처명을 입력하세요" required />
          </div>
          <div class="form-group">
            <label class="form-label">사업자등록번호 *</label>
            <input v-model="formData.business_registration_number" type="text" class="input-mordal" placeholder="사업자등록번호를 입력하세요" required />
          </div>
          <div class="form-group">
            <label class="form-label">원장명 *</label>
            <input v-model="formData.director_name" type="text" class="input-mordal" placeholder="원장명을 입력하세요" required />
          </div>
          <div class="form-group">
            <label class="form-label">주소 *</label>
            <input v-model="formData.address" type="text" class="input-mordal" placeholder="주소를 입력하세요" required />
          </div>
          <div class="form-group">
            <label class="form-label">사업자등록증</label>
            <input type="file" @change="onFileChange" style="position: relative; z-index: 1;" />
            <a v-if="isEdit && formData.business_license_file" :href="getPublicUrl(formData.business_license_file)" target="_blank" class="link">
              현재 파일 보기
            </a>
          </div>
          <div class="form-group">
            <label class="form-label">연결할 회원 (선택사항)</label>
            <div class="member-selection">
              <div class="member-search">
                <input 
                  v-model="memberSearch" 
                  type="text" 
                  class="input-field" 
                  placeholder="회원명 또는 회사명으로 검색" 
                  @input="searchMembers"
                />
              </div>
              <div class="member-list" v-if="filteredMembers.length > 0">
                <div 
                  v-for="member in filteredMembers" 
                  :key="member.id"
                  class="member-item"
                  :class="{ 'selected': selectedMembers.includes(member.id) }"
                  @click="toggleMemberSelection(member.id)"
                >
                  <div class="member-info">
                    <div class="member-name">{{ member.company_name }}</div>
                    <div class="member-details">{{ member.manager_name }} ({{ member.id_email }})</div>
                  </div>
                  <div class="member-checkbox">
                    <input 
                      type="checkbox" 
                      :checked="selectedMembers.includes(member.id)"
                      @click.stop="toggleMemberSelection(member.id)"
                    />
                  </div>
                </div>
              </div>
              <div v-if="memberSearch && filteredMembers.length === 0" class="no-results">
                검색 결과가 없습니다.
              </div>
            </div>
            <div v-if="selectedMembers.length > 0" class="selected-members">
              <div class="selected-title">선택된 회원 ({{ selectedMembers.length }}명):</div>
              <div class="selected-list">
                <div 
                  v-for="memberId in selectedMembers" 
                  :key="memberId"
                  class="selected-member"
                >
                  {{ getMemberName(memberId) }}
                  <button type="button" @click="removeMember(memberId)" class="remove-member">×</button>
                </div>
              </div>
            </div>
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


    <!-- 사업자등록증 보기, 다운로드 모달 -->
    <div v-if="showFileModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">거래처 사업자등록증</h3>
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
          <h3 class="modal-title">거래처 삭제 확인</h3>
          <button class="btn-close" @click="closeDeleteModal">×</button>
        </div>
        <div class="modal-body">
          <p v-if="hasMappings">
            <strong>'{{ hospitalToDelete?.hospital_name }}'</strong> 거래처에 매핑된 회원이 있습니다.<br>
            매핑정보까지 같이 삭제하시겠습니까?
          </p>
          <p v-else>
            <strong>'{{ hospitalToDelete?.hospital_name }}'</strong> 거래처를 정말 삭제하시겠습니까?<br>
            이 작업은 되돌릴 수 없습니다.
          </p>
        </div>
        <div class="modal-footer">
          <button class="btn-secondary" @click="closeDeleteModal">취소</button>
          <button class="btn-danger" @click="confirmDelete" :disabled="loading">
            {{ loading ? '삭제 중...' : '삭제' }}
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
  index: '4%',
  hospital_name: '10%',
  business_registration_number: '8%',
  director_name: '6%',
  address: '12%',
  license: '5%',
  member_count: '5%',
  mapped_members: '10%',
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
  member_count: 'center',
  mapped_members: 'left',
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
const tableRef = ref(null);
const appliedSearch = ref('');
const currentFilePath = ref(null);

// 회원 매핑 관련 상태
const members = ref([]);
const filteredMembers = ref([]);
const selectedMembers = ref([]);
const memberSearch = ref('');

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
const showDeleteModal = ref(false);
const showFileModal = ref(false);
const isEdit = ref(false);
const hasMappings = ref(false);
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
  return formData.value.hospital_name.trim() &&
         formData.value.business_registration_number.trim() &&
         formData.value.director_name.trim() &&
         formData.value.address.trim();
});

const isPdfFile = computed(() => {
  if (!currentFilePath.value) return false;
  const extension = currentFilePath.value.split('.').pop()?.toLowerCase();
  return extension === 'pdf';
});

// Data fetching
const fetchHospitals = async (pageFirst = 0, pageRows = 100) => {
  loading.value = true;
  try {
    let countQuery = supabase.from('hospitals').select('*', { count: 'exact', head: true });
    let dataQuery = supabase.from('hospitals').select(`
      *,
      creator:registered_by ( company_name ),
      updater:updated_by ( company_name )
    `);

    if (appliedSearch.value) {
      const keyword = `%${appliedSearch.value}%`;
      const orFilter = `hospital_name.ilike.${keyword},director_name.ilike.${keyword},business_registration_number.ilike.${keyword},address.ilike.${keyword}`;
      countQuery = countQuery.or(orFilter);
      dataQuery = dataQuery.or(orFilter);
    }

    // 1. Fetch total count
    const { count, error: countError } = await countQuery;
    if (countError) throw countError;
    totalCount.value = count;

    if (totalCount.value === 0) {
      hospitals.value = [];
      loading.value = false;
      return;
    }

    // 2. Fetch paginated data
    const from = pageFirst;
    const to = from + pageRows - 1;

    dataQuery = dataQuery.range(from, to).order('registered_at', { ascending: false });
    const { data, error } = await dataQuery;

    if (error) throw error;
    
    // 3. 각 거래처의 연결된 회원 수 계산 및 데이터 변환
    const hospitalsWithDetails = await Promise.all(
      data.map(async (hospital) => {
        // 1. 해당 거래처에 연결된 회원 ID 목록 조회
        const { data: mappings, error: mappingError } = await supabase
          .from('hospital_member_mappings')
          .select('member_id')
          .eq('hospital_id', hospital.id);

        if (mappingError) {
          console.error(`Error fetching mappings for hospital ${hospital.id}:`, mappingError);
          return {
            ...hospital,
            creator_name: hospital.creator ? hospital.creator.company_name : '-',
            updater_name: hospital.updater ? hospital.updater.company_name : '-',
            member_count: 0,
            mapped_members: []
          };
        }

        const memberIds = mappings.map(m => m.member_id);
        let mapped_members = [];

        // 2. 조회된 회원 ID로 업체명 목록 조회
        if (memberIds.length > 0) {
          const { data: memberDetails, error: memberError } = await supabase
            .from('members')
            .select('company_name')
            .in('id', memberIds);

          if (memberError) {
            console.error(`Error fetching member details for hospital ${hospital.id}:`, memberError);
          } else if (memberDetails) {
            mapped_members = memberDetails.map(m => m.company_name).filter(Boolean);
          }
        }

        return {
          ...hospital,
          creator_name: hospital.creator ? hospital.creator.company_name : '-',
          updater_name: hospital.updater ? hospital.updater.company_name : '-',
          member_count: mapped_members.length,
          mapped_members
        };
      })
    );
    hospitals.value = hospitalsWithDetails;

  } catch (error) {
    console.error('Error fetching hospitals:', error);
    alert('데이터 로드 실패: ' + error.message);
    hospitals.value = [];
    totalCount.value = 0;
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchHospitals(0, pageSize.value);
  fetchMembers();
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
    '등록일': new Date(row.registered_at).toLocaleDateString(),
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '거래처목록');
  XLSX.writeFile(wb, `거래처목록_${new Date().toISOString().slice(0, 10)}.xlsx`);
};

const downloadTemplate = () => {
  const headers = ['거래처명', '사업자등록번호', '원장명', '주소'];
  const exampleRow = ['예시거래처', '123-45-67890', '홍길동', '서울시 강남구 테헤란로 123'];
  const ws = XLSX.utils.aoa_to_sheet([headers, exampleRow]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '거래처목록 템플릿');
  XLSX.writeFile(wb, `거래처목록_template_${new Date().toISOString().slice(0,10)}.xlsx`);
};

const uploadExcel = async (e) => {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = async (evt) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('사용자 정보를 찾을 수 없습니다.');

      const data = evt.target.result;
      const workbook = XLSX.read(data, { type: 'binary' });
      const sheetName = workbook.SheetNames[0];
      const sheet = workbook.Sheets[sheetName];
      const json = XLSX.utils.sheet_to_json(sheet);
      
      const rowsToInsert = json.map(row => ({
        hospital_name: row['거래처명'],
        business_registration_number: row['사업자등록번호'] ? String(row['사업자등록번호']) : null,
        director_name: row['원장명'],
        address: row['주소'],
        registered_by: user.id,
        updated_at: null,
        updated_by: null
      })).filter(r => r.hospital_name && r.business_registration_number);

      if (rowsToInsert.length === 0) {
        alert('엑셀에 등록할 유효한 데이터가 없습니다. "거래처명"과 "사업자등록번호"는 필수입니다.');
        return;
      }

      loading.value = true;
      const { error } = await supabase.from('hospitals').insert(rowsToInsert);
      loading.value = false;

      if (error) throw error;
      
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
    let hospitalsQuery = supabase.from('hospitals').select('id');
    if (appliedSearch.value) {
        const keyword = `%${appliedSearch.value}%`;
        hospitalsQuery = hospitalsQuery.or(`hospital_name.ilike.${keyword},director_name.ilike.${keyword},business_registration_number.ilike.${keyword},address.ilike.${keyword}`);
    }
    const { data: hospitalsToDelete, error: getHospitalsError } = await hospitalsQuery;
    if(getHospitalsError) throw getHospitalsError;

    if (hospitalsToDelete && hospitalsToDelete.length > 0) {
      const hospitalIds = hospitalsToDelete.map(h => h.id);

      // 1. Delete mappings
      const { error: mappingError } = await supabase
        .from('hospital_member_mappings')
        .delete()
        .in('hospital_id', hospitalIds);
      if (mappingError) throw mappingError;

      // 2. Delete hospitals
      const { error: hospitalError } = await supabase
        .from('hospitals')
        .delete()
        .in('id', hospitalIds);
      if(hospitalError) throw hospitalError;
    }

    alert('삭제 완료!');
    fetchHospitals(0, pageSize.value);
  } catch (error) {
    console.error('Error deleting all hospitals:', error);
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
    address: '',
    business_license_file: null
  };
  selectedMembers.value = [];
  memberSearch.value = '';
  filteredMembers.value = members.value;
  showModal.value = true;
};

const openEditModal = async (hospital) => {
  isEdit.value = true;
  formData.value = { ...hospital };
  selectedMembers.value = [];
  memberSearch.value = '';
  filteredMembers.value = members.value;
  
  // 기존 매핑된 회원들 가져오기
  try {
    const { data: mappings, error } = await supabase
      .from('hospital_member_mappings')
      .select('member_id')
      .eq('hospital_id', hospital.id);
    
    if (!error && mappings) {
      selectedMembers.value = mappings.map(m => m.member_id);
    }
  } catch (error) {
    console.error('Error fetching existing mappings:', error);
  }
  
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  selectedFile.value = null;
  selectedMembers.value = [];
  memberSearch.value = '';
  filteredMembers.value = members.value;
};

const saveHospital = async () => {
  if (!formData.value.hospital_name) {
    alert('거래처명을 입력해주세요.');
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
    const file = selectedFile.value;
    const fileExt = file.name.split('.').pop();
    const fileName = `${uuidv4()}.${fileExt}`;
    
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('hospital-biz-licenses')
      .upload(fileName, file);

    if (uploadError) {
      alert('파일 업로드에 실패했습니다: ' + uploadError.message);
      loading.value = false;
      return;
    }
    filePath = uploadData.path;
  }

  try {
    let hospitalId;
    
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
      hospitalId = formData.value.id;
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
      const { data: newHospital, error } = await supabase.from('hospitals').insert(dataToInsert).select('id').single();
      if (error) throw error;
      hospitalId = newHospital.id;
      alert('새로운 거래처가 등록되었습니다.');
    }

    // 회원 매핑 처리
    if (selectedMembers.value.length > 0) {
      // 기존 매핑 삭제 (수정 시)
      if (isEdit.value) {
        const { error: deleteError } = await supabase
          .from('hospital_member_mappings')
          .delete()
          .eq('hospital_id', hospitalId);
        if (deleteError) throw deleteError;
      }

      // 새로운 매핑 추가
      const mappingsToInsert = selectedMembers.value.map(memberId => ({
        hospital_id: hospitalId,
        member_id: memberId
      }));

      const { error: mappingError } = await supabase
        .from('hospital_member_mappings')
        .insert(mappingsToInsert);
      
      if (mappingError) throw mappingError;
      
      alert(`거래처와 ${selectedMembers.value.length}명의 회원이 연결되었습니다.`);
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

const deleteHospital = async (hospital) => {
  if (!confirm(`'${hospital.hospital_name}' 거래처을 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) return;

  loading.value = true;
  try {
    // 1. 먼저 연결된 매핑 삭제
    const { error: mappingError } = await supabase
      .from('hospital_member_mappings')
      .delete()
      .eq('hospital_id', hospital.id);
    
    if (mappingError) throw mappingError;

    // 2. 거래처 삭제
    const { error } = await supabase.from('hospitals').delete().eq('id', hospital.id);
    if (error) throw error;

    alert('거래처와 연결된 모든 정보가 삭제되었습니다.');
    fetchHospitals(first.value, pageSize.value);
  } catch (error) {
    console.error('Error deleting hospital:', error);
    alert('삭제 실패: ' + error.message);
  } finally {
    loading.value = false;
  }
};

const onFileChange = (event) => {
  const files = event.target.files;
  if (files.length > 0) {
    selectedFile.value = files[0];
  }
};

const getPublicUrl = (filePath) => {
  if (!filePath) return '';
  const { data } = supabase.storage.from('hospital-biz-licenses').getPublicUrl(filePath);
  return data.publicUrl;
};

const openFileModal = async (hospital) => {
  if (!hospital.business_license_file) {
    alert('파일이 존재하지 않습니다.');
    return;
  }
  
  currentHospital.value = hospital;
  currentFilePath.value = hospital.business_license_file;

  // DB에 저장된 파일 경로를 사용하여 임시 URL 생성
  const { data, error } = await supabase.storage
    .from('hospital-biz-licenses')
    .createSignedUrl(currentFilePath.value, 60); // 60초간 유효

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
  currentHospital.value = null;
};

const closeDeleteModal = () => {
  showDeleteModal.value = false;
};

async function showLicenseModal(hospital) {
  if (!hospital.business_license_file) return;

  // business_license_file에 전체 URL이 저장되어 있을 경우, 경로만 추출합니다.
  const path = hospital.business_license_file.split('/').pop();

  const { data, error } = await supabase.storage
    .from('hospital-biz-licenses')
    .createSignedUrl(path, 60); // 60초 유효

  if (error) {
    console.error('Error creating signed URL:', error);
    alert('파일 URL을 생성하는 데 실패했습니다.');
    return;
  }
  fileUrl.value = data.signedUrl;
  showFileModal.value = true;
}

const downloadFile = async () => {
  if (!currentFilePath.value || !currentHospital.value) {
    alert('다운로드할 파일 정보가 없습니다.');
    return;
  }

  try {
    // 저장된 파일 경로를 사용해 직접 파일을 다운로드합니다.
    const { data: blob, error } = await supabase.storage
      .from('hospital-biz-licenses')
      .download(currentFilePath.value);

    if (error) {
      throw error;
    }

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

// 회원 관련 함수들
const fetchMembers = async () => {
  try {
    const { data, error } = await supabase
      .from('members')
      .select('id, company_name, manager_name, id_email')
      .eq('approval', 'approved')
      .order('company_name');

    if (error) throw error;
    members.value = data;
    filteredMembers.value = data;
  } catch (error) {
    console.error('Error fetching members:', error);
  }
};

const searchMembers = () => {
  if (!memberSearch.value.trim()) {
    filteredMembers.value = members.value;
    return;
  }

  const searchTerm = memberSearch.value.toLowerCase();
  filteredMembers.value = members.value.filter(member => 
    member.company_name.toLowerCase().includes(searchTerm) ||
    member.manager_name.toLowerCase().includes(searchTerm) ||
    member.id_email.toLowerCase().includes(searchTerm)
  );
};

const toggleMemberSelection = (memberId) => {
  const index = selectedMembers.value.indexOf(memberId);
  if (index > -1) {
    selectedMembers.value.splice(index, 1);
  } else {
    selectedMembers.value.push(memberId);
  }
};

const removeMember = (memberId) => {
  const index = selectedMembers.value.indexOf(memberId);
  if (index > -1) {
    selectedMembers.value.splice(index, 1);
  }
};

const getMemberName = (memberId) => {
  const member = members.value.find(m => m.id === memberId);
  return member ? member.company_name : 'Unknown';
};
</script>
