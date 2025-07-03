<template>
  <div class="board">
    <form @submit.prevent="registerHospital" class="board-form">
      <label>거래처명<span class="required">*</span></label>
      <input v-model="hospitalName" placeholder="거래처명을 입력하세요" class="input" required />
      <label>사업자등록번호<span class="required">*</span></label>
      <input v-model="businessNumber" placeholder="'-' 없이 숫자만 입력" class="input" required />
      <label>원장명<span class="required">*</span></label>
      <input v-model="directorName" placeholder="원장명을 입력하세요" class="input" required />
      <label>주소<span class="required">*</span></label>
      <input v-model="address" placeholder="주소를 입력하세요" class="input" required />
      <label>사업자등록증</label>
      <input type="file" @change="onFileChange" class="input" />
      <div style="display: flex; gap: 0.5rem; margin-top: 1.2rem;">
        <button type="button" class="btn-cancel" @click="goList" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :disabled="loading" style="flex:2;">
          {{ loading ? '저장 중...' : '등록' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import { v4 as uuidv4 } from 'uuid';

const hospitalName = ref('');
const businessNumber = ref('');
const directorName = ref('');
const address = ref('');
const licenseFile = ref(null);
const loading = ref(false);
const router = useRouter();

const onFileChange = (event) => {
  const files = event.target.files;
  if (files.length > 0) {
    licenseFile.value = files[0];
  }
};

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
        registered_by: user.id, // 등록자는 현재 로그인한 이용자
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
      const filePath = `${fileName}`;

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

    // 3. 병원-이용자 관계(매핑) 정보 추가
    const { error: mappingError } = await supabase
      .from('hospital_member_mappings')
      .insert({
        hospital_id: newHospitalId,
        member_id: user.id,
      });

    if (mappingError) throw mappingError;

    alert('거래처가 성공적으로 등록 및 연결되었습니다.');
    router.push('/hospitals/list');

  } catch (e) {
    console.error('거래처 등록 및 연결 오류:', e);
    alert('처리 중 오류가 발생했습니다: ' + e.message);
  } finally {
    loading.value = false;
  }
};

const goList = () => {
  router.push('/hospitals/list');
};
</script>
