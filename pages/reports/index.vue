<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-800 mb-6">Báo cáo tổng hợp</h1>

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

      <!-- Quick date filters + actions -->
      <div class="mt-3 flex flex-wrap items-center gap-2">
        <button @click="setDateRange('week')"
          :class="['px-3 py-1.5 rounded text-sm border transition',
            activePeriod === 'week' ? 'bg-primary-100 border-primary-400 text-primary-700' : 'bg-gray-50 border-gray-300 text-gray-600 hover:border-primary-400']">
          Tuần này
        </button>
        <button @click="setDateRange('month')"
          :class="['px-3 py-1.5 rounded text-sm border transition',
            activePeriod === 'month' ? 'bg-primary-100 border-primary-400 text-primary-700' : 'bg-gray-50 border-gray-300 text-gray-600 hover:border-primary-400']">
          Tháng này
        </button>
        <button @click="setDateRange('all')"
          :class="['px-3 py-1.5 rounded text-sm border transition',
            activePeriod === 'all' ? 'bg-primary-100 border-primary-400 text-primary-700' : 'bg-gray-50 border-gray-300 text-gray-600 hover:border-primary-400']">
          Toàn bộ
        </button>

        <div class="flex-1"></div>

        <label class="flex items-center gap-1.5 text-sm text-gray-600 cursor-pointer select-none">
          <input type="checkbox" v-model="onlyWithQuantity" class="rounded border-gray-300 text-primary-600 focus:ring-primary-500" />
          Chỉ hiện có KL
        </label>

        <button @click="loadReport" :disabled="loadingData"
          class="px-4 py-1.5 bg-primary-600 text-white rounded text-sm hover:bg-primary-700 disabled:opacity-50">
          {{ loadingData ? 'Đang tải...' : 'Xem báo cáo' }}
        </button>
        <button @click="exportExcel" :disabled="displayData.length === 0"
          class="px-4 py-1.5 bg-green-600 text-white rounded text-sm hover:bg-green-700 disabled:opacity-50">
          Xuất Excel
        </button>
        <button @click="recalcVolumes" :disabled="recalcBusy"
          class="px-4 py-1.5 bg-amber-600 text-white rounded text-sm hover:bg-amber-700 disabled:opacity-50"
          title="Tính lại khối lượng từ ĐTPL cho tất cả hạng mục (K95, K98, XLNDY, BUL)">
          {{ recalcBusy ? `Đang tính (${recalcProgress})...` : '⚡ Tính lại KL (ĐTPL)' }}
        </button>
      </div>
    </div>

    <!-- Recalc result -->
    <div v-if="recalcResult" class="bg-amber-50 border border-amber-200 rounded-lg p-3 mb-4 text-sm">
      <span class="font-medium text-amber-800">{{ recalcResult }}</span>
      <button @click="recalcResult = ''" class="ml-2 text-amber-600 hover:underline text-xs">✕</button>
    </div>

    <!-- Summary stats -->
    <div v-if="displayData.length" class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
      <div class="bg-white rounded-lg border p-3 text-center">
        <div class="text-2xl font-bold text-primary-600">{{ stats.structures }}</div>
        <div class="text-xs text-gray-500">Công trình</div>
      </div>
      <div class="bg-white rounded-lg border p-3 text-center">
        <div class="text-2xl font-bold text-primary-600">{{ stats.items }}</div>
        <div class="text-xs text-gray-500">Hạng mục có KL</div>
      </div>
      <div class="bg-white rounded-lg border p-3 text-center">
        <div class="text-2xl font-bold text-primary-600">{{ stats.entries }}</div>
        <div class="text-xs text-gray-500">Nhật ký</div>
      </div>
      <div class="bg-white rounded-lg border p-3 text-center">
        <div class="text-2xl font-bold" :class="stats.avgPercent >= 50 ? 'text-green-600' : 'text-orange-500'">
          {{ stats.avgPercent.toFixed(1) }}%
        </div>
        <div class="text-xs text-gray-500">Hoàn thành TB</div>
      </div>
    </div>

    <!-- Summary Table -->
    <div class="bg-white rounded-lg shadow-sm border">
      <div v-if="loadingData" class="p-8 text-center text-gray-400">Đang tải...</div>
      <div v-else-if="!reportLoaded" class="p-8 text-center text-gray-400">
        Chọn bộ lọc và nhấn "Xem báo cáo"
      </div>
      <div v-else-if="displayData.length === 0" class="p-8 text-center text-gray-400">
        Không có dữ liệu trong khoảng thời gian đã chọn
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 text-gray-600">
            <tr>
              <th class="text-left px-3 py-2">Loại</th>
              <th class="text-left px-3 py-2">Công trình</th>
              <th class="text-left px-3 py-2">Bộ phận</th>
              <th class="text-left px-3 py-2">Hạng mục</th>
              <th class="text-center px-3 py-2">Đơn vị</th>
              <th class="text-right px-3 py-2">KL thiết kế</th>
              <th class="text-right px-3 py-2">KL thực hiện</th>
              <th class="text-right px-3 py-2">Tỷ lệ %</th>
            </tr>
          </thead>
          <tbody class="divide-y">
            <tr v-for="(row, idx) in displayData" :key="idx"
              :class="[row._bridgeTotal ? 'bg-primary-50 border-t-2 border-primary-200 font-semibold' : (idx % 2 === 0 ? 'bg-gray-50' : '')]">
              <td class="px-3 py-2 text-gray-500 text-xs">{{ row.type_name }}</td>
              <td class="px-3 py-2 font-medium">{{ row.structure_name }}</td>
              <td class="px-3 py-2 text-gray-500 text-xs">{{ row.group_name || '' }}</td>
              <td class="px-3 py-2">
                {{ row.work_item_name }}
                <span v-if="row.layer_info" class="text-xs text-gray-400 ml-1">({{ row.layer_info }})</span>
              </td>
              <td class="px-3 py-2 text-center text-gray-500">{{ row.unit }}</td>
              <td class="px-3 py-2 text-right">
                <span class="text-gray-400">{{ formatNum(row.design_quantity) }}</span>
                <div v-if="row.dtpl_km_range" class="text-[10px] text-gray-400 leading-tight mt-0.5">
                  ĐTPL: {{ row.dtpl_km_range }}
                </div>
              </td>
              <td class="px-3 py-2 text-right font-medium"
                :class="row.total_quantity > 0 ? 'text-primary-700' : 'text-gray-400'">
                {{ formatNum(row.total_quantity) }}
              </td>
              <td class="px-3 py-2 text-right">
                <span v-if="row.design_quantity > 0"
                  :class="percent(row) >= 100 ? 'text-green-600 font-medium' : 'text-gray-600'">
                  {{ percent(row).toFixed(1) }}%
                </span>
                <span v-else class="text-gray-300">—</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { getTypes, getStructures, getWorkItems } = useStructures()
