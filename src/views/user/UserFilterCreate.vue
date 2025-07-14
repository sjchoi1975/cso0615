<template>
  <div class="board">
    <form class="board-form" @submit.prevent="submitRequest">
      <div class="form-grid-2x">
        <!-- 구분 -->
        <div class="form-group-2x">
          <label class="txt-110-222">구분<span class="required">*</span></label>
          <div class="selection-filter-type">
            <label class="radio-inline"><input type="radio" v-model="filterType" value="new" /> 신규</label>
            <label class="radio-inline"><input type="radio" v-model="filterType" value="transfer" /> 이관</label>
          </div>
        </div>
        <!-- 거래처 선택 구역 -->
        <div class="form-group-2x">
          <label class="txt-110-222">거래처 선택<span class="required">*</span></label>
          <div style="display: flex; gap: 1.5rem; margin-bottom: 0.5rem;">
            <label class="radio-inline"><input type="radio" v-model="hospitalSelectionType" value="existing" /> 등록 거래처</label>
            <label class="radio-inline"><input type="radio" v-model="hospitalSelectionType" value="new" /> 신규 거래처</label>
          </div>
          <!-- 거래처 선택 버튼 (등록 거래처 선택 시만 노출) -->
          <div v-if="hospitalSelectionType === 'existing' && !hospitalInfo.hospital_name">
            <button type="button" class="btn-select-wide" @click="openHospitalModal"
              style="width: 100%; margin-bottom: 0.25rem;">거래처 선택
            </button>
          </div>
          <!-- 거래처 변경 버튼 (거래처가 이미 선택된 경우) -->
          <div v-if="hospitalSelectionType === 'existing' && hospitalInfo.hospital_name">
            <button type="button" class="btn-select-wide" @click="openHospitalModal"
              style="width: 100%; margin-bottom: 0.25rem;">거래처 변경
            </button>
          </div>
          <!-- 등록 거래처 정보 표시 (선택된 경우) -->
          <div v-if="hospitalSelectionType === 'existing' && (hospitalInfo.id || hospitalInfo.hospital_name)" 
            style="margin-left: 1rem;">
            <div class="txt-120-222">
              {{ hospitalInfo.hospital_name }}
            </div>
            <div class="txt-100-666">
              {{ hospitalInfo.address }}
            </div>
            <div class="txt-100-666">
              {{ hospitalInfo.director_name }} | {{ hospitalInfo.business_registration_number }}
            </div>
          </div>
        </div>
        <!-- 신규 거래처 입력 폼 -->
        <template v-if="hospitalSelectionType === 'new'">
          <div class="form-grid">
            <div class="form-group">
              <label>거래처명<span class="required">*</span></label>
              <input v-model="hospitalInfo.hospital_name" type="text" class="input" placeholder="" required />
            </div>
            <div class="form-group">
              <label>사업자등록번호<span class="required">*</span></label>
              <input v-model="hospitalInfo.business_registration_number" type="text" class="input" placeholder="- (하이픈) 없이 숫자만 입력" required />
            </div>
            <div class="form-group">
              <label>원장명<span class="required">*</span></label>
              <input v-model="hospitalInfo.director_name" type="text" class="input" placeholder="" required />
            </div>
            <div class="form-group">
              <label>주소<span class="required">*</span></label>
              <input v-model="hospitalInfo.address" type="text" class="input" placeholder="" required />
            </div>
            <div class="form-group">
              <label>전화번호</label>
              <input v-model="hospitalInfo.telephone" type="text" class="input" placeholder="- (하이픈) 없이 숫자만 입력" />
            </div>
            <div class="form-group">
              <label>휴대폰번호</label>
              <input v-model="hospitalInfo.handphone" type="text" class="input" placeholder="- (하이픈) 없이 숫자만 입력" />
            </div>
            <div class="form-group">
              <label>사업자등록증</label>
              <input type="file" @change="onFileChange" class="input" />
            </div>
          </div>
        </template>
        <!-- 제약사 선택 -->
        <div class="form-group-2x">
          <label class="txt-110-222">제약사 선택<span class="required">*</span></label>
          <button type="button" class="btn-select-wide" @click="openPharmaModal" style="margin-bottom: 0.5rem;">제약사 선택</button>
          <div v-if="selectedPharmas.length > 0" class="selected-pharmas-list">
            <div v-for="pharma in selectedPharmas"
              :key="pharma.id"
              class="selected-pharma-item"
              style="display: flex; align-items: center; justify-content: space-between; gap: 0.5rem;">
              <span>{{ pharma.company_name }}</span>
              <button type="button" @click="removePharma(pharma.id)" style="background: none; border: none; cursor: pointer; padding: 0; margin-left: 0.5rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#dc3545" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
              </button>
            </div>
          </div>
        </div>
        <!-- 메모 -->
        <div class="form-group-2x">
          <label class="txt-110-222">메모</label>
          <textarea v-model="userRemarks" class="input" placeholder="요청 메모를 입력해 주세요." rows="5"></textarea>
        </div>
      </div>
      <div class="btn-row">
        <button type="button" class="btn-cancel" @click="goBack" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :disabled="loading || !isFormValid" style="flex:3;">
          {{ loading ? '요청 중...' : '등록' }}
        </button>
      </div>
    </form>

    <!-- 공용 선택 모달 -->
    <div v-if="showModal" class="custom-modal-overlay">
      <div class="custom-modal-filtering">
        <div class="modal-header">
          <h3 class="modal-title">{{ modalTitle }}</h3>
          <input v-model="modalSearch" class="input" :placeholder="modalSearchPlaceholder" style="margin-top:0.75rem; margin-bottom:0.25rem;" />
        </div>
        <div class="modal-body">
          <div class="selection-list-container">
            <!-- 거래처 목록 -->
            <template v-if="modalType === 'hospital'">
              <div v-for="hospital in sortedHospitals" :key="hospital.id" 
                   class="hospital-item" 
                   :class="{ selected: tempSelectedHospital?.id === hospital.id }" 
                   @click="selectHospital(hospital)"
                   style="display: flex; align-items: center; justify-content: space-between; cursor: pointer;">
                <div>
                  <div class="hospital-name">{{ hospital.hospital_name }}</div>
                  <div class="hospital-info">{{ hospital.address }}</div>
                  <div class="hospital-info">{{ hospital.director_name }} | {{ hospital.business_registration_number }}</div>
                </div>
                <span v-if="tempSelectedHospital?.id === hospital.id" class="check-icon" style="font-size: 1.2em; color: #1976d2; margin-left: 8px;">✓</span>
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
          <button
            class="btn-cancel" 
            @click="closeModal" 
            style="flex:1;">
            취소
          </button>
          <button 
            class="btn-confirm" 
            @click="confirmSelection" 
            style="flex:3;">
            선택
          </button>
        </div>
      </div>
    </div>

    <!-- 전달사항 모달 -->
    <div v-if="showCommentDialog" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">전달사항 확인</h3>
        </div>
        <div class="modal-body">
          <div class="comment-content">
            <template v-for="(pharma, index) in tempSelectedPharmas.filter(p => p.filtering_comment)" :key="pharma.id">
              <p class="pharma-name">[{{ pharma.company_name }}]</p>
              <p class="comment-text">{{ pharma.filtering_comment }}</p>
              <div v-if="index < tempSelectedPharmas.filter(p => p.filtering_comment).length - 1" class="comment-divider"></div>
            </template>
          </div>
        </div>
        <div class="modal-footer">
          <button
            class="btn-cancel" 
            @click="confirmCommentDialog" 
            style="flex:1;">
            확인
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { supabase } from '@/supabase';
import { v4 as uuidv4 } from 'uuid';

