<template>
  <div class="admin-pharmaceutical-companies-view page-container">
    <!-- 필터카드 -->
    
    <div class="filter-card">
      <div class="filter-row">
        <span class="hide-mobile">통합 검색</span>
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="제약사명 입력" class="input-search wide-mobile-search" />
        </span>
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
          :value="filteredCompanies"
          :loading="loading"
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
                {{ slotProps.index + 1 + first }}
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
              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Paginator -->
    <div class="fixed-paginator">
      <Paginator :rows="pageSize" :totalRecords="totalCount" :first="first" @page="onPageChange" />
    </div>

    <!-- 제약사 추가/수정 모달 -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">{{ isEdit ? '제약사 수정' : '제약사 추가' }}</h3>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>제약사명</label>
            <input 
              v-model="formData.company_name" 
              type="text" 
              class="input" 
              placeholder="제약사명을 입력하세요"
              required
              style="margin-bottom: 2rem;"
            />
          </div>
          <div class="form-group">
            <label>필터링</label>
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
                placeholder="필터링 관련 안내 메시지 (선택사항)"
                rows="4"
                style="margin-bottom: 2rem;"
              ></textarea>
            </div>
          </div>
          <div class="form-group">
            <label>EDI 증빙 파일</label>
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
                placeholder="EDI 관련 안내 메시지 (선택사항)"
                rows="4"
              ></textarea>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeModal">취소</button>
          <button class="btn-confirm modal" @click="saveCompany" 
            :disabled="!formData.company_name.trim() || loading"
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
import Paginator from 'primevue/paginator';
import Dialog from 'primevue/dialog';
import { pharmaceuticalCompaniesTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const companies = ref([]);
const loading = ref(true);
const search = ref('');
const totalCount = ref(0);
const pageSize = 10;
const first = ref(0);

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

const showCommentDialog = ref(false);
const commentDialogTitle = ref('');
const commentDialogContent = ref('');

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? pharmaceuticalCompaniesTableConfig.mobile : pharmaceuticalCompaniesTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

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
    
    totalCount.value = companies.value.length;
  } catch (e) {
    alert('제약사 데이터 조회 실패: ' + e.message);
  }
  loading.value = false;
};

// 필터링된 리스트
const filteredCompanies = computed(() => {
  let result = [...companies.value];
  
  if (search.value) {
    const keyword = search.value.toLowerCase();
    result = result.filter(company => 
      company.company_name.toLowerCase().includes(keyword)
    );
  }
  
  // 한글 가나다순 정렬
  return result.sort((a, b) => 
    a.company_name.localeCompare(b.company_name, 'ko-KR')
  );
});

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
  if (!filteredCompanies.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  const headers = ['순번', '제약사명', '등록일'];
  
  const data = filteredCompanies.value.map((item, index) => [
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

const onPageChange = (event) => {
  first.value = event.first;
  fetchCompanies();
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

