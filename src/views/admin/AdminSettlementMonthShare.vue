<template>
  <div class="admin-settlement-month-view page-container">
    <!-- 상단: 정산월 고정 -->
    <div class="filter-card">
      <div class="filter-row">
        <span>정산월</span>
        <span style="font-size:1.1rem; font-weight:600;">{{ month }}</span>
      </div>
    </div>

    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">정산 업체 총 {{ companies.length }}개</div>
      <div style="display: flex; gap: 1rem; align-items: center;">
        <Button
          :icon="allShared ? 'pi pi-times' : 'pi pi-share-alt'"
          :label="allShared ? '전체 해제' : '전체 공유'"
          class="btn-add-md"
          @click="toggleAllShare(!allShared)"
          iconPos="left"
          style="gap:0.5em;"
        />
        <Button
          icon="pi pi-save"
          label="저장하기"
          class="btn-add-md"
          :disabled="!isDirty"
          @click="saveShareStatus"
          iconPos="left"
          style="gap:0.5em;"
        />
        <Button
          icon="pi pi-download"
          label="다운로드"
          class="btn-download-md"
          @click="downloadExcel"
          iconPos="left"
          style="gap:0.5em;"
        />
      </div>
    </div>

    <!-- 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="companies"
          :loading="loading"
          :paginator="false"
          scrollable
          :scrollHeight="tableScrollHeight"
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
              <template v-else-if="col.type === 'icon' && col.field === 'share'">
                <div class="custom-toggle-wrap">
                  <input
                    type="checkbox"
                    :id="'share-toggle-' + slotProps.data.company_reg_no"
                    class="custom-toggle-checkbox"
                    :checked="slotProps.data.share === 'y'"
                    @change="onCustomToggleShare(slotProps.data)"
                  />
                  <label :for="'share-toggle-' + slotProps.data.company_reg_no" class="custom-toggle-label"></label>
                </div>
              </template>
              <template v-else-if="col.field === 'hospital_count'">
                {{ formatCurrency(slotProps.data.hospital_count) }}
              </template>
              <template v-else-if="col.field === 'prescription_count'">
                {{ formatCurrency(slotProps.data.prescription_count) }}
              </template>
              <template v-else-if="col.field === 'prescription_amount'">
                {{ formatCurrency(slotProps.data.prescription_amount) }}
              </template>
              <template v-else-if="col.field === 'payment_amount'">
                {{ formatCurrency(slotProps.data.payment_amount) }}
              </template>
              <template v-else-if="col.field === 'supply_amount'">
                {{ formatCurrency(calcSupply(slotProps.data.payment_amount)) }}
              </template>
              <template v-else-if="col.field === 'vat'">
                {{ formatCurrency(calcVat(slotProps.data.payment_amount)) }}
              </template>
              <template v-else-if="col.field === 'total_amount'">
                {{ formatCurrency(slotProps.data.payment_amount) }}
              </template>
              <template v-else-if="col.field === 'memo'">
                <span class="link" @click="openMemoModal(slotProps.data)">
                  <i v-if="!slotProps.data.memo" class="pi pi-pencil" style="margin-right:4px;"></i>
                  {{ slotProps.data.memo ? slotProps.data.memo : '등록' }}
                </span>
              </template>
              <template v-else-if="col.field === 'confirm_status'">
                {{ slotProps.data.confirm_status || '-' }}
              </template>
              <template v-else-if="col.field === 'confirm_comment'">
                <span v-if="slotProps.data.confirm_comment" class="link" style="color:#1976d2;cursor:pointer;" @click="openRequestModal(slotProps.data.confirm_comment)">
                  {{ slotProps.data.confirm_comment.length > 10 ? slotProps.data.confirm_comment.slice(0, 10) + '...' : slotProps.data.confirm_comment }}
                </span>
                <span v-else>-</span>
              </template>
              <template v-else-if="col.field === 'company_name'">
                <span class="table-title">{{ slotProps.data.company_name }}</span>
              </template>
              <template v-else-if="col.field === 'company_reg_no'">
                {{ slotProps.data.company_reg_no || '-' }}
              </template>
              <template v-else>
                {{ slotProps.data[col.field] }}
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- 전달사항 모달 (입력/수정) -->
    <div v-if="showMemoModal" class="custom-modal-overlay" @click.self="closeMemoModal">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">전달사항</h3></div>
        <div class="modal-body">
          <textarea v-model="memoInput" rows="8" class="input" placeholder="전달사항을 입력하세요"></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeMemoModal">취소</button>
          <button class="btn-confirm modal" @click="saveMemoModal">저장</button>
        </div>
      </div>
    </div>

    <!-- 요청내용 모달 (읽기전용) -->
    <div v-if="showRequestModal" class="custom-modal-overlay" @click.self="closeRequestModal">
      <div class="custom-modal">
        <div class="modal-header"><h3 class="modal-title">정정요청</h3></div>
        <div class="modal-body">
          <div style="white-space:pre-line; min-height:100px;">{{ requestContent }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeRequestModal">닫기</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute } from 'vue-router';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import { getTableScrollHeight } from '@/utils/tableHeight';
import { settlementMonthShareTableConfig } from '@/config/tableConfig';

const route = useRoute();
const month = route.params.month;

const companies = ref([]);
const loading = ref(false);

// 전달사항 팝업 상태
const showMemoModal = ref(false);
const selectedCompany = ref(null);
const memoInput = ref('');

const showConfirmCommentModal = ref(false);
const selectedConfirmCompany = ref(null);
const confirmCommentInput = ref('');

const showRequestModal = ref(false);
const requestContent = ref('');

const isMobile = computed(() => window.innerWidth <= 768);

// 공유 화면용 테이블 설정
const tableConfig = computed(() => isMobile.value ? settlementMonthShareTableConfig.mobile : settlementMonthShareTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 없음)
const tableScrollHeight = computed(() => getTableScrollHeight(false, 40));

const isDirty = ref(false);
const originalShareMap = ref({});

// 전체 공유 상태
const allShared = computed(() => companies.value.length > 0 && companies.value.every(row => row.share === 'y'));

// DataTable에 표시할 때 share 값을 InputSwitch용 shareSwitch로 매핑
watch(companies, (list) => {
  list.forEach(row => {
    row.shareSwitch = row.share === 'y' ? 'y' : 'n';
  });
}, { immediate: true });

function onCustomToggleShare(row) {
  row.share = row.share === 'y' ? 'n' : 'y';
  updateShareStatus(row);
}

// DB에서 해당 월의 업체별 데이터를 불러오는 함수
const fetchCompanies = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('v_settlement_share_summary')
      .select('*')
      .eq('settlement_month', month);
    
    if (error) {
      console.error('Error fetching companies:', error);
      alert('데이터를 불러오는 중 오류가 발생했습니다.');
      companies.value = [];
      originalShareMap.value = {};
      isDirty.value = false;
    } else {
      companies.value = data || [];
      // 원본 공유상태 저장
      originalShareMap.value = {};
      data.forEach(row => {
        originalShareMap.value[row.company_reg_no] = row.share;
      });
      isDirty.value = false;
    }
  } catch (error) {
    console.error('Error:', error);
    alert('데이터를 불러오는 중 오류가 발생했습니다.');
    companies.value = [];
    originalShareMap.value = {};
    isDirty.value = false;
  } finally {
    loading.value = false;
  }
};