const router = useRouter();
const route = useRoute();

// 폼 데이터
const filterType = ref('new');
const hospitalSelectionType = ref('existing'); // '내 거래처'을 기본값으로
const hospitalInfo = ref({
  id: null,
  hospital_name: '',
  business_registration_number: '',
  director_name: '',
  address: '',
  telephone: '',
  handphone: ''
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

const licenseFile = ref(null);

const showCommentDialog = ref(false);
const commentDialogContent = ref('');

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
    let filtered = allPharmas.value;
    if (modalSearch.value) {
      filtered = filtered.filter(p => p.company_name.toLowerCase().includes(modalSearch.value.toLowerCase()));
    }
    // 한글 가나다순 정렬
    return filtered.sort((a, b) => a.company_name.localeCompare(b.company_name, 'ko-KR'));
  }
  return [];
});

const sortedHospitals = computed(() => {
  return [...filteredModalItems.value].sort((a, b) => (a.hospital_name || '').localeCompare(b.hospital_name || '', 'ko'));
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
    closeModal();
  }
  if (modalType.value === 'pharma') {
    // 새로 선택된 제약사들만 확인
    const newSelectedPharmas = tempSelectedPharmas.value.filter(
      newPharma => !selectedPharmas.value.some(
        existingPharma => existingPharma.id === newPharma.id
      )
    );
    
    // 새로 선택된 제약사들 중 전달사항이 있는 것들을 확인
    const pharmasWithComments = newSelectedPharmas.filter(p => p.filtering_comment);
    
    if (pharmasWithComments.length > 0) {
      // 전달사항이 있는 경우 모달 표시
      commentDialogContent.value = pharmasWithComments
        .map(p => `[${p.company_name}]\n${p.filtering_comment}`)
        .join('\n\n');
      showCommentDialog.value = true;
    } else {
      // 전달사항이 없는 경우 바로 선택 완료
      selectedPharmas.value = [...tempSelectedPharmas.value];
      closeModal();
    }
  }
};

