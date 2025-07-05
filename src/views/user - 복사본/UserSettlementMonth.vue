<template>
  <div class="user-settlement-month-view page-container">
    <!-- 필터카드 -->
    <div class="filter-card">
      <div class="filter-row">
        <span>정산월</span>
        <select v-model="selectedMonth" class="input-120">
          <option value="">- 전체 -</option>
          <option v-for="m in monthOptions" :key="m" :value="m">
            {{ m.slice(0,4) + '년 ' + parseInt(m.slice(5,7)) + '월' }}
          </option>
        </select>
      </div>
    </div>

    <!-- 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount }}건</div>
      <div style="display: flex; gap: 1rem;">
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
    <div class="table-card user-settlement-month">
      <div :style="isMobile ? tableConfig.tableStyle : {}">
        <DataTable
          :value="filteredMonthList"
          :loading="loading"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="tableScrollHeight"
          :style="{ width: tableConfig.tableWidth, minWidth: isMobile ? tableConfig.tableStyle.minWidth : '100%' }"
        >
          <template #empty>
            <div v-if="!loading">조회된 데이터가 없습니다.</div>
          </template>
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
              <template v-else-if="col.type === 'icon' && col.field === 'detail'">
                <button class="p-button p-button-text p-button-rounded icon-only-btn" @click="goDetail(slotProps.data)" v-tooltip.top="'상세보기'">
                  <i class="pi pi-list" style="font-size: 1.2rem; color: #4B5563;"></i>
                </button>
              </template>
              <template v-else-if="col.field === 'note' && slotProps.data.note">
                <a href="#" @click.prevent="openNotePopup(slotProps.data)" class="link">
                  {{ slotProps.data.note }}
                </a>
              </template>
              <template v-else-if="col.format === 'currency'">
                {{ slotProps.data[col.field]?.toLocaleString() }}
              </template>
              <template v-else>
                {{ slotProps.data[col.field] }}
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>
    
    <!-- 전달사항 팝업 -->
    <div v-if="showNoteDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <div class="modal-title">전달사항</div>
        </div>
        <div class="modal-body">
          <div style="white-space: pre-line;">{{ noteValue }}</div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel modal" @click="closeNoteDialog">닫기</button>
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
import { useRouter } from 'vue-router';
import * as XLSX from 'xlsx';
import { userSettlementMonthTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import { format } from 'date-fns';
import Button from 'primevue/button';

const router = useRouter();

const monthList = ref([]); // 월별 현황 데이터
const loading = ref(false);
const totalCount = ref(0);

const selectedMonth = ref('');
const monthOptions = ref([]);

// 전달사항 팝업 상태
const showNoteDialog = ref(false);
const noteValue = ref('');

const currentUserRegNo = ref('');

const isMobile = computed(() => window.innerWidth <= 768);

const tableConfig = computed(() => isMobile.value ? userSettlementMonthTableConfig.mobile : userSettlementMonthTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 없음)
const tableScrollHeight = computed(() => getTableScrollHeight(false, 40));

// 정산월 목록 불러오기 (settlement_months 테이블)
const fetchMonthOptions = async () => {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('settlement_month')
    .order('settlement_month', { ascending: false });
  if (!error && data) {
    const unique = Array.from(new Set(data.map(row => row.settlement_month)));
    monthOptions.value = unique;
  }
};

// 필터링된 리스트
const filteredMonthList = computed(() => {
  if (!selectedMonth.value) return monthList.value;
  return monthList.value.filter(item => item.settlement_month === selectedMonth.value);
});

// 현재 로그인한 사용자의 사업자등록번호 가져오기
const getCurrentUser = async () => {
  console.log('getCurrentUser_유저확인 시작');
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    console.log('getCurrentUser_로그인 유저:', user.email);
    const { data: profile } = await supabase
      .from('members')
      .select('*')
      .eq('id_email', user.email)
      .single();
    if (profile) {
      currentUserRegNo.value = profile.biz_no;
      console.log('getCurrentUser_사업자등록번호 확인:', currentUserRegNo.value);
    } else {
      console.error('getCurrentUser_멤버 정보를 찾을 수 없습니다.');
    }
  } else {
    console.error('getCurrentUser_로그인된 유저가 없습니다.');
  }
};

