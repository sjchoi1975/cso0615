<template>
  <div class="admin-products-view page-container">
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row" style="gap: 0.5rem; align-items: center;">
        <span style="margin-right: 0.25rem;">검색</span>
        <span class="p-input-icon-left">
          <input v-model="search" placeholder="제약사, 제품명, 보험코드, 성분명 검색" class="input-search" />
        </span>
      </div>
    </div>
    <!-- 하단: 테이블카드 -->
    <div class="data-card">
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;">
        <div class="month-selector">
          <button v-if="hasPrevMonth" class="month-nav" @click="goToPrevMonth">&lt;</button>
          <span style="margin: 0 0.5rem;" class="selected-month">{{ displayMonth }}</span>
          <button v-if="hasNextMonth" class="month-nav" @click="goToNextMonth">&gt;</button>
        </div>
        <div style="display: flex; gap:0.5rem; align-items:center;">
          <button class="btn-add" @click="downloadExcel">엑셀 다운로드</button>
          <button class="btn-add" @click="downloadTemplate">엑셀 템플릿</button>
          <label class="btn-add" style="margin-bottom:0; cursor:pointer;">
            엑셀 일괄 등록
            <input type="file" accept=".xlsx,.xls" @change="uploadExcel" style="display:none;" />
          </label>
          <button class="btn-add" @click="goToProductCreate">제품 등록</button>
        </div>
      </div>
      <DataTable
        :value="filteredProducts"
        :loading="loading" paginator
        :rows="100"
        :rowsPerPageOptions="[20, 50, 100]"
        responsiveLayout="scroll"
        v-model:first="first"
        scrollable
        :scrollHeight="'calc(100vh - 250px)'"
      >
        <Column header="순번"
          :style="{ width: columnWidths.index }"
          :bodyStyle="{ textAlign: columnAligns.index }">
          <template #body="slotProps">
            {{ first + slotProps.index + 1 }}
          </template>
        </Column>
        <Column field="pharmacist" header="제약사*"
          :sortable="columnSortables.pharmacist"
          :style="{ width: columnWidths.pharmacist }"
          :bodyStyle="{ textAlign: columnAligns.pharmacist }">
          <template #body="slotProps">
            <span :title="slotProps.data.pharmacist">{{ slotProps.data.pharmacist }}</span>
          </template>
        </Column>
        <Column field="classification" header="분류명"
          :sortable="columnSortables.classification"
          :style="{ width: columnWidths.classification }"
          :bodyStyle="{ textAlign: columnAligns.classification }">
          <template #body="slotProps">
            <span :title="slotProps.data.classification">{{ slotProps.data.classification }}</span>
          </template>
        </Column>
        <Column field="product_name" header="제품명*"
          :sortable="columnSortables.product_name"
          :style="{ width: columnWidths.product_name }"
          :bodyStyle="{ textAlign: columnAligns.product_name }">
          <template #body="slotProps">
            <span :title="slotProps.data.product_name">{{ slotProps.data.product_name }}</span>
          </template>
        </Column>
        <Column field="insurance_code" header="보험코드"
          :sortable="columnSortables.insurance_code"
          :style="{ width: columnWidths.insurance_code }"
          :bodyStyle="{ textAlign: columnAligns.insurance_code }">
        </Column>
        <Column field="price" header="약가"
          :sortable="columnSortables.price"
          :style="{ width: columnWidths.price }"
          :bodyStyle="{ textAlign: columnAligns.price }">
          <template #body="slotProps">
            {{ slotProps.data.price != null ? slotProps.data.price.toLocaleString() : '' }}
          </template>
        </Column>
        <Column field="commission_rate_a" header="수수료 A"
          :sortable="columnSortables.commission_rate_a"
          :style="{ width: columnWidths.commission_rate_a }"
          :bodyStyle="{ textAlign: columnAligns.commission_rate_a }">
          <template #body="slotProps">
            {{ slotProps.data.commission_rate_a != null ? (slotProps.data.commission_rate_a * 100).toFixed(1).replace(/\.0$/, '') + '%' : '' }}
          </template>
        </Column>
        <Column field="commission_rate_b" header="수수료 B"
          :sortable="columnSortables.commission_rate_b"
          :style="{ width: columnWidths.commission_rate_b }"
          :bodyStyle="{ textAlign: columnAligns.commission_rate_b }">
          <template #body="slotProps">
            {{ slotProps.data.commission_rate_b != null ? (slotProps.data.commission_rate_b * 100).toFixed(1).replace(/\.0$/, '') + '%' : '' }}
          </template>
        </Column>
        <Column field="commission_rate_c" header="수수료 C"
          :sortable="columnSortables.commission_rate_c"
          :style="{ width: columnWidths.commission_rate_c }"
          :bodyStyle="{ textAlign: columnAligns.commission_rate_c }">
          <template #body="slotProps">
            {{ slotProps.data.commission_rate_c != null ? (slotProps.data.commission_rate_c * 100).toFixed(1).replace(/\.0$/, '') + '%' : '' }}
          </template>
        </Column>
        <Column field="Ingredient" header="성분"
          :sortable="columnSortables.Ingredient"
          :style="{ width: columnWidths.Ingredient }"
          :bodyStyle="{ textAlign: columnAligns.Ingredient }">
          <template #body="slotProps">
            <span :title="slotProps.data.Ingredient">{{ slotProps.data.Ingredient }}</span>
          </template>
        </Column>
        <Column field="comparator" header="대조약"
          :sortable="columnSortables.comparator"
          :style="{ width: columnWidths.comparator }"
          :bodyStyle="{ textAlign: columnAligns.comparator }">
          <template #body="slotProps">
            <span :title="slotProps.data.comparator">{{ slotProps.data.comparator }}</span>
          </template>
        </Column>
        <Column field="reimbursement" header="급여"
          :sortable="columnSortables.reimbursement"
          :style="{ width: columnWidths.reimbursement }"
          :bodyStyle="{ textAlign: columnAligns.reimbursement }">
        </Column>
        <Column field="bioequivalence" header="생동"
          :sortable="columnSortables.bioequivalence"
          :style="{ width: columnWidths.bioequivalence }"
          :bodyStyle="{ textAlign: columnAligns.bioequivalence }">
        </Column>
        <Column field="Inhouse" header="자사/위탁"
          :sortable="columnSortables.Inhouse"
          :style="{ width: columnWidths.Inhouse }"
          :bodyStyle="{ textAlign: columnAligns.Inhouse }">
        </Column>
        <Column field="remarks" header="비고"
          :sortable="columnSortables.remarks"
          :style="{ width: columnWidths.remarks }"
          :bodyStyle="{ textAlign: columnAligns.remarks }">
          <template #body="slotProps">
            <span :title="slotProps.data.remarks">{{ slotProps.data.remarks }}</span>
          </template>
        </Column>
        <Column field="status" header="상태"
          :sortable="columnSortables.status"
          :style="{ width: columnWidths.status }"
          :bodyStyle="{ textAlign: columnAligns.status }">
          <template #body="slotProps">
            <div class="custom-toggle-wrap">
              <input
                type="checkbox"
                :id="'toggle-' + slotProps.data.id"
                class="custom-toggle-checkbox"
                :checked="slotProps.data.status === 'active'"
                @change="e => onHtmlToggleStatus(slotProps.data, e.target.checked)"
              />
              <label :for="'toggle-' + slotProps.data.id" class="custom-toggle-label"></label>
            </div>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import dayjs from 'dayjs';
