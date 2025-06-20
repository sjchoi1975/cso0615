<template>
  <div class="user-filter-create-view page-container">
    <div class="filter-table-card">
      <table class="filter-table">
        <colgroup>
          <col style="width: 140px;">
          <col>
        </colgroup>
        <tbody>
          <!-- 구분 -->
          <tr>
            <th>구분</th>
            <td>
              <label class="radio-inline"><input type="radio" v-model="filterType" value="new" /> 신규</label>
              <label class="radio-inline"><input type="radio" v-model="filterType" value="transfer" /> 이관</label>
            </td>
          </tr>

          <!-- 병원 선택 -->
          <tr>
            <th>병원 선택</th>
            <td>
              <div class="selection-group">
                <label class="radio-inline"><input type="radio" v-model="hospitalSelectionType" value="existing" /> 내 병원</label>
                <label class="radio-inline"><input type="radio" v-model="hospitalSelectionType" value="new" /> 신규 병원</label>
                <button v-if="hospitalSelectionType === 'existing'" type="button" class="btn-add" @click="openHospitalModal" style="margin-left: 1rem;">병원 선택</button>
              </div>
            </td>
          </tr>
          <tr>
            <th>병원명</th>
            <td><input v-model="hospitalInfo.hospital_name" type="text" class="input-table" placeholder="병원명" :disabled="hospitalSelectionType === 'existing'" /></td>
          </tr>
          <tr>
            <th>사업자등록번호</th>
            <td><input v-model="hospitalInfo.business_registration_number" type="text" class="input-table" placeholder="사업자등록번호" :disabled="hospitalSelectionType === 'existing'" /></td>
          </tr>
           <tr>
            <th>원장명</th>
            <td><input v-model="hospitalInfo.director_name" type="text" class="input-table" placeholder="원장명" :disabled="hospitalSelectionType === 'existing'" /></td>
          </tr>
          <tr>
            <th>주소</th>
            <td><input v-model="hospitalInfo.address" type="text" class="input-table" placeholder="주소" :disabled="hospitalSelectionType === 'existing'" /></td>
          </tr>

          <!-- 제약사 선택 -->
          <tr>
            <th>제약사 선택</th>
            <td>
              <button type="button" class="btn-add" @click="openPharmaModal">제약사 추가</button>
              <div v-if="selectedPharmas.length > 0" class="selected-pharmas-list">
                <div v-for="pharma in selectedPharmas" :key="pharma.id" class="selected-pharma-item">
                  <span>{{ pharma.company_name }}</span>
                  <button type="button" class="btn-remove-badge" @click="removePharma(pharma.id)">×</button>
                </div>
              </div>
            </td>
          </tr>

          <!-- 메모 -->
          <tr>
            <th>메모</th>
            <td>
              <textarea v-model="userRemarks" class="input-table" placeholder="요청 메모를 입력해 주세요." rows="3"></textarea>
            </td>
          </tr>
        </tbody>
      </table>
      <div class="form-actions-table">
        <button type="button" class="btn-cancel" @click="goBack">취소</button>
        <button type="button" class="btn-save" @click="submitRequest" :disabled="loading || !isFormValid">{{ loading ? '요청 중...' : '등록' }}</button>
      </div>
    </div>

    <!-- 공용 선택 모달 -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">{{ modalTitle }}</h3>
          <button class="btn-close-nobg" @click="closeModal">×</button>
        </div>
        <div class="modal-body">
          <div class="search-box">
            <input v-model="modalSearch" type="text" class="input-search" :placeholder="modalSearchPlaceholder" />
          </div>
          <div class="selection-list-container">
            <!-- 병원 목록 -->
            <template v-if="modalType === 'hospital'">
              <div v-for="hospital in filteredModalItems" :key="hospital.id" 
                   class="hospital-item" 
                   :class="{ selected: tempSelectedHospital?.id === hospital.id }" 
                   @click="selectHospital(hospital)">
                <div class="hospital-name">{{ hospital.hospital_name }}</div>
                <div class="hospital-info">{{ hospital.director_name }} | {{ hospital.business_registration_number }}</div>
              </div>
            </template>
            <!-- 제약사 목록 -->
            <template v-if="modalType === 'pharma'">
              <div v-for="pharma in filteredModalItems" :key="pharma.id" 
                   class="pharma-modal-item" 
                   :class="{ selected: isPharmaSelectedInModal(pharma.id) }" 
                   @click="togglePharmaSelection(pharma)">
                <span class="pharma-name">{{ pharma.company_name }}</span>
                <span v-if="isPharmaSelectedInModal(pharma.id)" class="check-icon">✓</span>
              </div>
            </template>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="closeModal">취소</button>
          <button class="btn-save" @click="confirmSelection">선택</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const router = useRouter();

