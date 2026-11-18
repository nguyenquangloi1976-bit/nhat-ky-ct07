<template>
  <div class="p-8 text-center text-gray-400">
    <template v-if="failed">
      Không tìm thấy nhật ký này.
      <NuxtLink to="/diary/history" class="text-primary-600 underline">Về danh sách</NuxtLink>
    </template>
    <template v-else>Đang mở nhật ký...</template>
  </div>
</template>

<script setup lang="ts">
// Trang sửa nhật ký cũ đã gộp vào /diary: mở đúng ngày và công trình của nhật ký này
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const route = useRoute()
const failed = ref(false)

onMounted(async () => {
  const { data } = await $supabase
    .from('diary_entries')
    .select('entry_date, structure_id')
    .eq('id', String(route.params.id))
    .maybeSingle()
  if (!data) {
    failed.value = true
    return
  }
  await navigateTo(
    { path: '/diary', query: { date: data.entry_date, structure: data.structure_id } },
    { replace: true },
  )
})
</script>