import { useRouter } from 'vue-router';
import * as XLSX from 'xlsx';

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  index: '4%',
  pharmacist: '6%',
  classification: '8%',
  product_name: '10%',
  insurance_code: '6%',
  price: '4%',
  commission_rate_a: '4%',
  commission_rate_b: '4%',
  commission_rate_c: '4%',
  Ingredient: '13%',
  comparator: '10%',
  reimbursement: '4%',
  bioequivalence: '4%',
  Inhouse: '4%',
  remarks: '10%',
  status: '5%'
};

// 컬럼별 정렬 여부 한 곳에서 관리
const columnSortables = {
  index: false,
  pharmacist: true,
  classification: true,
  product_name: true,
  insurance_code: true,
  price: true,
  commission_rate_a: true,
  commission_rate_b: true,
  commission_rate_c: true,
  Ingredient: true,
  comparator: true,
  reimbursement: true,
  bioequivalence: true,
  Inhouse: true,
  remarks: true,
  status: true
};

// 컬럼별 정렬 방식 한 곳에서 관리
const columnAligns = {
  index: 'center',
  pharmacist: 'left',
  classification: 'left',
  product_name: 'left',
  insurance_code: 'center',
  price: 'right',
  commission_rate_a: 'center',
  commission_rate_b: 'center',
  commission_rate_c: 'center',
  Ingredient: 'left',
  comparator: 'left',
  reimbursement: 'center',
  bioequivalence: 'center',
  Inhouse: 'center',
  remarks: 'left',
  status: 'center'
};

const products = ref([]);
const loading = ref(false);
const search = ref('');
const currentMonth = ref('');
const router = useRouter();
const first = ref(0);

// 연월 관련
const today = dayjs();
currentMonth.value = today.format('YYYY-MM');

const displayMonth = computed(() => {
  const [y, m] = currentMonth.value.split('-');
  return `${y}년 ${parseInt(m)}월`;
});

const hasPrevMonth = computed(() => {
  // 예시: 2020-01 이후 데이터만 있다고 가정
  return currentMonth.value > '2020-01';
});
const hasNextMonth = computed(() => {
  return currentMonth.value < today.format('YYYY-MM');
});
const goToPrevMonth = () => {
  currentMonth.value = dayjs(currentMonth.value + '-01').subtract(1, 'month').format('YYYY-MM');
};
const goToNextMonth = () => {
  currentMonth.value = dayjs(currentMonth.value + '-01').add(1, 'month').format('YYYY-MM');
};

