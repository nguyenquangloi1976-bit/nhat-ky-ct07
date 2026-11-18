<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Lịch sử nhật ký</h1>
      <NuxtLink to="/diary" class="text-sm text-primary-600 hover:underline">← Ghi nhật ký</NuxtLink>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <div>
          <label class="block text-xs text-gray-500 mb-1">Loại công trình</label>
          <select v-model="filters.typeId" @change="onTypeChange" class="input-sm w-full">
            <option value="">Tất cả</option>
            <option v-for="t in types" :key="t.id" :value="t.id">{{ t.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Công trình</label>
          <select v-model="filters.structureId" class="input-sm w-full">
            <option value="">Tất cả</option>
            <option v-for="s in filteredStructures" :key="s.id" :value="s.id">{{ s.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Từ ngày</label>
          <input v-model="filters.dateFrom" type="date" class="input-sm w-full" />
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Đến ngày</label>
          <input v-model="filters.dateTo" type="date" class="input-sm w-full" />
        </div>
      </div>
      <button @click="loadEntries" class="mt-3 px-4 py-1.5 bg-gray-100 text-gray-700 rounded text-sm hover:bg-gray-200">
        Lọc
      </button>
    </div>

    <!-- Entry list -->
    <div class="bg-white rounded-lg shadow-sm border">
      <div v-if="loading" class="p-8 text-center text-gray-400">Đang tải...</div>
      <div v-else-if="entries.length === 0" class="p-8 text-center text-gray-400">
        Không có nhật ký nào
      </div>
      <table v-else class="w-full text-sm">
        <thead class="bg-gray-50 text-gray-600">
          <tr>
            <th class="text-left px-4 py-3">Ngày</th>
            <th class="text-left px-4 py-3">Loại</th>
            <th class="text-left px-4 py-3">Công trình</th>
            <th class="text-left px-4 py-3">Người tạo</th>
            <th class="text-center px-4 py-3">Trạng thái</th>
            <th class="px-4 py-3 w-24"></th>
          </tr>
        </thead>
        <tbody class="divide-y">
          <tr v-for="e in entries" :key="e.id" class="hover:bg-gray-50">
            <td class="px-4 py-3">{{ formatDate(e.entry_date) }}</td>
            <td class="px-4 py-3 text-gray-500">{{ e.structures?.structure_types?.name }}</td>
            <td class="px-4 py-3 font-medium">{{ e.structures?.name }}</td>
            <td class="px-4 py-3 text-gray-500">{{ e.profiles?.full_name }}</td>
            <td class="px-4 py-3 text-center">
              <span :class="[
                'px-2 py-0.5 text-xs rounded-full',
                e.is_locked ? 'bg-gray-100 text-gray-600' : 'bg-green-100 text-green-700'
              ]">
                {{ e.is_locked ? 'Đã khóa' : 'Nháp' }}
              </span>
            </td>
            <td class="px-4 py-3 text-right space-x-2">
              <NuxtLink :to="`/diary?date=${e.entry_date}&structure=${e.structure_id}`" class="text-primary-600 hover:underline text-sm">
                {{ e.is_locked ? 'Xem' : 'Sửa' }}
              </NuxtLink>
              <button v-if="isAdmin" @click="confirmDeleteEntry(e)"
                class="text-red-500 hover:text-red-700 text-sm">Xoá</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { getTypes, getStructures } = useStructures()
const { listEntries, deleteEntry } = useDiary()
const { isAdmin } = useAuth()
const { success, error: showError } = useToast()

const types = ref<any[]>([])
const allStructures = ref<any[]>([])
const entries = ref<any[]>([])
const loading = ref(true)

const filters = reactive({
  typeId: '',
  structureId: '',
  dateFrom: '',
  dateTo: '',
})

const filteredStructures = computed(() => {
  if (!filters.typeId) return allStructures.value
  return allStructures.value.filter(s => s.type_id === filters.typeId)
})

function onTypeChange() { filters.structureId = '' }

function formatDate(dateStr: string) {
  if (!dateStr) return ''
  const [y, m, d] = dateStr.split('-')
  return `${d}/${m}/${y}`
}

async function loadEntries() {
  loading.value = true
  let result = await listEntries({
    structureId: filters.structureId || undefined,
    dateFrom: filters.dateFrom || undefined,
    dateTo: filters.dateTo || undefined,
  })
  if (filters.typeId && !filters.structureId) {
    const structIds = new Set(filteredStructures.value.map((s: any) => s.id))
    result = result.filter(e => structIds.has(e.structure_id))
  }
  entries.value = result
  loading.value = false
}

async function confirmDeleteEntry(e: any) {
  if (!confirm(`Xoá nhật ký ngày ${e.entry_date} — ${e.structures?.name}?`)) return
  try {
    await deleteEntry(e.id)
    entries.value = entries.value.filter(x => x.id !== e.id)
    success('Đã xoá')
  } catch (err: any) {
    showError(err.message)
  }
}

onMounted(async () => {
  [types.value, allStructures.value] = await Promise.all([getTypes(), getStructures()])
  await loadEntries()
})
</script>

<style scoped>
.input-sm {
  @apply px-3 py-1.5 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
</style>
