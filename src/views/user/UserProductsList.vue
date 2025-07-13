<template>
  <div class="page-container">
    <div v-if="loading" class="table-loading-spinner-center">
      <img src="/spinner.svg" alt="로딩중" />
    </div>
    <!-- 상단: 필터카드 -->
    <div class="filter-card">
      <div class="filter-row filter-row-center">

        <span class="hide-mobile">통합 검색</span>
        <input v-model="search" class="input-search wide-mobile-search hide-mobile" placeholder="제약사, 제품명, 보험코드, 성분명 입력" />
        <button type="button" class="btn-search hide-mobile" @click="onSearch" :disabled="search.length < 2">검색</button>
        <button type="button" class="btn-reset hide-mobile"  @click="onReset">
          <i class="pi pi-refresh" style="font-size: 1rem;"></i>
          초기화
        </button>
        
        <div class="mobile-search-wrap hide-pc" style="position: relative; width: 100%;">
          <input v-model="search" class="input-search wide-mobile-search" placeholder="제약사, 제품명, 보험코드, 성분명 입력" @keyup.enter="onSearch"/>
          <i v-if="search.length > 0" class="pi pi-times-circle search-clear-icon" @click="onReset"
            style="position: absolute; right: 4.8rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
          <i class="pi pi-search search-btn-icon" @click="search.length >= 2 && onSearch()"
            style="position: absolute; right: 2.4rem; top: 50%; transform: translateY(-50%); cursor: pointer;"></i>
        </div>

      </div>
    </div>

    <!-- 중간: 기능카드 -->
    <div class="function-card">
      <div class="total-count">총 {{ totalCount.toLocaleString() }}개</div>
      <div style="display: flex; gap:1rem; align-items:center;">
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
    
    <!-- 하단: 테이블카드 -->
    <div class="table-card">
      <div :style="tableConfig.tableStyle">
        <DataTable
          :value="products"
          :loading="false"
          :paginator="false"
          scrollable
          scrollDirection="both"
          :scrollHeight="tableScrollHeight"
          ref="tableRef"
          :style="{ width: tableConfig.tableWidth, minWidth: tableConfig.tableStyle.minWidth }"
          lazy
        >
          <Column
            v-for="col in tableConfig.columns"
            :key="col.field"
            :field="col.field"
            :header="col.label"
            :sortable="col.sortable || false"
            :style="{ width: col.width, textAlign: col.align }"
            :bodyStyle="{ textAlign: col.align }"
            :frozen="col.frozen"
            :frozenPosition="col.frozenPosition"
          >
            <template #body="slotProps">
              <template v-if="col.field === 'index'">
                {{ first + slotProps.index + 1 }}
              </template>

              <template v-if="col.field === 'product_name'">
                <div class="product-name-wrapper" :data-product-id="slotProps.data.id">
                  <div class="table-title-link" @click="toggleProductDropdown(slotProps.data.id, slotProps.data)" style="cursor: pointer;">
                    {{ slotProps.data.product_name }}
                  </div>
                  <div v-if="isMobile" class="mobile-product-info">
                    <div class="product-ingredient">{{ slotProps.data.Ingredient }}</div>
                  </div>
                </div>
              </template>

              <template v-else-if="col.field === 'commission_rate'">
                {{ formatCommissionRate(getUserCommission(slotProps.data)) }}
              </template>

              <template v-else-if="col.field === 'price'">
                {{ slotProps.data.price != null ? slotProps.data.price.toLocaleString() : '' }}
              </template>
              
              <template v-else-if="col.field === 'insurance_code'">
                {{ slotProps.data.insurance_code }}
              </template>
              
              <template v-else-if="col.field === 'benefit'">
                {{ slotProps.data.reimbursement || '-' }}
              </template>
              <template v-else-if="col.field === 'pharmacist'">
                <span :title="slotProps.data.pharmacist" :class="{ 'mobile-pharmacist': isMobile }">{{ slotProps.data.pharmacist }}</span>
              </template>
              
              <template v-else>
                <span :title="slotProps.data[col.field]">{{ slotProps.data[col.field] }}</span>
              </template>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <div class="fixed-paginator">
      <Paginator
        :rows="pageSize"
        :totalRecords="totalCount"
        :first="first"
        :rowsPerPageOptions="[100, 200, 500]"
        @page="onPageChange"
      />
    </div>

    <!-- More Dropdown (Portal to body) -->
    <teleport to="body">
      <div v-if="activeDropdown" class="more-dropdown-box" :style="dropdownStyle">
        <button class="dropdown-item" @click="viewProductDetails(activeDropdownData)">
          <i class="pi pi-info-circle"></i>
          <span>상세 정보</span>
        </button>
        <button class="dropdown-item" @click="viewSimilarProducts(activeDropdownData)">
          <i class="pi pi-clone"></i>
          <span>동일성분의약품</span>
        </button>
        <button class="dropdown-item" @click="requestFilter(activeDropdownData)">
          <i class="pi pi-filter"></i>
          <span>필터링 요청</span>
        </button>
        <button class="dropdown-item" @click="viewApprovedPharmaceuticals(activeDropdownData)">
          <i class="pi pi-check-circle"></i>
          <span>승인 거래처</span>
        </button>
      </div>
    </teleport>

    <!-- Similar Products Modal -->
    <div v-if="showSimilarProductsModal" class="custom-modal-overlay">
      <div class="custom-modal-filtering">
        <div class="modal-header">
          <h3 class="modal-title">동일성분의약품</h3>
        </div>
        <div class="modal-body">
          <div v-if="loadingSimilarProducts" class="table-loading-spinner-center">
            <img src="/spinner.svg" alt="로딩중" />
          </div>
          <div v-else-if="similarProducts.length === 0" style="text-align: center; padding: 2rem; color: #666;">
            동일성분의약품이 없습니다.
          </div>
          <div v-else>
            <!-- 제품 정보 표시 -->
            <div class="product-info-header">
              <div class="info-row">
                <span class="info-value-pharmacist">{{ selectedProductForSimilar?.pharmacist }}</span>
              </div>
              <div class="info-row">
                <span class="info-value-product-name">{{ selectedProductForSimilar?.product_name }}</span>
              </div>
              <div class="info-row">
                <span class="info-value-ingredient">{{ selectedProductForSimilar?.Ingredient }}</span>
              </div>
            </div>
            
            <!-- 동일성분의약품 테이블 -->
            <div class="table-scroll-x">
              <table class="mordal-table">
                <thead>
                  <tr>
                    <th>제약사</th>
                    <th>제품명</th>
                    <th>약가</th>
                    <th>요율</th>
                    <th>급여</th>
                    <th>보험코드</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="product in similarProducts" :key="product.insurance_code">
                    <td>{{ product.pharmacist }}</td>
                    <td>{{ product.product_name }}</td>
                    <td>{{ product.price ? product.price.toLocaleString() : '-' }}</td>
                    <td>{{ formatCommissionRate(getUserCommission(product)) }}</td>
                    <td>{{ product.reimbursement }}</td>
                    <td>{{ product.insurance_code }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeSimilarProductsModal" style="flex:1;">
            닫기
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Paginator from 'primevue/paginator';
import Button from 'primevue/button';
import { userProductsTableConfig } from '@/config/tableConfig';
import { getTableScrollHeight } from '@/utils/tableHeight';
import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';
import { findMatchingCompany, logMatchingResult } from '@/utils/companyMatcher';

const router = useRouter();
const search = ref('');
const appliedSearch = ref('');
const isSearched = ref(false);
const products = ref([]);
const loading = ref(false);
const first = ref(0);
const pageSize = ref(200);
const totalCount = ref(0);
const tableRef = ref(null);
const userGrade = ref('');

// 더보기 드롭다운 관련
const activeDropdown = ref(null);
const activeDropdownData = ref(null);
const dropdownStyle = ref({});

// 동일성분의약품 모달 관련
const showSimilarProductsModal = ref(false);
const selectedProductForSimilar = ref(null);
const similarProducts = ref([]);
const loadingSimilarProducts = ref(false);

const isMobile = computed(() => window.innerWidth <= 768);
const tableConfig = computed(() => isMobile.value ? userProductsTableConfig.mobile : userProductsTableConfig.pc);

// 테이블 스크롤 높이 계산 (페이지네이터 있음)
const tableScrollHeight = computed(() => getTableScrollHeight(true));

let latestMonth = null;
let debounceTimer = null;

const fetchProducts = async (pageFirst = 0, pageRows = 200) => {
  loading.value = true;
  if (!latestMonth) {
    const { data: monthData, error: monthError } = await supabase
      .from('products')
      .select('base_month')
      .order('base_month', { ascending: false })
      .limit(1);
    if (monthError) {
      console.error('Error fetching latest month:', monthError);
      loading.value = false;
      return;
    }
    latestMonth = monthData && monthData.length > 0 ? monthData[0].base_month : null;
  }

  if (!latestMonth) {
    products.value = [];
    totalCount.value = 0;
    loading.value = false;
    return;
  }

  let query = supabase
    .from('products')
    .select('*', { count: 'exact' })
    .eq('base_month', latestMonth)
    .eq('status', 'active');

  if (appliedSearch.value) {
    const searchTerms = appliedSearch.value.split(',').map(term => term.trim()).filter(term => term);
    if (searchTerms.length > 0) {
      searchTerms.forEach(term => {
        const orFilter = `or(pharmacist.ilike.%${term}%,product_name.ilike.%${term}%,insurance_code.ilike.%${term}%,Ingredient.ilike.%${term}%)`;
        query = query.or(orFilter);
      });
    }
  }

  query = query.range(pageFirst, pageFirst + pageRows - 1).order('pharmacist', { ascending: true });

  const { data, error, count } = await query;

  if (error) {
    console.error('Error fetching products:', error);
    products.value = [];
    totalCount.value = 0;
  } else {
    products.value = data;
    totalCount.value = count || 0;
  }

  loading.value = false;
};

const onSearch = () => {
  const searchTerm = search.value.trim();
  if (searchTerm.length < 2) return;
  appliedSearch.value = searchTerm;
  first.value = 0;
  isSearched.value = true;
  fetchProducts(0, pageSize.value);
};

const onReset = () => {
  if (!isSearched.value) {
    search.value = '';
    return;
  }
  search.value = '';
  appliedSearch.value = '';
  first.value = 0;
  isSearched.value = false;
  fetchProducts(0, pageSize.value);
};

onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    const { data: memberData, error: memberError } = await supabase
      .from('members')
      .select('grade')
      .eq('id', user.id)
      .single();
    if (memberError) console.error('Error fetching user grade:', memberError);
    else userGrade.value = memberData.grade;
  }
  document.addEventListener('click', handleClickOutside);
  window.addEventListener('scroll', handleScroll, true);
  fetchProducts(first.value, pageSize.value);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
  window.removeEventListener('scroll', handleScroll, true);
});

