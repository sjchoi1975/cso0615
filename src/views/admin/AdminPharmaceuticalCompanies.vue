<template>
  <div class="admin-pharmaceutical-companies-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <span class="hide-mobile">통합 검색</span>
        <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="제약사명 입력" />
        <div class="hide-mobile" style="display: flex; gap: 0.5rem; align-items: center;">
          <button type="button" class="btn-search" @click="onSearch" :disabled="!isSearchEnabled">검색</button>
          <button type="button" class="btn-reset" @click="onReset">
            <i class="pi pi-refresh" style="font-size: 1rem;"></i>
            초기화
          </button>
        </div>
        <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
          <input v-model="search" class="input-search wide-mobile-search" placeholder="제약사명 입력" @keyup.enter="onSearch"/>
          <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onClearSearch"
            style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          <i class="pi pi-search search-btn-icon" @click="isSearchEnabled && onSearch()"
            :class="{ 'disabled': !isSearchEnabled }"
            style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
        </div>
      </div>
    </div>

    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}개사</div>
      <div style="display: flex; gap: 1rem;">
        <Button
          icon="pi pi-pencil"
          label="제약사 추가"
          class="btn-add-md"
          @click="openCreateModal"
          iconPos="left"
          style="gap:0.5em;"
        />
        <Button
          icon="pi pi-download"
          label="다운로드"
          class="btn-download-md"
          @click="downloadExcel"
          iconPos="left"
          style="gap:0.5em;"
        />
      </div>
    </div>

    <!-- 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="filteredList"
          :loading="false"
          :paginator="false"
          scrollable
          :scrollHeight="tableScrollHeight"
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
                {{ slotProps.index + 1 }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'edit'">
                <Button icon="pi pi-pencil" class="p-button-rounded p-button-text btn-icon-edit" @click="openEditModal(slotProps.data)" />
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'delete'">
                <Button icon="pi pi-trash" class="p-button-rounded p-button-text btn-icon-danger" @click="confirmDelete(slotProps.data)" />
              </template>
              <template v-else-if="col.field === 'filtering_status'">
                <div class="custom-toggle-wrap">
                  <input
                    type="checkbox"
                    :id="'filtering-status-' + slotProps.data.id"
                    :checked="slotProps.data.filtering_status === 'active'"
                    @change="toggleFilteringStatus(slotProps.data)"
                    class="custom-toggle-checkbox"
                  />
                  <label :for="'filtering-status-' + slotProps.data.id" class="custom-toggle-label"></label>
                </div>
              </template>
              <template v-else-if="col.field === 'edi_status'">
                <div class="custom-toggle-wrap">
                  <input
                    type="checkbox"
                    :id="'edi-status-' + slotProps.data.id"
                    :checked="slotProps.data.edi_status === 'active'"
                    @change="toggleEdiStatus(slotProps.data)"
                    class="custom-toggle-checkbox"
                  />
                  <label :for="'edi-status-' + slotProps.data.id" class="custom-toggle-label"></label>
                </div>
              </template>
              <template v-else-if="col.field === 'filtering_comment'">
                <div class="comment-cell">
                  <a 
                    v-if="slotProps.data.filtering_comment"
                    class="link"
                    @click="showFilteringComment(slotProps.data)"
                  >
                    {{ slotProps.data.filtering_comment }}
                  </a>
                </div>
              </template>
              <template v-else-if="col.field === 'edi_comment'">
                <div class="comment-cell">
                  <a 
                    v-if="slotProps.data.edi_comment"
                    class="link"
                    @click="showEdiComment(slotProps.data)"
                  >
                    {{ slotProps.data.edi_comment }}
                  </a>
                </div>
              </template>
              <template v-else-if="col.field === 'created_at'">
                {{ formatDate(slotProps.data.created_at) }}
              </template>
              <template v-else-if="col.field === 'company_name'">
                <span class="table-title">{{ slotProps.data.company_name }}</span>
              </template>
              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- 제약사 추가/수정 모달 -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">{{ isEdit ? '제약사 수정' : '제약사 추가' }}</h3>
        </div>
        <div class="modal-body">
          <div class="form-grid">
            <div class="form-group">
              <label class="label">제약사명<span class="required">*</span></label>
              <input 
                v-model="formData.company_name" 
                type="text" 
                class="input" 
                placeholder="제약사명을 입력하세요"
                required
              />
            </div>
            <div class="form-group">
              <label class="label">필터링</label>
              <div class="status-input">
                <div
                  class="custom-toggle-wrap custom-toggle-wrap-left" 
                  style="
                    display: flex; 
                    justify-content: flex-start; 
                    margin-bottom: 1rem;
                    width: 100%;
                    padding-left: 0;
                  "
                >
                  <input
                    type="checkbox"
                    v-model="formData.filtering_status"
                    :true-value="'active'"
                    :false-value="'inactive'"
                    class="custom-toggle-checkbox"
                    :id="'modal-filtering-status'"
                  />
                  <label
                    :for="'modal-filtering-status'" 
                    class="custom-toggle-label"
                    style="margin-left: 0;"
                  >
                  </label>
                </div>
                <textarea
                  v-model="formData.filtering_comment"
                  class="input"
                  placeholder="필터링 관련 안내 메시지"
                  rows="4"
                ></textarea>
              </div>
            </div>
            <div class="form-group">
              <label class="label">EDI 증빙 파일</label>
              <div class="status-input">
                <div
                  class="custom-toggle-wrap custom-toggle-wrap-left" 
                  style="
                    display: flex; 
                    justify-content: flex-start; 
                    margin-bottom: 1rem;
                    width: 100%;
                    padding-left: 0;"
                >
                  <input
                    type="checkbox"
                    v-model="formData.edi_status"
                    :true-value="'active'"
                    :false-value="'inactive'"
                    class="custom-toggle-checkbox"
                    :id="'modal-edi-status'"
                  />
                  <label
                    :for="'modal-edi-status'" 
                    class="custom-toggle-label"
                    style="margin-left: 0;"
                  >
                  </label>
                </div>
                <textarea
                  v-model="formData.edi_comment"
                  class="input"
                  placeholder="EDI 관련 안내 메시지"
                  rows="4"
                ></textarea>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeModal">취소</button>
          <button class="btn-confirm modal" @click="saveCompany" 
            :disabled="!canSave || loading"
          >
            {{ loading ? '저장 중...' : (isEdit ? '수정' : '추가') }}
          </button>
        </div>
      </div>
    </div>

    <!-- 상태 안내 메시지 모달 -->
    <div v-if="showCommentDialog" class="custom-modal-overlay" @click.self="showCommentDialog = false">
      <div class="custom-modal">
        <div class="modal-header">
          <div class="modal-title">{{ commentDialogTitle }}</div>
        </div>
        <div class="modal-body">
          <div style="white-space: pre-line;">{{ commentDialogContent }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="showCommentDialog = false">닫기</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { supabase } from '@/supabase';
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import * as XLSX from 'xlsx';
import Dialog from 'primevue/dialog';
import { pharmaceuticalCompaniesTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const companies = ref([]);
const filteredList = ref([]);
const loading = ref(true);
const search = ref('');
const isSearched = ref(false);
const totalCount = ref(0);

const isModalVisible = ref(false);
const modalTitle = ref('');

const showModal = ref(false);
const isEdit = ref(false);
const formData = ref({
  id: null,
  company_name: '',
  filtering_status: 'inactive',
  edi_status: 'inactive',
  filtering_comment: '',
  edi_comment: ''
});

// 원본 데이터 저장
const originalData = ref({
  company_name: '',
  filtering_status: 'inactive',
  edi_status: 'inactive',
  filtering_comment: '',
  edi_comment: ''
});

const showCommentDialog = ref(false);
const commentDialogTitle = ref('');
const commentDialogContent = ref('');

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? pharmaceuticalCompaniesTableConfig.mobile : pharmaceuticalCompaniesTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(false));

// 검색 활성화 조건
const isSearchEnabled = computed(() => {
  return search.value.length >= 2;
});

// 필수값 검증
const canSubmit = computed(() => {
  return formData.value.company_name.trim().length > 0;
});

// 변경사항 확인
const hasChanges = computed(() => {
  return formData.value.company_name !== originalData.value.company_name ||
         formData.value.filtering_status !== originalData.value.filtering_status ||
         formData.value.edi_status !== originalData.value.edi_status ||
         formData.value.filtering_comment !== originalData.value.filtering_comment ||
         formData.value.edi_comment !== originalData.value.edi_comment;
});

// 버튼 활성화 조건
const canSave = computed(() => {
  if (isEdit.value) {
    // 수정 모드: 필수값 + 변경사항
    return canSubmit.value && hasChanges.value;
  } else {
    // 추가 모드: 필수값만
    return canSubmit.value;
  }
});

// 제약사 데이터 불러오기
const fetchCompanies = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('pharmaceutical_companies')
      .select('*')
      .order('company_name', { ascending: true }); // 가나다순 정렬
    
    if (error) throw error;
    
    companies.value = data.map(item => ({
      ...item,
      created_at: new Date(item.created_at).toLocaleDateString('ko-KR')
    }));
    
    // 가나다순 정렬
    companies.value.sort((a, b) => 
      a.company_name.localeCompare(b.company_name, 'ko-KR')
    );
    
    filteredList.value = companies.value;
    totalCount.value = companies.value.length;
  } catch (e) {
    alert('제약사 데이터 조회 실패: ' + e.message);
  }
  loading.value = false;
};

