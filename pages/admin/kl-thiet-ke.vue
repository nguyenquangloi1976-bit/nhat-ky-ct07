<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Khối lượng thiết kế</h1>
        <p class="text-sm text-gray-500 mt-1">Khai báo khối lượng theo từng công trình — dùng để tính tỷ lệ hoàn thành</p>
      </div>
      <NuxtLink to="/admin" class="text-sm text-primary-600 hover:underline">← Quản trị</NuxtLink>
    </div>

    <!-- Type tabs -->
    <div class="flex gap-2 overflow-x-auto pb-2 mb-4 scrollbar-hide">
      <button v-for="t in types" :key="t.id"
        @click="selectType(t.id)"
        :class="[
          'px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition',
          selectedTypeId === t.id
            ? 'bg-primary-600 text-white'
            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
        ]">
        {{ t.name }} ({{ structCountByType[t.id] || 0 }})
      </button>
    </div>

    <!-- Structure selector -->
    <div v-if="structuresOfType.length" class="flex gap-2 overflow-x-auto pb-2 mb-4 scrollbar-hide">
      <button v-for="s in structuresOfType" :key="s.id"
        @click="selectStructure(s.id)"
        :class="[
          'px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap border transition',
          selectedStructureId === s.id
            ? 'bg-yellow-100 border-yellow-400 text-yellow-800'
            : 'bg-white border-gray-300 text-gray-600 hover:bg-gray-50'
        ]">
        {{ s.name }}
        <span v-if="completionByStruct[s.id] != null" class="ml-1 opacity-70">
          {{ completionByStruct[s.id] }}%
        </span>
      </button>
    </div>
    <div v-else-if="selectedTypeId" class="text-sm text-gray-400 mb-4">Chưa có công trình nào</div>

    <!-- Work items for selected structure -->
    <div v-if="selectedStructureId" class="bg-white rounded-lg shadow-sm border">
      <div class="px-4 py-3 border-b flex justify-between items-center">
        <div>
          <span class="font-semibold text-gray-800">{{ selectedStructure?.name }}</span>
          <span class="text-sm text-gray-400 ml-2">{{ items.length }} hạng mục</span>
        </div>
        <div class="flex gap-2">
          <button v-if="catalogMissing.length" @click="showImport = !showImport"
            class="text-xs px-3 py-1.5 rounded bg-blue-50 text-blue-700 hover:bg-blue-100">
            + Nhập từ danh mục ({{ catalogMissing.length }})
          </button>
          <button @click="showAddForm = !showAddForm"
            class="text-xs px-3 py-1.5 rounded bg-green-50 text-green-700 hover:bg-green-100">
            + Thêm hạng mục
          </button>
        </div>
      </div>

      <!-- Import from catalog -->
      <div v-if="showImport" class="px-4 py-3 bg-blue-50 border-b">
        <p class="text-xs text-blue-700 mb-2 font-medium">Chọn hạng mục từ danh mục mẫu để thêm:</p>
        <div class="flex flex-wrap gap-1.5 mb-2">
          <button v-for="c in catalogMissing" :key="c.id"
            @click="toggleCatalogItem(c)"
            :class="[
              'text-xs px-2 py-1 rounded border transition',
              selectedCatalogIds.has(c.id) ? 'bg-blue-600 text-white border-blue-600' : 'bg-white border-gray-300 hover:bg-blue-50'
            ]">
            {{ c.name }} ({{ c.unit }})
          </button>
        </div>
        <button v-if="selectedCatalogIds.size" @click="importFromCatalog"
          :disabled="importing"
          class="text-xs px-3 py-1.5 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50">
          {{ importing ? 'Đang thêm...' : `Thêm ${selectedCatalogIds.size} hạng mục` }}
        </button>
      </div>

      <!-- Add form -->
      <div v-if="showAddForm" class="px-4 py-3 bg-green-50 border-b">
        <form @submit.prevent="addItem" class="flex gap-2 items-end flex-wrap">
          <div>
            <label class="text-xs text-gray-600">Nhóm</label>
            <input v-model="newItem.group_name" class="input-sm" placeholder="Bê tông, Cốt thép..." />
          </div>
          <div>
            <label class="text-xs text-gray-600">Tên hạng mục</label>
            <input v-model="newItem.name" class="input-sm" placeholder="BT bệ trụ" required />
          </div>
          <div>
            <label class="text-xs text-gray-600">Đơn vị</label>
            <input v-model="newItem.unit" class="input-sm w-20" placeholder="m³" required />
          </div>
          <div>
            <label class="text-xs text-gray-600">KL thiết kế</label>
            <input v-model.number="newItem.design_quantity" type="number" step="any" class="input-sm w-28" placeholder="0" />
          </div>
          <button type="submit" class="text-xs px-3 py-2 bg-green-600 text-white rounded hover:bg-green-700">Thêm</button>
        </form>
      </div>

      <!-- Items table -->
      <div v-if="loadingItems" class="p-8 text-center text-gray-400">Đang tải...</div>
      <table v-else-if="items.length" class="w-full text-sm">
        <thead class="bg-gray-50 text-gray-500 text-xs uppercase">
          <tr>
            <th class="text-left px-4 py-2 w-10">#</th>
            <th class="text-left px-4 py-2">Hạng mục</th>
            <th class="text-left px-4 py-2 w-20">ĐV</th>
            <th class="text-right px-4 py-2 w-32">KL thiết kế</th>
            <th class="text-right px-4 py-2 w-32">KL thực hiện</th>
            <th class="text-right px-4 py-2 w-24">Tỷ lệ</th>
            <th class="px-4 py-2 w-10"></th>
          </tr>
        </thead>
        <tbody class="divide-y">
          <template v-for="(group, gIdx) in groupedItems" :key="gIdx">
            <tr class="bg-gray-50">
              <td colspan="7" class="px-4 py-1.5 text-xs font-bold text-gray-500 uppercase">
                {{ group.name }}
                <span class="font-normal ml-2">
                  ({{ groupCompletion(group) }})
                </span>
              </td>
            </tr>
            <tr v-for="(item, idx) in group.items" :key="item.id" class="hover:bg-gray-50">
              <td class="px-4 py-2 text-gray-400 text-xs">{{ idx + 1 }}</td>
              <td class="px-4 py-2 font-medium text-gray-800">{{ item.name }}</td>
              <td class="px-4 py-2 text-gray-500">{{ item.unit }}</td>
              <td class="px-4 py-2 text-right">
                <input
                  v-model.number="item._design"
                  type="number" step="any"
                  @blur="saveDesignQty(item)"
                  class="text-right w-full bg-transparent border-b border-transparent hover:border-gray-300 focus:border-primary-500 focus:outline-none py-0.5 text-sm"
                  :class="item._saving ? 'text-gray-400' : ''"
                />
              </td>
              <td class="px-4 py-2 text-right" :class="item._actual > 0 ? 'text-blue-700 font-medium' : 'text-gray-300'">
                {{ item._actual > 0 ? fmtNum(item._actual) : '—' }}
              </td>
              <td class="px-4 py-2 text-right">
                <span v-if="item._design > 0 && item._actual > 0"
                  :class="pctClass(item._actual / item._design * 100)">
                  {{ fmtPct(item._actual / item._design * 100) }}%
                </span>
                <span v-else class="text-gray-300">—</span>
              </td>
              <td class="px-4 py-2 text-right">
                <span v-if="item._saved" class="text-xs text-green-500">✓</span>
              </td>
            </tr>
          </template>
        </tbody>
        <!-- Total row -->
        <tfoot class="bg-gray-100 font-semibold text-sm">
          <tr>
            <td colspan="3" class="px-4 py-2 text-right">Tổng thể:</td>
            <td class="px-4 py-2 text-right">—</td>
            <td class="px-4 py-2 text-right">—</td>
            <td class="px-4 py-2 text-right" :class="pctClass(overallPct)">
              {{ overallPct != null ? fmtPct(overallPct) + '%' : '—' }}
            </td>
            <td></td>
          </tr>
        </tfoot>
      </table>
      <div v-else class="p-8 text-center text-gray-400 text-sm">
        Chưa có hạng mục nào. Thêm từ danh mục hoặc tạo mới.
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { isAdmin } = useAuth()
const { currentProject } = useProject()
const { getTypes, getStructures, getWorkItems, addWorkItem, addWorkItems, updateWorkItem } = useStructures()
const { error: showError } = useToast()
const router = useRouter()

