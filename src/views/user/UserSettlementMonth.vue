<template>
  <div class="user-settlement-month-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 정산내역이 없을 때 안내카드 -->
    <div v-else-if="!monthOptions.length" class="notice-card">
      <div class="notice-icon"><i class="pi pi-info-circle"></i></div>
      <div class="notice-message">
        <h3>아직 정산내역서가 없습니다.</h3>
        <p>EDI를 제출하신 회원은 정산내역서를 확인할 수 있습니다.</p>
      </div>
    </div>
    <!-- 기존 내용: 정산내역이 있을 때만 노출 -->
    <template v-else>
      <!-- 필터카드 -->
      <div class="filter-card">
        <div class="filter-row" style="margin-left:1rem;">
          <span>정산월</span>
          <select v-model="selectedMonth" class="input-120">
            <option value="">- 전체 -</option>
            <option v-for="m in monthOptions" :key="m" :value="m">
              {{ m.slice(0,4) + '년 ' + parseInt(m.slice(5,7)) + '월' }}
            </option>
          </select>
        </div>
      </div>
      <!-- board-form: 정산내역, 세금계산서, 전달사항 -->
      <div class="board">
        <div class="board-form">
          <div class="form-grid-2x">
            <!-- 정산내역 표 -->
            <div class="form-group">
              <label class="txt-110-222">정산내역</label>
              <table style="width:100%; border-collapse:collapse; border:2px solid #666; table-layout:fixed;">
                <thead>
                  <tr style="background:#f8f9fa;">
                    <th style="border:1px solid #bbb; font-weight:500; padding:0.35em; width:33.33%;">거래처</th>
                    <th style="border:1px solid #bbb; font-weight:500; padding:0.35em; width:33.33%;">처방건</th>
                    <th style="border:1px solid #bbb; font-weight:500; padding:0.35em; width:33.33%;">처방액</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td style="border:1px solid #bbb; text-align:center; font-weight:500; padding:0.35em; width:33.33%;">{{ formatCurrencyNoDecimal(summary.hospital_count) }}</td>
                    <td style="border:1px solid #bbb; text-align:center; font-weight:500; padding:0.35em; width:33.33%;">{{ formatCurrencyNoDecimal(summary.prescription_count) }}</td>
                    <td style="border:1px solid #bbb; text-align:center; font-weight:500; padding:0.35em; width:33.33%;">{{ formatCurrencyNoDecimal(summary.prescription_amount) }}</td>
                  </tr>
                </tbody>
              </table>
              <!-- 상세내역보기 버튼 -->
              <div style="text-align:center; margin-top:1rem;">
                <button class="btn-select-wide" style="width:100%;" @click="goDetail">상세 내역 보기 ></button>
              </div>
            </div>

            <!-- 세금계산서 발행 요청 표 -->
            <div class="form-group">
              <label class="txt-110-222">세금계산서 발행 요청</label>
              <table style="width:100%; border-collapse:collapse; border:2px solid #666; table-layout:fixed;">
                <thead>
                  <tr style="background:#f8f9fa;">
                    <th style="border:1px solid #bbb; font-weight:500; padding:0.35em; width:33.33%;">공급가</th>
                    <th style="border:1px solid #bbb; font-weight:500; padding:0.35em; width:33.33%;">부가세</th>
                    <th style="border:1px solid #bbb; font-weight:500; padding:0.35em; width:33.33%;">합계액</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td style="border:1px solid #bbb; text-align:center; font-weight:500; padding:0.35em; width:33.33%;">{{ formatCurrencyNoDecimal(summary.supply_amount) }}</td>
                    <td style="border:1px solid #bbb; text-align:center; font-weight:500; padding:0.35em; width:33.33%;">{{ formatCurrencyNoDecimal(summary.vat) }}</td>
                    <td style="border:1px solid #bbb; text-align:center; font-weight:500; padding:0.35em; width:33.33%;">{{ formatCurrencyNoDecimal(summary.total_amount) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- 전달사항 박스 (공용+개별 줄바꿈) -->
            <div class="form-group">
              <label class="txt-110-222">전달사항</label>
              <div style="border:1px solid #bbb;
                border-radius:2px;
                min-height:80px;
                padding:0.7rem;
                background:#fff;
                white-space:pre-line;">
                <template v-if="publicNote && privateNote">
                  {{ publicNote }}<br><br>{{ privateNote }}
                </template>
                <template v-else-if="publicNote">
                  {{ publicNote }}
                </template>
                <template v-else-if="privateNote">
                  {{ privateNote }}
                </template>
                <template v-else>
                  -
                </template>
              </div>
            </div>

            <!-- 정정요청 내용 표시 -->
            <div v-if="correctionText" class="form-group">
              <div style="display:flex;
                justify-content:space-between;
                align-items:center;
                margin-bottom:0.5rem"
              >
                <label class="txt-110-222" style="color:#dc3545;">정정요청</label>
                <button
                  style="font-size:0.95rem;
                  color:#1976d2;
                  background:none;
                  border:none;
                  cursor:pointer;
                  padding:0;
                  text-decoration:underline;"
                  @click="onEditCorrection">수정하기</button>
              </div>
              <div
                style="border:1px solid #bbb;
                border-radius:2px;
                min-height:60px;
                padding:0.7rem;
                background:#fcfcd8;
                white-space:pre-line;">
                {{ correctionText }}</div>
            </div>
          </div>

          <!-- 하단 버튼 -->
          <div class="btn-row">
            <button
              :class="correctionBtnClass"
              style="flex:1;"
              @click="onCorrectionClick"
              :disabled="correctionDisabled">
              {{ correctionBtnLabel }}</button>
            <button
              :class="confirmBtnClass"
              style="flex:3;"
              @click="onConfirmClick"
              :disabled="confirmDisabled">
              {{ confirmBtnLabel }}</button>
          </div>
        </div>
      </div>

      <!-- 정정요청 모달 -->
      <teleport to="body">
        <div v-if="showCorrectionModal" class="custom-modal-overlay" @click.self="cancelCorrection">
          <div class="custom-modal">
            <div class="modal-header">
              <div class="modal-title">정정요청 {{ isEditCorrection ? '수정' : '' }}</div>
            </div>
            <div class="modal-body">
              <textarea
                v-model="correctionInput"
                placeholder="정정요청 내용을 입력하세요"
                rows="8"
                class="input"
                style="width:100%;">
              </textarea>
            </div>
            <div class="modal-footer">
              <button class="btn-cancel modal" @click="cancelCorrection">취소</button>
              <button class="btn-confirm modal" @click="saveCorrection">저장</button>
            </div>
          </div>
        </div>
      </teleport>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
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

// 정정요청/확인 모달 상태
const showActionModal = ref(false);
const actionType = ref(''); // 'correction' 또는 'confirm'
const actionComment = ref('');

const currentUserRegNo = ref('');

const isMobile = computed(() => window.innerWidth <= 768);

const tableConfig = computed(() => isMobile.value ? userSettlementMonthTableConfig.mobile : userSettlementMonthTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 없음)
const tableScrollHeight = computed(() => getTableScrollHeight(false, 40));

const summary = ref({});
const publicNote = ref('');
const privateNote = ref('');

// 상태 관리
const isConfirmed = ref(false); // 정산확정 여부
const correctionText = ref(''); // 정정요청 내용
const currentStatus = ref('미확인'); // 현재 상태: '미확인', '확정', '정정요청'

// 정산확정 버튼 색상/문구
const confirmBtnClass = computed(() => {
  if (currentStatus.value === '확정') return 'btn-dark-gray';
  if (currentStatus.value === '정정요청') return 'btn-confirm-disabled';
  return 'btn-confirm';
});

const confirmBtnLabel = computed(() => {
  if (currentStatus.value === '확정') return '확정취소';
  if (currentStatus.value === '정정요청') return '정산확정';
  return '정산확정';
});

// 정산확정 버튼 비활성화 (정정요청 상태에서만)
const confirmDisabled = computed(() => false);

// 정정요청 버튼 색상/문구
const correctionBtnClass = computed(() => {
  if (currentStatus.value === '정정요청') return 'btn-dark-gray';
  return 'btn-warning';
});

const correctionBtnLabel = computed(() => {
  if (currentStatus.value === '정정요청') return '정정요청 취소';
  return '정정요청';
});

// 정정요청 버튼 비활성화 (확정 상태에서만)
const correctionDisabled = computed(() => false);

// 정정요청 모달 상태
const showCorrectionModal = ref(false);
const correctionInput = ref('');
const isEditCorrection = ref(false);

// 정산월 목록 불러오기 (settlement_months 테이블)
const fetchMonthOptions = async () => {
  if (!currentUserRegNo.value) return;
  const { data, error } = await supabase
    .from('settlements_share')
    .select('settlement_month')
    .eq('company_reg_no', currentUserRegNo.value)
    .eq('share', 'y')
    .order('settlement_month', { ascending: false });
  if (!error && data) {
    const unique = Array.from(new Set(data.map(row => row.settlement_month)));
    monthOptions.value = unique;
    // 최신월을 디폴트로 설정
    if (unique.length > 0) selectedMonth.value = unique[0];
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
  summary.value = {};
  publicNote.value = '';
  privateNote.value = '';
  if (!currentUserRegNo.value || !selectedMonth.value) {
    loading.value = false;
    return;
  }

  // 1. settlements_share에서 공유여부 확인
  const { data: shareRows, error: shareError } = await supabase
    .from('settlements_share')
    .select('settlement_month, memo')
    .eq('company_reg_no', currentUserRegNo.value)
    .eq('share', 'y')
    .eq('settlement_month', selectedMonth.value)
    .single();

  if (shareError || !shareRows) {
    loading.value = false;
    return;
  }

  // 2. settlements에서 해당 월 데이터 집계
  const { data: settlements, error: settlementsError } = await supabase
    .from('settlements')
    .select('*')
    .eq('company_reg_no', currentUserRegNo.value)
    .eq('settlement_month', selectedMonth.value);

  if (settlementsError || !settlements || settlements.length === 0) {
    loading.value = false;
    return;
  }

  // 집계 (항목별 실제 값)
  const hospitalSet = new Set(settlements.map(r => r.hospital_name));
  const prescription_count = settlements.length;
  const prescription_amount = settlements.reduce((sum, r) => sum + (Number(r.prescription_amount) || 0), 0);
  const payment_amount = settlements.reduce((sum, r) => sum + (Number(r.payment_amount) || 0), 0);
  const supply_amount = Math.round(payment_amount / 1.1);
  const vat = payment_amount - supply_amount;
  const total_amount = payment_amount;
  summary.value = {
    hospital_count: hospitalSet.size,
    prescription_count: prescription_count,
    prescription_amount: prescription_amount,
    payment_amount: payment_amount,
    supply_amount: supply_amount,
    vat: vat,
    total_amount: total_amount,
  };

  // 3. 전달사항(공용)
  const { data: monthRow } = await supabase
    .from('settlement_months')
    .select('note')
    .eq('settlement_month', selectedMonth.value)
    .single();
  publicNote.value = monthRow?.note?.trim() || '';

  // 4. 전달사항(개별)
  privateNote.value = shareRows.memo?.trim() || '';

  loading.value = false;
};

// 정산확정/정정요청 상태 DB에서 불러오기
const fetchShareStatus = async () => {
  if (!selectedMonth.value || !currentUserRegNo.value) {
    currentStatus.value = '미확인';
    correctionText.value = '';
    return;
  }
  const { data, error } = await supabase
    .from('settlements_share')
    .select('confirm_status, confirm_comment')
    .eq('settlement_month', selectedMonth.value)
    .eq('company_reg_no', currentUserRegNo.value)
    .single();
  if (data) {
    currentStatus.value = data.confirm_status || '미확인';
    correctionText.value = data.confirm_status === '정정요청' ? (data.confirm_comment || '') : '';
  } else {
    currentStatus.value = '미확인';
    correctionText.value = '';
  }
};

onMounted(async () => {
  await getCurrentUser();
  await fetchMonthOptions();
  await fetchMonthList();
  if (selectedMonth.value && currentUserRegNo.value) {
    await fetchShareStatus();
  }
});

watch([selectedMonth, currentUserRegNo], async ([month, regNo]) => {
  if (month && regNo) {
    await fetchShareStatus();
  }
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
const goDetail = () => {
  // 상세화면(월별 상세)로 이동, 정산월 파라미터 전달
  if (!selectedMonth.value || !currentUserRegNo.value) {
    alert('정산월 또는 사용자 정보가 없습니다.');
    return;
  }
  router.push({
    path: `/settlement/month/detail`,
    query: {
      month: selectedMonth.value,
      biz_no: currentUserRegNo.value
    }
  });
};

// 정정요청 버튼 클릭
const requestCorrection = () => {
  actionType.value = 'correction';
  actionComment.value = '';
  showActionModal.value = true;
};

// 확인 버튼 클릭
const confirmSettlement = () => {
  actionType.value = 'confirm';
  actionComment.value = '';
  showActionModal.value = true;
};

// 모달 닫기
const closeActionModal = () => {
  showActionModal.value = false;
  actionType.value = '';
  actionComment.value = '';
};

// 정정요청/확인 저장
const saveAction = async () => {
  if (!currentUserRegNo.value || !selectedMonth.value) {
    alert('사용자 정보 또는 정산월이 없습니다.');
    return;
  }

  const status = actionType.value === 'correction' ? 'requested' : 'confirmed';
  const comment = actionComment.value.trim();

  const upsertRow = {
    settlement_month: selectedMonth.value,
    company_reg_no: currentUserRegNo.value,
    confirm_status: status,
    confirm_comment: comment
  };

  const { error } = await supabase
    .from('settlements_share')
    .upsert([upsertRow], { onConflict: ['settlement_month', 'company_reg_no'] });

  if (error) {
    alert('저장 실패: ' + error.message);
  } else {
    alert(actionType.value === 'correction' ? '정정요청이 저장되었습니다.' : '확인이 저장되었습니다.');
    closeActionModal();
    await fetchMonthList(); // 데이터 갱신
  }
};

// 정산확정 버튼 클릭
const onConfirmClick = async () => {
  if (currentStatus.value === '미확인') {
    // 미확인 -> 확정
    if (window.confirm('정산내역을 확정하시겠습니까?')) {
      currentStatus.value = '확정';
      await supabase.from('settlements_share').upsert([
        {
          settlement_month: selectedMonth.value,
          company_reg_no: currentUserRegNo.value,
          confirm_status: '확정'
        }
      ], { onConflict: ['settlement_month', 'company_reg_no'] });
    }
  } else if (currentStatus.value === '확정') {
    // 확정 -> 미확인
    if (window.confirm('정산 확정을 취소하시겠습니까?')) {
      currentStatus.value = '미확인';
      await supabase.from('settlements_share').upsert([
        {
          settlement_month: selectedMonth.value,
          company_reg_no: currentUserRegNo.value,
          confirm_status: '미확인'
        }
      ], { onConflict: ['settlement_month', 'company_reg_no'] });
    }
  } else if (currentStatus.value === '정정요청') {
    // 정정요청 -> 확정
    if (window.confirm('정정 요청을 취소하고 정산 내역을 확정하시겠습니까?')) {
      currentStatus.value = '확정';
      correctionText.value = '';
      await supabase.from('settlements_share').upsert([
        {
          settlement_month: selectedMonth.value,
          company_reg_no: currentUserRegNo.value,
          confirm_status: '확정',
          confirm_comment: null
        }
      ], { onConflict: ['settlement_month', 'company_reg_no'] });
    }
  }
};

// 정정요청 버튼 클릭
const onCorrectionClick = () => {
  if (currentStatus.value === '확정') {
    // 확정 상태에서 정정요청 클릭 시 확인 모달
    if (window.confirm('정산 확정을 취소하고 정정요청을 하시겠습니까?')) {
      currentStatus.value = '미확인';
      // DB에서 확정 상태 해제
      supabase.from('settlements_share').upsert([
        {
          settlement_month: selectedMonth.value,
          company_reg_no: currentUserRegNo.value,
          confirm_status: '미확인'
        }
      ], { onConflict: ['settlement_month', 'company_reg_no'] });
      // 정정요청 모달 표시
      isEditCorrection.value = false;
      correctionInput.value = '';
      showCorrectionModal.value = true;
    }
  } else if (currentStatus.value === '정정요청') {
    // 정정요청 상태에서 취소
    if (window.confirm('정정요청을 취소하시겠습니까?')) {
      currentStatus.value = '미확인';
      correctionText.value = '';
      supabase.from('settlements_share').upsert([
        {
          settlement_month: selectedMonth.value,
          company_reg_no: currentUserRegNo.value,
          confirm_status: '미확인',
          confirm_comment: null
        }
      ], { onConflict: ['settlement_month', 'company_reg_no'] });
    }
  } else {
    // 미확인 상태에서 정정요청
    isEditCorrection.value = false;
    correctionInput.value = '';
    showCorrectionModal.value = true;
  }
};

// 정정요청 수정 버튼 클릭
const onEditCorrection = () => {
  isEditCorrection.value = true;
  correctionInput.value = correctionText.value;
  showCorrectionModal.value = true;
};

// 정정요청 모달 저장
const saveCorrection = async () => {
  if (!correctionInput.value.trim()) {
    alert('정정요청 내용을 입력해주세요.');
    return;
  }
  
  correctionText.value = correctionInput.value;
  currentStatus.value = '정정요청';
  showCorrectionModal.value = false;
  
  // DB에 정정요청 상태 반영
  const { error } = await supabase.from('settlements_share').upsert([
    {
      settlement_month: selectedMonth.value,
      company_reg_no: currentUserRegNo.value,
      confirm_status: '정정요청',
      confirm_comment: correctionText.value
    }
  ], { onConflict: ['settlement_month', 'company_reg_no'] });

  if (error) {
    alert('저장 실패: ' + error.message);
  } else {
    window.alert('정정요청이 등록되었습니다.');
  }
};

// 정정요청 모달 취소
const cancelCorrection = () => {
  showCorrectionModal.value = false;
};

// 숫자 천단위 콤마, 소수점 없이 포맷팅 함수
function formatCurrencyNoDecimal(val) {
  if (val === undefined || val === null || val === '') return '-';
  return Number(val).toLocaleString('ko-KR', { maximumFractionDigits: 0 });
}
</script>