const onPageChange = (event) => {
  first.value = event.first;
  pageSize.value = event.rows;
  fetchProducts(event.first, event.rows);
};

const resetFilters = () => {
  search.value = '';
};

function getUserCommission(product) {
  if (!userGrade.value) return null;
  switch (userGrade.value.toUpperCase()) {
    case 'A': return product.commission_rate_a;
    case 'B': return product.commission_rate_b;
    case 'C': return product.commission_rate_c;
    default: return null;
  }
}

const formatCommissionRate = (rate) => {
  if (rate === null || typeof rate === 'undefined' || isNaN(rate)) {
    return '';
  }
  const percentage = parseFloat(rate) * 100;
  return `${Number(percentage.toFixed(1))}%`;
};

function downloadExcel() {
  // 1. 테이블 데이터 준비
  const exportData = products.value.map((item, idx) => ({
    '순번': idx + 1,
    '제약사': item.pharmacist,
    '제품명': item.product_name,
    '성분명': item.Ingredient,
    '약가': item.price,
    '수수료율': formatCommissionRate(getUserCommission(item)),
    '급여': item.reimbursement,
    '보험코드': item.insurance_code,
    '분류명': item.category,
    '대조약': item.reference_drug,
    '생동': item.bioequivalence,
    '자사/위탁': item.own_or_consign,
    '비고': item.note,
  }));

  // 2. 워크시트/워크북 생성
  const worksheet = XLSX.utils.json_to_sheet(exportData);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, '수수료율');

  // 3. 엑셀 파일로 변환 및 다운로드
  const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
  const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });
  saveAs(blob, '수수료율_다운로드.xlsx');
}

