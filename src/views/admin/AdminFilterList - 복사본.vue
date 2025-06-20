<template>
  <div class="admin-filter-list-view page-container">
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span>상태</span>
        <select v-model="selectedStatus" class="input-120">
          <option value="">전체</option>
          <option value="pending">대기중</option>
          <option value="approved">승인</option>
          <option value="rejected">거절</option>
        </select>
      </div>
      <div class="filter-row">
        <span>필터링 구분</span>
        <select v-model="selectedFilterType" class="input-120">
          <option value="">전체</option>
          <option value="new">신규</option>
          <option value="transfer">이관</option>
        </select>
      </div>
    </div>

    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
      <div style="display: flex; gap: 0.5rem;">
        <button class="btn-add" @click="downloadExcel">엑셀 다운로드</button>
      </div>
    </div>

    <!-- 테이블카드 -->
    <div class="table-card">
      <DataTable :value="filteredList" :loading="loading" :paginator="false" scrollable :scrollHeight="'calc(100vh - 220px)'">
        <template #empty>
          <div v-if="!loading">조회된 데이터가 없습니다.</div>
        </template>
        <Column header="순번" :style="{ width: columnWidths.index, textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ slotProps.index + 1 }}
          </template>
        </Column>
        <Column
          v-for="col in columns"
          :key="col.field"
          :field="col.field"
          :header="col.header"
          :sortable="columnSortables[col.field] || false"
          :headerStyle="{ width: columnWidths[col.field], textAlign: columnAligns[col.field] }"
          :bodyStyle="{ textAlign: columnAligns[col.field] }"
        >
          <template v-if="col.field === 'status'" #body="slotProps">
            <span :class="getStatusClass(slotProps.data.status)">
              {{ getStatusText(slotProps.data.status) }}
            </span>
          </template>
          <template v-if="col.field === 'user_remarks'" #body="slotProps">
            <span
              v-if="slotProps.data.user_remarks"
              class="link"
              :title="slotProps.data.user_remarks"
              @click="openRemarksPopup(slotProps.data)"
            >
              {{ slotProps.data.user_remarks }}
            </span>
          </template>
          <template v-if="col.field === 'admin_comments'" #body="slotProps">
            <span
              v-if="slotProps.data.admin_comments"
              class="link"
              :title="slotProps.data.admin_comments"
              @click="openCommentsPopup(slotProps.data)"
            >
              {{ slotProps.data.admin_comments }}
            </span>
          </template>
        </Column>
        <Column header="관리" :style="{ width: columnWidths.manage, textAlign: columnAligns.manage }">
          <template #body="slotProps">
            <button 
              v-if="slotProps.data.status === 'pending'"
              class="btn-detail" 
              @click="openManageModal(slotProps.data)"
            >
              관리
            </button>
            <span v-else style="color: var(--text-light);">완료</span>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 비고 팝업 -->
    <div v-if="showRemarksDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <label class="modai-title">비고</label>
        <div class="modal-body">
          <div style="white-space: pre-line;">{{ remarksValue }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-primary" @click="closeRemarksDialog">확인</button>
        </div>
      </div>
    </div>

    <!-- 관리자 코멘트 팝업 -->
    <div v-if="showCommentsDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <label class="modai-title">관리자 코멘트</label>
        <div class="modal-body">
          <div style="white-space: pre-line;">{{ commentsValue }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-primary" @click="closeCommentsDialog">확인</button>
        </div>
      </div>
    </div>

    <!-- 관리 모달 -->
    <div v-if="showManageModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-footer">
          <h3 class="modai-title">필터링 요청 관리</h3>
          <button class="btn-close-nobg" @click="closeManageModal">×</button>
        </div>
        <div class="modal-body">
          <div class="filter-row">
            <label class="form-label">요청자</label>
            <div>{{ selectedRequest?.member_name || '' }}</div>
          </div>
          <div class="filter-row">
            <label class="form-label">병원명</label>
            <div>{{ selectedRequest?.hospital_name || '' }}</div>
          </div>
          <div class="filter-row">
            <label class="form-label">제약사</label>
            <div>{{ selectedRequest?.pharmaceutical_company_name || '' }}</div>
          </div>
          <div class="filter-row">
            <label class="form-label">필터링 구분</label>
            <div>{{ getFilterTypeText(selectedRequest?.filter_type) }}</div>
          </div>
          <div class="filter-row">
            <label class="form-label">비고</label>
            <div style="white-space: pre-line;">{{ selectedRequest?.user_remarks || '' }}</div>
          </div>
          <div class="filter-row">
            <label class="form-label">상태 변경</label>
            <select v-model="newStatus" class="input">
              <option value="pending">대기중</option>
              <option value="approved">승인</option>
              <option value="rejected">거절</option>
            </select>
          </div>
          <div class="filter-row">
            <label class="form-label">관리자 코멘트</label>
            <textarea 
              v-model="newComments" 
              class="input" 
              placeholder="관리자 코멘트를 입력하세요"
              rows="4"
              style="resize: vertical;"
            ></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeManageModal">취소</button>
          <button 
            class="btn-save" 
            @click="updateRequest"
            :disabled="loading"
          >
            {{ loading ? '저장 중...' : '저장' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

const filterList = ref([]); // 필터링 요청 목록
const loading = ref(false);
const totalCount = ref(0);

const selectedStatus = ref('');
const selectedFilterType = ref('');

// 팝업 상태
const showRemarksDialog = ref(false);
const showCommentsDialog = ref(false);
const showManageModal = ref(false);
const remarksValue = ref('');
const commentsValue = ref('');

// 관리 모달 상태
const selectedRequest = ref(null);
const newStatus = ref('pending');
const newComments = ref('');

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  created_at: '8%',
  member_name: '10%',
  filter_type: '6%',
  hospital_name: '12%',
  pharmaceutical_company_name: '12%',
  status: '6%',
  user_remarks: '12%',
  admin_comments: '12%',
  manage: '8%'
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  created_at: 'center',
  member_name: 'left',
  filter_type: 'center',
  hospital_name: 'left',
  pharmaceutical_company_name: 'left',
  status: 'center',
  user_remarks: 'left',
  admin_comments: 'left',
  manage: 'center'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  created_at: true,
  member_name: true,
  filter_type: true,
  hospital_name: true,
  pharmaceutical_company_name: true,
  status: true
};

// 컬럼 배열 한 곳에서 관리
const columns = [
  { field: 'created_at', header: '요청일' },
  { field: 'member_name', header: '요청자' },
  { field: 'filter_type', header: '구분' },
  { field: 'hospital_name', header: '병원명' },
  { field: 'pharmaceutical_company_name', header: '제약사' },
  { field: 'status', header: '상태' },
  { field: 'user_remarks', header: '비고' },
  { field: 'admin_comments', header: '관리자 코멘트' }
];

// 필터링된 리스트
const filteredList = computed(() => {
  let filtered = filterList.value;
  
  if (selectedStatus.value) {
    filtered = filtered.filter(item => item.status === selectedStatus.value);
  }
  
  if (selectedFilterType.value) {
    filtered = filtered.filter(item => item.filter_type === selectedFilterType.value);
  }
  
  return filtered;
});

// 필터링 요청 목록 불러오기
const fetchFilterList = async () => {
  loading.value = true;
  filterList.value = [];
  
  try {
    const { data, error } = await supabase
      .from('filtering_requests')
      .select(`
        *,
        members (
          company_name
        ),
        hospitals (
          hospital_name
        ),
        pharmaceutical_companies (
          company_name
        )
      `)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    
    if (data) {
      filterList.value = data.map(item => ({
        ...item,
        member_name: item.members?.company_name || '',
        hospital_name: item.hospitals?.hospital_name || '',
        pharmaceutical_company_name: item.pharmaceutical_companies?.company_name || '',
        created_at: new Date(item.created_at).toLocaleDateString('ko-KR')
      }));
    }
    
    totalCount.value = filterList.value.length;
  } catch (e) {
    alert('필터링 요청 목록 조회 실패: ' + e.message);
  }
  
  loading.value = false;
};

// 상태별 클래스 반환
const getStatusClass = (status) => {
  switch (status) {
    case 'pending': return 'badge-warning';
    case 'approved': return 'badge-success';
    case 'rejected': return 'badge-danger';
    default: return 'badge-secondary';
  }
};

// 상태별 텍스트 반환
const getStatusText = (status) => {
  switch (status) {
    case 'pending': return '대기중';
    case 'approved': return '승인';
    case 'rejected': return '거절';
    default: return '알 수 없음';
  }
};

// 필터링 구분 텍스트 반환
const getFilterTypeText = (type) => {
  switch (type) {
    case 'new': return '신규';
    case 'transfer': return '이관';
    default: return type;
  }
};

// 비고 팝업
const openRemarksPopup = (row) => {
  remarksValue.value = row.user_remarks;
  showRemarksDialog.value = true;
};

const closeRemarksDialog = () => {
  showRemarksDialog.value = false;
};

// 관리자 코멘트 팝업
const openCommentsPopup = (row) => {
  commentsValue.value = row.admin_comments;
  showCommentsDialog.value = true;
};

const closeCommentsDialog = () => {
  showCommentsDialog.value = false;
};

// 관리 모달
const openManageModal = (row) => {
  selectedRequest.value = row;
  newStatus.value = row.status;
  newComments.value = row.admin_comments || '';
  showManageModal.value = true;
};

const closeManageModal = () => {
  showManageModal.value = false;
  selectedRequest.value = null;
  newStatus.value = 'pending';
  newComments.value = '';
};

// 요청 업데이트
const updateRequest = async () => {
  if (!selectedRequest.value) return;
  
  loading.value = true;
  
  try {
    const { error } = await supabase
      .from('filtering_requests')
      .update({
        status: newStatus.value,
        admin_comments: newComments.value,
        updated_at: new Date().toISOString()
      })
      .eq('id', selectedRequest.value.id);
    
    if (error) throw error;
    
    alert('요청이 성공적으로 업데이트되었습니다.');
    closeManageModal();
    await fetchFilterList();
    
  } catch (e) {
    alert('요청 업데이트 실패: ' + e.message);
  } finally {
    loading.value = false;
  }
};

// 엑셀 다운로드
const downloadExcel = () => {
  if (!filterList.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  const headers = [
    '요청일', '요청자', '구분', '병원명', '제약사', '상태', '비고', '관리자 코멘트'
  ];
  
  const data = filterList.value.map(item => [
    item.created_at,
    item.member_name,
    getFilterTypeText(item.filter_type),
    item.hospital_name,
    item.pharmaceutical_company_name,
    getStatusText(item.status),
    item.user_remarks ? item.user_remarks.replace(/\n/g, '\\n') : '',
    item.admin_comments ? item.admin_comments.replace(/\n/g, '\\n') : ''
  ]);
  
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '필터링요청관리');
  const fileName = `필터링요청관리_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};

onMounted(async () => {
  await fetchFilterList();
});
</script>

<style scoped>
.admin-filter-list-view {
  padding: 2rem;
}

.filter-card {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.filter-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.filter-row:last-child {
  margin-bottom: 0;
}

.filter-row span {
  font-weight: 500;
  min-width: 80px;
}

.input-120 {
  width: 120px;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
}

.input-200 {
  width: 200px;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
}

.function-card {
  background: white;
  border-radius: 8px;
  padding: 1rem 1.5rem;
  margin-bottom: 1rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.total-count {
  font-weight: 500;
  color: #333;
}

.btn-add {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background 0.2s;
}

.btn-add:hover {
  background: #0056b3;
}

.table-card {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.status-select {
  padding: 0.25rem 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
  background: white;
}

.link {
  color: #007bff;
  cursor: pointer;
  text-decoration: underline;
}

.link:hover {
  color: #0056b3;
}

.btn-edit {
  padding: 0.25rem 0.5rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
}

.btn-edit:hover {
  background: #218838;
}

/* 모달 스타일 */
.custom-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.custom-modal {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 600px;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #eee;
}

.modal-title {
  font-size: 1.2rem;
  font-weight: 600;
  margin: 0;
}

.btn-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
}

.modal-body {
  padding: 1rem;
  overflow-y: auto;
  flex: 1;
}

.form-group {
  margin-bottom: 1rem;
}

.form-label {
  display: block;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: #333;
}

.request-info {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1rem;
}

.request-info div {
  margin-bottom: 0.5rem;
}

.request-info div:last-child {
  margin-bottom: 0;
}

.textarea-field {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
  resize: vertical;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding: 1rem;
  border-top: 1px solid #eee;
}

.btn-secondary {
  padding: 0.5rem 1rem;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .filter-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .function-card {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .function-card > div {
    display: flex;
    gap: 0.5rem;
  }
}
</style>
