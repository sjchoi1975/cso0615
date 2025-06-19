<template>
  <div class="user-filter-create-view page-container">
    <div class="filter-card">
      <h2 class="modai-title">필터링 요청</h2>
      
      <!-- 필터링 구분 -->
      <div class="filter-row">
        <label class="form-label">구분</label>
        <div class="filter-row">
          <label class="checkbox-wrapper">
            <input 
              type="radio" 
              v-model="filterType" 
              value="new" 
              class="checkbox-input"
            />
            <span class="checkbox-label">신규</span>
          </label>
          <label class="checkbox-wrapper">
            <input 
              type="radio" 
              v-model="filterType" 
              value="transfer" 
              class="checkbox-input"
            />
            <span class="checkbox-label">이관</span>
          </label>
        </div>
      </div>

      <!-- 병원 선택 -->
      <div class="filter-row">
        <label class="form-label">병원</label>
        <div class="filter-row">
          <button 
            type="button" 
            class="btn-secondary" 
            :class="{ active: hospitalSelectionType === 'existing' }"
            @click="selectExistingHospital"
          >
            등록 병원
          </button>
          <button 
            type="button" 
            class="btn-secondary" 
            :class="{ active: hospitalSelectionType === 'new' }"
            @click="selectNewHospital"
          >
            신규 병원
          </button>
        </div>
      </div>

      <!-- 병원 정보 입력 -->
      <div v-if="hospitalSelectionType === 'new'" class="filter-row">
        <div class="input-group">
          <label class="form-label">병원명</label>
          <input 
            v-model="hospitalInfo.hospital_name" 
            type="text" 
            class="input" 
            placeholder="병원명을 입력하세요"
            required
          />
        </div>
        <div class="input-group">
          <label class="form-label">사업자등록번호</label>
          <input 
            v-model="hospitalInfo.business_registration_number" 
            type="text" 
            class="input" 
            placeholder="사업자등록번호를 입력하세요"
            required
          />
        </div>
        <div class="input-group">
          <label class="form-label">원장명</label>
          <input 
            v-model="hospitalInfo.director_name" 
            type="text" 
            class="input" 
            placeholder="원장명을 입력하세요"
            required
          />
        </div>
        <div class="input-group">
          <label class="form-label">주소</label>
          <input 
            v-model="hospitalInfo.address" 
            type="text" 
            class="input" 
            placeholder="주소를 입력하세요"
            required
          />
        </div>
      </div>

      <!-- 제약사 선택 -->
      <div class="filter-row">
        <label class="form-label">제약사</label>
        <div class="filter-row">
          <button 
            type="button" 
            class="btn-add" 
            @click="openPharmaModal"
          >
            추가
          </button>
          <span v-if="selectedPharmas.length > 0" style="margin-left: 1rem; color: var(--text-secondary);">
            ({{ selectedPharmas.length }}개 선택됨)
          </span>
        </div>
        <div v-if="selectedPharmas.length > 0" class="selected-pharmas">
          <div 
            v-for="pharma in selectedPharmas" 
            :key="pharma.id" 
            class="selected-pharma-item"
          >
            <span>{{ pharma.company_name }}</span>
            <button 
              type="button" 
              class="btn-delete-sm" 
              @click="removePharma(pharma.id)"
            >
              삭제
            </button>
          </div>
        </div>
      </div>

      <!-- 비고 -->
      <div class="filter-row">
        <label class="form-label">비고 (선택사항)</label>
        <textarea 
          v-model="userRemarks" 
          class="input" 
          placeholder="특이사항을 입력하세요"
          rows="4"
          style="resize: vertical;"
        ></textarea>
      </div>

      <!-- 버튼 -->
      <div class="filter-actions">
        <button 
          type="button" 
          class="btn-cancel" 
          @click="goBack"
        >
          취소
        </button>
        <button 
          type="button" 
          class="btn-save" 
          @click="submitRequest"
          :disabled="loading || !isFormValid"
        >
          {{ loading ? '요청 중...' : '등록' }}
        </button>
      </div>
    </div>

    <!-- 내 거래처 모달 -->
    <div v-if="showHospitalModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-footer">
          <h3 class="modai-title">내 거래처 선택</h3>
          <button class="btn-close-nobg" @click="closeHospitalModal">×</button>
        </div>
        <div class="modal-body">
          <div class="filter-row">
            <input 
              v-model="hospitalSearch" 
              type="text" 
              class="input-search" 
              placeholder="병원명으로 검색"
            />
          </div>
          <div style="max-height: 400px; overflow-y: auto;">
            <div 
              v-for="hospital in filteredHospitals" 
              :key="hospital.id" 
              class="filter-row"
              :class="{ 'active-badge': selectedHospital?.id === hospital.id }"
              @click="selectHospital(hospital)"
              style="cursor: pointer; padding: 0.75rem; border: 1px solid var(--border-primary); border-radius: var(--border-radius); margin-bottom: 0.5rem;"
            >
              <div style="font-weight: 500; margin-bottom: 0.25rem;">{{ hospital.hospital_name }}</div>
              <div style="font-size: var(--font-size-90); color: var(--text-secondary); margin-bottom: 0.25rem;">
                {{ hospital.director_name }} | {{ hospital.business_registration_number }}
              </div>
              <div style="font-size: var(--font-size-90); color: var(--text-light);">{{ hospital.address }}</div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeHospitalModal">취소</button>
          <button 
            class="btn-save" 
            @click="confirmHospitalSelection"
            :disabled="!selectedHospital"
          >
            선택
          </button>
        </div>
      </div>
    </div>

    <!-- 제약사 선택 모달 -->
    <div v-if="showPharmaModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-footer">
          <h3 class="modai-title">제약사 선택</h3>
          <button class="btn-close-nobg" @click="closePharmaModal">×</button>
        </div>
        <div class="modal-body">
          <div class="filter-row">
            <input 
              v-model="pharmaSearch" 
              type="text" 
              class="input-search" 
              placeholder="제약사명으로 검색"
            />
          </div>
          <div style="max-height: 400px; overflow-y: auto;">
            <div 
              v-for="pharma in filteredPharmas" 
              :key="pharma.id" 
              class="filter-row"
              :class="{ 'active-badge': isPharmaSelected(pharma.id) }"
              @click="togglePharmaSelection(pharma)"
              style="cursor: pointer; padding: 0.75rem; border: 1px solid var(--border-primary); border-radius: var(--border-radius); margin-bottom: 0.5rem; display: flex; justify-content: space-between; align-items: center;"
            >
              <span style="font-weight: 500;">{{ pharma.company_name }}</span>
              <span v-if="isPharmaSelected(pharma.id)" style="color: var(--success); font-weight: bold;">✓</span>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closePharmaModal">취소</button>
          <button class="btn-save" @click="confirmPharmaSelection">
            선택 완료 ({{ selectedPharmas.length }}개)
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const router = useRouter();

