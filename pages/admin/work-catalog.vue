<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Danh mục hạng mục khối lượng</h1>
        <p class="text-sm text-gray-500 mt-1">Quản lý danh mục chung — gán cho từng dự án khi tạo</p>
      </div>
      <NuxtLink to="/admin" class="text-sm text-primary-600 hover:underline">← Quản trị</NuxtLink>
    </div>

    <!-- Project selector -->
    <div class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="flex items-center gap-4">
        <label class="text-sm font-medium text-gray-700 whitespace-nowrap">Dự án:</label>
        <select v-model="selectedProjectId" @change="onProjectChange" class="input-field flex-1 max-w-xs">
          <option value="">-- Chọn dự án --</option>
          <option v-for="p in allProjects" :key="p.id" :value="p.id">
            {{ p.code }} — {{ p.name }}
          </option>
        </select>
        <span v-if="selectedProjectId && structureTypes.length" class="text-xs text-gray-400">
          {{ structureTypes.length }} loại công trình
        </span>
      </div>
    </div>

    <!-- Chưa chọn dự án -->
    <div v-if="!selectedProjectId" class="bg-white rounded-lg shadow-sm border p-12 text-center text-gray-400">
      Chọn dự án ở trên để xem danh mục hạng mục khối lượng
    </div>

    <template v-else>
      <!-- Structure Type Tabs (from DB) -->
      <div class="bg-white rounded-lg shadow-sm border p-4 mb-4">
        <div v-if="structureTypes.length" class="flex space-x-2 overflow-x-auto">
          <button v-for="t in structureTypes" :key="t.code"
            @click="selectedType = t.code"
            :class="[
              'px-4 py-2 rounded-lg text-sm whitespace-nowrap transition',
              selectedType === t.code
                ? 'bg-primary-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]">
            {{ t.name }}
            <span class="ml-1 opacity-70">({{ getCatalogCount(t.code) }})</span>
          </button>
        </div>
        <div v-else class="text-center text-gray-400 text-sm py-4">
          Dự án chưa có loại công trình nào. Vào <NuxtLink to="/admin/projects" class="text-primary-600 underline">Quản lý dự án</NuxtLink> để thêm.
        </div>
      </div>

      <!-- Add new item form -->
      <div v-if="selectedType" class="bg-white rounded-lg shadow-sm border p-4 mb-4">
        <h3 class="font-semibold text-gray-700 mb-3">Thêm hạng mục mới vào danh mục</h3>
        <div class="grid grid-cols-1 md:grid-cols-5 gap-3 items-end">
          <div>
            <label class="block text-xs text-gray-500 mb-1">Nhóm</label>
            <input v-model="newItem.group_name" class="input-field w-full" placeholder="Bê tông, Cốt thép..."
              list="group-suggestions" />
            <datalist id="group-suggestions">
              <option v-for="g in groupsForType" :key="g" :value="g" />
            </datalist>
          </div>
          <div class="md:col-span-2">
            <label class="block text-xs text-gray-500 mb-1">Tên hạng mục</label>
            <input v-model="newItem.name" class="input-field w-full" placeholder="VD: Bê tông mố M1" />
          </div>
          <div>
            <label class="block text-xs text-gray-500 mb-1">Đơn vị</label>
            <input v-model="newItem.unit" class="input-field w-full" placeholder="m³, tấn, m²..." />
          </div>
          <div>
            <button @click="addCatalogItem"
              :disabled="!newItem.group_name || !newItem.name || !newItem.unit"
              class="w-full px-4 py-2 bg-primary-600 text-white rounded-lg text-sm hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed">
              + Thêm
            </button>
          </div>
        </div>
      </div>

      <!-- Catalog Items Table -->
      <div v-if="selectedType" class="bg-white rounded-lg shadow-sm border">
        <div class="p-4 border-b flex justify-between items-center">
          <h2 class="font-semibold text-gray-700">
            Hạng mục — {{ structureTypes.find(t => t.code === selectedType)?.name }}
          </h2>
          <span class="text-xs text-gray-400">{{ filteredCatalog.length }} hạng mục</span>
        </div>

        <div v-if="loading" class="p-8 text-center text-gray-400">Đang tải...</div>
        <div v-else-if="filteredCatalog.length === 0" class="p-8 text-center text-gray-400">
          Chưa có hạng mục nào cho loại công trình này
        </div>
        <div v-else>
          <!-- Group by group_name -->
          <div v-for="group in groupedCatalog" :key="group.name">
            <div class="px-4 py-2 bg-gray-50 border-y text-xs font-semibold text-gray-500 uppercase tracking-wide">
              {{ group.name }}
            </div>
            <table class="w-full text-sm">
              <tbody class="divide-y">
                <tr v-for="item in group.items" :key="item.id" class="hover:bg-gray-50">
                  <td class="px-4 py-2.5 font-medium text-gray-800 w-1/2">
                    {{ item.name }}
                  </td>
                  <td class="px-4 py-2.5 text-gray-500 w-24 text-center">
                    {{ item.unit }}
                  </td>
                  <td class="px-4 py-2.5 w-20 text-center">
                    <span :class="[
                      'px-2 py-0.5 text-xs rounded-full',
                      item.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                    ]">
                      {{ item.is_active ? 'Hoạt động' : 'Ẩn' }}
                    </span>
                  </td>
                  <td class="px-4 py-2.5 text-right w-40">
                    <button @click="toggleActive(item)"
                      class="text-xs mr-3"
                      :class="item.is_active ? 'text-gray-400 hover:text-gray-600' : 'text-green-500 hover:text-green-700'">
                      {{ item.is_active ? 'Ẩn' : 'Hiện' }}
                    </button>
                    <button @click="deleteCatalogItem(item)" class="text-xs text-red-400 hover:text-red-600">
                      Xóa
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Assign to Structure Section -->
      <div v-if="selectedType" class="mt-6 bg-white rounded-lg shadow-sm border">
        <div class="p-4 border-b">
          <h2 class="font-semibold text-gray-700">Gán hạng mục cho công trình</h2>
          <p class="text-sm text-gray-500 mt-1">Chọn công trình, sau đó chọn các hạng mục từ danh mục để gán</p>
        </div>

        <div class="p-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label class="block text-xs text-gray-500 mb-1">Chọn công trình</label>
              <select v-model="assignStructureId" @change="loadStructureWorkItems" class="input-field w-full">
                <option value="">-- Chọn --</option>
                <option v-for="s in structuresForType" :key="s.id" :value="s.id">{{ s.name }}</option>
              </select>
            </div>
            <div v-if="assignStructureId" class="flex items-end">
              <p class="text-sm text-gray-500">
                Đã gán: <span class="font-semibold text-gray-800">{{ assignedItems.length }}</span> hạng mục
              </p>
            </div>
          </div>

          <!-- Checkbox list of catalog items to assign -->
          <div v-if="assignStructureId">
            <div v-for="group in groupedCatalog" :key="'assign-' + group.name" class="mb-3">
              <div class="flex items-center mb-1">
                <input type="checkbox"
                  :checked="isGroupFullyAssigned(group)"
                  :indeterminate.prop="isGroupPartiallyAssigned(group)"
                  @change="toggleGroupAssign(group, $event)"
                  class="mr-2" />
                <span class="text-xs font-semibold text-gray-500 uppercase tracking-wide">{{ group.name }}</span>
              </div>
              <div class="ml-6 space-y-1">
                <label v-for="item in group.items.filter(i => i.is_active)" :key="'cb-' + item.id"
                  class="flex items-center text-sm cursor-pointer hover:bg-gray-50 py-0.5 px-2 rounded">
                  <input type="checkbox"
                    :checked="isItemAssigned(item)"
                    @change="toggleItemAssign(item, $event)"
                    class="mr-2" />
                  <span>{{ item.name }}</span>
                  <span class="ml-2 text-gray-400 text-xs">({{ item.unit }})</span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { isAdmin } = useAuth()
