<template>
  <div class="board">
    <form @submit.prevent="updateHospital" class="board-form">
      <div class="form-grid">
        <div class="form-group">
          <label>거래처명<span class="required">*</span></label>
          <input v-model="hospitalName" placeholder="" class="input" required />
        </div>
        <div class="form-group">
          <label>사업자등록번호<span class="required">*</span></label>
          <input v-model="businessNumber" placeholder="- (하이픈) 없이 숫자만 입력" class="input" required />
        </div>
        <div class="form-group">
          <label>원장명<span class="required">*</span></label>
          <input v-model="directorName" placeholder="" class="input" required />
        </div>
        <div class="form-group">
          <label>주소<span class="required">*</span></label>
          <input v-model="address" placeholder="" class="input" required />
        </div>
        <div class="form-group">
          <label>전화번호</label>
          <input v-model="phone" placeholder="- (하이픈) 없이 숫자만 입력" class="input" maxlength="13" />
        </div>
        <div class="form-group">
          <label>휴대폰 번호</label>
          <input v-model="handphone" placeholder="- (하이픈) 없이 숫자만 입력" class="input" maxlength="13" />
        </div>
        <div class="form-group">
          <label>사업자등록증</label>
          <input type="file" @change="onFileChange" class="input" />
          <div v-if="existingLicenseFile" class="file-info">
            <span>기존 파일: {{ getFileName(existingLicenseFile) }}</span>
            <a :href="getFileUrl(existingLicenseFile)" target="_blank" class="link">파일 보기</a>
          </div>
        </div>
      </div>
      <div class="btn-row">
        <button 
          type="button" 
          class="btn-cancel" 
          @click="goList" style="flex:1;">
          취소
        </button>
        <button 
          type="submit" 
          class="btn-confirm" 
          :class="{ 'btn-disabled': loading || !canEdit }" 
          style="flex:3;">
          {{ loading ? '저장 중...' : '수정' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue';
import { supabase } from '@/supabase';
import { useRouter, useRoute } from 'vue-router';
import { v4 as uuidv4 } from 'uuid';

const hospitalName = ref('');
const businessNumber = ref('');
const directorName = ref('');
const address = ref('');
const phone = ref('');
const handphone = ref('');
const newLicenseFile = ref(null);
const existingLicenseFile = ref(null);
const loading = ref(false);
const router = useRouter();
const route = useRoute();
const hospitalId = route.params.id;

// 원본 데이터 저장
const originalData = ref({
  hospital_name: '',
  business_registration_number: '',
  director_name: '',
  address: '',
  telephone: '',
  handphone: ''
});

// 필수값 검증
const canSubmit = computed(() => {
  return hospitalName.value.trim().length > 0 &&
         businessNumber.value.trim().length > 0 &&
         directorName.value.trim().length > 0 &&
         address.value.trim().length > 0;
});

// 변경사항 확인
const hasChanges = computed(() => {
  return hospitalName.value !== originalData.value.hospital_name ||
         businessNumber.value !== originalData.value.business_registration_number ||
         directorName.value !== originalData.value.director_name ||
         address.value !== originalData.value.address ||
         phone.value !== originalData.value.telephone ||
         handphone.value !== originalData.value.handphone ||
         newLicenseFile.value !== null;
});

// 수정 버튼 활성화 조건
const canEdit = computed(() => {
  return canSubmit.value && hasChanges.value;
});

const onFileChange = (event) => {
  const files = event.target.files;
  if (files.length > 0) {
    newLicenseFile.value = files[0];
  }
};

const fetchHospitalData = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from('hospitals')
      .select('*')
      .eq('id', hospitalId)
      .single();
    
    if (error) throw error;

    hospitalName.value = data.hospital_name;
    businessNumber.value = data.business_registration_number;
    directorName.value = data.director_name;
    address.value = data.address;
    phone.value = data.telephone || '';
    handphone.value = data.handphone || '';
    existingLicenseFile.value = data.business_license_file;

    // 원본 데이터 저장
    originalData.value = {
      hospital_name: data.hospital_name,
      business_registration_number: data.business_registration_number,
      director_name: data.director_name,
      address: data.address,
      telephone: data.telephone || '',
      handphone: data.handphone || ''
    };

  } catch (e) {
    console.error('거래처 정보 로드 오류:', e);
    alert('거래처 정보를 불러오는 데 실패했습니다.');
    router.push('/hospitals/list');
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchHospitalData();
});

const updateHospital = async () => {
  if (!hospitalName.value || !businessNumber.value || !directorName.value || !address.value) {
    alert('필수 입력 항목(*)을 모두 입력해주세요.');
    return;
  }

  loading.value = true;
  let licenseFilePath = existingLicenseFile.value;

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('로그인이 필요합니다.');

    // 새 파일이 업로드된 경우
    if (newLicenseFile.value) {
      // 1. 기존 파일이 있으면 삭제
      if (existingLicenseFile.value) {
        const { error: deleteError } = await supabase.storage
          .from('hospital-biz-licenses')
          .remove([existingLicenseFile.value]);
        if (deleteError) console.error('기존 파일 삭제 실패:', deleteError);
      }
      
      // 2. 새 파일 업로드
      const file = newLicenseFile.value;
      const fileExt = file.name.split('.').pop();
      const fileName = `${uuidv4()}.${fileExt}`;
      const filePath = `${user.id}/${hospitalId}/${fileName}`;
      
      const { error: uploadError } = await supabase.storage
        .from('hospital-biz-licenses')
        .upload(filePath, file);

      if (uploadError) throw uploadError;
      licenseFilePath = filePath;
    }

    // 병원 정보 업데이트
    const { error: updateError } = await supabase
      .from('hospitals')
      .update({
        hospital_name: hospitalName.value,
        business_registration_number: businessNumber.value,
        director_name: directorName.value,
        address: address.value,
        telephone: phone.value,
        handphone: handphone.value,
        business_license_file: licenseFilePath,
        updated_by: user.id,
        updated_at: new Date().toISOString()
      })
      .eq('id', hospitalId);

    if (updateError) throw updateError;

    alert('거래처 정보가 성공적으로 수정되었습니다.');
    router.push('/hospitals/list');

  } catch (e) {
    console.error('거래처 수정 오류:', e);
    alert('처리 중 오류가 발생했습니다: ' + e.message);
  } finally {
    loading.value = false;
  }
};

const goList = () => {
  router.push('/hospitals/list');
};

const getFileName = (path) => {
  if (!path) return '';
  return path.split('/').pop();
};

const getFileUrl = (path) => {
  if (!path) return '#';
  const { data } = supabase.storage.from('hospital-biz-licenses').getPublicUrl(path);
  return data.publicUrl;
};

// 전화번호, 휴대폰번호 자동 하이픈 처리
watch(() => phone.value, (newValue) => {
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
  if (formatted !== phone.value) {
    phone.value = formatted;
  }
});

watch(() => handphone.value, (newValue) => {
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
  if (formatted !== handphone.value) {
    handphone.value = formatted;
  }
});
</script>