// 검색 실행
const onSearch = () => {
  if (!isSearchEnabled.value) return;
  isSearched.value = true;
  
  const keyword = search.value.toLowerCase();
  const result = companies.value.filter(company => 
    company.company_name.toLowerCase().includes(keyword)
  );
  
  // 가나다순 정렬
  filteredList.value = result.sort((a, b) => 
    a.company_name.localeCompare(b.company_name, 'ko-KR')
  );
  
  totalCount.value = filteredList.value.length;
};

// 초기화
const onReset = () => {
  search.value = '';
  isSearched.value = false;
  // 가나다순 정렬된 전체 목록으로 복원
  filteredList.value = companies.value.sort((a, b) => 
    a.company_name.localeCompare(b.company_name, 'ko-KR')
  );
  totalCount.value = companies.value.length;
};

// 검색어만 초기화 (모바일 X 버튼)
const onClearSearch = () => {
  if (isSearched.value) {
    // 검색 후: 전체 초기화
    onReset();
  } else {
    // 검색 전: 검색어만 삭제
    search.value = '';
  }
};

// 제약사 선택 모달용 목록 생성 (가나다순, 활성만)
const activeSortedCompanies = computed(() => {
  return companies.value
    .filter(c => c.status === 'active')
    .sort((a, b) => a.company_name.localeCompare(b.company_name, 'ko'));
});

