<template>
  <div class="board">
    <form @submit.prevent="updateProduct" class="board-form">
      <div class="form-grid">
        <div class="form-group">
          <label class="label">기준년월</label>
          <input v-model="baseMonth" class="input" disabled />
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
        <button type="submit" class="btn-confirm" :class="{ 'btn-disabled': loading || !canEdit }" style="flex:3;">수정</button>
      </div>
    </form>
  </div>
</template>
  
  <script setup>
  import { ref, computed, onMounted } from 'vue';
  import { supabase } from '@/supabase';
  import { useRouter, useRoute } from 'vue-router';
  
  const pharmacist = ref('');
  const classification = ref('');
  const productName = ref('');
  const insuranceCode = ref('');
  const price = ref();
  const commissionA = ref();
  const commissionB = ref();
  const commissionC = ref();
  const ingredient = ref('');
  const comparator = ref('');
  const reimbursement = ref('');
  const bioequivalence = ref('');
  const inhouse = ref('');
  const remarks = ref('');
  const status = ref('active');
  const baseMonth = ref('');
  const loading = ref(false);
  const router = useRouter();
  const route = useRoute();
  const productId = route.params.id;

  // 원본 데이터 저장
  const originalData = ref({
    pharmacist: '',
    classification: '',
    product_name: '',
    insurance_code: '',
    price: null,
    commission_rate_a: null,
    commission_rate_b: null,
    commission_rate_c: null,
    Ingredient: '',
    comparator: '',
    reimbursement: '',
    bioequivalence: '',
    Inhouse: '',
    remarks: '',
    status: ''
  });

  // 필수 항목이 모두 입력되었는지 확인
  const canSubmit = computed(() => {
    return pharmacist.value.trim().length > 0 && 
           productName.value.trim().length > 0;
  });

  // 변경사항이 있는지 확인
  const hasChanges = computed(() => {
    return pharmacist.value !== originalData.value.pharmacist ||
           classification.value !== originalData.value.classification ||
           productName.value !== originalData.value.product_name ||
           insuranceCode.value !== originalData.value.insurance_code ||
           price.value !== originalData.value.price ||
           commissionA.value !== originalData.value.commission_rate_a ||
           commissionB.value !== originalData.value.commission_rate_b ||
           commissionC.value !== originalData.value.commission_rate_c ||
           ingredient.value !== originalData.value.Ingredient ||
           comparator.value !== originalData.value.comparator ||
           reimbursement.value !== originalData.value.reimbursement ||
           bioequivalence.value !== originalData.value.bioequivalence ||
           inhouse.value !== originalData.value.Inhouse ||
           remarks.value !== originalData.value.remarks ||
           status.value !== originalData.value.status;
  });

  // 수정 버튼 활성화 조건
  const canEdit = computed(() => {
    return canSubmit.value && hasChanges.value;
  });
  
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
    
    baseMonth.value = data.base_month;
    pharmacist.value = data.pharmacist;
    classification.value = data.classification;
    productName.value = data.product_name;
    insuranceCode.value = data.insurance_code;
    price.value = data.price;
    ingredient.value = data.Ingredient;
    comparator.value = data.comparator;
    reimbursement.value = data.reimbursement;
    bioequivalence.value = data.bioequivalence;
    inhouse.value = data.Inhouse;
    remarks.value = data.remarks;
    status.value = data.status;
    
    // 원본 데이터 저장 (수수료율은 백분율로 저장)
    originalData.value = {
      pharmacist: data.pharmacist,
      classification: data.classification,
      product_name: data.product_name,
      insurance_code: data.insurance_code,
      price: data.price,
      commission_rate_a: data.commission_rate_a !== null ? parseFloat(data.commission_rate_a) * 100 : null,
      commission_rate_b: data.commission_rate_b !== null ? parseFloat(data.commission_rate_b) * 100 : null,
      commission_rate_c: data.commission_rate_c !== null ? parseFloat(data.commission_rate_c) * 100 : null,
      Ingredient: data.Ingredient,
      comparator: data.comparator,
      reimbursement: data.reimbursement,
      bioequivalence: data.bioequivalence,
      Inhouse: data.Inhouse,
      remarks: data.remarks,
      status: data.status
    };
    
    // 수수료율을 % 단위로 변환하여 표시
    if (data.commission_rate_a !== null) commissionA.value = parseFloat(data.commission_rate_a) * 100;
    if (data.commission_rate_b !== null) commissionB.value = parseFloat(data.commission_rate_b) * 100;
    if (data.commission_rate_c !== null) commissionC.value = parseFloat(data.commission_rate_c) * 100;
  };
  
  onMounted(fetchProduct);
  
  const updateProduct = async () => {
    if (!pharmacist.value || !productName.value) {
      alert("제약사와 제품명을 모두 입력하세요.");
      return;
    }
    try {
      loading.value = true;
      const commissionAValue = commissionA.value !== undefined && commissionA.value !== null && commissionA.value !== '' ? parseFloat((parseFloat(commissionA.value) / 100).toFixed(3)) : null;
      const commissionBValue = commissionB.value !== undefined && commissionB.value !== null && commissionB.value !== '' ? parseFloat((parseFloat(commissionB.value) / 100).toFixed(3)) : null;
      const commissionCValue = commissionC.value !== undefined && commissionC.value !== null && commissionC.value !== '' ? parseFloat((parseFloat(commissionC.value) / 100).toFixed(3)) : null;
      
              const { error } = await supabase
          .from('products')
          .update({
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
          })
        .eq('id', productId);
        
      if (error) throw error;
      alert('제품 정보가 수정되었습니다.');
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
  