// 외부 클릭 시 드롭다운 닫기
const handleClickOutside = (event) => {
  if (activeDropdown.value && !event.target.closest('.product-name-wrapper') && !event.target.closest('.more-dropdown-box')) {
    activeDropdown.value = null;
    activeDropdownData.value = null;
  }
};

// 스크롤 시 드롭다운 닫기
const handleScroll = () => {
  if (activeDropdown.value) {
    activeDropdown.value = null;
    activeDropdownData.value = null;
  }
};

// 제품명 드롭다운 토글
const toggleProductDropdown = (productId, productData) => {
  if (activeDropdown.value === productId) {
    activeDropdown.value = null;
    activeDropdownData.value = null;
  } else {
    activeDropdown.value = productId;
    activeDropdownData.value = productData;
    
    // 드롭다운 위치 계산
    setTimeout(() => {
      const dropdownElement = document.querySelector(`.product-name-wrapper[data-product-id="${productId}"]`);
      if (dropdownElement) {
        const rect = dropdownElement.getBoundingClientRect();
        const dropdownHeight = 200; // 드롭다운 예상 높이
        const spaceBelow = window.innerHeight - rect.bottom;
        const spaceAbove = rect.top;
        
        // 아래쪽 공간이 부족하고 위쪽 공간이 충분하면 위로 표시
        const showAbove = spaceBelow < dropdownHeight + 10 && spaceAbove > dropdownHeight + 10;
        
        dropdownStyle.value = {
          position: 'fixed',
          top: showAbove ? `${rect.top - dropdownHeight - 5}px` : `${rect.bottom + 5}px`,
          left: `${rect.left}px`,
          zIndex: 10000
        };
      }
    }, 0);
  }
};