// 전달사항 확인 후 선택 완료
const confirmCommentDialog = () => {
  showCommentDialog.value = false;
  selectedPharmas.value = [...tempSelectedPharmas.value];
  closeModal();
};

const removePharma = (pharmaId) => {
  selectedPharmas.value = selectedPharmas.value.filter(p => p.id !== pharmaId);
};

watch(hospitalSelectionType, (type) => {
  hospitalInfo.value = { id: null, hospital_name: '', business_registration_number: '', director_name: '', address: '', telephone: '', handphone: '' };
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

// 신규 거래처 전화번호 하이픈 자동 입력
watch(() => hospitalInfo.value.telephone, (newValue) => {
  const digits = (newValue || '').replace(/\D/g, '');
  let formatted = '';
  if (digits.startsWith('02')) {
    if (digits.length <= 2) {
      formatted = digits;
    } else if (digits.length <= 6) {
      formatted = `${digits.slice(0,2)}-${digits.slice(2)}`;
    } else {
      formatted = `${digits.slice(0,2)}-${digits.slice(2,6)}-${digits.slice(6,10)}`;
    }
  } else {
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = `${digits.slice(0,3)}-${digits.slice(3)}`;
    } else {
      formatted = `${digits.slice(0,3)}-${digits.slice(3,7)}-${digits.slice(7,11)}`;
    }
  }
  if (formatted !== hospitalInfo.value.telephone) {
    hospitalInfo.value.telephone = formatted;
  }
});

// 신규 거래처 휴대폰번호 하이픈 자동 입력
watch(() => hospitalInfo.value.handphone, (newValue) => {
  const digits = (newValue || '').replace(/\D/g, '');
  let formatted = '';
  if (digits.length > 0) {
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3)}`;
    } else {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3, 7)}-${digits.slice(7, 11)}`;
    }
  }
  if (formatted !== hospitalInfo.value.handphone) {
    hospitalInfo.value.handphone = formatted;
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
  const { data, error } = await supabase
    .from('pharmaceutical_companies')
    .select('*')
    .eq('filtering_status', 'active')  // 필터링이 활성화된 제약사만 조회
    .order('company_name');
  
  if (!error) {
    allPharmas.value = data;
    
    // 제약사 데이터 로딩 완료 후 쿼리 파라미터에서 제약사 자동 선택 처리
    const query = route.query;
    if (query.company_id && query.company_name) {
      const companyId = parseInt(query.company_id);
      const companyName = query.company_name;
      
      console.log(`🔍 제약사 자동 선택 시도: ID=${companyId}, Name=${companyName}`);
      console.log(`📋 로딩된 제약사 목록:`, allPharmas.value.map(p => `${p.id}: ${p.company_name}`));
      
      // 제약사 목록에서 해당 제약사 찾기
      const matchedCompany = allPharmas.value.find(company => company.id === companyId);
      
      if (matchedCompany) {
        selectedPharmas.value = [matchedCompany];
        console.log(`✅ 제약사 자동 선택 완료: ${matchedCompany.company_name}`);
      } else {
        console.log(`❌ 제약사 ID ${companyId}를 찾을 수 없습니다.`);
      }
    }
  } else {
    console.error('제약사 데이터 조회 실패:', error);
  }
};