const { getStructures, addWorkItem, deleteWorkItem } = useStructures()
const { success, error: showError } = useToast()
const router = useRouter()

// Project dropdown
const allProjects = ref<any[]>([])
const selectedProjectId = ref('')

// Structure types loaded from DB per project
const structureTypes = ref<{ id: string; code: string; name: string }[]>([])

const selectedType = ref('')
const loading = ref(true)
const catalog = ref<any[]>([])
const allStructures = ref<any[]>([])

// Assign section
const assignStructureId = ref('')
const assignedItems = ref<any[]>([])

const newItem = reactive({ group_name: '', name: '', unit: '' })

// Computed
const filteredCatalog = computed(() =>
  catalog.value.filter(c => c.type_code === selectedType.value)
)

const groupsForType = computed(() => {
  const groups = new Set(filteredCatalog.value.map(c => c.group_name))
  return Array.from(groups)
})

const groupedCatalog = computed(() => {
  const map = new Map<string, any[]>()
  for (const item of filteredCatalog.value) {
    if (!map.has(item.group_name)) map.set(item.group_name, [])
    map.get(item.group_name)!.push(item)
  }
  const result: { name: string; items: any[] }[] = []
  for (const [name, items] of map.entries()) {
    items.sort((a: any, b: any) => (a.sort_order || 0) - (b.sort_order || 0))
    result.push({ name, items })
  }
  return result
})