// 더보기 드롭다운 메뉴 액션들
const viewProductDetails = async (product) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  
  if (!product.insurance_code) {
    alert('보험코드 정보가 없습니다.');
    return;
  }
  
  try {
    // products_mfds 테이블에서 해당 보험코드의 상세 URL 조회
    const { data, error } = await supabase
      .from('products_mfds')
      .select('detail_url')
      .eq('insurance_code', product.insurance_code)
      .single();
    
    if (error) {
      console.error('Error fetching product details:', error);
      alert('제품 상세 정보를 찾을 수 없습니다.');
      return;
    }
    
    if (data && data.detail_url) {
      // 새 창에서 상세 정보 URL 열기
      window.open(data.detail_url, '_blank');
    } else {
      alert('해당 제품의 상세 정보가 등록되지 않았습니다.');
    }
  } catch (error) {
    console.error('Error:', error);
    alert('제품 상세 정보를 불러오는 중 오류가 발생했습니다.');
  }
};

const viewSimilarProducts = async (product) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  
  if (!product.insurance_code) {
    alert('보험코드 정보가 없습니다.');
    return;
  }
  
  try {
    // 1. 해당 제품의 성분코드 조회
    const { data: ingredientData, error: ingredientError } = await supabase
      .from('products_ingredient_code')
      .select('ingredient_code')
      .eq('insurance_code', product.insurance_code)
      .single();
    
    if (ingredientError) {
      console.error('Error fetching ingredient code:', ingredientError);
      alert('성분코드 정보를 찾을 수 없습니다.');
      return;
    }
    
    if (!ingredientData || !ingredientData.ingredient_code) {
      alert('해당 제품의 성분코드가 등록되지 않았습니다.');
      return;
    }
    
    // 성분코드가 있으면 모달 열기
    selectedProductForSimilar.value = product;
    showSimilarProductsModal.value = true;
    loadingSimilarProducts.value = true;
    similarProducts.value = [];
    
    // 2. 같은 성분코드를 가진 모든 보험코드 조회
    const { data: sameIngredientCodes, error: sameIngredientError } = await supabase
      .from('products_ingredient_code')
      .select('insurance_code')
      .eq('ingredient_code', ingredientData.ingredient_code);
    
    if (sameIngredientError) {
      console.error('Error fetching same ingredient codes:', sameIngredientError);
      alert('동일성분의약품 조회 중 오류가 발생했습니다.');
      loadingSimilarProducts.value = false;
      return;
    }
    
    if (!sameIngredientCodes || sameIngredientCodes.length === 0) {
      loadingSimilarProducts.value = false;
      return;
    }
    
    // 3. 현재 base_month의 products 테이블에서 해당 보험코드들 조회
    const insuranceCodes = sameIngredientCodes.map(item => item.insurance_code);
    
    const { data: similarProductsData, error: similarProductsError } = await supabase
      .from('products')
      .select('*')
      .eq('base_month', latestMonth)
      .eq('status', 'active')
      .in('insurance_code', insuranceCodes)
      .order('pharmacist', { ascending: true });
    
    if (similarProductsError) {
      console.error('Error fetching similar products:', similarProductsError);
      alert('동일성분의약품 조회 중 오류가 발생했습니다.');
      loadingSimilarProducts.value = false;
      return;
    }
    
    similarProducts.value = similarProductsData || [];
    
  } catch (error) {
    console.error('Error:', error);
    alert('동일성분의약품 조회 중 오류가 발생했습니다.');
  } finally {
    loadingSimilarProducts.value = false;
  }
};