// 폼 데이터
const filterType = ref('new');
const hospitalSelectionType = ref('existing');
const hospitalInfo = ref({
  hospital_name: '',
  business_registration_number: '',
  director_name: '',
  address: ''
});
const selectedPharmas = ref([]);
const userRemarks = ref('');

// 모달 상태
const showHospitalModal = ref(false);
const showPharmaModal = ref(false);

// 검색어
const hospitalSearch = ref('');
const pharmaSearch = ref('');

// 데이터
const myHospitals = ref([]);
const allPharmas = ref([]);
const selectedHospital = ref(null);

// 로딩 상태
const loading = ref(false);

// 현재 사용자 정보
const currentUser = ref(null);

// 폼 유효성 검사
const isFormValid = computed(() => {
  return filterType.value && 
         hospitalInfo.value.hospital_name && 
         hospitalInfo.value.business_registration_number && 
         hospitalInfo.value.director_name && 
         hospitalInfo.value.address && 
         selectedPharmas.value.length > 0;
});

// 현재 사용자 정보 가져오기
const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    currentUser.value = user;
  }
};

// 내 거래처 목록 가져오기
const fetchMyHospitals = async () => {
  if (!currentUser.value) return;
  
  const { data, error } = await supabase
    .from('hospital_member_mappings')
    .select(`
      hospital_id,
      hospitals (
        id,
        hospital_name,
        business_registration_number,
        director_name,
        address
      )
    `)
    .eq('member_id', currentUser.value.id);
  
  if (!error && data) {
    myHospitals.value = data.map(item => item.hospitals);
  }
};

