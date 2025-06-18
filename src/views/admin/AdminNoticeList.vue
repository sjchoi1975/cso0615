<template>
  <div class="admin-notice-view page-container">
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span>통합 검색</span>
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="제목, 내용 검색" class="input-search" />
        </span>
      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div class="total-count">총 {{ totalCount }}건</div>
        <div style="display: flex; gap: 0.5rem;">
          <router-link to="/admin/notices/create" class="btn-add">공지 작성</router-link>
        </div>
      </div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <DataTable 
        :value="filterednotice"
        :paginator="true"
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        :first="first"
        :totalRecords="totalCount"
        @page="onPageChange"
        scrollable
        :scrollHeight="'calc(100vh - 238px)'"
      >
        <Column 
          header="순번" 
          field="id"
          :style="{ width: columnWidths.index }"
          :class="columnAligns.index"
        />
        <Column 
          field="title" 
          header="제목"
          :style="{ width: columnWidths.title }"
          :class="columnAligns.title"
          :sortable="columnSortables.title"
        >
          <template #body="{ data }">
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span v-if="data.is_important" class="important-badge">중요</span>
              <a @click="goDetail(data.id)" style="cursor: pointer; color: #2196f3; text-decoration: underline;">
                {{ data.title }}
              </a>
            </div>
          </template>
        </Column>
        <Column 
          field="content" 
          header="내용"
          :style="{ width: columnWidths.content }"
          :class="columnAligns.content"
          :sortable="columnSortables.content"
        />
        <Column 
          field="created_at" 
          header="작성일시"
          :style="{ width: columnWidths.created_at }"
          :class="columnAligns.created_at"
          :sortable="columnSortables.created_at"
        >
          <template #body="{ data }">
            {{ formatDate(data.created_at) }}
          </template>
        </Column>
        <Column 
          field="author" 
          header="작성자"
          :style="{ width: columnWidths.author }"
          :class="columnAligns.author"
          :sortable="columnSortables.author"
        />
        <Column 
          field="status" 
          header="상태"
          :style="{ width: columnWidths.status }"
          :class="columnAligns.status"
          :sortable="columnSortables.status"
        >
          <template #body="{ data }">
            <div class="custom-toggle-wrap">
              <input
                type="checkbox"
                :id="'status-' + data.id"
                :checked="data.status === 'active'"
                @change="toggleStatus(data.id, data.status)"
                class="custom-toggle-checkbox"
              />
              <label :for="'status-' + data.id" class="custom-toggle-label"></label>
            </div>
          </template>
        </Column>
        <Column 
          header="수정"
          :style="{ width: columnWidths.edit }"
          :class="columnAligns.edit"
        >
          <template #body="{ data }">
            <button class="btn-edit-sm" @click="goEdit(data.id)">수정</button>
          </template>
        </Column>
        <Column 
          header="삭제"
          :style="{ width: columnWidths.delete }"
          :class="columnAligns.delete"
        >
          <template #body="{ data }">
            <button class="btn-delete-sm" @click="deleteNotice(data.id)">삭제</button>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';

const router = useRouter();
const search = ref('');
const notices = ref([]);
const pageSize = ref(20);
const first = ref(0);

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  title: '26%',
  content: '40%',
  created_at: '8%',
  author: '10%',
  status: '4%',
  edit: '4%',
  delete: '4%'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  index: false,
  title: false,
  content: false,
  created_at: false,
  author: false,
  status: false,
  edit: false,
  delete: false
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'text-center',
  title: 'text-left',
  content: 'text-left',
  created_at: 'text-center',
  author: 'text-center',
  status: 'text-center',
  edit: 'text-center',
  delete: 'text-center'
};

// 공지 불러오기 (전체 데이터)
const fetchNotices = async () => {
  const { data, error } = await supabase
    .from('notices')
    .select('*')
    .order('created_at', { ascending: false });
  if (!error) {
    notices.value = data;
  }
};

onMounted(() => {
  fetchNotices();
});

const onPageChange = (event) => {
  first.value = event.first;
};

// 검색 등 필터링 및 중요 공지 상단 고정 (slice로 페이지 데이터만 반환)
const filteredAll = computed(() => {
  let filtered = notices.value;
  if (search.value) {
    const keyword = search.value.toLowerCase();
    filtered = filtered.filter(
      n =>
        (n.title && n.title.toLowerCase().includes(keyword)) ||
        (n.content && n.content.toLowerCase().includes(keyword))
    );
  }
  const importantNotices = filtered.filter(n => n.is_important);
  const normalNotices = filtered.filter(n => !n.is_important);
  return [...importantNotices, ...normalNotices];
});

const filterednotice = computed(() => {
  return filteredAll.value.slice(first.value, first.value + pageSize.value);
});

const totalCount = computed(() => filteredAll.value.length);

// 날짜 포맷팅 (한국시각)
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const koreanTime = new Date(date.getTime() + (9 * 60 * 60 * 1000)); // UTC+9
  // YYYY-MM-DD HH:MM
  return koreanTime.toISOString().slice(0, 16).replace('T', ' ');
};

// 상태 토글
const toggleStatus = async (id, currentStatus) => {
  const newStatus = currentStatus === 'active' ? 'inactive' : 'active';
  const { error } = await supabase
    .from('notices')
    .update({ status: newStatus })
    .eq('id', id);
  
  if (!error) {
    await fetchNotices(); // 목록 새로고침
  } else {
    alert('상태 변경 실패: ' + error.message);
  }
};

// 상세 화면으로 이동
const goDetail = (id) => {
  router.push(`/admin/notices/detail/${id}`);
};

// 수정 화면으로 이동
const goEdit = (id) => {
  router.push(`/admin/notices/edit/${id}`);
};

// 삭제
const deleteNotice = async (id) => {
  if (!confirm('삭제하시겠습니까?')) return;
  
  const { error } = await supabase
    .from('notices')
    .delete()
    .eq('id', id);
  
  if (!error) {
    alert('삭제되었습니다.');
    await fetchNotices(); // 목록 새로고침
  } else {
    alert('삭제 실패: ' + error.message);
  }
};
</script>
