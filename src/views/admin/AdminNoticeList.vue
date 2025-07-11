<template>
  <div class="admin-notice-view page-container">
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
      <div class="total-count">
        총 {{ notices.length }}건
      </div>
      <Button
        icon="pi pi-pencil"
        label="신규 등록"
        class="btn-add-md"
        @click="$router.push('/admin/notices/create')"
        iconPos="left"
        style="gap:0.5rem;"
      />
    </div>
    
    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable 
          :value="notices.slice(first, first + pageSize)"
          :loading="false"
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
          :columns="tableConfig.columns"
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
            <template #body="{ data }">
              <template v-if="col.field === 'created_at'">
                {{ formatDate(data.created_at) }}
              </template>
              <template v-else-if="col.field === 'status'">
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
              <template v-else-if="col.field === 'edit'">
                <Button icon="pi pi-pencil"
                  class="p-button-rounded p-button-text btn-icon-edit"
                  @click="goEdit(data.id)" />
              </template>
              <template v-else-if="col.field === 'delete'">
                <Button icon="pi pi-trash"
                  class="p-button-rounded p-button-text btn-icon-delete"
                  @click="deleteNotice(data.id)" />
              </template>
              <template v-else-if="col.field === 'title'">
                <a @click="toggleExpand(data.id)" class="table-title-link">
                  {{ data.title }}
                </a>
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
    </div>

    <div v-if="showPaginator" class="fixed-paginator">
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
import Button from 'primevue/button';
import { noticeTableConfig } from '@/config/tableConfig';
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
const tableConfig = computed(() => isMobile.value ? noticeTableConfig.mobile : noticeTableConfig.pc);
const tableScrollHeight = computed(() => getTableScrollHeight(true));

const fetchNotices = async () => {
  loading.value = true;
  let query = supabase
    .from('notices')
    .select('*');
  if (search.value && search.value.length >= 2) {
    const keyword = search.value;
    query = query.or(`title.ilike.%${keyword}%,content.ilike.%${keyword}%`);
  }
  query = query.order('created_at', { ascending: false });
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

// 날짜 포맷팅 (한국시각)
const formatDate = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const koreanTime = new Date(date.getTime() + (9 * 60 * 60 * 1000)); // UTC+9
  // YYYY-MM-DD
  return koreanTime.toISOString().slice(0, 10);
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

// 상세 화면으로 이동 <- 미사용
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

// 페이지네이터 표시 여부(예시: 전체 데이터가 1페이지 초과일 때만 true)
const showPaginator = ref(true); // 실제로는 데이터 개수로 판단

// 확장 토글 함수
const toggleExpand = (id) => {
  if (expandedRows.value[id]) {
    delete expandedRows.value[id];
  } else {
    expandedRows.value[id] = true;
  }
};
</script>