const structuresForType = computed(() => {
  return allStructures.value.filter((s: any) =>
    s.structure_types?.code === selectedType.value
  )
})

function getCatalogCount(typeCode: string) {
  return catalog.value.filter(c => c.type_code === typeCode && c.is_active).length
}

// --- Project change ---
async function onProjectChange() {
  structureTypes.value = []
  selectedType.value = ''
  assignStructureId.value = ''
  assignedItems.value = []
  allStructures.value = []

  if (!selectedProjectId.value) return

  // Load structure_types for the selected project
  const { data: types } = await $supabase
    .from('structure_types')
    .select('id, code, name')
    .eq('project_id', selectedProjectId.value)
    .order('sort_order')

  structureTypes.value = types || []

  // Auto-select first tab
  if (structureTypes.value.length) {
    selectedType.value = structureTypes.value[0].code
  }

  // Load structures for this project
  const { data: structs } = await $supabase
    .from('structures')
    .select('*, structure_types(*)')
    .eq('project_id', selectedProjectId.value)
    .order('sort_order')
  allStructures.value = structs || []
}

// --- Load catalog (all projects, type_code based) ---
async function loadCatalog() {
  const { data, error: err } = await $supabase
    .from('work_item_catalog')
    .select('*')
    .order('sort_order')
  if (err) {
    showError(err.message)
    return
  }
  catalog.value = data || []
}

async function loadStructureWorkItems() {
  if (!assignStructureId.value) {
    assignedItems.value = []
    return
  }
  const { data, error: err } = await $supabase
    .from('work_items')
    .select('*')
    .eq('structure_id', assignStructureId.value)
  if (err) {
    showError(err.message)
    return
  }
  assignedItems.value = data || []
}

// Add catalog item
async function addCatalogItem() {
  try {
    const maxSort = filteredCatalog.value.reduce((max: number, c: any) => Math.max(max, c.sort_order || 0), 0)
    const { error: err } = await $supabase
      .from('work_item_catalog')
      .insert({
        type_code: selectedType.value,
        group_name: newItem.group_name,
        name: newItem.name,
        unit: newItem.unit,
        sort_order: maxSort + 1,
      })
    if (err) throw err
    Object.assign(newItem, { group_name: '', name: '', unit: '' })
    await loadCatalog()
    success('Đã thêm hạng mục vào danh mục')
  } catch (e: any) {
    showError(e.message)
  }
}