const types = ref<any[]>([])
const allStructures = ref<any[]>([])
const selectedTypeId = ref('')
const selectedStructureId = ref('')
const items = ref<any[]>([])
const actualMap = ref<Record<string, number>>({}) // work_item_id → sum quantity
const catalogItems = ref<any[]>([])
const loadingItems = ref(false)
const showImport = ref(false)
const showAddForm = ref(false)
const importing = ref(false)
const selectedCatalogIds = ref(new Set<string>())

const newItem = reactive({ name: '', group_name: '', unit: '', design_quantity: null as number | null })

// Computed
const structCountByType = computed(() => {
  const m: Record<string, number> = {}
  for (const s of allStructures.value) {
    m[s.type_id] = (m[s.type_id] || 0) + 1
  }
  return m
})

const structuresOfType = computed(() =>
  allStructures.value.filter(s => s.type_id === selectedTypeId.value)
)

const selectedStructure = computed(() =>
  allStructures.value.find(s => s.id === selectedStructureId.value)
)

const selectedTypeCode = computed(() =>
  types.value.find(t => t.id === selectedTypeId.value)?.code || ''
)

const groupedItems = computed(() => {
  const groups: { name: string; items: any[] }[] = []
  const map = new Map<string, any[]>()
  for (const it of items.value) {
    const g = it.group_name || 'Khác'
    if (!map.has(g)) map.set(g, [])
    map.get(g)!.push(it)
  }
  for (const [name, list] of map) {
    groups.push({ name, items: list })
  }
  return groups
})

