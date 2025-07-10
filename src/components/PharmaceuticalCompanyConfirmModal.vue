<template>
  <Dialog 
    v-model:visible="visible" 
    :modal="true"
    header="제약사 매핑"
    :style="{ width: '40rem' }"
    :breakpoints="{ '960px': '75vw', '641px': '90vw' }"
  >
    <div class="pharmaceutical-mapping">
      <div class="selected-companies">
        <h3>이용자가 선택한 제약사</h3>
        <div v-for="company in selectedCompanies" :key="company.id" class="company-item">
          <Checkbox v-model="confirmedCompanies" :value="company.id" />
          <span>{{ company.company_name }}</span>
        </div>
      </div>
      
      <Divider />
      
      <div class="unselected-companies">
        <h3>미선택 제약사 목록</h3>
        <div class="companies-list" style="max-height: 300px; overflow-y: auto;">
          <div v-for="company in unselectedCompanies" :key="company.id" class="company-item">
            <Checkbox v-model="confirmedCompanies" :value="company.id" />
            <span>{{ company.company_name }}</span>
          </div>
        </div>
      </div>
    </div>
    
    <template #footer>
      <Button label="취소" icon="pi pi-times" @click="onCancel" text />
      <Button label="확인" icon="pi pi-check" @click="onConfirm" autofocus />
    </template>
  </Dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { useSupabase } from '../supabase';

const supabase = useSupabase();

const props = defineProps({
  visible: {
    type: Boolean,
    required: true
  },
  selectedCompanies: {
    type: Array,
    required: true
  },
  fileId: {
    type: Number,
    required: true
  }
});

const emit = defineEmits(['update:visible', 'confirm']);

// 선택된 제약사 ID 목록
const confirmedCompanies = ref([]);

// 초기 선택된 제약사 설정
watch(() => props.selectedCompanies, (newCompanies) => {
  confirmedCompanies.value = newCompanies.map(c => c.id);
}, { immediate: true });

// 전체 제약사 목록
const allCompanies = ref([]);

// 미선택 제약사 목록 (가나다순 정렬)
const unselectedCompanies = computed(() => {
  return allCompanies.value
    .filter(company => !props.selectedCompanies.some(sc => sc.id === company.id))
    .sort((a, b) => a.company_name.localeCompare(b.company_name, 'ko'));
});

// 전체 제약사 목록 가져오기
const fetchCompanies = async () => {
  const { data, error } = await supabase
    .from('pharmaceutical_companies')
    .select('id, company_name')
    .eq('is_deleted', false);
    
  if (error) {
    console.error('Error fetching companies:', error);
    return;
  }
  
  allCompanies.value = data;
};

// 컴포넌트 마운트 시 제약사 목록 가져오기
fetchCompanies();

const onCancel = () => {
  emit('update:visible', false);
};

const onConfirm = () => {
  emit('confirm', confirmedCompanies.value);
  emit('update:visible', false);
};
</script>

<style scoped>
.pharmaceutical-mapping {
  padding: 1rem;
}

.company-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.companies-list {
  padding-right: 1rem;
}
</style> 