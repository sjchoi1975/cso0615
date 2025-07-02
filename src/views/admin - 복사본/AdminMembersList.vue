<template>
  <div class="admin-members-view page-container">
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="회사명, 사업자등록번호, 대표자명 검색" class="input-search wide-mobile-search" />
        </span>
        <div class="hide-mobile">
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
        </div>
      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ filteredMembers.length }}명</div>
      <button class="btn-download-md" @click="downloadExcel">다운로드</button>
    </div>
    
    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="filteredMembers"
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
                {{ slotProps.index + 1 }}
              </template>
              <template v-else-if="col.type === 'toggle' && col.field === 'approval'">
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
              <template v-else-if="col.type === 'dropdown' && col.field === 'grade'">
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
              <template v-else-if="col.field === 'created_at'">
                {{ slotProps.data.created_at ? new Date(slotProps.data.created_at).toISOString().split('T')[0] : '' }}
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
import { membersTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

// 반응형 테이블 설정
const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? membersTableConfig.mobile : membersTableConfig.pc);
const tableRef = ref(null);

// 테이블 스크롤 높이 계산 (페이지네이터 없음)
const tableScrollHeight = computed(() => getTableScrollHeight(false, 40));

// 윈도우 리사이즈 이벤트 리스너
const handleResize = () => {
  // isMobile이 computed이므로 자동으로 업데이트됨
};

onMounted(() => {
  window.addEventListener('resize', handleResize);
  fetchMembers();
});

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
    '담당자': member.manager_name,
    '휴대폰번호': member.phone,
    '이메일': member.email,
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