// 파일 변경 핸들러
const onFileChange = (event) => {
  const files = event.target.files;
  if (files.length > 0) {
    licenseFile.value = files[0];
    console.log('선택된 파일:', licenseFile.value);
  }
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
          telephone: hospitalInfo.value.telephone,
          handphone: hospitalInfo.value.handphone,
          registered_by: currentUser.value.id,
        }]).select('id').single();
        if (error) throw error;
        hospitalId = newHospital.id;
        // 파일 업로드 및 hospitals 테이블 업데이트
        if (licenseFile.value) {
          const file = licenseFile.value;
          const fileExt = file.name.split('.').pop();
          const userId = currentUser.value.id;
          const fileName = `${uuidv4()}.${fileExt}`;
          const filePath = `${userId}/${hospitalId}/${fileName}`;

          // hospitalId와 파일 정보 출력
          console.log('hospitalId:', hospitalId);
          console.log('licenseFile:', licenseFile.value);

          const { error: uploadError } = await supabase.storage
            .from('hospital-biz-licenses')
            .upload(filePath, file);

          if (uploadError) {
            console.error('파일 업로드 실패:', uploadError);
            throw uploadError;
          }

          // update 쿼리 실행 전 hospitalId, filePath 출력
          console.log('update hospitalId:', hospitalId, 'filePath:', filePath);

          const { error: updateError } = await supabase
            .from('hospitals')
            .update({ business_license_file: filePath })
            .eq('id', hospitalId);

          // updateError 출력
          if (updateError) {
            console.error('파일 경로 DB 업데이트 실패:', updateError);
            throw updateError;
          }
        }
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
      created_by: currentUser.value.id, // 생성자 uuid
      // updated_at, processed_at은 절대 포함하지 않음
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

// 쿼리 파라미터 처리 함수
const processQueryParams = async () => {
  const query = route.query;
  
  console.log('🔍 쿼리 파라미터:', query);
  
  // 거래처 정보가 쿼리 파라미터로 전달된 경우
  if (query.hospital_id) {
    console.log('✅ 거래처 정보 쿼리 파라미터 발견');
    
    hospitalSelectionType.value = 'existing';
    hospitalInfo.value = {
      id: parseInt(query.hospital_id),
      hospital_name: query.hospital_name || '',
      address: query.hospital_address || '',
      director_name: query.hospital_director || '',
      business_registration_number: query.hospital_business_number || '',
      // 추가 필드들
      telephone: query.hospital_telephone || '',
      handphone: query.hospital_handphone || ''
    };
    
    console.log('🏥 설정된 거래처 정보:', hospitalInfo.value);
  }
  
  // 제약사 자동 선택은 fetchPharmas() 함수에서 처리됨
};

onMounted(async () => {
  await getCurrentUser();
  await fetchMyHospitals();
  
  // 거래처 쿼리 파라미터 처리 (제약사 로드 전에 실행)
  await processQueryParams();
  
  // 제약사 데이터 로드 (내부에서 제약사 자동 선택 처리)
  await fetchPharmas();
});

const activeSortedCompanies = computed(() => {
  return allPharmas.value
    .filter(c => c.filtering_status === 'active')  // 필터링 상태로 필터링
    .sort((a, b) => a.company_name.localeCompare(b.company_name, 'ko'));
});

console.log(activeSortedCompanies.value);
</script>

