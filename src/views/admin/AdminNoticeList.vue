<template>
  <div class="admin-notice-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">
        <span class="hide-mobile">통합 검색</span>
          <input
            v-model="search"
            placeholder="제목, 내용 입력"
            class="input-search wide-mobile-search"
          />
      </div>
    </div>
    
    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
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
          :value="filterednotice"
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
                <a @click="toggleExpand(data.id)" style="cursor: pointer; color: var(--primary); text-decoration: underline;">
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

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? noticeTableConfig.mobile : noticeTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

// 공지 불러오기 (전체 데이터)
const fetchNotices = async () => {
  loading.value = true;
  const { data, error } = await supabase
    .from('notices')
    .select('*')
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

// 페이지네이터 개수 설정
const filterednotice = computed(() => {
  return filteredAll.value.slice(first.value, first.value + 50);
});


const totalCount = computed(() => filteredAll.value.length);

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
