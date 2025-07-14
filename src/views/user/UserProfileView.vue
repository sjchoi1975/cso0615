<template>
  <div class="board">
    <form class="board-form">
      <label class="txt-150-222"
        style="margin-bottom: 1.5rem !important; text-align: center !important;">
        내 정보
      </label>
      <div class="form-grid">
        <div class="form-group">
          <label>아이디</label>
          <input type="email" v-model="user.email" class="input" disabled />
        </div>
        <div class="form-group">
          <label>회사명</label>
          <input type="text" v-model="user.company_name" class="input" disabled />
        </div>
        <div class="form-group">
          <label>대표자명</label>
          <input type="text" v-model="user.ceo_name" class="input" disabled />
        </div>
        <div class="form-group">
          <label>사업자등록번호</label>
          <input type="text" v-model="user.biz_no" class="input" disabled />
        </div>
        <div class="form-group">
          <label>주소</label>
          <input type="text" v-model="user.address" class="input" disabled />
        </div>
        <div class="form-group">
          <label>CSO 신고번호</label>
          <input type="text" v-model="user.cso_regist_no" class="input" disabled />
        </div>
        <div class="form-group">
          <label>담당자명</label>
          <input type="text" v-model="user.manager_name" class="input" disabled />
        </div>
        <div class="form-group">
          <label>휴대폰 번호</label>
          <input type="text" v-model="user.handphone" class="input" disabled />
        </div>
        <div class="form-group">
          <label>이메일(연락용)</label>
          <input type="email" v-model="user.contact_email" class="input" disabled />
        </div>
      </div>
      <div class="btn-row">
        <Button label="비밀번호 변경" class="btn-pwchange" @click.prevent="openPwModal" style="flex:1;" />
        <Button label="정보 수정" class="btn-edit" @click.prevent="goToEdit" style="flex:3;" />
      </div>
    </form>
    <UserChangePasswordModal :visible="showPwModal" @close="closePwModal" @success="onPwChangeSuccess" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import TopbarMenu from '@/components/TopbarMenu.vue';
import Button from 'primevue/button';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import UserChangePasswordModal from './UserChangePasswordModal.vue';

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
const showPwModal = ref(false);

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

function goToEdit() {
  router.push('/profile/edit');
}
function openPwModal() {
  showPwModal.value = true;
}
function closePwModal() {
  showPwModal.value = false;
}
function onPwChangeSuccess() {
  // 필요시 안내 또는 새로고침 등 추가 가능
}
</script>

