<template>
  <div class="page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- Filter Card -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">

        <span class="hide-mobile">통합 검색</span>
        <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="거래처명, 원장명, 사업자등록번호, 주소 입력" />
        <button type="button" class="btn-search hide-mobile" @click="onSearch" :disabled="search.length < 2">검색</button>
        <button type="button" class="btn-reset hide-mobile"  @click="onReset">
          <i class="pi pi-refresh" style="font-size: 1rem;"></i>
          초기화
        </button>
        
        <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
          <input v-model="search" class="input-search wide-mobile-search" placeholder="거래처명, 원장명, 사업자등록번호, 주소 입력" @keyup.enter="onSearch"/>
          <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onReset"
            style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          <i class="pi pi-search search-btn-icon" @click="search.length >= 2 && onSearch()"
            style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
        </div>
        
      </div>
    </div>
    
    <!-- Function Card -->
    <div class="function-card custom-auto-height">
      <div class="total-count total-count-nowrap">총 {{ totalCount.toLocaleString() }}개</div>
      <div style="display: flex; gap:1rem; align-items:center;">
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
          label="거래처 등록"
          class="btn-add-md"
          @click="goToCreatePage"
          iconPos="left"
          style="gap:0.5em;"
        />
      </div>
    </div>
    
    <!-- Table Card -->
    <div class="table-card user-hospitals-view-table">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="hospitals"
          :loading="false"
          :paginator="false"
          scrollable
          :scrollHeight="getTableScrollHeight(false)"
          scrollDirection="vertical"
          ref="tableRef"
          :style="{ width: tableConfig.tableWidth, minWidth: tableConfig.tableStyle.minWidth }"
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

              <template v-if="col.field === 'hospital_name'">
                <!-- PC: 거래처명만 표시 -->
                <div v-if="screenWidth > 768" class="table-title-link">
                  {{ slotProps.data.hospital_name }}
                </div>

                <!-- 모바일: 거래처명 + 주소 + 사업자번호/원장명 -->
                <div v-else class="mobile-hospital-info">
                  <div class="table-title-link">{{ slotProps.data.hospital_name }}</div>
                  <div class="hospital-address">{{ slotProps.data.address }}</div>
                  <div class="hospital-details">
                    {{ slotProps.data.business_registration_number }} / {{ slotProps.data.director_name }}
                  </div>
                </div>
              </template>

              <template v-else-if="col.type === 'icon' && col.field === 'edit'">
                <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="goToEditPage(slotProps.data.id)" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'delete'">
                <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="confirmDeleteMapping(slotProps.data)" />
              </template>

              <template v-else-if="col.field === 'address'">
                <!-- PC: 주소 텍스트 표시 -->
                <span v-if="screenWidth > 768" :title="slotProps.data.address">
                  {{ slotProps.data.address || '-' }}
                </span>
                <!-- 모바일: 지도 아이콘 (활성/비활성) -->
                <span v-else @click="slotProps.data.address ? openMap(slotProps.data.address) : null" 
                      class="hospital-icon" 
                      :class="{ 'inactive-icon': !slotProps.data.address }"
                      :title="slotProps.data.address ? '지도에서 보기' : '주소 정보 없음'">
                  <i class="pi pi-map-marker"></i>
                </span>
              </template>
              
              <template v-else-if="col.field === 'telephone'">
                <!-- PC: 전화번호 텍스트 표시 -->
                <span v-if="screenWidth > 768">
                  {{ slotProps.data.telephone || '-' }}
                </span>
                <!-- 모바일: 전화 아이콘 (활성/비활성) -->
                <span v-else @click="slotProps.data.telephone ? makeCall(slotProps.data.telephone) : null" 
                      class="hospital-icon" 
                      :class="{ 'inactive-icon': !slotProps.data.telephone }"
                      :title="slotProps.data.telephone ? '전화걸기' : '전화번호 정보 없음'">
                  <i class="pi pi-phone"></i>
                </span>
              </template>
              
              <template v-else-if="col.field === 'handphone'">
                <!-- PC: 휴대폰번호 텍스트 표시 -->
                <span v-if="screenWidth > 768">
                  {{ slotProps.data.handphone || '-' }}
                </span>
                <!-- 모바일: 휴대폰 아이콘 (활성/비활성) -->
                <span v-else @click="slotProps.data.handphone ? makeCall(slotProps.data.handphone) : null" 
                      class="hospital-icon" 
                      :class="{ 'inactive-icon': !slotProps.data.handphone }"
                      :title="slotProps.data.handphone ? '전화걸기' : '휴대폰번호 정보 없음'">
                  <i class="pi pi-mobile"></i>
                </span>
              </template>

              <template v-else-if="col.type === 'icon' && col.field === 'license'">
                <span v-if="slotProps.data.business_license_file" @click="openFileModal(slotProps.data)" style="cursor:pointer;">
                  <i class="pi pi-file biz-doc-icon"></i>
                </span>
                <span v-else>-</span>
              </template>
              
              <template v-else-if="col.type === 'icon' && col.field === 'more'">
                <div class="more-dropdown-wrapper" :data-hospital-id="slotProps.data.id">
                  <span @click="toggleMoreDropdown(slotProps.data.id)" class="more-icon" title="더보기">
                    <i class="pi pi-ellipsis-v"></i>
                  </span>
                </div>
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
      </div>
    </div>

    <!-- 페이지네이터 미사용
    <div class="fixed-paginator">
      <Paginator
        :rows="pageSize"
        :totalRecords="totalCount"
        :first="first"
        :rowsPerPageOptions="[100, 200, 500]"
        @page="onPageChange"
      />
    </div>
    -->

    <!-- More Dropdown (Portal to body) -->
    <teleport to="body">
      <div v-if="activeDropdown" class="more-dropdown-box" :style="dropdownStyle">
        <button class="dropdown-item" @click="requestFilter(activeDropdownData)">
          <i class="pi pi-filter"></i>
          <span>필터링 요청</span>
        </button>
        <button class="dropdown-item" @click="viewApprovedPharmaceuticals(activeDropdownData)">
          <i class="pi pi-check-circle"></i>
          <span>승인 제약사</span>
        </button>
        <button class="dropdown-item" 
                @click="viewBusinessLicense(activeDropdownData)"
                :disabled="!activeDropdownData?.business_license_file"
                :class="{ 'dropdown-item-disabled': !activeDropdownData?.business_license_file }">
          <i class="pi pi-file"></i>
          <span>사업자등록증</span>
        </button>
        <button class="dropdown-item" @click="editHospital(activeDropdownData)">
          <i class="pi pi-pencil"></i>
          <span>수정</span>
        </button>
        <button class="dropdown-item" @click="deleteHospital(activeDropdownData)">
          <i class="pi pi-trash"></i>
          <span>삭제</span>
        </button>
      </div>
    </teleport>

    <!-- File Viewer Modal -->
    <div v-if="showFileModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title" style="text-align: center;">사업자등록증</h3>
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

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import Paginator from 'primevue/paginator';
import * as XLSX from 'xlsx';
import { v4 as uuidv4 } from 'uuid';
import { userHospitalsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const router = useRouter();

// Component state
const allHospitals = ref([]);
const screenWidth = ref(window.innerWidth);
const hospitals = ref([]);
const loading = ref(false);
const search = ref('');
const first = ref(0);
const totalCount = ref(0);
const pageSize = ref(100);
const appliedSearch = ref('');
const currentFilePath = ref(null);
const isSearched = ref(false);

// Modal state
const showFileModal = ref(false);
const fileUrl = ref('');
const currentHospital = ref(null);

// More dropdown state
const activeDropdown = ref(null);
const activeDropdownData = ref(null);
const dropdownStyle = ref({});

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userHospitalsTableConfig.mobile : userHospitalsTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const isPdfFile = computed(() => {
  if (!currentFilePath.value) return false;
  const extension = currentFilePath.value.split('.').pop()?.toLowerCase();
  return extension === 'pdf';
});

const goToCreatePage = () => {
  router.push('/hospitals/create');
};

const goToEditPage = (id) => {
  router.push(`/hospitals/edit/${id}`);
};

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
            return;
        }

        let hospitalIdsQuery = supabase
            .from('hospital_member_mappings')
            .select('hospital_id')
            .eq('member_id', user.id);

        const { data: idData, error: idError } = await hospitalIdsQuery;
        if (idError) throw idError;
        
        const hospitalIds = idData.map(item => item.hospital_id);
        if (hospitalIds.length === 0) {
            hospitals.value = [];
            totalCount.value = 0;
            loading.value = false;
            return;
        }

        let query = supabase
            .from('hospitals')
            .select(`
                *,
                creator:registered_by ( company_name ),
                updater:updated_by ( company_name ),
                mappings:hospital_member_mappings!inner(id)
            `, { count: 'exact' })
            .in('id', hospitalIds)
            .eq('mappings.member_id', user.id);

        if (appliedSearch.value) {
            const searchTerm = `%${appliedSearch.value}%`;
            query = query.or(
                `hospital_name.ilike.${searchTerm},` +
                `director_name.ilike.${searchTerm},` +
                `business_registration_number.ilike.${searchTerm},` +
                `address.ilike.${searchTerm}`
            );
        }

        query = query
            .range(pageFirst, pageFirst + pageRows - 1);

        const { data, error, count } = await query;
        if (error) throw error;

        // 데이터를 가져온 후 JavaScript에서 정렬
        const sortedData = data.sort((a, b) => 
            a.hospital_name.localeCompare(b.hospital_name, 'ko')
        );

        hospitals.value = sortedData.map(item => ({
            ...item,
            creator_name: item.creator ? item.creator.company_name : '-',
            updater_name: item.updater ? item.updater.company_name : '-',
            mapping_id: item.mappings[0]?.id
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

// watch(search, ...) 등 실시간 검색 완전 제거

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchHospitals(event.first, event.rows);
};

const onSearch = () => {
  if (search.value.length < 2) return;
  appliedSearch.value = search.value.trim();
  first.value = 0;
  isSearched.value = true;
  fetchHospitals(0, pageSize.value);
};

const onReset = () => {
  if (isSearched.value) {
    search.value = '';
    appliedSearch.value = '';
    first.value = 0;
    isSearched.value = false;
    fetchHospitals(0, pageSize.value);
  } else {
    search.value = '';
  }
};

const handleResize = () => {
  screenWidth.value = window.innerWidth;
};

onMounted(() => {
    window.addEventListener('resize', handleResize);
    document.addEventListener('click', handleClickOutside);
    fetchHospitals(first.value, pageSize.value);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
  document.removeEventListener('click', handleClickOutside);
});

// 외부 클릭 시 드롭다운 닫기
const handleClickOutside = (event) => {
  if (activeDropdown.value && !event.target.closest('.more-dropdown-wrapper') && !event.target.closest('.more-dropdown-box')) {
    activeDropdown.value = null;
    activeDropdownData.value = null;
  }
};

// 지도 열기 함수
const openMap = (address) => {
  const encodedAddress = encodeURIComponent(address);
  window.open(`https://map.kakao.com/link/search/${encodedAddress}`, '_blank');
};

// 전화걸기 함수
const makeCall = (phoneNumber) => {
  if (!phoneNumber) return;
  // 전화번호 정리 (하이픈 제거)
  const cleanNumber = phoneNumber.replace(/-/g, '');
  window.location.href = `tel:${cleanNumber}`;
};

// 더보기 드롭다운 토글
const toggleMoreDropdown = (hospitalId) => {
  if (activeDropdown.value === hospitalId) {
    activeDropdown.value = null;
    activeDropdownData.value = null;
  } else {
    activeDropdown.value = hospitalId;
    activeDropdownData.value = hospitals.value.find(h => h.id === hospitalId);
    
    // 드롭다운 위치 계산
    setTimeout(() => {
      const dropdownElement = document.querySelector(`.more-dropdown-wrapper[data-hospital-id="${hospitalId}"]`);
      if (dropdownElement) {
        const rect = dropdownElement.getBoundingClientRect();
        dropdownStyle.value = {
          position: 'fixed',
          top: `${rect.bottom + 5}px`,
          left: `${rect.left - 140}px`, // 드롭다운 너비(160px)에서 아이콘 위치 조정
          zIndex: 10000
        };
      }
    }, 0);
  }
};

// 더보기 드롭다운 메뉴 액션들
const requestFilter = (hospital) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  // TODO: 필터링 요청 페이지로 이동
  console.log('필터링 요청:', hospital);
  alert('필터링 요청 기능은 구현 예정입니다.');
};

const viewApprovedPharmaceuticals = (hospital) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  // TODO: 승인 제약사 보기
  console.log('승인 제약사 보기:', hospital);
  alert('승인 제약사 보기 기능은 구현 예정입니다.');
};

