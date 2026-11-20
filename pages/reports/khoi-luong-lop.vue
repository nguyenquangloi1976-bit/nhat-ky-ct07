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
            <optgroup v-for="g in structureGroups" :key="g.id" :label="g.name">
              <option v-for="s in g.items" :key="s.id" :value="s.id">{{ s.name }}</option>
            </optgroup>
          </select>
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Hạng mục</label>
          <select v-model="itemType" class="input-sm w-full">
            <option v-for="t in ITEM_TYPES" :key="t.value" :value="t.value">{{ t.label }}</option>
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
          <button @click="generate" :disabled="loading"
            class="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 text-sm font-medium disabled:opacity-50 w-full">
            {{ loading ? 'Đang tính...' : 'Tạo thống kê' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Kết quả -->
    <div v-if="result.length" class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="flex justify-between items-center mb-3">
        <h2 class="font-semibold text-gray-700">
          Kết quả: {{ result.length }} dòng
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

const ITEM_TYPES = [
  { label: 'Đắp K95', value: 'K95' },
  { label: 'Đắp K98', value: 'K98' },
  { label: 'Xử lý nền đất yếu', value: 'XLNDY' },
  { label: 'Đắp bù lún', value: 'BUL' },
  { label: 'CPĐD loại I', value: 'CPDD1' },
  { label: 'CPĐD GCXM', value: 'CPDD_GCXM' },
  { label: 'CPĐD loại II', value: 'CPDD2' },
]

// Map item_type → regex cho tên hạng mục
const ITEM_TYPE_NAME_MAP: { itemType: string; pattern: RegExp }[] = [
  { itemType: 'K95', pattern: /k95/i },
  { itemType: 'K98', pattern: /k98/i },
  { itemType: 'XLNDY', pattern: /xử lý nền|xlndy/i },
  { itemType: 'BUL', pattern: /bù lún|bul/i },
  { itemType: 'CPDD1', pattern: /cpđd[^,;]*loại i\b|cpdd.?loai.?i\b/i },
  { itemType: 'CPDD_GCXM', pattern: /gcxm|gia cố xi măng/i },
  { itemType: 'CPDD2', pattern: /cpđd[^,;]*loại ii\b|cpdd.?loai.?ii\b/i },
]

function nameMatchesItemType(name: string, it: string): boolean {
  const m = ITEM_TYPE_NAME_MAP.find(x => x.itemType === it)
  return m ? m.pattern.test(name) : false
}

// --- Structures ---
const structures = ref<any[]>([])
const structureGroups = computed(() => {
  const map = new Map<string, { id: string; name: string; items: any[] }>()
  for (const s of structures.value) {
    const t = s.structure_types || {}
    const tid = t.id || 'other'
    if (!map.has(tid)) map.set(tid, { id: tid, name: t.name || 'Khác', items: [] })
    map.get(tid)!.items.push(s)
  }
  return Array.from(map.values())
})

const structureId = ref('')
const itemType = ref('K95')
const sideFilter = ref('')
const loading = ref(false)
const generated = ref(false)

interface ResultRow {
  date: string; side: string; kmRange: string; batchNumber: string | number
  layer: string | number; stFrom: string; stTo: string
  area1: string; area2: string; length: string; volume: string
  isSubtotal?: boolean; volNum?: number
}
const result = ref<ResultRow[]>([])
const totalVol = computed(() => result.value.reduce((s, r) => s + (r.volNum || 0), 0))

// Load structures
onMounted(async () => {
  const pid = currentProject.value?.id
  if (!pid) return
  const { data } = await $supabase
    .from('structures')
    .select('id, name, km_range, structure_types(id, name)')
    .eq('project_id', pid)
    .order('sort_order')
  if (data) structures.value = data
  if (data?.length) structureId.value = data[0].id
})

async function generate() {
  const pid = currentProject.value?.id
  if (!pid || !structureId.value) return
  loading.value = true
  generated.value = true
  result.value = []

  try {
    // 1. Load nhật ký (station_lines) với batch_number
    const { data: lines } = await $supabase
      .from('station_lines')
      .select('id, km_from, km_to, batch_number, side, quantity, notes, work_items!inner(name, unit), diary_entries!inner(entry_date, structure_id)')
      .eq('diary_entries.structure_id', structureId.value)
      .not('km_from', 'is', null)
      .not('batch_number', 'is', null)

    if (!lines?.length) { loading.value = false; return }

    // Lọc theo item_type
    const filtered = lines.filter(l => nameMatchesItemType(l.work_items?.name || '', itemType.value))
    if (!filtered.length) { loading.value = false; return }

    // 2. Load ĐTPL (phân trang)
    const dtplMap: Record<string, Map<number, Map<number, number>>> = {} // key=side → station → layer → area
    const pageSize = 1000
    let from = 0
    while (true) {
      const { data, error } = await $supabase
        .from('layer_sections')
        .select('station, layer, side, area, item_type')
        .eq('project_id', pid)
        .eq('item_type', itemType.value)
        .range(from, from + pageSize - 1)
      if (error || !data || data.length === 0) break
      for (const r of data) {
        const s = r.side || 'T'
        if (!dtplMap[s]) dtplMap[s] = new Map()
        if (!dtplMap[s].has(r.station)) dtplMap[s].set(r.station, new Map())
        dtplMap[s].get(r.station)!.set(r.layer, r.area)
      }
      if (data.length < pageSize) break
      from += pageSize
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

      if (sideFilter.value && lineSide !== sideFilter.value) continue

      const sideData = dtplMap[lineSide]
      if (!sideData) continue

      // Lấy stations trong đoạn, sắp xếp
      const stationsInRange = Array.from(sideData.keys())
        .filter(st => st >= kmA && st <= kmB)
        .sort((a, b) => a - b)

      if (stationsInRange.length < 2) continue

      // Tìm maxLayer tại mỗi station
      const maxLayerAtStation = (st: number) => {
        const layers = sideData.get(st)
        if (!layers) return 0
        return Math.max(...layers.keys())
      }

      // Tính KL cho từng lớp từ bn đến maxLayer(station)
      // Với mỗi cặp station liền kề, tính cho mỗi lớp
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
          if (a1 === 0 && a2 === 0) continue // lớp không tồn tại tại cả 2 MC
          const vol = (a1 + a2) / 2 * dist
          subtotalVol += vol
          rows.push({
            date: fDate,
            side: lineSide,
            kmRange: `${formatKm(kmA)} – ${formatKm(kmB)}`,
            batchNumber: bn,
            layer,
            stFrom: formatKm(st1),
            stTo: formatKm(st2),
            area1: a1.toFixed(3),
            area2: a2.toFixed(3),
            length: dist.toFixed(1),
            volume: vol.toFixed(2),
            volNum: vol,
          })
        }
      }

      // Subtotal cho nhật ký này
      if (subtotalVol > 0) {
        rows.push({
          date: fDate,
          side: lineSide,
          kmRange: `${formatKm(kmA)} – ${formatKm(kmB)}`,
          batchNumber: `Lớp ${bn}`,
          layer: '',
          stFrom: '', stTo: '',
          area1: '', area2: '', length: '',
          volume: subtotalVol.toFixed(2),
          isSubtotal: true,
          volNum: 0, // không cộng vào tổng (đã cộng từng dòng)
        })
      }
    }

    result.value = rows
  } catch (e: any) {
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
