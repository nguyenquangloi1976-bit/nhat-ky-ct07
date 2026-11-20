<template>
  <div class="max-w-7xl mx-auto px-4 py-6">
    <h1 class="text-xl font-bold text-gray-800 mb-1">Thống kê khối lượng theo lớp đã nghiệm thu</h1>
    <p class="text-sm text-gray-500 mb-6">
      Tính KL từng lớp tại từng mặt cắt ngang (ĐTPL) dựa trên nhật ký thi công — phương pháp hình thang
    </p>

    <!-- Bộ lọc -->
    <div class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <div>
          <label class="block text-xs text-gray-500 mb-1">Công trình</label>
          <select v-model="structureId" class="input-sm w-full">
            <option value="" disabled>-- Chọn --</option>
            <option v-for="s in structures" :key="s.id" :value="s.id">{{ s.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Hạng mục</label>
          <select v-model="itemType" class="input-sm w-full">
            <option v-if="!catalogGroups.length" disabled>Đang tải danh mục...</option>
            <optgroup v-for="g in catalogGroups" :key="g.group" :label="g.group">
              <option v-for="t in g.items" :key="t.id" :value="t.name">{{ t.name }} ({{ t.unit }})</option>
            </optgroup>
          </select>
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Bên</label>
          <select v-model="sideFilter" class="input-sm w-full">
            <option value="">Cả hai</option>
            <option value="T">Trái (T)</option>
            <option value="P">Phải (P)</option>
          </select>
        </div>
        <div class="flex items-end">
          <button @click="generate" :disabled="loading || !structureId"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 text-sm font-medium disabled:opacity-50 w-full">
            {{ loading ? 'Đang tính...' : 'Tạo thống kê' }}
          </button>
        </div>
      </div>
      <p v-if="errorMsg" class="text-red-500 text-xs mt-2">{{ errorMsg }}</p>
    </div>

    <!-- Kết quả -->
    <div v-if="result.length" class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="flex justify-between items-center mb-3">
        <h2 class="font-semibold text-gray-700">
          Kết quả: {{ detailCount }} dòng chi tiết
          <span class="text-gray-400 font-normal text-sm ml-2">
            Tổng KL: {{ totalVol.toFixed(2) }} m³
          </span>
        </h2>
        <button @click="exportExcel" class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-primary-700 bg-primary-50 border border-primary-200 rounded-lg hover:bg-primary-100">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
          Tải Excel
        </button>
      </div>

      <div class="overflow-x-auto max-h-[70vh] overflow-y-auto border rounded">
        <table class="min-w-full text-xs">
          <thead class="bg-gray-50 sticky top-0 z-10">
            <tr>
              <th class="px-2 py-1.5 text-left">Ngày NK</th>
              <th class="px-2 py-1.5 text-left">Bên</th>
              <th class="px-2 py-1.5 text-left">Lý trình NK</th>
              <th class="px-2 py-1.5 text-right">Lớp NK</th>
              <th class="px-2 py-1.5 text-right">Lớp tính</th>
              <th class="px-2 py-1.5 text-left">MC từ</th>
              <th class="px-2 py-1.5 text-left">MC đến</th>
              <th class="px-2 py-1.5 text-right">DT MC1 (m²)</th>
              <th class="px-2 py-1.5 text-right">DT MC2 (m²)</th>
              <th class="px-2 py-1.5 text-right">L (m)</th>
              <th class="px-2 py-1.5 text-right font-bold">KL (m³)</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="(r, i) in result" :key="i">
              <tr :class="[r.isSubtotal ? 'bg-yellow-50 font-semibold' : 'hover:bg-gray-50', 'border-t']">
                <td class="px-2 py-1">{{ r.date }}</td>
                <td class="px-2 py-1">{{ r.side }}</td>
                <td class="px-2 py-1">{{ r.kmRange }}</td>
                <td class="px-2 py-1 text-right">{{ r.batchNumber }}</td>
                <td class="px-2 py-1 text-right">{{ r.layer }}</td>
                <td class="px-2 py-1 font-mono">{{ r.stFrom }}</td>
                <td class="px-2 py-1 font-mono">{{ r.stTo }}</td>
                <td class="px-2 py-1 text-right font-mono">{{ r.area1 }}</td>
                <td class="px-2 py-1 text-right font-mono">{{ r.area2 }}</td>
                <td class="px-2 py-1 text-right font-mono">{{ r.length }}</td>
                <td class="px-2 py-1 text-right font-mono font-bold" :class="r.isSubtotal ? 'text-primary-700' : ''">{{ r.volume }}</td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else-if="generated && !loading" class="bg-gray-50 rounded-lg border p-8 text-center text-gray-500">
      Không có dữ liệu phù hợp
    </div>
  </div>
</template>

<script setup lang="ts">
import { formatKm } from '~/composables/useStation'

definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { currentProject } = useProject()
const { getStructures } = useStructures()
const { listLines } = useDiary()

// Danh mục hạng mục KL — load từ work_item_catalog (is_default = true)
const catalogItems = ref<any[]>([])
const catalogGroups = computed(() => {
  const map = new Map<string, any[]>()
  for (const item of catalogItems.value) {
    const g = item.group_name || 'Khác'
    if (!map.has(g)) map.set(g, [])
    map.get(g)!.push(item)
  }
  return Array.from(map.entries()).map(([group, items]) => ({ group, items }))
})

// Map tên hạng mục → item_type code trong layer_sections (ĐTPL)
const NAME_TO_DTPL_CODE: { pattern: RegExp; code: string }[] = [
  { pattern: /k95/i, code: 'K95' },
  { pattern: /k98/i, code: 'K98' },
  { pattern: /xử lý nền|xlndy/i, code: 'XLNDY' },
  { pattern: /bù lún|bul/i, code: 'BUL' },
  { pattern: /cpđd[^,;]*loại i\b|cpdd.?loai.?i\b/i, code: 'CPDD1' },
  { pattern: /gcxm|gia cố xi măng/i, code: 'CPDD_GCXM' },
  { pattern: /cpđd[^,;]*loại ii\b|cpdd.?loai.?ii\b/i, code: 'CPDD2' },
  { pattern: /btn[^,;]*hạt thô|btn.?ht\b/i, code: 'BTN_HT' },
  { pattern: /btn[^,;]*hạt mịn|btn.?hm\b/i, code: 'BTN_HM' },
  { pattern: /btn[^,;]*polyme|btn.?pm\b/i, code: 'BTN_PM' },
]

function nameToDtplCode(name: string): string {
  const m = NAME_TO_DTPL_CODE.find(x => x.pattern.test(name))
  return m ? m.code : ''
}

async function loadCatalog() {
  // Load hạng mục mặc định cho loại công trình Đường
  const { data } = await $supabase
    .from('work_item_catalog')
    .select('*')
    .eq('type_code', 'Đường')
    .eq('is_active', true)
    .eq('is_default', true)
    .order('group_name')
    .order('sort_order')
  catalogItems.value = data || []
  // Auto-select hạng mục đầu tiên
  if (catalogItems.value.length && !itemType.value) {
    itemType.value = catalogItems.value[0].name
  }
}

const structures = ref<any[]>([])
const structureId = ref('')
const itemType = ref('')
const sideFilter = ref('')
const loading = ref(false)
const generated = ref(false)
const errorMsg = ref('')

interface ResultRow {
  date: string; side: string; kmRange: string; batchNumber: string | number
  layer: string | number; stFrom: string; stTo: string
  area1: string; area2: string; length: string; volume: string
  isSubtotal?: boolean; volNum?: number
}
const result = ref<ResultRow[]>([])
const totalVol = computed(() => result.value.reduce((s, r) => s + (r.volNum || 0), 0))
const detailCount = computed(() => result.value.filter(r => !r.isSubtotal).length)

async function loadStructures() {
  try {
    structures.value = await getStructures()
    const road = structures.value.find(s => s.structure_types?.name === 'Đường')
    if (road) structureId.value = road.id
    else if (structures.value.length) structureId.value = structures.value[0].id
  } catch (e) {
    console.error('Load structures error:', e)
  }
}

watch(() => currentProject.value?.id, (pid) => {
  if (pid) {
    loadStructures()
    loadCatalog()
  }
}, { immediate: true })

async function generate() {
  const pid = currentProject.value?.id
  if (!pid || !structureId.value) return
  loading.value = true
  generated.value = true
  result.value = []
  errorMsg.value = ''

  try {
    // 1. Load nhật ký qua composable (đã phân trang sẵn)
    const allLines = await listLines({ structureId: structureId.value })

    // Lọc: có batch_number, có km_from, tên hạng mục khớp item_type
    const filtered = allLines.filter(l =>
      l.batch_number &&
      l.km_from != null &&
      (l.work_items?.name || '') === itemType.value &&
      (!sideFilter.value || (l.side || 'T') === sideFilter.value)
    )

    if (!filtered.length) {
      errorMsg.value = `Tìm thấy ${allLines.length} dòng NK nhưng không có dòng nào khớp ${itemType.value}${sideFilter.value ? ' bên ' + sideFilter.value : ''}`
      loading.value = false
      return
    }

    // 2. Load ĐTPL (phân trang)
    const dtplCode = nameToDtplCode(itemType.value)
    if (!dtplCode) {
      errorMsg.value = `Không tìm thấy mã ĐTPL tương ứng cho "${itemType.value}"`
      loading.value = false
      return
    }
    const dtplMap: Record<string, Map<number, Map<number, number>>> = {}
    const pgSize = 1000
    let offset = 0
    while (true) {
      const { data, error } = await $supabase
        .from('layer_sections')
        .select('station, layer, side, area, item_type')
        .eq('project_id', pid)
        .eq('item_type', dtplCode)
        .range(offset, offset + pgSize - 1)
      if (error) { errorMsg.value = 'Lỗi load ĐTPL: ' + error.message; break }
      if (!data || data.length === 0) break
      for (const r of data) {
        const s = r.side || 'T'
        if (!dtplMap[s]) dtplMap[s] = new Map()
        if (!dtplMap[s].has(r.station)) dtplMap[s].set(r.station, new Map())
        dtplMap[s].get(r.station)!.set(r.layer, r.area)
      }
      if (data.length < pgSize) break
      offset += pgSize
    }

    const dtplTotal = Object.values(dtplMap).reduce((s, m) => s + m.size, 0)
    if (dtplTotal === 0) {
      errorMsg.value = `Có ${filtered.length} dòng NK khớp nhưng không có dữ liệu ĐTPL cho "${itemType.value}" (mã: ${dtplCode})`
      loading.value = false
      return
    }

    // 3. Tính khối lượng
    const rows: ResultRow[] = []
    for (const line of filtered) {
      const kmA = Math.min(Number(line.km_from), Number(line.km_to ?? line.km_from))
      const kmB = Math.max(Number(line.km_from), Number(line.km_to ?? line.km_from))
      const bn = Number(line.batch_number)
      const lineSide = line.side || 'T'
      const date = line.diary_entries?.entry_date || ''
      const fDate = date ? date.split('-').reverse().join('/') : ''

      const sideData = dtplMap[lineSide]
      if (!sideData) continue

      const stationsInRange = Array.from(sideData.keys())
        .filter(st => st >= kmA && st <= kmB)
        .sort((a, b) => a - b)

      if (stationsInRange.length < 2) continue

      const maxLayerAtStation = (st: number) => {
        const layers = sideData.get(st)
        if (!layers || layers.size === 0) return 0
        return Math.max(...layers.keys())
      }

      let subtotalVol = 0
      for (let si = 0; si < stationsInRange.length - 1; si++) {
        const st1 = stationsInRange[si]
        const st2 = stationsInRange[si + 1]
        const dist = st2 - st1
        const layers1 = sideData.get(st1)!
        const layers2 = sideData.get(st2)!
        const maxL = Math.max(maxLayerAtStation(st1), maxLayerAtStation(st2))

        for (let layer = bn; layer <= maxL; layer++) {
          const a1 = layers1.get(layer) || 0
          const a2 = layers2.get(layer) || 0
          if (a1 === 0 && a2 === 0) continue
          const vol = (a1 + a2) / 2 * dist
          subtotalVol += vol
          rows.push({
            date: fDate, side: lineSide,
            kmRange: `${formatKm(kmA)} – ${formatKm(kmB)}`,
            batchNumber: bn, layer,
            stFrom: formatKm(st1), stTo: formatKm(st2),
            area1: a1.toFixed(3), area2: a2.toFixed(3),
            length: dist.toFixed(1), volume: vol.toFixed(2),
            volNum: vol,
          })
        }
      }

      if (subtotalVol > 0) {
        rows.push({
          date: fDate, side: lineSide,
          kmRange: `${formatKm(kmA)} – ${formatKm(kmB)}`,
          batchNumber: `Lớp ${bn}`, layer: '',
          stFrom: '', stTo: '',
          area1: '', area2: '', length: '',
          volume: subtotalVol.toFixed(2),
          isSubtotal: true, volNum: 0,
        })
      }
    }

    result.value = rows
    if (!rows.length) {
      errorMsg.value = `${filtered.length} dòng NK, ${dtplTotal} stations ĐTPL — nhưng không có stations ĐTPL nằm trong lý trình nhật ký`
    }
  } catch (e: any) {
    errorMsg.value = 'Lỗi: ' + (e.message || e)
    console.error('Generate error:', e)
  } finally {
    loading.value = false
  }
}

async function exportExcel() {
  const XLSX = await import('xlsx')
  const wsData = result.value.map(r => ({
    'Ngày NK': r.date,
    'Bên': r.side,
    'Lý trình NK': r.kmRange,
    'Lớp NK (batch)': r.batchNumber,
    'Lớp tính': r.layer,
    'MC từ': r.stFrom,
    'MC đến': r.stTo,
    'DT MC1 (m²)': r.area1,
    'DT MC2 (m²)': r.area2,
    'Chiều dài (m)': r.length,
    'KL (m³)': r.volume,
  }))
  const ws = XLSX.utils.json_to_sheet(wsData)
  ws['!cols'] = [
    { wch: 12 }, { wch: 5 }, { wch: 24 }, { wch: 10 }, { wch: 8 },
    { wch: 14 }, { wch: 14 }, { wch: 12 }, { wch: 12 }, { wch: 10 }, { wch: 12 },
  ]
  const wb = XLSX.utils.book_new()
  const structName = structures.value.find(s => s.id === structureId.value)?.name || 'CT'
  XLSX.utils.book_append_sheet(wb, ws, 'KL theo lớp')
  XLSX.writeFile(wb, `KL-lop-${itemType.value}-${structName.replace(/[/\\?*[\]]/g, '_')}.xlsx`)
}
</script>

<style scoped>
.input-sm {
  @apply px-3 py-1.5 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
</style>
