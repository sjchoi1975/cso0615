<template>
  <div>
    <DataTable :value="members" :loading="loading" responsiveLayout="scroll">
      <Column field="company_name" header="회사명" />
      <Column field="ceo_name" header="대표자명" />
      <Column field="manager_name" header="담당자명" />
      <Column field="email" header="이메일" />
      <Column field="approval" header="승인상태" />
      <Column field="created_at" header="가입일" />
      <Column header="관리">
        <template #body="slotProps">
          <button
            v-if="slotProps.data.approval !== 'approved'"
            class="btn btn-sm btn-approve"
            @click="approveMember(slotProps.data.id)"
          >승인</button>
        </template>
      </Column>
    </DataTable>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';

const members = ref([]);
const loading = ref(true);

onMounted(async () => {
  const { data, error } = await supabase.from('members')
    .select('*')
    .eq('role', 'user')
    .order('created_at', { ascending: false });
  if (!error) {
    members.value = data;
  }
  loading.value = false;
});

const approveMember = async (id) => {
  await supabase.from('members').update({ approval: 'approved' }).eq('id', id);
  // 목록 갱신
  const { data } = await supabase.from('members')
    .select('*')
    .eq('role', 'user')
    .order('created_at', { ascending: false });
  members.value = data;
};
</script>

