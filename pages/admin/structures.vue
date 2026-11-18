<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Công trình & Hạng mục</h1>
      <NuxtLink to="/admin" class="text-sm text-primary-600 hover:underline">← Quản trị</NuxtLink>
    </div>

    <!-- Structure Types -->
    <div class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="flex items-center space-x-2 overflow-x-auto">
        <button v-for="t in types" :key="t.id"
          @click="selectedTypeId = t.id"
          :class="[
            'px-4 py-2 rounded-lg text-sm whitespace-nowrap',
            selectedTypeId === t.id
              ? 'bg-primary-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]">
          {{ t.name }}
          <span class="ml-1 opacity-70">({{ getCount(t.id) }})</span>
        </button>
        <button @click="showAddType = true"
          class="px-3 py-2 rounded-lg text-sm whitespace-nowrap border-2 border-dashed border-gray-300 text-gray-400 hover:border-primary-400 hover:text-primary-600">
          + Loại mới
        </button>
      </div>
      <div v-if="selectedTypeId && types.length > 0" class="mt-2 flex items-center space-x-2 text-xs text-gray-400">
        <span>{{ selectedTypeName }}</span>
        <button @click="deleteTypeConfirm" class="text-red-400 hover:text-red-600">Xóa loại này</button>
      </div>
    </div>

    <!-- Structures List -->
    <div class="bg-white rounded-lg shadow-sm border mb-4">
      <div class="p-4 border-b flex justify-between items-center">
        <h2 class="font-semibold text-gray-700">Danh sách công trình</h2>
        <button @click="showAddStructure = true"
          class="px-3 py-1 bg-primary-600 text-white rounded text-sm hover:bg-primary-700">
          + Thêm
        </button>
      </div>

      <div v-if="filteredStructures.length === 0" class="p-8 text-center text-gray-400">
        Chưa có công trình nào
      </div>
      <div v-else class="divide-y">
        <div v-for="s in filteredStructures" :key="s.id"
          class="p-4 hover:bg-gray-50 cursor-pointer"
          @click="selectStructure(s)">
          <div class="flex justify-between items-center">
            <div>
              <p class="font-medium text-gray-800">{{ s.name }}</p>
              <p class="text-xs text-gray-400">
                {{ s.km_start || '' }}{{ s.km_end ? ' → ' + s.km_end : '' }}
                <span v-if="s.has_left_right" class="ml-2 text-primary-500">T/P</span>
              </p>
            </div>
            <span class="text-xs text-gray-400">{{ getWorkItemCount(s.id) }} hạng mục</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Work Items for selected structure -->
    <div v-if="selectedStructure" class="bg-white rounded-lg shadow-sm border">
      <div class="p-4 border-b flex justify-between items-center">
        <h2 class="font-semibold text-gray-700">
          Hạng mục — {{ selectedStructure.name }}
        </h2>
        <button @click="showAddWorkItem = true"
          class="px-3 py-1 bg-primary-600 text-white rounded text-sm hover:bg-primary-700">
          + Thêm hạng mục
        </button>
      </div>

      <table class="w-full text-sm">
        <thead class="bg-gray-50 text-gray-600">
          <tr>
            <th class="text-left px-4 py-2">Nhóm</th>
            <th class="text-left px-4 py-2">Tên hạng mục</th>
            <th class="text-center px-4 py-2">Đơn vị</th>
            <th class="text-right px-4 py-2">KL thiết kế</th>
            <th class="text-center px-4 py-2">Thứ tự</th>
            <th class="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody class="divide-y">
          <tr v-for="wi in workItems" :key="wi.id" class="hover:bg-gray-50">
            <td class="px-4 py-2 text-gray-500">{{ wi.group_name }}</td>
            <td class="px-4 py-2 font-medium">{{ wi.name }}</td>
            <td class="px-4 py-2 text-center text-gray-500">{{ wi.unit }}</td>
            <td class="px-4 py-2 text-right">{{ wi.design_quantity ?? '—' }}</td>
            <td class="px-4 py-2 text-center text-gray-400">{{ wi.sort_order }}</td>
            <td class="px-4 py-2 text-right">
              <button @click="deleteWorkItemConfirm(wi)" class="text-red-400 hover:text-red-600 text-xs">
                Xóa
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Add Structure Modal -->
    <div v-if="showAddStructure" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click.self="showAddStructure = false">
      <div class="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 class="font-semibold text-gray-800 mb-4">Thêm công trình mới</h3>
        <div class="space-y-3">
          <div>
            <label class="block text-sm text-gray-600 mb-1">Tên công trình</label>
            <input v-model="newStructure.name" class="input-field w-full" placeholder="VD: Cầu Sông Công" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">Km bắt đầu</label>
              <input v-model="newStructure.km_start" class="input-field w-full" placeholder="Km64+200" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">Km kết thúc</label>
              <input v-model="newStructure.km_end" class="input-field w-full" placeholder="Km64+800" />
            </div>
          </div>
          <label class="flex items-center space-x-2 text-sm">
            <input type="checkbox" v-model="newStructure.has_left_right" />
            <span>Phân biệt Trái / Phải</span>
          </label>
        </div>
        <div class="mt-4 flex justify-end space-x-3">
          <button @click="showAddStructure = false" class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800">
            Hủy
          </button>
          <button @click="addStructureSubmit" :disabled="!newStructure.name"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg text-sm hover:bg-primary-700 disabled:opacity-50">
            Thêm
          </button>
        </div>
      </div>
    </div>

    <!-- Add Type Modal -->
    <div v-if="showAddType" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click.self="showAddType = false">
      <div class="bg-white rounded-xl p-6 w-full max-w-sm">
        <h3 class="font-semibold text-gray-800 mb-4">Thêm loại công trình</h3>
        <div class="space-y-3">
          <div>
            <label class="block text-sm text-gray-600 mb-1">Mã loại</label>
            <input v-model="newType.code" class="input-field w-full" placeholder="VD: CAU, DUONG, HAM..." />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">Tên loại</label>
            <input v-model="newType.name" class="input-field w-full" placeholder="VD: Cầu, Đường, Hầm..." />
          </div>
        </div>
        <div class="mt-4 flex justify-end space-x-3">
          <button @click="showAddType = false" class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800">Hủy</button>
          <button @click="addTypeSubmit" :disabled="!newType.code || !newType.name"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg text-sm hover:bg-primary-700 disabled:opacity-50">
            Thêm
          </button>
        </div>
      </div>
    </div>

    <!-- Add Work Item Modal -->
    <div v-if="showAddWorkItem" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click.self="showAddWorkItem = false">
      <div class="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 class="font-semibold text-gray-800 mb-4">Thêm hạng mục</h3>
        <div class="space-y-3">
          <div>
            <label class="block text-sm text-gray-600 mb-1">Nhóm</label>
            <input v-model="newWorkItem.group_name" class="input-field w-full" placeholder="VD: Bê tông, Cốt thép..." />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">Tên hạng mục</label>
            <input v-model="newWorkItem.name" class="input-field w-full" placeholder="VD: Bê tông mố M1" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">Đơn vị</label>
              <input v-model="newWorkItem.unit" class="input-field w-full" placeholder="m³, tấn..." />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">KL thiết kế</label>
              <input v-model.number="newWorkItem.design_quantity" type="number" class="input-field w-full" />
            </div>
          </div>
        </div>
        <div class="mt-4 flex justify-end space-x-3">
          <button @click="showAddWorkItem = false" class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800">
            Hủy
          </button>
          <button @click="addWorkItemSubmit" :disabled="!newWorkItem.name || !newWorkItem.unit"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg text-sm hover:bg-primary-700 disabled:opacity-50">
            Thêm
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { getTypes, addType, deleteType, getStructures, getWorkItems, addWorkItem, deleteWorkItem, addStructure: composableAddStructure } = useStructures()
const { isAdmin } = useAuth()
const { success, error: showError } = useToast()
const router = useRouter()

