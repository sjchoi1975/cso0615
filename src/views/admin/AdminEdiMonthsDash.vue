<template>
  <div class="admin-edi-months-dash-view page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    
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
      <div class="total-count">전체 업체수 : {{ totalCompanies }}개</div>
      <div style="display: flex; gap: 1rem;">
        <Button
          icon="pi pi-list"
          label="전체 상세"
          class="btn-add-md"
          @click="goToDetailList"
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
          :value="filteredCompanies"
          :loading="false"
          :paginator="false"
          scrollable
          :scrollHeight="tableScrollHeight"
          sortMode="multiple"
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
              <template v-else-if="col.field === 'company_name'">
                <span class="table-title">{{ slotProps.data.company_name }}</span>
              </template>
              <template v-else-if="col.field === 'total_hospitals'">
                {{ slotProps.data.total_hospitals === 0 ? '-' : slotProps.data.total_hospitals }}
              </template>
              <template v-else-if="col.field === 'prev_month_submitted_hospitals'">
                {{ slotProps.data.prev_month_submitted_hospitals === 0 ? '-' : slotProps.data.prev_month_submitted_hospitals }}
              </template>
              <template v-else-if="col.field === 'current_month_submitted_hospitals'">
                {{ slotProps.data.current_month_submitted_hospitals === 0 ? '-' : slotProps.data.current_month_submitted_hospitals }}
              </template>
              <template v-else-if="col.field === 'prev_month_files'">
                {{ slotProps.data.prev_month_files === 0 ? '-' : slotProps.data.prev_month_files }}
              </template>
              <template v-else-if="col.field === 'current_month_files'">
                {{ slotProps.data.current_month_files === 0 ? '-' : slotProps.data.current_month_files }}
              </template>
              <template v-else-if="col.field === 'confirmed_files'">
                {{ slotProps.data.confirmed_files === 0 ? '-' : slotProps.data.confirmed_files }}
              </template>
              <template v-else-if="col.field === 'unconfirmed_files'">
                {{ slotProps.data.unconfirmed_files === 0 ? '-' : slotProps.data.unconfirmed_files }}
              </template>
              <template v-else-if="col.field === 'last_submission_date'">
                {{ formatDateTime(slotProps.data.last_submission_date) }}
              </template>
              <template v-else-if="col.type === 'icon' && col.field === 'detail'">
                <Button 
                  icon="pi pi-list" 
                  class="p-button-rounded p-button-text btn-icon-view" 
                  @click="goToCompanyDetail(slotProps.data)" 
                  v-tooltip.top="'상세보기'"
                />
              </template>
              <template v-else>
                {{ slotProps.data[col.field] }}
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Button from 'primevue/button';
import * as XLSX from 'xlsx';
import { getTableScrollHeight } from '@/utils/tableHeight';
import { adminEdiDashboardTableConfig } from '@/config/tableConfig';

const router = useRouter();
const loading = ref(false);
const selectedMonth = ref('');
const monthOptions = ref([]);
const companies = ref([]);
const totalCompanies = ref(0);

// 테이블 설정
const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => {
  return isMobile.value ? adminEdiDashboardTableConfig.mobile : adminEdiDashboardTableConfig.pc;
});

const tableScrollHeight = computed(() => getTableScrollHeight(false));

// 필터링된 업체 목록
const filteredCompanies = computed(() => {
  if (!selectedMonth.value) return companies.value;
  return companies.value.filter(company => {
    // 선택된 월에 해당하는 데이터만 필터링 (실제로는 모든 데이터를 다시 조회해야 함)
    return true; // 임시로 모든 데이터 표시
  });
});

// 정산월 옵션 조회
const fetchMonthOptions = async () => {
  const { data, error } = await supabase
    .from('edi_months')
    .select('settlement_month')
    .order('settlement_month', { ascending: false });
  
  if (!error && data) {
    const unique = Array.from(new Set(data.map(row => row.settlement_month)));
    monthOptions.value = unique;
    if (unique.length > 0) {
      selectedMonth.value = unique[0]; // 최신 정산월을 기본값으로 설정
    }
  }
};

