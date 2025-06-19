<template>
  <div class="admin-notice-view page-container">
    
    <!-- 상단: 필터카드 -->
    <div class="filter-card search-center-card">
      <div class="filter-row">
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="제목, 내용 검색" class="input-search wide-mobile-search" />
        </span>
      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <DataTable 
        :value="filterednotice"
        :paginator="false"
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        :first="first"
        :totalRecords="totalCount"
        @page="onPageChange"
        scrollable
        :scrollHeight="'calc(100vh - 220px)'"
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
      </DataTable>
    </div>

    <div class="fixed-paginator">
      <Paginator
        :rows="pageSize"
        :totalRecords="totalCount"
        :first="first"
        :rowsPerPageOptions="[20, 50, 100]"
        @page="onPageChange"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';

const router = useRouter();
const search = ref('');
const notices = ref([]);
const pageSize = ref(20);
const first = ref(0);

const columnWidths = {
  index: '4%',
  title: '26%',
  content: '40%',
  created_at: '8%',
  author: '10%'
};
const columnSortables = {
  index: false,
  title: true,
  content: true,
  created_at: true,
  author: true
};
const columnAligns = {
  index: 'text-center',
  title: 'text-left',
  content: 'text-left',
  created_at: 'text-center',
  author: 'text-center'
};

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

const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const koreanTime = new Date(date.getTime() + (9 * 60 * 60 * 1000)); // UTC+9
  return koreanTime.toISOString().slice(0, 16).replace('T', ' ');
};

const goDetail = (id) => {
  router.push(`/notice/detail/${id}`);
};
</script>
