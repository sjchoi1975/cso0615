<template>
  <div class="admin-members-view page-container">
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="회사명, 사업자등록번호, 대표자명 검색" class="input-search wide-mobile-search" />
        </span>
          <span>인증</span>
          <select v-model="approval" class="input-120">
            <option value="">- 전체 -</option>
            <option value="approved">인증 회원</option>
            <option value="unapproved">미인증 회원</option>
          </select>
          <span>등급</span>
          <select v-model="grade" class="input-100">
            <option value="">- 전체 -</option>
            <option value="A">A</option>
            <option value="B">B</option>
            <option value="C">C</option>
          </select>
          <button class="filter-reset-btn"
            @click="resetFilters"
            style="margin-left: 1rem; display: flex; align-items: center; gap: 0.2rem;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" style="vertical-align: middle; margin-right: 2px;"><path fill="currentColor" d="M12 6V3L8 7l4 4V8c2.76 0 5 2.24 5 5a5 5 0 0 1-5 5a5 5 0 0 1-5-5H5a7 7 0 0 0 7 7a7 7 0 0 0 7-7c0-3.87-3.13-7-7-7z"/></svg>
            초기화
          </button>
      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ filteredMembers.length }}명</div>
      <button class="btn-add" @click="downloadExcel">엑셀 다운</button>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <DataTable
        :value="filteredMembers"
        :loading="loading"
        responsiveLayout="scroll"
      >
        <Column header="순번" 
          :style="{ width: columnWidths.index }" 
          :bodyStyle="{ textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ slotProps.index + 1 }}
          </template>
        </Column>
        <Column field="id_email" header="아이디"
          :sortable="columnSortables.id_email" 
          :style="{ width: columnWidths.id_email }" 
          :bodyStyle="{ textAlign: columnAligns.id_email }">
        </Column>
        <Column field="company_name" header="회사명"
          :sortable="columnSortables.company_name" 
          :style="{ width: columnWidths.company_name }" 
          :bodyStyle="{ textAlign: columnAligns.company_name }">
        </Column>
        <Column field="biz_no" header="사업자등록번호" 
          :sortable="columnSortables.biz_no" 
          :style="{ width: columnWidths.biz_no }" 
          :bodyStyle="{ textAlign: columnAligns.biz_no }">
        </Column>
        <Column field="ceo_name" header="대표자명" 
          :sortable="columnSortables.ceo_name" 
          :style="{ width: columnWidths.ceo_name }" 
          :bodyStyle="{ textAlign: columnAligns.ceo_name }">
        </Column>
        <Column field="address" header="주소" 
          :sortable="columnSortables.address" 
          :style="{ width: columnWidths.address }" 
          :bodyStyle="{ textAlign: columnAligns.address }">
        </Column>
        <Column field="cso_regist_no" header="CSO 신고번호" 
          :sortable="columnSortables.cso_regist_no" 
          :style="{ width: columnWidths.cso_regist_no }" 
          :bodyStyle="{ textAlign: columnAligns.cso_regist_no }">
        </Column>
        <Column field="approval" header="인증" 
          :sortable="columnSortables.approval" 
          :style="{ width: columnWidths.approval }" 
          :bodyStyle="{ textAlign: columnAligns.approval }">
          <template #body="slotProps">
            <div class="custom-toggle-wrap">
              <input
                type="checkbox"
                :id="'toggle-' + slotProps.data.id"
                class="custom-toggle-checkbox"
                :checked="slotProps.data.approval === 'approved'"
                @click.prevent="() => onHtmlToggleApproval(slotProps.data)"
              />
              <label :for="'toggle-' + slotProps.data.id" class="custom-toggle-label"></label>
            </div>
          </template>
        </Column>
        <Column field="grade" header="등급"
          :sortable="columnSortables.grade"
          :style="{ width: columnWidths.grade }"
          :bodyStyle="{ textAlign: columnAligns.grade }">
          <template #body="slotProps">
            <select
              :value="slotProps.data.grade"
              @change="e => onChangeGrade(slotProps.data, e.target.value)"
              class="grade-dropdown"
            >
              <option value="A">A</option>
              <option value="B">B</option>
              <option value="C">C</option>
            </select>
          </template>
        </Column>
        <Column field="created_at" header="가입일자" 
          :sortable="columnSortables.created_at" 
          :style="{ width: columnWidths.created_at }" 
          :bodyStyle="{ textAlign: columnAligns.created_at }">
          <template #body="slotProps">
            {{ slotProps.data.created_at ? new Date(slotProps.data.created_at).toISOString().split('T')[0] : '' }}
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputSwitch from 'primevue/inputswitch';
import Dropdown from 'primevue/dropdown';
import { supabase } from '@/supabase';
import * as XLSX from 'xlsx';

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  id_email: '10%',
  company_name: '12%',
  biz_no: '8%',
  ceo_name: '8%',
  address: '22%',
  cso_regist_no: '16%',
  approval: '8%',
  grade: '6%',
  created_at: '8%'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  index: false,
  id_email: true,
  company_name: true,
  biz_no: true,
  ceo_name: true,
  address: true,
  cso_regist_no: true,
  approval: true,
  grade: true,
  created_at: true
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  id_email: 'left',
  company_name: 'left',
  biz_no: 'center',
  ceo_name: 'center',
  address: 'left',
  cso_regist_no: 'center',
  approval: 'center',
  grade: 'center',
  created_at: 'center'
};

