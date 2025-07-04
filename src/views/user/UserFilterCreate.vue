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
              <div class="selection-filter-type">
                <label class="radio-inline"><input type="radio" v-model="filterType" value="new" /> 신규</label>
                <label class="radio-inline"><input type="radio" v-model="filterType" value="transfer" /> 이관</label>
              </div>
            </td>
          </tr>

          <!-- 거래처 선택 -->
          <tr>
            <th>거래처 선택</th>
            <td>
              <div class="selection-hoapital">
                <label class="radio-inline"><input type="radio" v-model="hospitalSelectionType" value="existing" /> 내 거래처</label>
                <label class="radio-inline"><input type="radio" v-model="hospitalSelectionType" value="new" /> 신규 거래처</label>
              </div>
              <div>
                <button v-if="hospitalSelectionType === 'existing'" type="button" class="btn-add-sm" 
                @click="openHospitalModal" style="margin-left: 1.6rem; margin-top: 0.5rem;">거래처 선택</button>
              </div>
            </td>
          </tr>
          <tr>
            <th>거래처명</th>
            <td><input v-model="hospitalInfo.hospital_name" type="text" class="input-table" placeholder="거래처명" :disabled="hospitalSelectionType === 'existing'" /></td>
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
              <button type="button" class="btn-add-sm" @click="openPharmaModal">제약사 선택</button>
              <div v-if="selectedPharmas.length > 0" class="selected-pharmas-list">
                <div v-for="pharma in selectedPharmas" :key="pharma.id" class="selected-pharma-item">
                  <span>{{ pharma.company_name }}</span>
                </div>
              </div>
            </td>
          </tr>

          <!-- 메모 -->
          <tr>
            <th>메모</th>
            <td>
              <textarea v-model="userRemarks" class="input-table" placeholder="요청 메모를 입력해 주세요." rows="5"></textarea>
            </td>
          </tr>
        </tbody>
      </table>
      <div class="form-actions-table">
        <button type="button" class="btn-cancel" @click="goBack" style="flex:1;">취소</button>
        <button type="button" class="btn-confirm" @click="submitRequest" :disabled="loading || !isFormValid" style="flex:2;">{{ loading ? '요청 중...' : '등록' }}</button>
      </div>
    </div>
    
    <!-- 공용 선택 모달 -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal custom-modal-pharma">
        <div class="modal-header">
          <h3 class="modal-title">{{ modalTitle }}</h3>
        </div>
        <div class="modal-body">
          <!--
          <div class="search-box">
            <input v-model="modalSearch"
              type="text"
              class="input-search-filter"
              :placeholder="modalSearchPlaceholder" />
          </div>
          -->
          <div class="selection-list-container">
            <!-- 거래처 목록 -->
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
              <div v-for="pharma in activeSortedCompanies" :key="pharma.id" 
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
          <button class="btn-cancel" @click="closeModal" style="flex:1;">취소</button>
          <button class="btn-confirm" @click="confirmSelection" style="flex:2;">선택</button>
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
const hospitalSelectionType = ref('existing'); // '내 거래처'을 기본값으로
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
  modalTitle.value = '거래처 선택';
  modalSearchPlaceholder.value = '거래처명으로 검색';
  tempSelectedHospital.value = hospitalInfo.value.id ? { ...hospitalInfo.value } : null;
  showModal.value = true;
};

const openPharmaModal = () => {
  modalType.value = 'pharma';
  modalTitle.value = '제약사 선택';
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

// 사업자등록번호 자동 하이픈 추가
watch(() => hospitalInfo.value.business_registration_number, (newValue) => {
  // 숫자 이외의 문자를 모두 제거
  const digits = (newValue || '').replace(/\D/g, '');
  
  // 길이에 따라 하이픈 추가
  let formatted = '';
  if (digits.length > 0) {
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 5) {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3)}`;
    } else {
      // 10자리까지만 입력받음
      formatted = `${digits.slice(0, 3)}-${digits.slice(3, 5)}-${digits.slice(5, 10)}`;
    }
  }
  
  // 값이 변경되었을 때만 업데이트하여 무한 루프 방지
  if (formatted !== hospitalInfo.value.business_registration_number) {
    hospitalInfo.value.business_registration_number = formatted;
  }
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

const activeSortedCompanies = computed(() => {
  return allPharmas.value
    .filter(c => c.status === 'active')
    .sort((a, b) => a.company_name.localeCompare(b.company_name, 'ko'));
});

console.log(activeSortedCompanies.value);
</script>