// 제약사 목록 가져오기
const fetchPharmas = async () => {
  const { data, error } = await supabase
    .from('pharmaceutical_companies')
    .select('*')
    .order('company_name');
  
  if (!error && data) {
    allPharmas.value = data;
  }
};

// 필터링된 병원 목록
const filteredHospitals = computed(() => {
  if (!hospitalSearch.value) return myHospitals.value;
  return myHospitals.value.filter(hospital => 
    hospital.hospital_name.toLowerCase().includes(hospitalSearch.value.toLowerCase())
  );
});

// 필터링된 제약사 목록
const filteredPharmas = computed(() => {
  if (!pharmaSearch.value) return allPharmas.value;
  return allPharmas.value.filter(pharma => 
    pharma.company_name.toLowerCase().includes(pharmaSearch.value.toLowerCase())
  );
});

// 병원 선택 타입 변경
const selectExistingHospital = () => {
  hospitalSelectionType.value = 'existing';
  clearHospitalInfo();
  openHospitalModal();
};

const selectNewHospital = () => {
  hospitalSelectionType.value = 'new';
  clearHospitalInfo();
};

// 병원 정보 초기화
const clearHospitalInfo = () => {
  hospitalInfo.value = {
    hospital_name: '',
    business_registration_number: '',
    director_name: '',
    address: ''
  };
  selectedHospital.value = null;
};

// 모달 열기/닫기
const openHospitalModal = () => {
  showHospitalModal.value = true;
  hospitalSearch.value = '';
};

const closeHospitalModal = () => {
  showHospitalModal.value = false;
  selectedHospital.value = null;
};

const openPharmaModal = () => {
  showPharmaModal.value = true;
  pharmaSearch.value = '';
};

const closePharmaModal = () => {
  showPharmaModal.value = false;
};

// 병원 선택
const selectHospital = (hospital) => {
  selectedHospital.value = hospital;
};

const confirmHospitalSelection = () => {
  if (selectedHospital.value) {
    hospitalInfo.value = {
      hospital_name: selectedHospital.value.hospital_name,
      business_registration_number: selectedHospital.value.business_registration_number,
      director_name: selectedHospital.value.director_name,
      address: selectedHospital.value.address
    };
  }
  closeHospitalModal();
};

// 제약사 선택
const isPharmaSelected = (pharmaId) => {
  return selectedPharmas.value.some(pharma => pharma.id === pharmaId);
};

const togglePharmaSelection = (pharma) => {
  const index = selectedPharmas.value.findIndex(p => p.id === pharma.id);
  if (index > -1) {
    selectedPharmas.value.splice(index, 1);
  } else {
    selectedPharmas.value.push(pharma);
  }
};

const removePharma = (pharmaId) => {
  selectedPharmas.value = selectedPharmas.value.filter(p => p.id !== pharmaId);
};

const confirmPharmaSelection = () => {
  closePharmaModal();
};

