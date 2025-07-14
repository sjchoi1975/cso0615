<template>
  <div class="board">
    <form @submit.prevent="registerHospital" class="board-form">
      <div class="form-grid">
        <div class="form-group">
          <label class="label">거래처명<span class="required">*</span></label>
          <input v-model="hospitalName" placeholder="거래처명을 입력하세요" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">사업자등록번호<span class="required">*</span></label>
          <input v-model="businessNumber" placeholder="'-' 없이 숫자만 입력" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">원장명<span class="required">*</span></label>
          <input v-model="directorName" placeholder="원장명을 입력하세요" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">주소<span class="required">*</span></label>
          <input v-model="address" placeholder="주소를 입력하세요" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">전화번호</label>
          <input v-model="phone" placeholder="지역번호-국번-번호" class="input" maxlength="13" />
        </div>
        <div class="form-group">
          <label class="label">휴대폰 번호</label>
          <input v-model="handphone" placeholder="010-1234-5678" class="input" maxlength="13" />
        </div>
        <div class="form-group">
          <label class="label">사업자등록증</label>
          <input type="file" @change="onFileChange" class="input" />
        </div>
        <div class="form-group">
          <label class="label">담당 업체</label>
          <button type="button" class="btn-secondary" @click="openMemberModal">업체 선택</button>
          <div v-if="selectedMembers.length > 0" class="selected-members" style="margin-top: 0.5rem;">
            <div class="selected-title">선택된 업체 ({{ selectedMembers.length }}곳):</div>
            <div class="selected-list">
              <div v-for="memberId in selectedMembers" :key="memberId" class="selected-member">
                {{ getMemberName(memberId) }}
                <button type="button" @click="removeMember(memberId)" class="remove-member">×</button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="btn-row">
        <button type="button" class="btn-cancel" @click="goList" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :class="{ 'btn-disabled': loading || !canSubmit }" style="flex:3;">
          {{ loading ? '저장 중...' : '등록' }}
        </button>
      </div>
    </form>

    <!-- 업체 선택 모달 -->
    <div v-if="showMemberModal" class="custom-modal-overlay">
      <div class="custom-modal">
        <div class="modal-header">
          <h3 class="modal-title">업체 선택</h3>
        </div>
        <div class="modal-body">
          <div class="member-selection">
            <div class="member-search">
              <input 
                v-model="memberSearch" 
                type="text" 
                class="input-field" 
                placeholder="업체명, 사업자번호, 대표자명, 주소로 검색" 
                @input="searchMembers"
              />
            </div>
            <div class="member-list">
              <div v-if="loadingMembers" class="no-results">로딩 중...</div>
              <div v-else-if="filteredMembers.length > 0">
                <div 
                  v-for="member in filteredMembers" 
                  :key="member.id"
                  class="member-item"
                  :class="{ 'selected': tempSelectedMembers.includes(member.id) }"
                  @click="toggleTempMemberSelection(member.id)"
                >
                  <div class="member-info">
                    <div class="member-name">{{ member.company_name }} ({{ member.ceo_name }})</div>
                    <div class="member-details">{{ member.biz_no }}</div>
                    <div class="member-details">{{ member.address }}</div>
                  </div>
                  <div class="member-checkbox">
                    <input 
                      type="checkbox" 
                      :checked="tempSelectedMembers.includes(member.id)"
                      @click.stop="toggleTempMemberSelection(member.id)"
                    />
                  </div>
                </div>
              </div>
              <div v-else class="no-results">
                검색 결과가 없습니다.
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn-cancel" @click="cancelMemberSelection">취소</button>
          <button type="button" class="btn-confirm" @click="confirmMemberSelection">선택</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import { v4 as uuidv4 } from 'uuid';

// 기존 상태 변수
const hospitalName = ref('');
const businessNumber = ref('');
const directorName = ref('');
const address = ref('');
const licenseFile = ref(null);
const loading = ref(false);
const router = useRouter();

// 필수값 검증을 위한 computed
const canSubmit = computed(() => {
  return hospitalName.value.trim().length > 0 &&
         businessNumber.value.trim().length > 0 &&
         directorName.value.trim().length > 0 &&
         address.value.trim().length > 0;
});

// 회원 선택 모달 관련 상태 변수
const showMemberModal = ref(false);
const members = ref([]);
const filteredMembers = ref([]);
const selectedMembers = ref([]); // 최종 선택된 회원
const tempSelectedMembers = ref([]); // 모달 내에서 임시로 선택된 회원
const memberSearch = ref('');
const loadingMembers = ref(false);

const phone = ref('');
const handphone = ref('');

const onFileChange = (event) => {
  const files = event.target.files;
  if (files.length > 0) {
    licenseFile.value = files[0];
  }
};

// 회원 목록 가져오기
const fetchMembers = async () => {
  loadingMembers.value = true;
  try {
    const { data, error } = await supabase
      .from('members')
      .select('id, company_name, ceo_name, biz_no, address')
      .eq('approval', 'approved')
      .order('company_name');
    if (error) throw error;
    members.value = data;
    filteredMembers.value = data;
  } catch (e) {
    console.error('회원 정보 로드 오류:', e);
    alert('회원 정보를 불러오는 데 실패했습니다.');
  } finally {
    loadingMembers.value = false;
  }
};

onMounted(() => {
  fetchMembers();
});

// 회원 검색
const searchMembers = () => {
  if (!memberSearch.value.trim()) {
    filteredMembers.value = members.value;
    return;
  }
  const searchTerm = memberSearch.value.toLowerCase();
  filteredMembers.value = members.value.filter(member =>
    (member.company_name?.toLowerCase().includes(searchTerm)) ||
    (member.biz_no?.toLowerCase().includes(searchTerm)) ||
    (member.ceo_name?.toLowerCase().includes(searchTerm)) ||
    (member.address?.toLowerCase().includes(searchTerm))
  );
};