const fetchProducts = async () => {
  loading.value = true;
  let query = supabase.from('products').select('*').eq('base_month', currentMonth.value).order('registered_at', { ascending: false });
  const { data, error } = await query;
  if (!error) {
    products.value = data;
  }
  loading.value = false;
};

onMounted(fetchProducts);

// 연월이 바뀌면 데이터 다시 불러오기
watch(currentMonth, fetchProducts);

const filteredProducts = computed(() => {
  let result = products.value;
  if (search.value) {
    const keyword = search.value.toLowerCase();
    result = result.filter(p =>
      (p.pharmacist && p.pharmacist.toLowerCase().includes(keyword)) ||
      (p.product_name && p.product_name.toLowerCase().includes(keyword)) ||
      (p.insurance_code && p.insurance_code.toLowerCase().includes(keyword)) ||
      (p.Ingredient && p.Ingredient.toLowerCase().includes(keyword))
    );
  }
  return result;
});

const goToProductCreate = () => {
  router.push('/admin/products/create');
};

// 상태 토글 함수 추가
const onHtmlToggleStatus = async (product, checked) => {
  const toActive = checked;
  const msg = toActive ? '활성화 하시겠습니까?' : '비활성화 하시겠습니까?';
  if (!confirm(msg)) {
    fetchProducts(); // 상태 복구
    return;
  }
  await supabase.from('products').update({ status: toActive ? 'active' : 'inactive' }).eq('id', product.id);
  fetchProducts();
};

// 엑셀 다운로드
const downloadExcel = () => {
  const todayStr = dayjs().format('YYYY-MM-DD');
  // 목록에 표시되는 컬럼만 추출
  const exportData = filteredProducts.value.map(row => ({
    '제약사': row.pharmacist,
    '분류명': row.classification,
    '제품명': row.product_name,
    '보험코드': row.insurance_code,
    '약가': row.price,
    '수수료A': row.commission_rate_a != null ? row.commission_rate_a : '',
    '수수료B': row.commission_rate_b != null ? row.commission_rate_b : '',
    '수수료C': row.commission_rate_c != null ? row.commission_rate_c : '',
    '성분': row.Ingredient,
    '대조약': row.comparator,
    '급여': row.reimbursement,
    '생동': row.bioequivalence,
    '자사/위탁': row.Inhouse,
    '비고': row.remarks,
    '상태': row.status === 'active' ? '활성' : '비활성',
  }));
  const ws = XLSX.utils.json_to_sheet(exportData);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '제품목록');
  XLSX.writeFile(wb, `products_${todayStr}.xlsx`);
};

// 엑셀 일괄등록용 템플릿 다운로드
const downloadTemplate = () => {
  const headers = [
    '제약사', '분류명', '제품명', '보험코드', '약가',
    '수수료A', '수수료B', '수수료C', '성분',
    '대조약',
    '급여',
    '생동', '자사/위탁', '비고', '상태'
  ];
  const ws = XLSX.utils.aoa_to_sheet([headers]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, '템플릿');
  const todayStr = dayjs().format('YYYY-MM-DD');
  XLSX.writeFile(wb, `products_template_${todayStr}.xlsx`);
};

// 엑셀 업로드
const uploadExcel = async (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = async (evt) => {
    const data = evt.target.result;
    const workbook = XLSX.read(data, { type: 'binary' });
    const sheetName = workbook.SheetNames[0];
    const sheet = workbook.Sheets[sheetName];
    const json = XLSX.utils.sheet_to_json(sheet);
    // 엑셀 헤더에 맞춰 변환
    const rows = json.map(row => ({
      pharmacist: row['제약사'] || '',
      classification: row['분류명'] || '',
      product_name: row['제품명'] || '',
      insurance_code: row['보험코드'] || '',
      price: row['약가'] || null,
      commission_rate_a: row['수수료A'] ? parseFloat(row['수수료A']) : null,
      commission_rate_b: row['수수료B'] ? parseFloat(row['수수료B']) : null,
      commission_rate_c: row['수수료C'] ? parseFloat(row['수수료C']) : null,
      Ingredient: row['성분'] || '',
      comparator: row['대조약'] || '',
      reimbursement: row['급여'] || '',
      bioequivalence: row['생동'] || '',
      Inhouse: row['자사/위탁'] || '',
      remarks: row['비고'] || '',
      status: row['상태'] === '비활성' ? 'inactive' : 'active',
      base_month: currentMonth.value,
      registered_at: new Date().toISOString()
    }));
    // 필수값 체크(제약사, 제품명)
    const validRows = rows.filter(r => r.pharmacist && r.product_name);
    if (validRows.length === 0) {
      alert('엑셀에 등록할 데이터가 없습니다.');
      return;
    }
    const { error } = await supabase.from('products').insert(validRows);
    if (error) {
      alert('엑셀 등록 실패: ' + error.message);
    } else {
      alert('엑셀 등록 성공!');
      fetchProducts();
    }
  };
  reader.readAsBinaryString(file);
};
</script>
