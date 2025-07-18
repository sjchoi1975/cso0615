<template>
  <div class="board">
    <form @submit.prevent="registerProduct" class="board-form">
      <div class="form-grid">
        <div class="form-group">
          <label class="label">기준년월</label>
          <input :value="baseMonth" class="input" disabled />
        </div>
        <div class="form-group">
          <label class="label">제약사<span class="required">*</span></label>
          <input v-model="pharmacist" placeholder="제약사" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">분류명</label>
          <input v-model="classification" placeholder="분류명" class="input" />
        </div>
        <div class="form-group">
          <label class="label">제품명<span class="required">*</span></label>
          <input v-model="productName" placeholder="제품명" class="input" required />
        </div>
        <div class="form-group">
          <label class="label">보험코드</label>
          <input v-model="insuranceCode" placeholder="보험코드" class="input" maxlength="9" />
        </div>
        <div class="form-group">
          <label class="label">약가</label>
          <input v-model.number="price" type="number" placeholder="약가" class="input" />
        </div>
        <div class="form-group">
          <label class="label">수수료 등급 A(%)</label>
          <input v-model.number="commissionA" type="number" step="0.1" placeholder="수수료 A" class="input" />
        </div>
        <div class="form-group">
          <label class="label">수수료 등급 B(%)</label>
          <input v-model.number="commissionB" type="number" step="0.1" placeholder="수수료 B" class="input" />
        </div>
        <div class="form-group">
          <label class="label">수수료 등급 C(%)</label>
          <input v-model.number="commissionC" type="number" step="0.1" placeholder="수수료 C" class="input" />
        </div>
        <div class="form-group">
          <label class="label">성분</label>
          <input v-model="ingredient" placeholder="성분" class="input" />
        </div>
        <div class="form-group">
          <label class="label">대조약</label>
          <input v-model="comparator" placeholder="대조약" class="input" />
        </div>
        <div class="form-group">
          <label class="label">급여</label>
          <input v-model="reimbursement" placeholder="급여" class="input" />
        </div>
        <div class="form-group">
          <label class="label">생동</label>
          <input v-model="bioequivalence" placeholder="생동" class="input" />
        </div>
        <div class="form-group">
          <label class="label">자사/위탁</label>
          <input v-model="inhouse" placeholder="자사/위탁" class="input" />
        </div>
        <div class="form-group">
          <label class="label">비고</label>
          <input v-model="remarks" placeholder="비고" class="input" />
        </div>
        <div class="form-group">
          <label class="label">상태</label>
          <select v-model="status" class="input">
            <option value="active">활성</option>
            <option value="inactive">비활성</option>
          </select>
        </div>
      </div>
      <div class="btn-row">
        <button type="button" class="btn-cancel" @click="goList" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :class="{ 'btn-disabled': loading || !canSubmit }" style="flex:3;">등록</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { supabase } from '@/supabase';
import { useRouter } from 'vue-router';
import dayjs from 'dayjs';

const today = dayjs();
const baseMonth = today.format('YYYY-MM');
const pharmacist = ref("");
const classification = ref("");
const productName = ref("");
const insuranceCode = ref("");
const price = ref();
const commissionA = ref();
const commissionB = ref();
const commissionC = ref();
const ingredient = ref("");
const comparator = ref("");
const reimbursement = ref("");
const bioequivalence = ref("");
const inhouse = ref("");
const remarks = ref("");
const status = ref("active");
const loading = ref(false);
const router = useRouter();

// 필수 항목이 모두 입력되었는지 확인
const canSubmit = computed(() => {
  return pharmacist.value.trim().length > 0 && productName.value.trim().length > 0;
});

const registerProduct = async () => {
  if (!pharmacist.value || !productName.value) {
    alert("제약사와 제품명을 모두 입력하세요.");
    return;
  }
  try {
    loading.value = true;
    const commissionAValue = commissionA.value !== undefined && commissionA.value !== null && commissionA.value !== '' ? parseFloat((parseFloat(commissionA.value) / 100).toFixed(3)) : null;
    const commissionBValue = commissionB.value !== undefined && commissionB.value !== null && commissionB.value !== '' ? parseFloat((parseFloat(commissionB.value) / 100).toFixed(3)) : null;
    const commissionCValue = commissionC.value !== undefined && commissionC.value !== null && commissionC.value !== '' ? parseFloat((parseFloat(commissionC.value) / 100).toFixed(3)) : null;
    const { error } = await supabase.from('products').insert({
      base_month: baseMonth,
      pharmacist: pharmacist.value,
      classification: classification.value,
      product_name: productName.value,
      insurance_code: insuranceCode.value,
      price: price.value,
      commission_rate_a: commissionAValue,
      commission_rate_b: commissionBValue,
      commission_rate_c: commissionCValue,
      Ingredient: ingredient.value,
      comparator: comparator.value,
      reimbursement: reimbursement.value,
      bioequivalence: bioequivalence.value,
      Inhouse: inhouse.value,
      remarks: remarks.value,
      status: status.value,
      registered_at: new Date().toISOString()
    });
    if (error) throw error;
    alert('제품이 등록되었습니다.');
    router.push('/admin/products/list');
  } catch (e) {
    alert('등록 실패: ' + e.message);
  } finally {
    loading.value = false;
  }
};

const goList = () => {
  router.push('/admin/products/list');
};
</script>
