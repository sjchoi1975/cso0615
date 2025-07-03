<template>
  <div class="admin-hospitals-view page-container">
    <!-- Filter Card -->
    <div class="filter-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="거래처명, 원장명, 사업자번호, 주소 검색" class="input-search wide-mobile-search" />
        </span>
      </div>
    </div>
    
    <!-- Function Card -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}개</div>
      <div style="display: flex; gap:1rem; align-items:center;">
        <Button
          icon="pi pi-file-excel"
          label="양식다운"
          class="btn-add-md"
          @click="downloadTemplate"
          iconPos="left"
          style="gap:0.5em;"
        />
        <Button
          icon="pi pi-upload"
          label="엑셀 등록"
          class="btn-add-md"
          @click="() => $refs.fileInput.click()"
          iconPos="left"
          style="gap:0.5em;"
        />
        <input
          ref="fileInput"
          type="file"
          accept=".xlsx,.xls"
          @change="uploadExcel"
          style="display:none;"
        />
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
          label="신규 등록"
          class="btn-add-md"
          @click="goToCreatePage"
          iconPos="left"
          style="gap:0.5em;"
        />
        <Button
          icon="pi pi-trash"
          label="전체 삭제"
          class="btn-delete-md"
          @click="deleteAllHospitals"
          iconPos="left"
          style="gap:0.5em;"
        />
      </div>
    </div>

    <!-- Table Card -->
    <div class="table-card admin-hospitals-view-table">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="hospitals"
          :loading="loading"
          :paginator="false"
          scrollable
          :scrollHeight="tableScrollHeight"
          ref="tableRef"
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
                {{ first + slotProps.index + 1 }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'edit'">
                <Button icon="pi pi-pencil"
                  class="p-button-rounded p-button-text btn-icon-edit"
                  @click="goToEditPage(slotProps.data.id)" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'delete'">
                <Button icon="pi pi-trash"
                  class="p-button-rounded p-button-text btn-icon-danger"
                  @click="deleteHospital(slotProps.data)" />
              </template>

              <template v-else-if="col.type === 'icon' && col.field === 'license'">
                <span v-if="slotProps.data.business_license_file" @click="openFileModal(slotProps.data)" style="cursor:pointer;">
                  <i class="pi pi-file biz-doc-icon"></i>
                </span>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'member_count'">
                <span v-if="slotProps.data.member_count > 0" class="member-count">
                  {{ slotProps.data.member_count }}명
                </span>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'mapped_members'">
                <div v-if="slotProps.data.mapped_members && slotProps.data.mapped_members.length > 0">
                  <div v-for="(company, index) in slotProps.data.mapped_members" :key="index">
                    {{ company }}
                  </div>
                </div>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'registered_at' || col.field === 'updated_at'">
                {{ formatDate(slotProps.data[col.field]) }}
              </template>
              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
        </DataTable>
        <div v-if="loading" class="table-loading-spinner-center">
          <img src="/spinner.svg" alt="로딩중" />
        </div>
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

    <!-- 사업자등록증 보기, 다운로드 모달 -->
    <div v-if="showFileModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <div class="modal-title">사업자등록증</div>
        </div>
        <div class="modal-body">
          <object v-if="isPdfFile" :data="fileUrl" type="application/pdf" style="width: 100%; height: 70vh;">
            <p>PDF 뷰어를 로드할 수 없습니다. <a :href="fileUrl" target="_blank">여기서 다운로드</a>하여 확인해주세요.</p>
          </object>
          <img v-else :src="fileUrl" alt="사업자등록증" style="width: 100%; max-height: 70vh; object-fit: contain;" />
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeFileModal">닫기</button>
          <button class="btn-confirm modal" @click="downloadFile">다운로드</button>
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
import { ref, onMounted, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Paginator from 'primevue/paginator';
import { formatDate } from '@/utils/dateFormatter.js';
import { hospitalsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const router = useRouter();
const hospitals = ref([]);
const loading = ref(false);
const search = ref('');
const appliedSearch = ref('');
const totalCount = ref(0);
const pageSize = ref(100);
const first = ref(0);
const tableRef = ref(null);

// State for file viewer modal
const showFileModal = ref(false);
const fileUrl = ref('');
const currentFilePath = ref(null);

// State for delete confirmation modal
const showDeleteModal = ref(false);
const hospitalToDelete = ref(null);
const hasMappings = ref(false);

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? hospitalsTableConfig.mobile : hospitalsTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const isPdfFile = computed(() => {
  if (!currentFilePath.value) return false;
  const extension = currentFilePath.value.split('.').pop()?.toLowerCase();
  return extension === 'pdf';
});

const goToCreatePage = () => {
  router.push('/admin/hospitals/create');
};

const goToEditPage = (id) => {
  router.push(`/admin/hospitals/edit/${id}`);
};

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

const deleteHospital = async (hospital) => {
  if (!confirm(`'${hospital.hospital_name}' 거래처 정보를 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.`)) return;

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

    alert('거래처 정보가 삭제되었습니다.');
    fetchHospitals(first.value, pageSize.value);
  } catch (error) {
    console.error('Error deleting hospital:', error);
    alert('삭제 실패: ' + error.message);
  } finally {
    loading.value = false;
  }
};

const openFileModal = async (row) => {
  if (!row.business_license_file) return;
  currentFilePath.value = row.business_license_file;
  // signedUrl 발급
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

const closeDeleteModal = () => {
  showDeleteModal.value = false;
};

const downloadFile = async () => {
  if (!fileUrl.value || !currentFilePath.value) {
    alert('다운로드할 파일 정보가 없습니다.');
    return;
  }

  try {
    // 저장된 파일 경로를 사용해 직접 파일을 다운로드합니다.
    const { data: blob, error } = await supabase.storage
      .from('hospital-biz-licenses')
      .download(fileUrl.value);

    if (error) {
      throw error;
    }

    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    
    const fileExtension = fileUrl.value.split('.').pop();
    a.download = `${currentFilePath.value}_사업자등록증.${fileExtension}`;
    
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);
  } catch (error) {
    console.error('Download failed:', error);
    alert('파일 다운로드에 실패했습니다: ' + error.message);
  }
};

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

</script>
