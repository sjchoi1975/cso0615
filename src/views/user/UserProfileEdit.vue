<template>
  <div class="board">
    <form class="board-form">
      <label class="txt-150-222"
        style="margin-bottom: 1.5rem !important; text-align: center !important;">
        내 정보 수정
      </label>
      <div class="form-grid">
        <div class="form-group">
          <label>아이디</label>
          <input type="email" v-model="user.email" class="input" disabled />
        </div>
        <div class="form-group">
          <label>회사명<span class="required">*</span></label>
          <input type="text" v-model="user.company_name" class="input" />
        </div>
        <div class="form-group">
          <label>대표자명<span class="required">*</span></label>
          <input type="text" v-model="user.ceo_name" class="input" />
        </div>
        <div class="form-group">
          <label>사업자등록번호<span class="required">*</span></label>
          <input type="text" v-model="user.biz_no" class="input" @input="formatBizNo" maxlength="12" />
        </div>
        <div class="form-group">
          <label>주소</label>
          <input type="text" v-model="user.address" placeholder="" class="input" />
        </div>
        <div class="form-group">
          <label>CSO 신고번호</label>
          <input type="text" v-model="user.cso_regist_no" placeholder="숫자와 - (하이픈)만 입력" class="input" />
        </div>
        <div class="form-group">
          <label>담당자명</label>
          <input type="text" v-model="user.manager_name" placeholder="" class="input" />
        </div>
        <div class="form-group">
          <label>휴대폰 번호</label>
          <input type="text" v-model="user.handphone" placeholder="숫자만 입력" class="input" @input="formatPhone" maxlength="13" />
        </div>
        <div class="form-group">
          <label>이메일(연락용)</label>
          <input type="email" v-model="user.contact_email" placeholder="" class="input" />
        </div>
      </div>
      <div class="btn-row">
        <Button label="취소" class="btn-cancel" @click.prevent="goToCancel" style="flex:1;"/>
        <Button label="저장" class="btn-signup" @click.prevent="goToSave" style="flex:3;"/>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import TopbarMenu from '@/components/TopbarMenu.vue';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';

const router = useRouter();
const user = ref({
  email: '',
  company_name: '',
  ceo_name: '',
  biz_no: '',
  address: '',
  cso_regist_no: '',
  manager_name: '',
  handphone: '',
  contact_email: ''
});

onMounted(async () => {
  const { data: { user: supaUser } } = await supabase.auth.getUser();
  if (supaUser) {
    user.value.email = supaUser.email;
    // members 테이블에서 상세 정보 조회
    const { data: memberData } = await supabase
      .from('members')
      .select('*')
      .eq('id_email', supaUser.email)
      .single();
    if (memberData) {
      user.value.company_name = memberData.company_name || '';
      user.value.ceo_name = memberData.ceo_name || '';
      user.value.biz_no = memberData.biz_no || '';
      user.value.address = memberData.address || '';
      user.value.cso_regist_no = memberData.cso_regist_no || '';
      user.value.manager_name = memberData.manager_name || '';
      user.value.handphone = memberData.handphone || '';
      user.value.contact_email = memberData.email || '';
    }
  }
});

function formatBizNo(e) {
  let v = e.target.value.replace(/[^0-9]/g, '');
  if (v.length > 3 && v.length <= 5) v = v.replace(/(\d{3})(\d+)/, '$1-$2');
  else if (v.length > 5) v = v.replace(/(\d{3})(\d{2})(\d{0,5})/, '$1-$2-$3');
  user.value.biz_no = v;
}

function formatPhone(e) {
  let v = e.target.value.replace(/[^0-9]/g, '');
  if (v.length < 4) {
    // 그대로
  } else if (v.length < 8) {
    v = v.replace(/(\d{3})(\d{0,4})/, '$1-$2');
  } else {
    v = v.replace(/(\d{3})(\d{4})(\d{0,4})/, '$1-$2-$3');
  }
  user.value.handphone = v;
}

function validateEmail(email) {
  const re = /^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}$/;
  return re.test(email);
}

function validateBizNo(bizNo) {
  // 000-00-00000 형식, 숫자 10자리
  return /^\d{3}-\d{2}-\d{5}$/.test(bizNo);
}

function validatePhone(phone) {
  // 010-0000-0000 또는 000-000-0000 형식
  return /^(01\d-\d{3,4}-\d{4})$/.test(phone);
}

function goToCancel() {
  router.back();
}

async function goToSave() {
  // 필수값 체크
  if (!user.value.company_name) {
    alert('회사명을 입력해 주세요.');
    return;
  }
  if (!user.value.ceo_name) {
    alert('대표자명을 입력해 주세요.');
    return;
  }
  if (!validateBizNo(user.value.biz_no)) {
    alert('사업자등록번호를 올바르게 입력해 주세요. (예: 123-45-67890)');
    return;
  }
  // 휴대폰, 이메일 등은 입력하지 않아도 됨
  if (user.value.handphone && !validatePhone(user.value.handphone)) {
    alert('휴대폰 번호를 올바르게 입력해 주세요. (예: 010-1234-5678)');
    return;
  }
  if (user.value.contact_email && !validateEmail(user.value.contact_email)) {
    alert('이메일 형식이 올바르지 않습니다.');
    return;
  }
  // 저장
  const { error } = await supabase
    .from('members')
    .update({
      company_name: user.value.company_name,
      ceo_name: user.value.ceo_name,
      biz_no: user.value.biz_no,
      address: user.value.address,
      cso_regist_no: user.value.cso_regist_no,
      manager_name: user.value.manager_name,
      handphone: user.value.handphone,
      email: user.value.contact_email
    })
    .eq('id_email', user.value.email);
  if (error) {
    alert('저장에 실패했습니다. 다시 시도해 주세요.');
  } else {
    alert('저장되었습니다.');
    router.push('/profile');
  }
}
</script>