const viewBusinessLicense = (hospital) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  if (hospital.business_license_file) {
    openFileModal(hospital);
  } else {
    alert('사업자등록증이 등록되지 않았습니다.');
  }
};

const editHospital = (hospital) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  goToEditPage(hospital.id);
};

const deleteHospital = (hospital) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  confirmDeleteMapping(hospital);
};

const getPublicUrl = (filePath) => {
  if (!filePath) return '';
  const { data } = supabase.storage.from('hospital-biz-licenses').getPublicUrl(filePath);
  return data.publicUrl;
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
    if (hospitals.value.length === 0) {
        alert('데이터가 없어 엑셀 다운로드를 할 수 없습니다.');
        return;
    }
    loading.value = true;
    try {
        const formattedData = hospitals.value.map((item, index) => ({
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

const confirmDeleteMapping = (hospital) => {
  if (window.confirm(`'${hospital.hospital_name}' 거래처를 삭제하시겠습니까?`)) {
    deleteMapping(hospital);
  }
};

const deleteMapping = async (hospital) => {
  loading.value = true;
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error("User not found");

    // Get the mapping ID
    const { data: mappingData, error: mappingError } = await supabase
      .from('hospital_member_mappings')
      .select('id')
      .eq('hospital_id', hospital.id)
      .eq('member_id', user.id)
      .single();

    if (mappingError || !mappingData) {
        throw new Error('해당 거래처와의 연결 정보를 찾을 수 없습니다.');
    }
    
    // Delete the mapping
    const { error: deleteError } = await supabase
      .from('hospital_member_mappings')
      .delete()
      .eq('id', mappingData.id);
      
    if (deleteError) throw deleteError;

    alert('거래처가 삭제되었습니다.');
    await fetchHospitals(first.value, pageSize.value); // Refresh the list
  } catch (error) {
    console.error('Error deleting hospital mapping:', error.message);
    alert('거래처 연결 해제 중 오류가 발생했습니다: ' + error.message);
  } finally {
    loading.value = false;
  }
};

</script>
