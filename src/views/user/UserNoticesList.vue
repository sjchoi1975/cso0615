<template>

  <div class="page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">

        <span class="hide-mobile">통합 검색</span>
        <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="제목, 내용 입력" />
        <button type="button" class="btn-search hide-mobile" @click="onSearch" :disabled="search.length < 2">검색</button>
        <button type="button" class="btn-reset hide-mobile"  @click="onReset">
          <i class="pi pi-refresh" style="font-size: 1rem;"></i>
          초기화
        </button>
        
        <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
          <input v-model="search" class="input-search wide-mobile-search" placeholder="제목, 내용 입력" @keyup.enter="onSearch"/>
          <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onReset"
            style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          <i class="pi pi-search search-btn-icon" @click="search.length >= 2 && onSearch()"
            style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
        </div>

      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ notices.length }}건</div>
    </div>

    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <DataTable 
        :value="notices.slice(first, first + pageSize)"
        :paginator="false"
        :rows="50"
        :rowsPerPageOptions="[20, 50, 100]"
        :first="first"
        :totalRecords="notices.length"
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
        :totalRecords="notices.length"
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
const isSearched = ref(false); // 검색 실행 여부

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userNoticesTableConfig.mobile : userNoticesTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const fetchNotices = async () => {
  loading.value = true;
  let query = supabase
    .from('notices')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false });
  if (search.value && search.value.length >= 2) {
    const keyword = search.value;
    query = query.or(`title.ilike.%${keyword}%,content.ilike.%${keyword}%`);
  }
  const { data, error } = await query;
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

// filteredAll, filterednotice, totalCount computed 제거
// 화면에는 notices.value.slice(first.value, first.value + pageSize.value) 등으로 직접 사용

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

const toggleExpand = (id) => {
  if (expandedRows.value[id]) {
    delete expandedRows.value[id];
  } else {
    expandedRows.value[id] = true;
  }
};

function onSearch() {
  if (search.value.length < 2) return;
  isSearched.value = true;
  fetchNotices();
}
function onReset() {
  if (isSearched.value) {
    search.value = '';
    isSearched.value = false;
    fetchNotices();
  } else {
    search.value = '';
  }
}
</script>