// 월별 현황 데이터 불러오기
const fetchMonthList = async () => {
  loading.value = true;
  monthList.value = [];
  console.log('fetchMonthList_데이터 조회 시작, 사업자등록번호:', currentUserRegNo.value);
  if (!currentUserRegNo.value) {
    loading.value = false;
    console.log('fetchMonthList_사업자등록번호가 없어서 중단합니다.');
    return;
  }

  try {
    // 1. 현재 사용자의 모든 정산 데이터 가져오기
    console.log('fetchMonthList_settlements 테이블 조회 시작');
    const { data: settlements, error: settlementsError } = await supabase
      .from('settlements')
      .select('*')
      .like('company_reg_no', `%${currentUserRegNo.value}%`);

    if (settlementsError) {
      console.error('settlements 조회 에러', settlementsError);
      throw settlementsError;
    }
    console.log('fetchMonthList_settlements 조회 결과:', settlements);

    if (!settlements || settlements.length === 0) {
      console.log('fetchMonthList_settlements 데이터가 없습니다.');
      monthList.value = [];
      totalCount.value = 0;
      loading.value = false;
      return;
    }

    // 2. 노트와 등록일자 정보를 위해 모든 정산월 정보 가져오기
    const { data: allMonths, error: monthsError } = await supabase
      .from('settlement_months')
      .select('settlement_month, note, created_at')
      .order('settlement_month', { ascending: false });

    if (monthsError) throw monthsError;

    const allMonthsMap = new Map((allMonths || []).map(m => [m.settlement_month, m]));

    // 3. 사용자의 정산 데이터에서 고유한 월 목록 추출 및 정렬
    const userMonths = [...new Set(settlements.map(s => s.settlement_month))].sort().reverse();

    // 4. 월별로 데이터 집계
    monthList.value = userMonths.map(month => {
      const rows = settlements.filter(r => r.settlement_month === month);
      const hospitalSet = new Set(rows.map(r => r.hospital_name));
      
      const prescription_count = rows.length;
      const prescription_amount = rows.reduce((sum, r) => sum + (Number(r.prescription_amount) || 0), 0);
      const payment_amount = rows.reduce((sum, r) => sum + (Number(r.payment_amount) || 0), 0);

      const monthInfo = allMonthsMap.get(month) || {};

      return {
        settlement_month: month,
        hospital_name: hospitalSet.size,
        prescription_count: prescription_count ? prescription_count.toLocaleString() : '0',
        prescription_amount: prescription_amount ? prescription_amount.toLocaleString() : '0',
        payment_amount: payment_amount ? payment_amount.toLocaleString() : '0',
        note: monthInfo.note || '',
        created_at: monthInfo.created_at ? format(new Date(monthInfo.created_at), 'yyyy-MM-dd') : '-',
      };
    });
    
    console.log('fetchMonthList_최종 집계 데이터:', monthList.value);
    totalCount.value = monthList.value.length;

  } catch (e) {
    alert('월별 현황 데이터 조회 실패: ' + e.message);
    console.error('fetchMonthList_에러:', e);
  }
  loading.value = false;
};

onMounted(async () => {
  await getCurrentUser();
  await fetchMonthOptions();
  await fetchMonthList();
  // 기본값을 전체로 설정
  selectedMonth.value = '';
});

const downloadExcel = () => {
  if (!monthList.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  const headers = [
    '정산월', '병의원수', '처방건수', '처방액', '지급액', '전달사항'
  ];
  const data = monthList.value.map(item => [
    item.settlement_month,
    item.hospital_name,
    item.prescription_count,
    item.prescription_amount,
    item.payment_amount,
    item.note ? item.note.replace(/\n/g, '\\n') : ''
  ]);
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '월별정산현황');
  const fileName = `월별정산현황_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};
const openNotePopup = (row) => {
  noteValue.value = row.note;
  showNoteDialog.value = true;
};
const closeNoteDialog = () => {
  showNoteDialog.value = false;
};
const goDetail = (row) => {
  // 상세화면(월별 상세)로 이동, 정산월 파라미터 전달
  router.push(`/settlement/month/${row.settlement_month}`);
};
</script>