const { listLines } = useDiary()
const { currentProject } = useProject()
const { success, error: showError } = useToast()
const { $supabase } = useNuxtApp()
const { calcVolume, calcArea, calcCumulativeVolume } = useLayerVolume()

const types = ref<any[]>([])
const allStructures = ref<any[]>([])
const summaryData = ref<any[]>([])
const loadingData = ref(false)
const reportLoaded = ref(false)
const onlyWithQuantity = ref(true)
const activePeriod = ref<'week' | 'month' | 'all'>('all')

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

function onTypeChange() {
  filters.structureId = ''
}

// --- Quick date range ---
function todayLocal() {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function setDateRange(period: 'week' | 'month' | 'all') {
  activePeriod.value = period
  const today = new Date()
  if (period === 'week') {
    // Thứ 2 đầu tuần
    const day = today.getDay() // 0=CN, 1=T2...
    const diff = day === 0 ? 6 : day - 1
    const monday = new Date(today)
    monday.setDate(today.getDate() - diff)
    filters.dateFrom = fmtDate(monday)
    filters.dateTo = todayLocal()
  } else if (period === 'month') {
    const first = new Date(today.getFullYear(), today.getMonth(), 1)
    filters.dateFrom = fmtDate(first)
    filters.dateTo = todayLocal()
  } else {
    filters.dateFrom = ''
    filters.dateTo = ''
  }
}

function fmtDate(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

// When user manually changes date inputs, clear activePeriod
watch([() => filters.dateFrom, () => filters.dateTo], () => {
  // Check if dates still match a period
  const today = todayLocal()
  if (filters.dateTo === today || filters.dateTo === '') {
    // could be a quick filter, don't clear
  } else {
    activePeriod.value = 'all'
  }
})

// --- Formatting ---
function formatNum(n: number | null) {
  if (n == null || n === 0) return '—'
  return n.toLocaleString('vi-VN', { maximumFractionDigits: 2 })
}

function percent(row: any) {
  if (!row.design_quantity) return 0
  return Math.min((row.total_quantity / row.design_quantity) * 100, 999.9)
}

// --- Display data (filtered by onlyWithQuantity) ---
const displayData = computed(() => {
  if (onlyWithQuantity.value) {
    return summaryData.value.filter(r => r.total_quantity > 0)
  }
  return summaryData.value
})

// --- Stats ---
const stats = computed(() => {
  const rows = displayData.value
  const structures = new Set(rows.map(r => r.structure_id))
  const withQty = rows.filter(r => r.total_quantity > 0)
  const withDesign = rows.filter(r => r.design_quantity > 0 && r.total_quantity > 0)
  const avgPercent = withDesign.length
    ? withDesign.reduce((s, r) => s + Math.min((r.total_quantity / r.design_quantity) * 100, 100), 0) / withDesign.length
    : 0
  // Count distinct entry dates from raw lines (stored during load)
  return {
    structures: structures.size,
    items: withQty.length,
    entries: entryCount.value,
    avgPercent,
  }
})
const entryCount = ref(0)

// --- Load report ---
async function loadReport() {
  loadingData.value = true
  reportLoaded.value = false
  try {
    // Determine which structures to include
    let targetStructIds: Set<string> | null = null
    if (filters.structureId) {
      targetStructIds = new Set([filters.structureId])
    } else if (filters.typeId) {
      targetStructIds = new Set(filteredStructures.value.map((s: any) => s.id))
    }

    // 1. Get all work items for target structures (for design quantities)
    const structList = targetStructIds
      ? allStructures.value.filter(s => targetStructIds!.has(s.id))
      : allStructures.value

    // Build work items map: structure_id -> work_item_id -> work_item
    const wiMap = new Map<string, Map<string, any>>()
    for (const st of structList) {
      const items = await getWorkItems(st.id)
      const m = new Map<string, any>()
      for (const it of items) {
        m.set(it.id, it)
      }
      wiMap.set(st.id, m)
    }

    // 2. Get diary lines (with date filter)
    const rawLines = await listLines({
      structureId: filters.structureId || undefined,
      dateFrom: filters.dateFrom || undefined,
      dateTo: filters.dateTo || undefined,
    })

    // Count distinct entries
    const entryIds = new Set(rawLines.map(l => l.entry_id))
    entryCount.value = entryIds.size

    // 3. Aggregate: km-based items sum normally; non-km items use max-per-batch (cọc, K95…)
    const agg = new Map<string, { structureId: string; sumKm: number; maxByBatch: Map<string, number>; maxBatch: number; minBatch: number }>()
    for (const line of rawLines) {
      const entry = line.diary_entries
      if (!entry) continue
      const structId = entry.structure_id
      if (targetStructIds && !targetStructIds.has(structId)) continue

      const key = line.work_item_id
      let item = agg.get(key)
      if (!item) {
        item = { structureId: structId, sumKm: 0, maxByBatch: new Map(), maxBatch: 0, minBatch: Infinity }
        agg.set(key, item)
      }
      const hasKm = line.km_from != null
      // Integer-unit items (cọc, chiếc…): each diary line = distinct event → sum
      // Continuous-unit non-km items (m³ K95…): same batch recorded multiple times → max per batch
      const INTEGER_UNITS = ['cọc', 'chiếc', 'bộ', 'thanh', 'cái', 'tấm', 'trụ', 'cây', 'mố']
      const isIntUnit = INTEGER_UNITS.includes(line.work_items?.unit ?? '')
      if (hasKm || isIntUnit) {
        item.sumKm += (line.quantity || 0)
      } else {
        const bk = `${line.side ?? ''}|${line.batch_number ?? ''}`
        item.maxByBatch.set(bk, Math.max(item.maxByBatch.get(bk) ?? 0, line.quantity || 0))
      }
      const bn = line.batch_number || 0
      if (bn > item.maxBatch) item.maxBatch = bn
      if (bn > 0 && bn < item.minBatch) item.minBatch = bn
    }

    // 4. Build summary rows — one per work_item
    const NON_LINEAR = new Set(['CAU', 'CONG', 'HAM_CHUI', 'TRAM_THU_PHI'])
    const rows: any[] = []
    for (const [structId, itemsMap] of wiMap) {
      const st = allStructures.value.find(s => s.id === structId)
      if (!st) continue
      const typeName = st.structure_types?.name || types.value.find(t => t.id === st.type_id)?.name || ''
      const typeCode: string = st.structure_types?.code || ''

      for (const [wiId, wi] of itemsMap) {
        const aggEntry = agg.get(wiId)
        let total = 0
        let maxBatch = 0
        let minBatch = 0
        if (aggEntry) {
          total = aggEntry.sumKm + Array.from(aggEntry.maxByBatch.values() as Iterable<number>).reduce((a: number, b: number) => a + b, 0)
          maxBatch = aggEntry.maxBatch
          minBatch = aggEntry.minBatch === Infinity ? 0 : aggEntry.minBatch
        }
        const isRoad = !NON_LINEAR.has(typeCode)
        // Lớp 1=trên cùng (đắp sau), lớp N=dưới cùng (đắp trước)
        // Thi công: maxBatch (lớp đáy) → minBatch (lớp đang đắp)
        let layerInfo = ''
        if (isRoad && maxBatch > 0) {
          if (minBatch === maxBatch) {
            layerInfo = `lớp ${minBatch}`
          } else {
            layerInfo = `lớp ${maxBatch}→${minBatch}`
          }
        }
        rows.push({
          structure_id: structId,
          structure_name: st.name,
          type_name: typeName,
          type_code: typeCode,
          work_item_id: wiId,
          work_item_name: wi.name,
          group_name: wi.group_name || '',
          unit: wi.unit,
          design_quantity: wi.design_quantity,
          total_quantity: total,
          max_batch: maxBatch,
          layer_info: layerInfo,
          _sortOrder: 0,
        })
      }
    }

    // 5. Gộp các hạng mục cọc (unit "cọc") thành 1 dòng per bộ phận
    //    "Đổ BT cọc" = bước hoàn thành → lấy KL từ dòng này
    const pileRows = rows.filter(r => r.unit === 'cọc')
    const nonPileRows = rows.filter(r => r.unit !== 'cọc')
    const pileGroupMap = new Map<string, any[]>()
    for (const r of pileRows) {
      const key = `${r.structure_id}|${r.group_name}`
      if (!pileGroupMap.has(key)) pileGroupMap.set(key, [])
      pileGroupMap.get(key)!.push(r)
    }
    const mergedPiles: any[] = []
    const bridgeTotals = new Map<string, { name: string; type: string; typeCode: string; total: number; design: number }>()
    for (const [, groupRows] of pileGroupMap) {
      const btRow = groupRows.find((r: any) => /đổ\s*b[eê]?\s*t[oô]ng|đổ\s*bt/i.test(r.work_item_name))
      const completedQty = btRow ? btRow.total_quantity : Math.max(...groupRows.map((r: any) => r.total_quantity))
      const designQty = btRow?.design_quantity || groupRows[0].design_quantity || null
      const tpl = groupRows[0]
      mergedPiles.push({
        ...tpl,
        work_item_name: 'Cọc KN hoàn thành',
        total_quantity: completedQty,
        design_quantity: designQty,
        layer_info: '',
        _merged: true,
        _sortOrder: 0,
      })
      if (!bridgeTotals.has(tpl.structure_id)) {
        bridgeTotals.set(tpl.structure_id, { name: tpl.structure_name, type: tpl.type_name, typeCode: tpl.type_code, total: 0, design: 0 })
      }
      const bt = bridgeTotals.get(tpl.structure_id)!
      bt.total += completedQty
      if (designQty) bt.design += designQty
    }
    for (const [structId, info] of bridgeTotals) {
      mergedPiles.push({
        structure_id: structId,
        structure_name: info.name,
        type_name: info.type,
        type_code: info.typeCode,
        group_name: '',
        work_item_name: 'Tổng cọc hoàn thành toàn cầu',
        unit: 'cọc',
        design_quantity: info.design || null,
        total_quantity: info.total,
        max_batch: 0,
        layer_info: '',
        _bridgeTotal: true,
        _sortOrder: 1,
      })
    }
    const allRows = [...nonPileRows, ...mergedPiles]

    // 6. Bổ sung KL thiết kế từ ĐTPL cho các hạng mục đường chưa có design_quantity
    const dtplCache = new Map<string, { quantity: number; kmFrom: number; kmTo: number } | null>()
    for (const row of allRows) {
      if (row.design_quantity && row.design_quantity > 0) continue // đã có KL thiết kế
      const detected = _detectItemType(row.work_item_name)
      if (!detected) continue

      let dtplResult = dtplCache.get(detected.itemType)
      if (dtplResult === undefined) {
        dtplResult = await _calcDesignFromDTPL(detected.itemType, detected.unit)
        dtplCache.set(detected.itemType, dtplResult)
      }
      if (dtplResult && dtplResult.quantity > 0) {
        row.design_quantity = dtplResult.quantity
        row.dtpl_km_range = _fmtKmRange(dtplResult.kmFrom, dtplResult.kmTo)
      }
    }

    // Sort: type → structure → sortOrder (tổng cầu cuối cùng) → group → item
    allRows.sort((a, b) =>
      a.type_name.localeCompare(b.type_name)
      || a.structure_name.localeCompare(b.structure_name, 'vi')
      || (a._sortOrder || 0) - (b._sortOrder || 0)
      || a.group_name.localeCompare(b.group_name, 'vi')
      || a.work_item_name.localeCompare(b.work_item_name, 'vi')
    )

    summaryData.value = allRows
    reportLoaded.value = true
  } catch (e: any) {
    showError(e.message)
  } finally {
    loadingData.value = false
  }
}

async function exportExcel() {
  try {
    const XLSX = await import('xlsx')
    const wsData = displayData.value.map(r => ({
      'Loại': r.type_name,
      'Công trình': r.structure_name,
      'Bộ phận': r.group_name,
      'Hạng mục': r.work_item_name + (r.layer_info ? ` (${r.layer_info})` : ''),
      'Đơn vị': r.unit,
      'KL thiết kế': r.design_quantity || '',
      'KL thực hiện': r.total_quantity || '',
      'Tỷ lệ (%)': r.design_quantity ? ((r.total_quantity / r.design_quantity) * 100).toFixed(1) : '',
    }))
    const ws = XLSX.utils.json_to_sheet(wsData)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Báo cáo')
    const code = currentProject.value?.code?.toLowerCase() || 'all'
    const period = filters.dateFrom ? `${filters.dateFrom}_${filters.dateTo || 'now'}` : 'all'
    XLSX.writeFile(wb, `bao-cao-${code}-${period}.xlsx`)
    success('Đã xuất file Excel')
  } catch (e: any) {
    showError('Lỗi xuất Excel: ' + e.message)
  }
}

// --- Recalc volumes from ĐTPL (all item types) ---
const recalcBusy = ref(false)
const recalcProgress = ref('')
const recalcResult = ref('')

// Map: regex pattern on work_item name → item_type in layer_sections
// unit: 'm3' = thể tích (calcVolume), 'm2' = diện tích bề mặt (calcArea)
const ITEM_TYPE_MAP: { pattern: RegExp; itemType: string; label: string; unit: 'm3' | 'm2' }[] = [
  // Nền đường (m³)
  { pattern: /k95/i, itemType: 'K95', label: 'K95', unit: 'm3' },
  { pattern: /k98/i, itemType: 'K98', label: 'K98', unit: 'm3' },
  { pattern: /xử lý nền|xlndy|xử lí nền/i, itemType: 'XLNDY', label: 'XLNDY', unit: 'm3' },
  { pattern: /bù lún|bul/i, itemType: 'BUL', label: 'BUL', unit: 'm3' },
  // Lớp móng (m³)
  { pattern: /cpđd loại i|cpdd.?loai.?i|cpđd.?i(?!i)/i, itemType: 'CPDD1', label: 'CPĐD I', unit: 'm3' },
  { pattern: /cpđd.?gcxm|cpdd.?gcxm|cpđd.?gia cố/i, itemType: 'CPDD_GCXM', label: 'CPĐD GCXM', unit: 'm3' },
  { pattern: /cpđd loại ii|cpdd.?loai.?ii|cpđd.?ii/i, itemType: 'CPDD2', label: 'CPĐD II', unit: 'm3' },
  // Mặt đường BTN (m²) — dùng chiều rộng mặt rải
  { pattern: /btn.?rỗng|btn.?r.?25|btn rỗng/i, itemType: 'BTN_R25', label: 'BTN rỗng', unit: 'm2' },
  { pattern: /btn.?chặt.?19|btn.?c.?19/i, itemType: 'BTN_C19', label: 'BTN chặt 19', unit: 'm2' },
  { pattern: /btn.?chặt.?12[,.]?5|btn.?c.?12[,.]?5/i, itemType: 'BTN_C125', label: 'BTN chặt 12.5', unit: 'm2' },
]

function _detectItemType(name: string): { itemType: string; label: string; unit: 'm3' | 'm2' } | null {
  for (const m of ITEM_TYPE_MAP) {
    if (m.pattern.test(name)) return { itemType: m.itemType, label: m.label, unit: m.unit }
  }
  return null
}

/**
 * Tính tổng KL thiết kế từ ĐTPL cho 1 item_type (tất cả lớp, cả 2 bên T/P).
 */
async function _calcDesignFromDTPL(itemType: string, unit: 'm3' | 'm2'): Promise<{ quantity: number; kmFrom: number; kmTo: number } | null> {
  const pid = currentProject.value?.id
  if (!pid) return null

  const { data, error: err } = await $supabase
    .from('layer_sections')
    .select('station, layer, side, area')
    .eq('project_id', pid)
    .eq('item_type', itemType)
    .order('side')
    .order('layer')
    .order('station')

  if (err || !data || data.length === 0) return null

  let minSt = Infinity, maxSt = -Infinity
  for (const r of data) {
    if (r.station < minSt) minSt = r.station
    if (r.station > maxSt) maxSt = r.station
  }

  // Group by (side, layer) → tính volume/area cho mỗi nhóm
  const groups = new Map<string, { station: number; area: number }[]>()
  for (const r of data) {
    const key = `${r.side}|${r.layer}`
    if (!groups.has(key)) groups.set(key, [])
    groups.get(key)!.push({ station: r.station, area: r.area })
  }

  let total = 0
  for (const [, sections] of groups) {
    sections.sort((a, b) => a.station - b.station)
    for (let i = 0; i < sections.length - 1; i++) {
      const L = sections[i + 1].station - sections[i].station
      total += ((sections[i].area + sections[i + 1].area) / 2) * L
    }
  }

  return {
    quantity: Math.round(total * 100) / 100,
    kmFrom: minSt,
    kmTo: maxSt,
  }
}

function _fmtKmRange(kmFrom: number, kmTo: number): string {
  const f = (m: number) => {
    const km = Math.floor(m / 1000)
    const remain = Math.round(m % 1000)
    return `Km${km}+${String(remain).padStart(3, '0')}`
  }
  return `${f(kmFrom)}–${f(kmTo)}`
}

function _parseKm(input: string | number | null | undefined): number | null {
  if (input === null || input === undefined) return null
  if (typeof input === 'number') return Number.isFinite(input) ? input : null
  const t = String(input).toUpperCase().replace(/\s+/g, '').replace(/^KM/, '').replace(',', '.')
  if (!t) return null
  if (t.includes('+')) {
    const [km, m] = t.split('+')
    const a = Number(km), b = Number(m)
    if (km === '' || m === '' || !Number.isFinite(a) || !Number.isFinite(b)) return null
    return a * 1000 + b
  }
  const n = Number(t)
  return Number.isFinite(n) ? n : null
}

async function recalcVolumes() {
  recalcBusy.value = true
  recalcResult.value = ''
  recalcProgress.value = '0/0'
  try {
    const pid = currentProject.value?.id
    if (!pid) throw new Error('Chưa chọn dự án')

    // Fetch all diary_lines for this project that have side + layer info
    const { data: rawLines, error: lErr } = await $supabase
      .from('diary_lines')
      .select('id, work_item_id, side, batch_number, km_from, km_to, quantity, work_items(name), diary_entries!inner(project_id)')
      .eq('diary_entries.project_id', pid)
      .not('side', 'is', null)
      .not('batch_number', 'is', null)

    if (lErr) throw lErr

    // Filter lines that match any known ĐTPL item type
    const lines = (rawLines || []).filter((l: any) => {
      const name = l.work_items?.name || ''
      return _detectItemType(name) !== null
    })

    const totalRaw = rawLines?.length || 0
    console.log('[recalcVolumes] total diary_lines:', totalRaw, '→ ĐTPL lines:', lines.length)

    if (!lines || lines.length === 0) {
      recalcResult.value = 'Không có dòng nào khớp hạng mục ĐTPL (K95, K98, XLNDY, BUL) có đủ thông tin (bên, lớp)'
      return
    }

    // Track stats per item type
    const stats: Record<string, { updated: number; skipped: number; errors: number }> = {}
    let totalUpdated = 0
    let totalSkipped = 0
    let totalErrors = 0

    for (let i = 0; i < lines.length; i++) {
      recalcProgress.value = `${i + 1}/${lines.length}`
      const line = lines[i]
      const detected = _detectItemType(line.work_items?.name || '')
      if (!detected) { totalSkipped++; continue }

      if (!stats[detected.label]) stats[detected.label] = { updated: 0, skipped: 0, errors: 0 }

      const rawFrom = line.km_from
      const rawTo = line.km_to
      if (rawFrom === null || rawFrom === undefined || rawTo === null || rawTo === undefined) {
        stats[detected.label].skipped++
        totalSkipped++
        continue
      }

      const kmFrom = Math.min(rawFrom, rawTo)
      const kmTo = Math.max(rawFrom, rawTo)
      if (kmFrom === kmTo) { stats[detected.label].skipped++; totalSkipped++; continue }

      try {
        // m² (BTN) → calcArea cho 1 lớp
        // m³ (K95…) → calcVolume: khối lượng riêng từng lớp
        let quantity: number
        if (detected.unit === 'm2') {
          quantity = (await calcArea({
            side: line.side as 'T' | 'P',
            layer: Number(line.batch_number),
            kmFrom,
            kmTo,
            itemType: detected.itemType,
          })).area
        } else {
          const vol = await calcVolume({
            side: line.side as 'T' | 'P',
            layer: Number(line.batch_number),
            kmFrom,
            kmTo,
            itemType: detected.itemType,
          })
          quantity = vol.volume
        }
        const result = { volume: quantity }

        if (result.volume > 0 && Math.abs(result.volume - (line.quantity || 0)) > 0.01) {
          const { error: uErr } = await $supabase
            .rpc('update_line_quantity', { p_line_id: line.id, p_quantity: result.volume })
          if (uErr) {
            stats[detected.label].errors++
            totalErrors++
            console.error('[recalcVolumes] Update error:', detected.label, line.id, uErr)
          } else {
            stats[detected.label].updated++
            totalUpdated++
          }
        } else {
          stats[detected.label].skipped++
          totalSkipped++
        }
      } catch (e) {
        stats[detected.label].errors++
        totalErrors++
        console.warn('[recalcVolumes] Calc error:', detected.label, line.id, e)
      }
    }

    // Build result message with per-type breakdown
    const parts = Object.entries(stats)
      .filter(([, s]) => s.updated > 0 || s.errors > 0)
      .map(([label, s]) => `${label}: ${s.updated} cập nhật` + (s.errors > 0 ? `, ${s.errors} lỗi` : ''))

    recalcResult.value = `Hoàn thành: ${totalUpdated} dòng đã cập nhật, ${totalSkipped} bỏ qua` +
      (totalErrors > 0 ? `, ${totalErrors} lỗi` : '') +
      (parts.length > 0 ? ` (${parts.join('; ')})` : '') +
      `. Nhấn "Xem báo cáo" để cập nhật bảng.`
    if (totalUpdated > 0) success(`Đã tính lại ${totalUpdated} dòng ĐTPL`)
  } catch (e: any) {
    showError('Lỗi tính lại KL: ' + e.message)
  } finally {
    recalcBusy.value = false
  }
}

onMounted(async () => {
  [types.value, allStructures.value] = await Promise.all([getTypes(), getStructures()])
})
</script>

<style scoped>
.input-sm {
  @apply px-3 py-1.5 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
</style>
