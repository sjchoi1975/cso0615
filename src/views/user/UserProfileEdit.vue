<template>
  <div class="board">
    <form class="board-form">
      <label
        class="title-lg"
        style="margin-top: -1rem !important;
               margin-bottom: 1rem !important;
               text-align: center !important;">
        내 정보 수정
      </label>
      <label>아이디</label>
      <input type="email" v-model="user.email" class="input" disabled />
      <label>회사명</label>
      <input type="text" v-model="user.company_name" class="input" />
      <label>대표자명</label>
      <input type="text" v-model="user.ceo_name" class="input" />
      <label>사업자등록번호</label>
      <input type="text" v-model="user.biz_no" class="input" />
      <label>주소</label>
      <input type="text" v-model="user.address" class="input" />
      <label>CSO 신고번호</label>
      <input type="text" v-model="user.cso_regist_no" class="input" />
      <label>담당자명</label>
      <input type="text" v-model="user.manager_name" class="input" />
      <label>휴대폰 번호</label>
      <input type="text" v-model="user.handphone" class="input" />
      <label>이메일(연락용)</label>
      <input type="email" v-model="user.contact_email" class="input" />
      <div style="display: flex; justify-content: flex-end; gap: 0.5rem; margin-top: 1.2rem;">
        <Button label="취소" class="btn-cancel" @click.prevent="goToCancel" style="width: 100px;" />
        <Button label="저장" class="btn-signup" @click.prevent="goToSave" style="width: 100px;" />
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

function goToEdit() {
  router.push('/profile/edit');
}
function goToChangePw() {
  router.push('/profile/password');
}
</script>

