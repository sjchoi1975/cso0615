<script setup>
import { ref, onMounted } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';

const products = ref([]);
const loading = ref(true);

onMounted(async () => {
  const { data, error } = await supabase.from('products').select('*');
  if (!error) {
    products.value = data;
  }
  loading.value = false;
});
</script>

<template>
  <div>
    <h2>요율표(제품 리스트)</h2>
    <DataTable :value="products" :loading="loading" responsiveLayout="scroll">
      <Column field="product_name" header="제품명" />
      <Column field="insurance_code" header="보험코드" />
      <Column field="price" header="약가" />
      <Column field="commission_rate_a" header="수수료 A" />
      <Column field="commission_rate_b" header="수수료 B" />
      <Column field="commission_rate_c" header="수수료 C" />
      <Column field="base_month" header="기준월" />
      <Column field="remarks" header="비고" />
      <Column field="status" header="상태" />
    </DataTable>
  </div>
</template>