const types = ref<any[]>([])
const allStructures = ref<any[]>([])
const selectedTypeId = ref('')
const selectedStructure = ref<any>(null)
const workItems = ref<any[]>([])
const workItemCounts = ref<Record<string, number>>({})

const showAddStructure = ref(false)
const showAddWorkItem = ref(false)
const showAddType = ref(false)

const newStructure = reactive({ name: '', km_start: '', km_end: '', has_left_right: false })
const newWorkItem = reactive({ group_name: '', name: '', unit: '', design_quantity: null as number | null })
const newType = reactive({ code: '', name: '' })

const selectedTypeName = computed(() => {
  const t = types.value.find(t => t.id === selectedTypeId.value)
  return t?.name || ''
})

const filteredStructures = computed(() =>
  allStructures.value.filter(s => s.type_id === selectedTypeId.value)
)

function getCount(typeId: string) {
  return allStructures.value.filter(s => s.type_id === typeId).length
}

function getWorkItemCount(structureId: string) {
  return workItemCounts.value[structureId] || '?'
}

async function selectStructure(s: any) {
  selectedStructure.value = s
  workItems.value = await getWorkItems(s.id)
}

async function addTypeSubmit() {
  try {
    await addType({
      code: newType.code.toUpperCase(),
      name: newType.name,
      sort_order: types.value.length + 1,
    } as any)
    showAddType.value = false
    Object.assign(newType, { code: '', name: '' })
    types.value = await getTypes()
    if (types.value.length === 1) {
      selectedTypeId.value = types.value[0].id
    }
    success('Đã thêm loại công trình')
  } catch (e: any) {
    showError(e.message)
  }
}