// 동일성분의약품 모달 닫기
const closeSimilarProductsModal = () => {
  showSimilarProductsModal.value = false;
  selectedProductForSimilar.value = null;
  similarProducts.value = [];
  loadingSimilarProducts.value = false;
};

const requestFilter = async (product) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  
  try {
    // 제약사 목록 조회
    const { data: pharmaceuticalCompanies, error } = await supabase
      .from('pharmaceutical_companies')
      .select('*')
      .eq('filtering_status', 'active')
      .order('company_name');
    
    if (error) {
      console.error('제약사 데이터 조회 실패:', error);
      // 제약사 정보 없이 필터링 요청 페이지로 이동
      router.push('/filter/create');
      return;
    }
    
    // 제품의 pharmacist와 일치하는 제약사 찾기
    const matchedCompany = findMatchingCompany(product.pharmacist, pharmaceuticalCompanies);
    
    // 매칭 결과 로깅
    logMatchingResult(product.pharmacist, matchedCompany);
    
    // 필터링 요청 페이지로 이동 (제약사 정보가 있으면 쿼리 파라미터로 전달)
    if (matchedCompany) {
      router.push({
        path: '/filter/create',
        query: {
          company_id: matchedCompany.id,
          company_name: matchedCompany.company_name
        }
      });
    } else {
      // 매칭되는 제약사가 없으면 그냥 필터링 요청 페이지로 이동
      router.push('/filter/create');
    }
    
  } catch (error) {
    console.error('필터링 요청 처리 중 오류:', error);
    alert('필터링 요청 처리 중 오류가 발생했습니다.');
  }
};

const viewApprovedPharmaceuticals = (product) => {
  activeDropdown.value = null;
  activeDropdownData.value = null;
  // TODO: 승인 거래처 보기
  console.log('승인 거래처 보기:', product);
  alert('승인 거래처 보기 기능은 구현 예정입니다.');
};
</script>