// 모달 열기/닫기
const openCreateModal = () => {
  isEdit.value = false;
  formData.value = {
    id: null,
    company_name: '',
    filtering_status: 'active',  // 기본값을 active로 변경
    edi_status: 'active',      // 기본값을 active로 변경
    filtering_comment: '',
    edi_comment: ''
  };
  // 추가 모드에서는 원본 데이터 초기화
  originalData.value = {
    company_name: '',
    filtering_status: 'active',
    edi_status: 'active',
    filtering_comment: '',
    edi_comment: ''
  };
  showModal.value = true;
};

const openEditModal = (company) => {
  isEdit.value = true;
  formData.value = {
    id: company.id,
    company_name: company.company_name,
    filtering_status: company.filtering_status || 'inactive',
    edi_status: company.edi_status || 'inactive',
    filtering_comment: company.filtering_comment || '',
    edi_comment: company.edi_comment || ''
  };
  // 원본 데이터 저장
  originalData.value = {
    company_name: company.company_name,
    filtering_status: company.filtering_status || 'inactive',
    edi_status: company.edi_status || 'inactive',
    filtering_comment: company.filtering_comment || '',
    edi_comment: company.edi_comment || ''
  };
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  formData.value = {
    id: null,
    company_name: '',
    filtering_status: 'inactive',
    edi_status: 'inactive',
    filtering_comment: '',
    edi_comment: ''
  };
  // 원본 데이터도 초기화
  originalData.value = {
    company_name: '',
    filtering_status: 'inactive',
    edi_status: 'inactive',
    filtering_comment: '',
    edi_comment: ''
  };
};

