<template>
  <div class="user-filter-list-view page-container">
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
        <button class="btn-add" @click="createRequest">요청</button>
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
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import * as XLSX from 'xlsx';

const router = useRouter();

const filterList = ref([]); // 필터링 요청 목록
const loading = ref(false);
const totalCount = ref(0);

const selectedStatus = ref('');
const selectedFilterType = ref('');

// 팝업 상태
const showRemarksDialog = ref(false);
const showCommentsDialog = ref(false);
const remarksValue = ref('');
const commentsValue = ref('');

const currentUser = ref(null);

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  created_at: '10%',
  filter_type: '8%',
  hospital_name: '12%',
  pharmaceutical_company_name: '15%',
  status: '8%',
  user_remarks: '15%',
  admin_comments: '18%'
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  created_at: 'center',
  filter_type: 'center',
  hospital_name: 'left',
  pharmaceutical_company_name: 'left',
  status: 'center',
  user_remarks: 'left',
  admin_comments: 'left'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  created_at: true,
  filter_type: true,
  hospital_name: true,
  pharmaceutical_company_name: true,
  status: true
};

// 컬럼 배열 한 곳에서 관리
const columns = [
  { field: 'created_at', header: '요청일' },
  { field: 'filter_type', header: '구분' },
  { field: 'hospital_name', header: '병원명' },
  { field: 'pharmaceutical_company_name', header: '제약사' },
  { field: 'status', header: '상태' },
  { field: 'user_remarks', header: '비고' },
  { field: 'admin_comments', header: '관리자 코멘트' }
];

// 현재 사용자 정보 가져오기
const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    currentUser.value = user;
  }
};

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
        hospitals (
          hospital_name
        ),
        pharmaceutical_companies (
          company_name
        )
      `)
      .eq('member_id', currentUser.value.id)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    
    if (data) {
      filterList.value = data.map(item => ({
        ...item,
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

// 새 요청 생성
const createRequest = () => {
  router.push('/filter/create');
};

// 엑셀 다운로드
const downloadExcel = () => {
  if (!filterList.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  const headers = [
    '요청일', '구분', '병원명', '제약사', '상태', '비고', '관리자 코멘트'
  ];
  
  const data = filterList.value.map(item => [
    item.created_at,
    getFilterTypeText(item.filter_type),
    item.hospital_name,
    item.pharmaceutical_company_name,
    getStatusText(item.status),
    item.user_remarks ? item.user_remarks.replace(/\n/g, '\\n') : '',
    item.admin_comments ? item.admin_comments.replace(/\n/g, '\\n') : ''
  ]);
  
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '필터링요청목록');
  const fileName = `필터링요청목록_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};

onMounted(async () => {
  await getCurrentUser();
  await fetchFilterList();
});
</script>

<style scoped>
.user-filter-list-view {
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

.link {
  color: #007bff;
  cursor: pointer;
  text-decoration: underline;
}

.link:hover {
  color: #0056b3;
}

/* 상태별 스타일 */
.status-checking {
  color: #ffc107;
  font-weight: 500;
}

.status-approved {
  color: #28a745;
  font-weight: 500;
}

.status-rejected {
  color: #dc3545;
  font-weight: 500;
}

.status-pending {
  color: #6c757d;
  font-weight: 500;
}

.status-cancelled {
  color: #6c757d;
  font-weight: 500;
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
  max-width: 500px;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
}

.modai-title {
  font-size: 1.2rem;
  font-weight: 600;
  margin: 0;
  padding: 1rem;
  border-bottom: 1px solid #eee;
}

.modal-body {
  padding: 1rem;
  overflow-y: auto;
  flex: 1;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 1rem;
  border-top: 1px solid #eee;
}

.btn-primary {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
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