// 폼 데이터
const filterType = ref('new');
const hospitalSelectionType = ref('existing'); // '내 병원'을 기본값으로
const hospitalInfo = ref({
  id: null,
  hospital_name: '',
  business_registration_number: '',
  director_name: '',
  address: ''
});
const selectedPharmas = ref([]);
const userRemarks = ref('');

// 모달 관련 상태
const showModal = ref(false);
const modalType = ref(''); // 'hospital' 또는 'pharma'
const modalTitle = ref('');
const modalSearch = ref('');
const modalSearchPlaceholder = ref('');
const tempSelectedHospital = ref(null);
const tempSelectedPharmas = ref([]);

// 데이터
const myHospitals = ref([]);
const allPharmas = ref([]);

const loading = ref(false);
const currentUser = ref(null);

// 폼 유효성 검사
const isFormValid = computed(() => {
  const hasValidHospital = hospitalSelectionType.value === 'existing' 
    ? !!hospitalInfo.value.id
    : hospitalInfo.value.hospital_name &&
      hospitalInfo.value.business_registration_number &&
      hospitalInfo.value.director_name &&
      hospitalInfo.value.address;
  return filterType.value && hasValidHospital && selectedPharmas.value.length > 0;
});

// 모달 내 필터링된 아이템
const filteredModalItems = computed(() => {
  if (modalType.value === 'hospital') {
    if (!modalSearch.value) return myHospitals.value;
    return myHospitals.value.filter(h => h.hospital_name.toLowerCase().includes(modalSearch.value.toLowerCase()));
  }
  if (modalType.value === 'pharma') {
    if (!modalSearch.value) return allPharmas.value;
    return allPharmas.value.filter(p => p.company_name.toLowerCase().includes(modalSearch.value.toLowerCase()));
  }
  return [];
});

// 모달 열기
const openHospitalModal = () => {
  modalType.value = 'hospital';
  modalTitle.value = '내 병원 선택';
  modalSearchPlaceholder.value = '병원명으로 검색';
  tempSelectedHospital.value = hospitalInfo.value.id ? { ...hospitalInfo.value } : null;
  showModal.value = true;
};

const openPharmaModal = () => {
  modalType.value = 'pharma';
  modalTitle.value = '제약사 추가';
  modalSearchPlaceholder.value = '제약사명으로 검색';
  tempSelectedPharmas.value = [...selectedPharmas.value];
  showModal.value = true;
};

// 모달 닫기
const closeModal = () => {
  showModal.value = false;
  modalSearch.value = '';
};

// 모달 내 선택 로직
const selectHospital = (hospital) => {
  tempSelectedHospital.value = hospital;
};

const isPharmaSelectedInModal = (pharmaId) => {
  return tempSelectedPharmas.value.some(p => p.id === pharmaId);
};

const togglePharmaSelection = (pharma) => {
  const index = tempSelectedPharmas.value.findIndex(p => p.id === pharma.id);
  if (index > -1) {
    tempSelectedPharmas.value.splice(index, 1);
  } else {
    tempSelectedPharmas.value.push(pharma);
  }
};

// 모달 선택 완료
const confirmSelection = () => {
  if (modalType.value === 'hospital' && tempSelectedHospital.value) {
    hospitalInfo.value = { ...tempSelectedHospital.value };
  }
  if (modalType.value === 'pharma') {
    selectedPharmas.value = [...tempSelectedPharmas.value];
  }
  closeModal();
};


const removePharma = (pharmaId) => {
  selectedPharmas.value = selectedPharmas.value.filter(p => p.id !== pharmaId);
};

watch(hospitalSelectionType, (type) => {
  hospitalInfo.value = { id: null, hospital_name: '', business_registration_number: '', director_name: '', address: '' };
});

// --- 기존 로직 (fetch, submit 등) ---
const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (user) currentUser.value = user;
};

const fetchMyHospitals = async () => {
  if (!currentUser.value) return;
  const { data, error } = await supabase
    .from('hospital_member_mappings')
    .select('hospitals(*)')
    .eq('member_id', currentUser.value.id);
  if (!error) myHospitals.value = data.map(item => item.hospitals).filter(Boolean);
};

const fetchPharmas = async () => {
  const { data, error } = await supabase.from('pharmaceutical_companies').select('*').order('company_name');
  if (!error) allPharmas.value = data;
};