// 전체 공유/해제
function toggleAllShare(val) {
  companies.value.forEach(company => {
    company.share = val ? 'y' : 'n';
    company.shareSwitch = val ? 'y' : 'n';
  });
  updateShareStatus();
  alert(val ? '전체 업체가 공유되었습니다.' : '전체 업체 공유가 해제되었습니다.');
}

// 개별 공유 상태 업데이트
const updateShareStatus = (company) => {
  isDirty.value = companies.value.some(row =>
    (row.share === 'y' ? 'y' : 'n') !== (originalShareMap.value[row.company_reg_no] || 'n')
  );
};

// 저장 버튼 클릭 시 settlements_share 테이블에 upsert
const saveShareStatus = async () => {
  const changed = companies.value.filter(row =>
    (row.share === 'y' ? 'y' : 'n') !== (originalShareMap.value[row.company_reg_no] || 'n')
  );
  if (changed.length === 0) {
    alert('변경된 내용이 없습니다.');
    return;
  }
  const upsertRows = changed.map(row => ({
    settlement_month: month,
    company_reg_no: row.company_reg_no,
    share: row.share === 'y' ? 'y' : 'n'
  }));
  const { error } = await supabase.from('settlements_share').upsert(upsertRows, { onConflict: ['settlement_month', 'company_reg_no'] });
  if (error) {
    alert('저장 실패: ' + error.message);
  } else {
    alert('저장되었습니다.');
    await fetchCompanies();
  }
};

// 엑셀 다운로드
const downloadExcel = () => {
  alert('엑셀 다운로드 기능은 추후 구현 예정입니다.');
};

// 전달사항 팝업 열기
const openMemoModal = (company) => {
  selectedCompany.value = company;
  memoInput.value = company.memo || '';
  showMemoModal.value = true;
};

// 전달사항 팝업 닫기
const closeMemoModal = () => {
  showMemoModal.value = false;
  selectedCompany.value = null;
  memoInput.value = '';
};

function calcSupply(payment) {
  const num = Number(payment);
  if (isNaN(num) || !isFinite(num)) return 0;
  return Math.round(num / 1.1);
}
function calcVat(payment) {
  const num = Number(payment);
  if (isNaN(num) || !isFinite(num)) return 0;
  return Math.round(num - num / 1.1);
}
function formatCurrency(val) {
  if (val === undefined || val === null || val === '') return '-';
  return Number(val).toLocaleString('ko-KR', { maximumFractionDigits: 0 });
}
async function saveMemoModal() {
  if (!selectedCompany.value) return;
  // settlements_share에 해당 row가 없으면 upsert, 있으면 update
  const upsertRow = {
    settlement_month: month,
    company_reg_no: selectedCompany.value.company_reg_no,
    memo: memoInput.value
  };
  const { error } = await supabase
    .from('settlements_share')
    .upsert([upsertRow], { onConflict: ['settlement_month', 'company_reg_no'] });
  if (error) {
    alert('저장 실패: ' + error.message);
  } else {
    alert('저장되었습니다.');
    fetchCompanies();
  }
  closeMemoModal();
}

function openRequestModal(content) {
  requestContent.value = content;
  showRequestModal.value = true;
}
function closeRequestModal() {
  showRequestModal.value = false;
}

onMounted(() => {
  fetchCompanies();
});
</script>