const catalogMissing = computed(() => {
  const have = new Set(items.value.map(i => i.name.toLowerCase()))
  return catalogItems.value.filter(c => !have.has(c.name.toLowerCase()))
})

// Completion per structure for the tab badges
const completionByStruct = ref<Record<string, number | null>>({})

const overallPct = computed(() => {
  let totalDesign = 0, totalActual = 0
  for (const it of items.value) {
    if (it._design > 0) {
      totalDesign += it._design
      totalActual += Math.min(it._actual, it._design) // cap at 100%
    }
  }
  if (totalDesign === 0) return null
  return totalActual / totalDesign * 100
})

// Methods
function fmtNum(n: number) {
  if (n == null) return '—'
  return n % 1 === 0 ? n.toLocaleString('vi-VN') : n.toLocaleString('vi-VN', { maximumFractionDigits: 2 })
}
function fmtPct(p: number) {
  return p.toFixed(1)
}
function pctClass(p: number | null) {
  if (p == null) return 'text-gray-300'
  if (p >= 100) return 'text-green-600 font-bold'
  if (p >= 70) return 'text-blue-600'
  if (p >= 30) return 'text-yellow-600'
  return 'text-gray-600'
}

function groupCompletion(group: { items: any[] }) {
  let d = 0, a = 0
  for (const it of group.items) {
    if (it._design > 0) { d += it._design; a += Math.min(it._actual, it._design) }
  }
  if (d === 0) return 'chưa có KL TK'
  return fmtPct(a / d * 100) + '%'
}

function selectType(typeId: string) {
  selectedTypeId.value = typeId
  selectedStructureId.value = ''
  items.value = []
  showImport.value = false
  showAddForm.value = false
}

async function selectStructure(structId: string) {
  selectedStructureId.value = structId
  showImport.value = false
  showAddForm.value = false
  await loadItems()
}

async function loadItems() {
  if (!selectedStructureId.value) return
  loadingItems.value = true
  try {
    const wi = await getWorkItems(selectedStructureId.value)

    // Load actual quantities from diary_lines
    const wiIds = wi.map(w => w.id)
    const actual: Record<string, number> = {}
    if (wiIds.length) {
      const { data: lines } = await $supabase
        .from('diary_lines')
        .select('work_item_id, quantity')
        .in('work_item_id', wiIds)
      for (const l of (lines || [])) {
        actual[l.work_item_id] = (actual[l.work_item_id] || 0) + Number(l.quantity)
      }
    }
    actualMap.value = actual

    items.value = wi.map(w => ({
      ...w,
      _design: w.design_quantity || 0,
      _actual: actual[w.id] || 0,
      _saving: false,
      _saved: false,
    }))

    // Load catalog
    await loadCatalog()
  } catch (e: any) {
    showError(e.message)
  } finally {
    loadingItems.value = false
  }
}

async function loadCatalog() {
  const code = selectedTypeCode.value
  if (!code) { catalogItems.value = []; return }
  const { data } = await $supabase
    .from('work_item_catalog')
    .select('*')
    .eq('type_code', code)
    .eq('is_active', true)
    .order('sort_order')
  catalogItems.value = data || []
}

