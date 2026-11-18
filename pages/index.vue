<template>
  <div>
    <!-- Project Header -->
    <div v-if="currentProject" class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">{{ currentProject.code }}</h1>
      <p class="text-sm text-gray-500 mt-1">{{ currentProject.name }}</p>
      <p v-if="currentProject.km_range" class="text-xs text-gray-400 mt-0.5">{{ currentProject.km_range }}</p>
    </div>
    <div v-else class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Dashboard</h1>
      <p class="text-sm text-gray-400">Chọn dự án để bắt đầu</p>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
      <div class="bg-white rounded-lg shadow-sm p-4 border">
        <p class="text-sm text-gray-500">Loại công trình</p>
        <p class="text-2xl font-bold text-primary-700">{{ stats.types }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-4 border">
        <p class="text-sm text-gray-500">Công trình</p>
        <p class="text-2xl font-bold text-primary-700">{{ stats.structures }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-4 border">
        <p class="text-sm text-gray-500">Nhật ký hôm nay</p>
        <p class="text-2xl font-bold text-green-600">{{ stats.todayEntries }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-4 border">
        <p class="text-sm text-gray-500">Tổng nhật ký</p>
        <p class="text-2xl font-bold text-gray-700">{{ stats.totalEntries }}</p>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="grid md:grid-cols-2 gap-4 mb-8">
      <NuxtLink to="/diary"
        class="bg-primary-600 text-white rounded-lg p-6 hover:bg-primary-700 transition flex items-center space-x-4">
        <span class="text-3xl">+</span>
        <div>
          <p class="font-semibold text-lg">Ghi nhật ký mới</p>
          <p class="text-primary-200 text-sm">Chọn công trình và ghi khối lượng hôm nay</p>
        </div>
      </NuxtLink>
      <NuxtLink to="/reports"
        class="bg-white border rounded-lg p-6 hover:bg-gray-50 transition flex items-center space-x-4">
        <span class="text-3xl text-gray-400">📊</span>
        <div>
          <p class="font-semibold text-lg text-gray-800">Xem báo cáo</p>
          <p class="text-gray-500 text-sm">Tổng hợp khối lượng và tiến độ</p>
        </div>
      </NuxtLink>
    </div>

    <!-- Recent Entries -->
    <div class="bg-white rounded-lg shadow-sm border">
      <div class="p-4 border-b">
        <h2 class="font-semibold text-gray-800">Nhật ký gần đây</h2>
      </div>
      <div v-if="recentEntries.length === 0" class="p-8 text-center text-gray-400">
        Chưa có nhật ký nào
      </div>
      <div v-else class="divide-y">
        <NuxtLink v-for="entry in recentEntries" :key="entry.id"
          :to="`/diary?date=${entry.entry_date}&structure=${entry.structure_id}`"
          class="block p-4 hover:bg-gray-50 transition">
          <div class="flex justify-between items-start">
            <div>
              <p class="font-medium text-gray-800">{{ entry.structures?.name }}</p>
              <p class="text-sm text-gray-500">
                {{ entry.structures?.structure_types?.name }} · {{ entry.entry_date }}
              </p>
            </div>
            <span :class="[
              'px-2 py-1 text-xs rounded-full',
              entry.is_locked ? 'bg-gray-100 text-gray-600' : 'bg-green-100 text-green-700'
            ]">
              {{ entry.is_locked ? 'Đã khóa' : 'Nháp' }}
            </span>
          </div>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { listEntries } = useDiary()
const { currentProject } = useProject()

const stats = ref({ types: 0, structures: 0, todayEntries: 0, totalEntries: 0 })
const recentEntries = ref<any[]>([])

onMounted(async () => {
  if (!currentProject.value) return

  const now = new Date()
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
  const pid = currentProject.value.id

  const [typesRes, structRes, todayRes, totalRes, recent] = await Promise.all([
    $supabase.from('structure_types').select('id', { count: 'exact', head: true }),
    $supabase.from('structures').select('id', { count: 'exact', head: true }).eq('project_id', pid),
    $supabase.from('diary_entries').select('id', { count: 'exact', head: true }).eq('project_id', pid).eq('entry_date', today),
    $supabase.from('diary_entries').select('id', { count: 'exact', head: true }).eq('project_id', pid),
    listEntries(),
  ])

  stats.value = {
    types: typesRes.count || 0,
    structures: structRes.count || 0,
    todayEntries: todayRes.count || 0,
    totalEntries: totalRes.count || 0,
  }
  recentEntries.value = recent.slice(0, 10)
})
</script>