async function deleteTypeConfirm() {
  const t = types.value.find(t => t.id === selectedTypeId.value)
  if (!t) return
  const count = getCount(t.id)
  if (count > 0) {
    if (!confirm(`Loại "${t.name}" có ${count} công trình. Xóa sẽ xóa tất cả công trình và hạng mục bên trong!\nBạn chắc chắn?`)) return
  } else {
    if (!confirm(`Xóa loại "${t.name}"?`)) return
  }
  try {
    await deleteType(t.id)
    types.value = await getTypes()
    allStructures.value = await getStructures()
    selectedTypeId.value = types.value.length > 0 ? types.value[0].id : ''
    selectedStructure.value = null
    workItems.value = []
    success('Đã xóa loại công trình')
  } catch (e: any) {
    showError(e.message)
  }
}

async function addStructureSubmit() {
  try {
    await composableAddStructure({
      type_id: selectedTypeId.value,
      code: newStructure.name.replace(/\s+/g, '_').toUpperCase().slice(0, 20),
      name: newStructure.name,
      station: [newStructure.km_start, newStructure.km_end].filter(Boolean).join(' → ') || null,
      has_left_right: newStructure.has_left_right,
    } as any)
    showAddStructure.value = false
    Object.assign(newStructure, { name: '', km_start: '', km_end: '', has_left_right: false })
    allStructures.value = await getStructures()
    success('Đã thêm công trình')
  } catch (e: any) {
    showError(e.message)
  }
}

async function addWorkItemSubmit() {
  try {
    await addWorkItem({
      structure_id: selectedStructure.value.id,
      group_name: newWorkItem.group_name || 'Khác',
      name: newWorkItem.name,
      unit: newWorkItem.unit,
      design_quantity: newWorkItem.design_quantity,
      sort_order: workItems.value.length + 1,
    })
    showAddWorkItem.value = false
    Object.assign(newWorkItem, { group_name: '', name: '', unit: '', design_quantity: null })
    workItems.value = await getWorkItems(selectedStructure.value.id)
    success('Đã thêm hạng mục')
  } catch (e: any) {
    showError(e.message)
  }
}

async function deleteWorkItemConfirm(wi: any) {
  if (!confirm(`Xóa hạng mục "${wi.name}"?`)) return
  try {
    await deleteWorkItem(wi.id)
    workItems.value = workItems.value.filter(w => w.id !== wi.id)
    success('Đã xóa hạng mục')
  } catch (e: any) {
    showError(e.message)
  }
}

onMounted(async () => {
  if (!isAdmin.value) {
    router.push('/')
    return
  }

  [types.value, allStructures.value] = await Promise.all([getTypes(), getStructures()])
  if (types.value.length > 0) {
    selectedTypeId.value = types.value[0].id
  }

  // Load work item counts
  const { $supabase } = useNuxtApp()
  const { data: counts } = await $supabase
    .from('work_items')
    .select('structure_id')
  if (counts) {
    const map: Record<string, number> = {}
    for (const c of counts) {
      map[c.structure_id] = (map[c.structure_id] || 0) + 1
    }
    workItemCounts.value = map
  }
})
</script>

<style scoped>
.input-field {
  @apply px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500;
}
.input-xs {
  @apply px-2 py-1 border border-gray-300 rounded text-sm;
}
</style>