// Toggle active
async function toggleActive(item: any) {
  try {
    const { error: err } = await $supabase
      .from('work_item_catalog')
      .update({ is_active: !item.is_active })
      .eq('id', item.id)
    if (err) throw err
    item.is_active = !item.is_active
  } catch (e: any) {
    showError(e.message)
  }
}

// Delete catalog item
async function deleteCatalogItem(item: any) {
  if (!confirm(`Xóa hạng mục "${item.name}" khỏi danh mục?`)) return
  try {
    const { error: err } = await $supabase
      .from('work_item_catalog')
      .delete()
      .eq('id', item.id)
    if (err) throw err
    catalog.value = catalog.value.filter(c => c.id !== item.id)
    success('Đã xóa')
  } catch (e: any) {
    showError(e.message)
  }
}

// Assign/unassign
function isItemAssigned(catalogItem: any) {
  return assignedItems.value.some(
    (wi: any) => wi.name === catalogItem.name && wi.group_name === catalogItem.group_name
  )
}

function isGroupFullyAssigned(group: { name: string; items: any[] }) {
  const activeItems = group.items.filter(i => i.is_active)
  return activeItems.length > 0 && activeItems.every(i => isItemAssigned(i))
}

function isGroupPartiallyAssigned(group: { name: string; items: any[] }) {
  const activeItems = group.items.filter(i => i.is_active)
  const assignedCount = activeItems.filter(i => isItemAssigned(i)).length
  return assignedCount > 0 && assignedCount < activeItems.length
}

async function toggleItemAssign(catalogItem: any, event: Event) {
  const checked = (event.target as HTMLInputElement).checked
  try {
    if (checked) {
      await addWorkItem({
        structure_id: assignStructureId.value,
        group_name: catalogItem.group_name,
        name: catalogItem.name,
        unit: catalogItem.unit,
        design_quantity: null,
        sort_order: catalogItem.sort_order || 0,
      })
      success(`Đã gán "${catalogItem.name}"`)
    } else {
      const existing = assignedItems.value.find(
        (wi: any) => wi.name === catalogItem.name && wi.group_name === catalogItem.group_name
      )
      if (existing) {
        await deleteWorkItem(existing.id)
        success(`Đã bỏ gán "${catalogItem.name}"`)
      }
    }
    await loadStructureWorkItems()
  } catch (e: any) {
    showError(e.message)
  }
}

async function toggleGroupAssign(group: { name: string; items: any[] }, event: Event) {
  const checked = (event.target as HTMLInputElement).checked
  const activeItems = group.items.filter(i => i.is_active)

  for (const item of activeItems) {
    const alreadyAssigned = isItemAssigned(item)
    if (checked && !alreadyAssigned) {
      try {
        await addWorkItem({
          structure_id: assignStructureId.value,
          group_name: item.group_name,
          name: item.name,
          unit: item.unit,
          design_quantity: null,
          sort_order: item.sort_order || 0,
        })
      } catch { /* ignore duplicates */ }
    } else if (!checked && alreadyAssigned) {
      const existing = assignedItems.value.find(
        (wi: any) => wi.name === item.name && wi.group_name === item.group_name
      )
      if (existing) {
        try { await deleteWorkItem(existing.id) } catch { /* ignore */ }
      }
    }
  }

  await loadStructureWorkItems()
  success(checked ? `Đã gán nhóm "${group.name}"` : `Đã bỏ gán nhóm "${group.name}"`)
}

onMounted(async () => {
  if (!isAdmin.value) {
    router.push('/')
    return
  }

  loading.value = true

  // Load all projects for dropdown
  const { data: projects } = await $supabase
    .from('projects')
    .select('id, code, name')
    .order('code')
  allProjects.value = projects || []

  await loadCatalog()
  loading.value = false
})
</script>

<style scoped>
.input-field {
  @apply px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500;
}
</style>