const members = ref([]);
const loading = ref(false);
const search = ref('');
const approval = ref('');
const grade = ref('');

const fetchMembers = async () => {
  loading.value = true;
  let query = supabase.from('members').select('*').order('created_at', { ascending: false });
  const { data, error } = await query;
  if (!error) {
    members.value = data;
  }
  loading.value = false;
};

onMounted(fetchMembers);

const filteredMembers = computed(() => {
  let result = members.value;
  // 관리자 목록에서는 user만 표시
  result = result.filter(m => m.role === 'user');
  // 인증 상태 필터 적용
  if (approval.value) {
    result = result.filter(m => m.approval === approval.value);
  }
  // 등급 필터 적용
  if (grade.value) {
    result = result.filter(m => m.grade === grade.value);
  }
  // 검색어 필터 적용
  if (search.value) {
    const keyword = search.value.toLowerCase();
    result = result.filter(m =>
      (m.company_name && m.company_name.toLowerCase().includes(keyword)) ||
      (m.biz_no && m.biz_no.toLowerCase().includes(keyword)) ||
      (m.ceo_name && m.ceo_name.toLowerCase().includes(keyword))
    );
  }
  return result;
});

const approvalOptions = [
  { label: '인증', value: 'approved' },
  { label: '미인증', value: 'unapproved' }
];

const onDropdownApproval = async (member, val) => {
  if (member.approval === val) return;
  const msg = val === 'approved' ? '인증 회원으로 변경하시겠습니까?' : '미인증 회원으로 변경하시겠습니까?';
  if (!confirm(msg)) return;
  await supabase.from('members').update({ approval: val }).eq('id', member.id);
  fetchMembers();
};

const onHtmlToggleApproval = async (member) => {
  const toApprove = member.approval !== 'approved';
  const msg = toApprove ? '인증 회원으로 변경하시겠습니까?' : '미인증 회원으로 변경하시겠습니까?';
  if (!confirm(msg)) {
    return;
  }
  await supabase.from('members').update({ approval: toApprove ? 'approved' : 'unapproved' }).eq('id', member.id);
  fetchMembers();
};

// 등급 변경 함수
const onChangeGrade = async (member, newGrade) => {
  if (member.grade === newGrade) return;
  if (!confirm('회원 등급을 변경하시겠습니까?')) {
    fetchMembers(); // 상태 복구
    return;
  }
  await supabase.from('members').update({ grade: newGrade }).eq('id', member.id);
  fetchMembers();
};

// 엑셀 다운로드
const downloadExcel = () => {
  const data = filteredMembers.value.map(member => ({
    '아이디': member.id_email,
    '회사명': member.company_name,
    '사업자등록번호': member.biz_no,
    '대표자명': member.ceo_name,
    '주소': member.address,
    'CSO 신고번호': member.cso_regist_no,
    '인증': member.approval === 'approved' ? 'Y' : 'N',
    '등급': member.grade,
    '가입일자': member.created_at ? new Date(member.created_at).toISOString().split('T')[0] : ''
  }));
  const worksheet = XLSX.utils.json_to_sheet(data);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, '회원목록');
  
  const today = new Date();
  const dateString = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
  XLSX.writeFile(workbook, `회원목록_${dateString}.xlsx`);
};

const resetFilters = () => {
  search.value = '';
  approval.value = '';
  grade.value = '';
};
</script>