// 업체별 제출 현황 조회
const fetchCompaniesData = async () => {
  loading.value = true;
  
  try {
    // 1. 승인된 모든 회원 조회
    const { data: members, error: membersError } = await supabase
      .from('members')
      .select('id, company_name, biz_no, ceo_name')
      .eq('approval', 'approved')
      .order('company_name');
    
    if (membersError) throw membersError;
    
    // 2. 각 회원별로 통계 계산
    const companiesData = [];
    
    for (const member of members) {
      // 해당 회원의 거래처 수 조회
      const { data: hospitals, error: hospitalsError } = await supabase
        .from('hospital_member_mappings')
        .select('hospital_id')
        .eq('member_id', member.id);
      
      if (hospitalsError) {
        console.error('Error fetching hospitals:', hospitalsError);
        continue;
      }
      
      const totalHospitals = hospitals?.length || 0;
      
      // EDI 파일 통계 조회
      let ediQuery = supabase
        .from('edi_files')
        .select('id, created_at, confirm, settlement_month_id, hospital_id')
        .eq('member_id', member.id)
        .eq('is_deleted', false);
      
      if (selectedMonth.value) {
        // 선택된 정산월에 해당하는 edi_months의 ID 조회
        const { data: ediMonthData } = await supabase
          .from('edi_months')
          .select('id')
          .eq('settlement_month', selectedMonth.value)
          .single();
        
        if (ediMonthData) {
          ediQuery = ediQuery.eq('settlement_month_id', ediMonthData.id);
        }
      }
      
      const { data: ediFiles, error: ediError } = await ediQuery;
      
      if (ediError) {
        console.error('Error fetching EDI files:', ediError);
        continue;
      }
      
      // 전월/당월 파일 수 계산
      let currentMonthFiles = 0;
      let prevMonthFiles = 0;
      let prevEdiMonthData = null;
      
      if (selectedMonth.value) {
        // 선택된 정산월에 해당하는 파일 수
        currentMonthFiles = ediFiles?.length || 0;
        
        // 전월 파일 수 계산을 위해 전월 정산월 ID 조회
        const currentYear = parseInt(selectedMonth.value.slice(0, 4));
        const currentMonthNum = parseInt(selectedMonth.value.slice(5, 7));
        const prevMonthNum = currentMonthNum === 1 ? 12 : currentMonthNum - 1;
        const prevYear = currentMonthNum === 1 ? currentYear - 1 : currentYear;
        const prevMonthStr = `${prevYear}-${String(prevMonthNum).padStart(2, '0')}`;
        
        const { data: prevEdiMonthResult } = await supabase
          .from('edi_months')
          .select('id')
          .eq('settlement_month', prevMonthStr)
          .single();
        
        prevEdiMonthData = prevEdiMonthResult;
        
        if (prevEdiMonthData) {
          const { data: prevEdiFiles } = await supabase
            .from('edi_files')
            .select('id')
            .eq('member_id', member.id)
            .eq('settlement_month_id', prevEdiMonthData.id)
            .eq('is_deleted', false);
          
          prevMonthFiles = prevEdiFiles?.length || 0;
        }
      } else {
        // 전체 조회 시에는 최근 2개월 기준으로 계산
        const today = new Date();
        const currentMonth = today.getMonth() + 1;
        const prevMonth = currentMonth === 1 ? 12 : currentMonth - 1;
        
        currentMonthFiles = ediFiles?.filter(file => {
          const fileMonth = new Date(file.created_at).getMonth() + 1;
          return fileMonth === currentMonth;
        }).length || 0;
        
        prevMonthFiles = ediFiles?.filter(file => {
          const fileMonth = new Date(file.created_at).getMonth() + 1;
          return fileMonth === prevMonth;
        }).length || 0;
      }
      
              // 전월/당월 제출 거래처 수 계산
        let prevMonthSubmittedHospitals = 0;
        let currentMonthSubmittedHospitals = 0;
        
        if (selectedMonth.value) {
          // 당월 제출 거래처 수 (선택된 정산월에 EDI 파일을 제출한 거래처 수)
          const currentMonthHospitalIds = new Set(ediFiles?.map(file => file.hospital_id) || []);
          currentMonthSubmittedHospitals = currentMonthHospitalIds.size;
          
          // 전월 제출 거래처 수 계산
          if (prevEdiMonthData) {
            const { data: prevEdiFiles } = await supabase
              .from('edi_files')
              .select('hospital_id')
              .eq('member_id', member.id)
              .eq('settlement_month_id', prevEdiMonthData.id)
              .eq('is_deleted', false);
            
            const prevMonthHospitalIds = new Set(prevEdiFiles?.map(file => file.hospital_id) || []);
            prevMonthSubmittedHospitals = prevMonthHospitalIds.size;
          }
        } else {
          // 전체 조회 시에는 최근 2개월 기준으로 계산
          const today = new Date();
          const currentMonth = today.getMonth() + 1;
          const prevMonth = currentMonth === 1 ? 12 : currentMonth - 1;
          
          const currentMonthFiles = ediFiles?.filter(file => {
            const fileMonth = new Date(file.created_at).getMonth() + 1;
            return fileMonth === currentMonth;
          }) || [];
          
          const prevMonthFiles = ediFiles?.filter(file => {
            const fileMonth = new Date(file.created_at).getMonth() + 1;
            return fileMonth === prevMonth;
          }) || [];
          
          const currentMonthHospitalIds = new Set(currentMonthFiles.map(file => file.hospital_id));
          const prevMonthHospitalIds = new Set(prevMonthFiles.map(file => file.hospital_id));
          
          currentMonthSubmittedHospitals = currentMonthHospitalIds.size;
          prevMonthSubmittedHospitals = prevMonthHospitalIds.size;
        }
      
      // 확인/미확인 파일 수
      const confirmedFiles = ediFiles?.filter(file => file.confirm === true).length || 0;
      const unconfirmedFiles = (ediFiles?.length || 0) - confirmedFiles;
      
      // 최종 등록일시
      const lastSubmissionDate = ediFiles?.length > 0 
        ? ediFiles.reduce((latest, file) => {
            const fileDate = new Date(file.created_at);
            return fileDate > latest ? fileDate : latest;
          }, new Date(0))
        : null;
      
      companiesData.push({
        id: member.id,
        company_name: member.company_name,
        business_registration_number: member.biz_no,
        ceo_name: member.ceo_name,
        total_hospitals: totalHospitals,
        prev_month_submitted_hospitals: prevMonthSubmittedHospitals,
        current_month_submitted_hospitals: currentMonthSubmittedHospitals,
        prev_month_files: prevMonthFiles,
        current_month_files: currentMonthFiles,
        confirmed_files: confirmedFiles,
        unconfirmed_files: unconfirmedFiles,
        last_submission_date: lastSubmissionDate
      });
    }
    
    companies.value = companiesData;
    totalCompanies.value = companiesData.length;
    
  } catch (error) {
    console.error('Error fetching companies data:', error);
    alert('업체 데이터 조회 중 오류가 발생했습니다.');
  } finally {
    loading.value = false;
  }
};

