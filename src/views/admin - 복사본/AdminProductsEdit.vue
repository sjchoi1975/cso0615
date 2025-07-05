<template>
  <div class="board">
    <form @submit.prevent="updateProduct" class="board-form">
      <label>기준년월</label>
      <input v-model="product.base_month" class="input" disabled />
      <label>제약사<span class="required">*</span></label>
      <input v-model="product.pharmacist" placeholder="제약사" class="input" required />
      <label>분류명</label>
      <input v-model="product.classification" placeholder="분류명" class="input" />
      <label>제품명<span class="required">*</span></label>
      <input v-model="product.product_name" placeholder="제품명" class="input" required />
      <label>보험코드</label>
      <input v-model="product.insurance_code" placeholder="보험코드" class="input" maxlength="9" />
      <label>약가</label>
      <input v-model.number="product.price" type="number" placeholder="약가" class="input" />
      <label>수수료 등급 A(%)</label>
      <input v-model.number="commissionA" type="number" step="0.01" placeholder="수수료 A" class="input" />
      <label>수수료 등급 B(%)</label>
      <input v-model.number="commissionB" type="number" step="0.01" placeholder="수수료 B" class="input" />
      <label>수수료 등급 C(%)</label>
      <input v-model.number="commissionC" type="number" step="0.01" placeholder="수수료 C" class="input" />
      <label>성분</label>
      <input v-model="product.Ingredient" placeholder="성분" class="input" />
      <label>대조약</label>
      <input v-model="product.comparator" placeholder="대조약" class="input" />
      <label>급여</label>
      <input v-model="product.reimbursement" placeholder="급여" class="input" />
      <label>생동</label>
      <input v-model="product.bioequivalence" placeholder="생동" class="input" />
      <label>자사/위탁</label>
      <input v-model="product.Inhouse" placeholder="자사/위탁" class="input" />
      <label>비고</label>
      <input v-model="product.remarks" placeholder="비고" class="input" />
      <label>상태</label>
      <select v-model="product.status" class="input">
        <option value="active">활성</option>
        <option value="inactive">비활성</option>
      </select>
      <div style="display: flex; gap: 0.5rem; margin-top: 1.2rem;">
        <button type="button" class="btn-cancel" @click="goList" style="flex:1;">취소</button>
        <button type="submit" class="btn-confirm" :disabled="loading" style="flex:2;">수정</button>
      </div>
    </form>
  </div>
</template>
  
  <script setup>
  import { ref, onMounted } from 'vue';
  import { supabase } from '@/supabase';
  import { useRouter, useRoute } from 'vue-router';
  
  const product = ref({});
  const commissionA = ref();
  const commissionB = ref();
  const commissionC = ref();
  const loading = ref(false);
  const router = useRouter();
  const route = useRoute();
  const productId = route.params.id;
  
  const fetchProduct = async () => {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', productId)
      .single();
    
    if (error) {
      alert('제품 정보를 불러오는 데 실패했습니다: ' + error.message);
      return;
    }
    
    product.value = data;
    // 수수료율을 % 단위로 변환하여 표시
    if (data.commission_rate_a !== null) commissionA.value = parseFloat(data.commission_rate_a) * 100;
    if (data.commission_rate_b !== null) commissionB.value = parseFloat(data.commission_rate_b) * 100;
    if (data.commission_rate_c !== null) commissionC.value = parseFloat(data.commission_rate_c) * 100;
  };
  
  onMounted(fetchProduct);
  
  const updateProduct = async () => {
    if (!product.value.pharmacist || !product.value.product_name) {
      alert("제약사와 제품명을 모두 입력하세요.");
      return;
    }
    try {
      loading.value = true;
      const commissionAValue = commissionA.value !== undefined && commissionA.value !== null && commissionA.value !== '' ? (parseFloat(commissionA.value) / 100).toFixed(3) : null;
      const commissionBValue = commissionB.value !== undefined && commissionB.value !== null && commissionB.value !== '' ? (parseFloat(commissionB.value) / 100).toFixed(3) : null;
      const commissionCValue = commissionC.value !== undefined && commissionC.value !== null && commissionC.value !== '' ? (parseFloat(commissionC.value) / 100).toFixed(3) : null;
      
      const { error } = await supabase
        .from('products')
        .update({
          pharmacist: product.value.pharmacist,
          classification: product.value.classification,
          product_name: product.value.product_name,
          insurance_code: product.value.insurance_code,
          price: product.value.price,
          commission_rate_a: commissionAValue,
          commission_rate_b: commissionBValue,
          commission_rate_c: commissionCValue,
          Ingredient: product.value.Ingredient,
          comparator: product.value.comparator,
          reimbursement: product.value.reimbursement,
          bioequivalence: product.value.bioequivalence,
          Inhouse: product.value.Inhouse,
          remarks: product.value.remarks,
          status: product.value.status,
        })
        .eq('id', productId);
        
      if (error) throw error;
      alert('제품이 수정되었습니다.');
      window.location.href = '/admin/products/list';
    } catch (e) {
      alert('수정 실패: ' + e.message);
    } finally {
      loading.value = false;
    }
  };
  
  const goList = () => {
    window.location.href = '/admin/products/list';
  };
  </script>
  