// 모달 열기
const openMemberModal = () => {
  tempSelectedMembers.value = [...selectedMembers.value];
  showMemberModal.value = true;
}

// 모달 내 임시 선택
const toggleTempMemberSelection = (memberId) => {
  const index = tempSelectedMembers.value.indexOf(memberId);
  if (index > -1) {
    tempSelectedMembers.value.splice(index, 1);
  } else {
    tempSelectedMembers.value.push(memberId);
  }
};

// '선택' 버튼 클릭 시
const confirmMemberSelection = () => {
  selectedMembers.value = [...tempSelectedMembers.value];
  showMemberModal.value = false;
};

// '취소' 버튼 클릭 시
const cancelMemberSelection = () => {
  showMemberModal.value = false;
};

// 선택된 회원 제거
const removeMember = (memberId) => {
  const index = selectedMembers.value.indexOf(memberId);
  if (index > -1) selectedMembers.value.splice(index, 1);
};

// ID로 회원 이름 찾기
const getMemberName = (memberId) => {
  const member = members.value.find(m => m.id === memberId);
  return member ? member.company_name : '알 수 없음';
};

// 사업자등록번호 자동 하이픈 추가
watch(businessNumber, (newValue) => {
  const digits = newValue.replace(/\D/g, '');
  let formatted = '';
  if (digits.length > 0) {
    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 5) {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3)}`;
    } else {
      formatted = `${digits.slice(0, 3)}-${digits.slice(3, 5)}-${digits.slice(5, 10)}`;
    }
  }
  if (formatted !== businessNumber.value) {
    businessNumber.value = formatted;
  }
});

// 전화번호 자동 하이픈 추가 (지역번호 자동 분류)
watch(phone, (newValue) => {
  const digits = newValue.replace(/\D/g, '');
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
  if (formatted !== phone.value) {
    phone.value = formatted;
  }
});

// 휴대폰 번호 자동 하이픈 추가
watch(handphone, (newValue) => {
  const digits = newValue.replace(/\D/g, '');
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
  if (formatted !== handphone.value) {
    handphone.value = formatted;
  }
});

// 병원 등록 로직 수정
const registerHospital = async () => {
  if (!hospitalName.value || !businessNumber.value || !directorName.value || !address.value) {
    alert('필수 입력 항목(*)을 모두 입력해주세요.');
    return;
  }
  loading.value = true;
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      alert('로그인이 필요합니다.');
      loading.value = false;
      return;
    }
    // 1. 텍스트 정보 먼저 삽입
    const { data: newHospital, error: insertError } = await supabase
      .from('hospitals')
      .insert({
        hospital_name: hospitalName.value,
        business_registration_number: businessNumber.value,
        director_name: directorName.value,
        address: address.value,
        telephone: phone.value,
        handphone: handphone.value,
        registered_by: user.id,
      })
      .select('id')
      .single();
    if (insertError) throw insertError;
    const newHospitalId = newHospital.id;

    // 2. 파일이 있으면 업로드하고 테이블 업데이트
    if (licenseFile.value) {
      const file = licenseFile.value;
      const fileExt = file.name.split('.').pop();
      const fileName = `${uuidv4()}.${fileExt}`;
      const filePath = `${user.id}/${newHospitalId}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('hospital-biz-licenses')
        .upload(filePath, file);
      if (uploadError) throw uploadError;

      const { error: updateError } = await supabase
        .from('hospitals')
        .update({ business_license_file: filePath })
        .eq('id', newHospitalId);
      if (updateError) throw updateError;
    }

    // 3. 회원 매핑 처리
    if (selectedMembers.value.length > 0) {
      const mappings = selectedMembers.value.map(memberId => ({
        hospital_id: newHospitalId,
        member_id: memberId,
      }));
      const { error: mappingError } = await supabase.from('hospital_member_mappings').insert(mappings);
      if (mappingError) throw mappingError;
    }

    alert('신규 거래처가 등록되었습니다.');
    router.push('/admin/hospitals/list');
  } catch (e) {
    console.error('거래처 등록 오류:', e);
    alert('처리 중 오류가 발생했습니다: ' + e.message);
  } finally {
    loading.value = false;
  }
};

const goList = () => {
  router.push('/admin/hospitals/list');
};
</script>

<style scoped>
.member-selection {
  /* 필요한 경우 스타일 추가 */
}
.member-search .input-field {
  width: 100%;
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.member-list {
  margin-top: 10px;
  max-height: 300px;
  overflow-y: auto;
  border: 1px solid #eee;
}
.member-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  border-bottom: 1px solid #eee;
  cursor: pointer;
}
.member-item:hover {
  background-color: #f9f9f9;
}
.member-item.selected {
  background-color: #e3f2fd;
}
.member-name {
  font-weight: bold;
}
.member-details {
  font-size: 0.9em;
  color: #666;
}
.no-results {
  padding: 10px;
  text-align: center;
  color: #888;
}
.selected-members {
  margin-top: 1rem;
  padding: 0.5rem;
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 4px;
}
.selected-title {
  font-weight: bold;
  margin-bottom: 0.5rem;
}
.selected-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
.selected-member {
  display: flex;
  align-items: center;
  background-color: #e9ecef;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.9em;
}
.remove-member {
  margin-left: 8px;
  border: none;
  background: none;
  cursor: pointer;
  font-size: 1.2em;
  color: #6c757d;
}
</style>