// 날짜 포맷팅
const formatDateTime = (dateTime) => {
  if (!dateTime) return '-';
  return new Date(dateTime).toLocaleString('sv-SE').slice(0, 16);
};

// 전체 상세 보기 (AdminEdiMonthsList로 이동)
const goToDetailList = () => {
  router.push('/admin/edi/months/list');
};

// 업체별 상세 보기 (AdminEdiMonthsList로 해당 업체 필터링된 상태로 이동)
const goToCompanyDetail = (company) => {
  router.push({
    path: '/admin/edi/months/list',
    query: { company: company.id }
  });
};

// 엑셀 다운로드
const downloadExcel = () => {
  if (!companies.value.length) {
    alert('다운로드할 데이터가 없습니다.');
    return;
  }
  
  const headers = [
    '순번', '업체명', '사업자등록번호', '대표자', '총 거래처', 
    '전월 제출파일', '당월 제출파일', '확인', '미확인', '최종 등록일시'
  ];
  
  const data = companies.value.map((company, index) => [
    index + 1,
    company.company_name,
    company.business_registration_number,
    company.ceo_name,
    company.total_hospitals,
    company.prev_month_files,
    company.current_month_files,
    company.confirmed_files,
    company.unconfirmed_files,
    formatDateTime(company.last_submission_date)
  ]);
  
  const ws = XLSX.utils.aoa_to_sheet([headers, ...data]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'EDI업체현황');
  
  const monthStr = selectedMonth.value ? `_${selectedMonth.value}` : '';
  const fileName = `EDI업체현황${monthStr}_${new Date().toISOString().slice(0,10)}.xlsx`;
  XLSX.writeFile(wb, fileName);
};

// 정산월 변경 시 데이터 다시 조회
const onMonthChange = () => {
  fetchCompaniesData();
};

onMounted(async () => {
  await fetchMonthOptions();
  await fetchCompaniesData();
});

// 정산월 변경 감지
import { watch } from 'vue';
watch(selectedMonth, onMonthChange);
</script>

