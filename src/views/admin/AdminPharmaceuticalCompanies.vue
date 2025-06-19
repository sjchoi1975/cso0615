<template>
  <div class="admin-pharmaceutical-companies-view page-container">
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span>검색</span>
        <input 
          v-model="searchKeyword" 
          type="text" 
          class="input-200" 
          placeholder="제약사명으로 검색"
        />
      </div>
    </div>

    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
      <div style="display: flex; gap: 0.5rem;">
        <button class="btn-add" @click="openCreateModal">새 제약사 추가</button>
        <button class="btn-add" @click="downloadExcel">엑셀 다운로드</button>
      </div>
    </div>

    <!-- 테이블카드 -->
    <div class="table-card">
      <DataTable :value="filteredCompanies" :loading="loading" :paginator="false" scrollable :scrollHeight="'calc(100vh - 220px)'">
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
          <template v-if="col.field === 'actions'" #body="slotProps">
            <button 
              class="btn-edit" 
              @click="openEditModal(slotProps.data)"
            >
              수정
            </button>
            <button 
              class="btn-delete" 
              @click="deleteCompany(slotProps.data)"
            >
              삭제
            </button>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- 제약사 추가/수정 모달 -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-footer">
          <h3 class="modai-title">{{ isEdit ? '제약사 수정' : '제약사 추가' }}</h3>
          <button class="btn-close-nobg" @click="closeModal">×</button>
        </div>
        <div class="modal-body">
          <div class="filter-row">
            <label class="form-label">제약사명 *</label>
            <input 
              v-model="formData.company_name" 
              type="text" 
              class="input" 
              placeholder="제약사명을 입력하세요"
              required
            />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeModal">취소</button>
          <button 
            class="btn-save" 
            @click="saveCompany"
            :disabled="!formData.company_name.trim() || loading"
          >
            {{ loading ? '저장 중...' : (isEdit ? '수정' : '추가') }}
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

const companies = ref([]); // 제약사 데이터
const loading = ref(false);
const totalCount = ref(0);

const searchKeyword = ref('');

// 모달 상태
const showModal = ref(false);
const isEdit = ref(false);
const formData = ref({
  id: null,
  company_name: ''
});

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '8%',
  company_name: '70%',
  created_at: '12%',
  actions: '10%'
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  company_name: 'left',
  created_at: 'center',
  actions: 'center'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  company_name: true,
  created_at: true
};

// 컬럼 배열 한 곳에서 관리
const columns = [
  { field: 'company_name', header: '제약사명' },
  { field: 'created_at', header: '등록일' },
  { field: 'actions', header: '작업' }
];

// 제약사 데이터 불러오기
const fetchCompanies = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('pharmaceutical_companies')
      .select('*')
      .order('company_name');
    
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
  if (!searchKeyword.value) return companies.value;
  
  const keyword = searchKeyword.value.toLowerCase();
  return companies.value.filter(company => 
    company.company_name.toLowerCase().includes(keyword)
  );
});

// 모달 열기/닫기
const openCreateModal = () => {
  isEdit.value = false;
  formData.value = {
    id: null,
    company_name: ''
  };
  showModal.value = true;
};

const openEditModal = (company) => {
  isEdit.value = true;
  formData.value = {
    id: company.id,
    company_name: company.company_name
  };
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  formData.value = {
    id: null,
    company_name: ''
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
        .update({ company_name: formData.value.company_name.trim() })
        .eq('id', formData.value.id);
      
      if (error) throw error;
      alert('제약사가 수정되었습니다.');
    } else {
      // 추가
      const { error } = await supabase
        .from('pharmaceutical_companies')
        .insert([{ company_name: formData.value.company_name.trim() }]);
      
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

onMounted(async () => {
  await fetchCompanies();
});
</script>

<style scoped>
.admin-pharmaceutical-companies-view {
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
}

.filter-row span {
  font-weight: 500;
  min-width: 60px;
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

.btn-edit {
  padding: 0.25rem 0.5rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
  margin-right: 0.5rem;
}

.btn-edit:hover {
  background: #218838;
}

.btn-delete {
  padding: 0.25rem 0.5rem;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
}

.btn-delete:hover {
  background: #c82333;
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

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding: 1rem;
  border-top: 1px solid #eee;
}

.btn-cancel {
  padding: 0.5rem 1rem;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-save {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-save:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.btn-close-nobg {
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

.form-label {
  display: block;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: #333;
}

.input {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
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