// 제약사 저장
const saveCompany = async () => {
  if (!formData.value.company_name.trim()) {
    alert('제약사명을 입력해주세요.');
    return;
  }

  loading.value = true;
  
  try {
    if (isEdit.value) {
      // 수정
      const { error } = await supabase
        .from('pharmaceutical_companies')
        .update({
          company_name: formData.value.company_name.trim(),
          filtering_status: formData.value.filtering_status,
          edi_status: formData.value.edi_status,
          filtering_comment: formData.value.filtering_comment.trim() || null,
          edi_comment: formData.value.edi_comment.trim() || null
        })
        .eq('id', formData.value.id);
      
      if (error) throw error;
      alert('제약사가 수정되었습니다.');
    } else {
      // 추가
      const { error } = await supabase
        .from('pharmaceutical_companies')
        .insert([{
          company_name: formData.value.company_name.trim(),
          filtering_status: 'active',  // 기본값을 active로 변경
          edi_status: 'active'       // 기본값을 active로 변경
        }]);
      
      if (error) throw error;
      alert('제약사가 추가되었습니다.');
    }
    
    closeModal();
    await fetchCompanies(); // 목록 새로고침
  } catch (e) {
    if (e.code === '23505') {
      alert('이미 존재하는 제약사명입니다.');
    } else {
      alert('저장 실패: ' + e.message);
    }
  } finally {
    loading.value = false;
  }
};

// 제약사 삭제
const deleteCompany = async (company) => {
  if (!confirm(`"${company.company_name}" 제약사를 삭제하시겠습니까?`)) {
    return;
  }

  try {
    const { error } = await supabase
      .from('pharmaceutical_companies')
      .delete()
      .eq('id', company.id);
    
    if (error) throw error;
    
    alert('제약사가 삭제되었습니다.');
    await fetchCompanies(); // 목록 새로고침
  } catch (e) {
    if (e.code === '23503') {
      alert('이 제약사는 필터링 요청에서 사용되고 있어 삭제할 수 없습니다.');
    } else {
      alert('삭제 실패: ' + e.message);
    }
  }
};

// 엑셀 다운로드
const downloadExcel = () => {
  if (!filteredList.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  const headers = ['순번', '제약사명', '등록일'];
  
  const data = filteredList.value.map((item, index) => [
    index + 1,
    item.company_name,
    item.created_at
  ]);
  
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '제약사목록');
  const fileName = `제약사목록_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};



const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const year = date.getFullYear();
  const month = ('0' + (date.getMonth() + 1)).slice(-2);
  const day = ('0' + date.getDate()).slice(-2);
  return `${year}-${month}-${day}`;
};

async function toggleStatus(company) {
  const newStatus = company.status === 'active' ? 'inactive' : 'active';
  const { error } = await supabase
    .from('pharmaceutical_companies')
    .update({ status: newStatus })
    .eq('id', company.id);
  if (!error) {
    company.status = newStatus;
  } else {
    alert('상태 변경에 실패했습니다.');
  }
}

// 필터링 상태 토글
async function toggleFilteringStatus(company) {
  const newStatus = company.filtering_status === 'active' ? 'inactive' : 'active';
  const { error } = await supabase
    .from('pharmaceutical_companies')
    .update({ filtering_status: newStatus })
    .eq('id', company.id);
  if (!error) {
    company.filtering_status = newStatus;
  } else {
    alert('필터링 상태 변경에 실패했습니다.');
  }
}

// EDI 상태 토글
async function toggleEdiStatus(company) {
  const newStatus = company.edi_status === 'active' ? 'inactive' : 'active';
  const { error } = await supabase
    .from('pharmaceutical_companies')
    .update({ edi_status: newStatus })
    .eq('id', company.id);
  if (!error) {
    company.edi_status = newStatus;
  } else {
    alert('EDI 상태 변경에 실패했습니다.');
  }
}

// 필터링 상태 메시지 표시
const showFilteringComment = (company) => {
  commentDialogTitle.value = '필터링 전달사항';
  commentDialogContent.value = company.filtering_comment;
  showCommentDialog.value = true;
};

// EDI 상태 메시지 표시
const showEdiComment = (company) => {
  commentDialogTitle.value = 'EDI 증빙파일 전달사항';
  commentDialogContent.value = company.edi_comment;
  showCommentDialog.value = true;
};

onMounted(async () => {
  await fetchCompanies();
});
</script>