// 요청 제출
const submitRequest = async () => {
  if (!isFormValid.value) {
    alert('필수 항목을 모두 입력해주세요.');
    return;
  }

  loading.value = true;
  
  try {
    // 1. 병원 정보 확인/생성
    let hospitalId;
    const { data: existingHospital } = await supabase
      .from('hospitals')
      .select('id')
      .eq('business_registration_number', hospitalInfo.value.business_registration_number)
      .single();

    if (existingHospital) {
      hospitalId = existingHospital.id;
    } else {
      // 신규 병원 등록
      const { data: newHospital, error: hospitalError } = await supabase
        .from('hospitals')
        .insert([hospitalInfo.value])
        .select('id')
        .single();
      
      if (hospitalError) throw hospitalError;
      hospitalId = newHospital.id;
    }

    // 2. 병원-회원 매칭 등록 (중복 방지)
    const { error: mappingError } = await supabase
      .from('hospital_member_mappings')
      .upsert([{
        hospital_id: hospitalId,
        member_id: currentUser.value.id
      }], { onConflict: 'hospital_id,member_id' });
    
    if (mappingError) throw mappingError;

    // 3. 필터링 요청 등록
    const requests = selectedPharmas.value.map(pharma => ({
      member_id: currentUser.value.id,
      hospital_id: hospitalId,
      pharmaceutical_company_id: pharma.id,
      filter_type: filterType.value,
      user_remarks: userRemarks.value
    }));

    const { error: requestError } = await supabase
      .from('filtering_requests')
      .insert(requests);
    
    if (requestError) throw requestError;

    alert('필터링 요청이 성공적으로 제출되었습니다.');
    router.push('/filter/list');
    
  } catch (error) {
    console.error('요청 제출 실패:', error);
    alert('요청 제출에 실패했습니다: ' + error.message);
  } finally {
    loading.value = false;
  }
};

// 뒤로가기
const goBack = () => {
  router.push('/filter/list');
};

onMounted(async () => {
  await getCurrentUser();
  await fetchMyHospitals();
  await fetchPharmas();
});
</script>

<style scoped>
.user-filter-create-view {
  padding: 2rem;
}

.filter-card {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  max-width: 800px;
  margin: 0 auto;
}

.modai-title {
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 2rem;
  color: #333;
}

.filter-row {
  margin-bottom: 1.5rem;
}

.form-label {
  display: block;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: #333;
}

.checkbox-wrapper {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.checkbox-input {
  width: 16px;
  height: 16px;
}

.checkbox-label {
  font-size: 0.9rem;
}

.input-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
}

.input {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
}

.input:disabled {
  background: #f5f5f5;
  color: #666;
}

.textarea-field {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
  resize: vertical;
}

.btn-add {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-add:hover {
  background: #0056b3;
}

.selected-pharmas {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.selected-pharma-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.25rem 0.5rem;
  background: #e3f2fd;
  border: 1px solid #2196f3;
  border-radius: 4px;
  font-size: 0.9rem;
}

.btn-delete-sm {
  background: none;
  border: none;
  color: #f44336;
  cursor: pointer;
  font-size: 1.2rem;
  padding: 0;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.filter-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid #eee;
}

.btn-cancel {
  padding: 0.5rem 1rem;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-save {
  padding: 0.5rem 1rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-save:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

/* 모달 스타일 */
.custom-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.custom-modal {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 600px;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #eee;
}

.modal-title {
  font-size: 1.2rem;
  font-weight: 600;
  margin: 0;
}

.btn-close-nobg {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
}

.modal-body {
  padding: 1rem;
  overflow-y: auto;
  flex: 1;
}

.search-box {
  margin-bottom: 1rem;
}

.hospital-list,
.pharma-list {
  max-height: 400px;
  overflow-y: auto;
}

.hospital-item,
.pharma-item {
  padding: 0.75rem;
  border: 1px solid #eee;
  border-radius: 4px;
  margin-bottom: 0.5rem;
  cursor: pointer;
  transition: all 0.2s;
}

.hospital-item:hover,
.pharma-item:hover {
  background: #f8f9fa;
}

.hospital-item.selected,
.pharma-item.selected {
  background: #e3f2fd;
  border-color: #2196f3;
}

.hospital-name {
  font-weight: 500;
  margin-bottom: 0.25rem;
}

.hospital-info {
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 0.25rem;
}

.hospital-address {
  font-size: 0.8rem;
  color: #999;
}

.pharma-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pharma-name {
  font-weight: 500;
}

.pharma-check {
  color: #28a745;
  font-weight: bold;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  padding: 1rem;
  border-top: 1px solid #eee;
}

@media (max-width: 768px) {
  .input-row {
    grid-template-columns: 1fr;
  }
  
  .filter-row {
    flex-direction: column;
  }
  
  .filter-actions {
    flex-direction: column;
  }
}
</style>
