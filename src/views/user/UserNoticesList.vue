<template>
  <div class="page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <span class="hide-mobile">통합 검색</span>
        <span>
          <input
            v-model="search"
            class="input-search wide-mobile-search"
            placeholder="제목, 내용 입력"
          />
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
        :rows="50"
        :rowsPerPageOptions="[20, 50, 100]"
        :first="first"
        :totalRecords="totalCount"
        @page="onPageChange"
        scrollable
        :scrollHeight="tableScrollHeight"
        v-model:expandedRows="expandedRows"
        dataKey="id"
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
          <template #body="{ data }">
            <template v-if="col.field === 'title'">
              <div style="display: flex; align-items: center; gap: 0.5rem;">
                <span v-if="data.is_important" class="important-badge">중요</span>
                <a @click="toggleExpand(data.id)" class="table-title-link">
                  {{ data.title }}
                </a>
              </div>
            </template>
            <template v-else-if="col.field === 'created_at'">
              {{ formatDate(data.created_at) }}
            </template>
            <template v-else>
              {{ data[col.field] }}
            </template>
          </template>
        </Column>
        <template #expansion="{ data }">
          <div class="notice-expansion">
            <div class="content-text">{{ data.content }}</div>
          </div>
        </template>
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
import { userNoticesTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';

const router = useRouter();
const search = ref('');
const notices = ref([]);
const pageSize = ref(50);
const first = ref(0);
const expandedRows = ref({});
const loading = ref(false);

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userNoticesTableConfig.mobile : userNoticesTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const fetchNotices = async () => {
  loading.value = true;
  const { data, error } = await supabase
    .from('notices')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false });
  if (!error) {
    notices.value = data;
  }
  loading.value = false;
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
  // YYYY-MM-DD
  return koreanTime.toISOString().slice(0, 10);
};

const goDetail = (id) => {
  router.push(`/notice/detail/${id}`);
};

// 확장 토글 함수
const toggleExpand = (id) => {
  if (expandedRows.value[id]) {
    delete expandedRows.value[id];
  } else {
    expandedRows.value[id] = true;
  }
};
</script>