const submitRequest = async () => {
  if (!isFormValid.value) {
    alert('필수 항목을 모두 입력해주세요.');
    return;
  }
  loading.value = true;
  try {
    let hospitalId;
    if (hospitalSelectionType.value === 'existing') {
      hospitalId = hospitalInfo.value.id;
    } else {
      const { data: existing } = await supabase.from('hospitals').select('id').eq('business_registration_number', hospitalInfo.value.business_registration_number).single();
      if (existing) {
        hospitalId = existing.id;
      } else {
        const { data: newHospital, error } = await supabase.from('hospitals').insert([{
          hospital_name: hospitalInfo.value.hospital_name,
          business_registration_number: hospitalInfo.value.business_registration_number,
          director_name: hospitalInfo.value.director_name,
          address: hospitalInfo.value.address,
        }]).select('id').single();
        if (error) throw error;
        hospitalId = newHospital.id;
      }
      await supabase.from('hospital_member_mappings').upsert([{ hospital_id: hospitalId, member_id: currentUser.value.id }], { onConflict: 'hospital_id,member_id' });
    }
    const requests = selectedPharmas.value.map(pharma => ({
      member_id: currentUser.value.id,
      hospital_id: hospitalId,
      pharmaceutical_company_id: pharma.id,
      filter_type: filterType.value,
      user_remarks: userRemarks.value,
      status: 'pending',
    }));
    const { error } = await supabase.from('filtering_requests').insert(requests);
    if (error) throw error;
    alert('필터링 요청이 성공적으로 제출되었습니다.');
    router.push('/filter/list');
  } catch (error) {
    console.error('요청 제출 실패:', error);
    alert('요청 제출에 실패했습니다: ' + error.message);
  } finally {
    loading.value = false;
  }
};

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
.filter-table-card {
  background: #fff;
  border-radius: 8px;
  border: 1px solid #d1d5db;
  padding: 0;
  max-width: 900px;
  margin: 0 auto;
}
.filter-table {
  width: 100%;
  border-collapse: collapse;
}
.filter-table th, .filter-table td {
  border: 1px solid #e5e7eb;
  padding: 0.75rem;
  text-align: left;
  vertical-align: top;
}
.filter-table th {
  background: #f1f3f5;
  font-weight: 500;
  color: #333;
  width: 140px;
}
.input-table, .input-search {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}
.selection-group {
  display: flex;
  align-items: center;
}

.selected-pharmas-list {
  margin-top: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.selected-pharma-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #f8f9fa;
  border: 1px solid #e9ecef;
  padding: 0.5rem 0.75rem;
  border-radius: 4px;
}

.pharma-badge {
  display: inline-flex;
  align-items: center;
  background: #e3f2fd;
  color: #1976d2;
  border-radius: 12px;
  padding: 0.25rem 0.75rem;
  font-size: 0.95rem;
}
.btn-remove-badge {
  background: none;
  border: none;
  color: #fa5252;
  font-size: 1.2rem;
  font-weight: bold;
  cursor: pointer;
  padding: 0;
  line-height: 1;
}
.form-actions-table {
  display: flex; justify-content: flex-end; gap: 1rem;
  padding: 1.5rem 1rem; border-top: 1px solid #e5e7eb;
}
.btn-cancel, .btn-save, .btn-add, .btn-change {
  padding: 0.5rem 1.5rem; border: none; border-radius: 4px;
  font-size: 1rem; cursor: pointer; color: white;
}
.btn-cancel { background: #b0b0b0; }
.btn-save { background: #22c55e; }
.btn-add { background: #1976d2; }
.btn-change { background: #f59e0b; padding: 0.25rem 0.75rem; font-size: 0.9rem; }
.btn-save:disabled { background: #b0b0b0; cursor: not-allowed; }

/* 인라인 선택 목록 스타일 */
.selection-list-container {
  max-height: 250px;
  overflow-y: auto;
  border: 1px solid #e5e7eb;
  border-radius: 4px;
  margin-top: 0.5rem;
}
.hospital-item, .pharma-modal-item {
  padding: 0.75rem;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
  transition: background-color 0.2s;
}
.hospital-item:hover, .pharma-modal-item:hover { background-color: #f8f9fa; }
.hospital-item:last-child, .pharma-modal-item:last-child { border-bottom: none; }

.hospital-name { font-weight: 600; }
.hospital-info, .hospital-address { font-size: 0.9rem; color: #666; }

.pharma-modal-item { display: flex; justify-content: space-between; align-items: center; }
.pharma-modal-item.selected { background-color: #e3f2fd; }
.check-icon { color: #1976d2; font-weight: bold; }
.no-data { padding: 1rem; text-align: center; color: #888; }
.selected-item-display { margin-top: 0.5rem; }
</style>