async function saveDesignQty(item: any) {
  if (item._design === item.design_quantity) return
  item._saving = true
  item._saved = false
  try {
    await updateWorkItem(item.id, { design_quantity: item._design || 0 })
    item.design_quantity = item._design
    item._saved = true
    setTimeout(() => { item._saved = false }, 2000)
    updateStructCompletion(selectedStructureId.value)
  } catch (e: any) {
    showError(e.message)
  } finally {
    item._saving = false
  }
}

function toggleCatalogItem(c: any) {
  const s = selectedCatalogIds.value
  if (s.has(c.id)) s.delete(c.id)
  else s.add(c.id)
}

async function importFromCatalog() {
  importing.value = true
  try {
    const toAdd = catalogItems.value
      .filter(c => selectedCatalogIds.value.has(c.id))
      .map((c, i) => ({
        structure_id: selectedStructureId.value,
        name: c.name,
        unit: c.unit,
        group_name: c.group_name,
        design_quantity: 0,
        sort_order: (items.value.length + i + 1) * 10,
      }))
    await addWorkItems(toAdd)
    selectedCatalogIds.value.clear()
    showImport.value = false
    await loadItems()
  } catch (e: any) {
    showError(e.message)
  } finally {
    importing.value = false
  }
}

async function addItem() {
  try {
    await addWorkItem({
      structure_id: selectedStructureId.value,
      name: newItem.name,
      unit: newItem.unit,
      group_name: newItem.group_name,
      design_quantity: newItem.design_quantity || 0,
      sort_order: (items.value.length + 1) * 10,
    })
    newItem.name = ''
    newItem.unit = ''
    newItem.group_name = ''
    newItem.design_quantity = null
    await loadItems()
  } catch (e: any) {
    showError(e.message)
  }
}

function updateStructCompletion(structId: string) {
  const structItems = items.value
  let d = 0, a = 0
  for (const it of structItems) {
    if (it._design > 0) { d += it._design; a += Math.min(it._actual, it._design) }
  }
  completionByStruct.value[structId] = d > 0 ? Math.round(a / d * 100) : null
}

async function loadAllCompletions() {
  // For badge display on structure buttons — lightweight query
  if (!structuresOfType.value.length) return
  const ids = structuresOfType.value.map(s => s.id)

  // Get all work_items for these structures
  const { data: wiData } = await $supabase
    .from('work_items')
    .select('id, structure_id, design_quantity')
    .in('structure_id', ids)
  if (!wiData?.length) return

  const wiIds = wiData.map(w => w.id)
  const { data: lineData } = await $supabase
    .from('diary_lines')
    .select('work_item_id, quantity')
    .in('work_item_id', wiIds)

  const actualByWI: Record<string, number> = {}
  for (const l of (lineData || [])) {
    actualByWI[l.work_item_id] = (actualByWI[l.work_item_id] || 0) + Number(l.quantity)
  }

  const pctByStruct: Record<string, number | null> = {}
  const designByStruct: Record<string, number> = {}
  const actualByStruct: Record<string, number> = {}

  for (const wi of wiData) {
    const dq = Number(wi.design_quantity) || 0
    if (dq > 0) {
      designByStruct[wi.structure_id] = (designByStruct[wi.structure_id] || 0) + dq
      actualByStruct[wi.structure_id] = (actualByStruct[wi.structure_id] || 0) + Math.min(actualByWI[wi.id] || 0, dq)
    }
  }

  for (const s of structuresOfType.value) {
    const d = designByStruct[s.id] || 0
    pctByStruct[s.id] = d > 0 ? Math.round((actualByStruct[s.id] || 0) / d * 100) : null
  }
  completionByStruct.value = { ...completionByStruct.value, ...pctByStruct }
}

watch(() => selectedTypeId.value, () => { loadAllCompletions() })

onMounted(async () => {
  if (!isAdmin.value) { router.push('/'); return }
  try {
    types.value = await getTypes()
    allStructures.value = await getStructures()
    if (types.value.length) {
      selectedTypeId.value = types.value[0].id
      await loadAllCompletions()
    }
  } catch (e: any) {
    showError(e.message)
  }
})
</script>

<style scoped>
.input-sm {
  @apply px-2 py-1.5 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
.scrollbar-hide::-webkit-scrollbar { display: none; }
.scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
</style>
