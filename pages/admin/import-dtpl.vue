<template>
  <div class="max-w-4xl mx-auto px-4 py-6">
    <h1 class="text-xl font-bold text-gray-800 mb-1">Import dữ liệu diện tích mặt cắt</h1>
    <p class="text-sm text-gray-500 mb-6">Upload file Excel diện tích phân lớp — hỗ trợ K95, K98, xử lý nền, và các hạng mục khác</p>

    <!-- Step 1: Chọn hạng mục -->
    <div class="bg-white rounded-lg border p-5 mb-4">
      <h2 class="font-semibold text-gray-700 mb-3">1. Chọn hạng mục</h2>
      <div class="flex flex-wrap gap-2 mb-3">
        <button v-for="t in ITEM_TYPES" :key="t.value"
          @click="itemType = t.value; if (t.value === 'custom') customItemType = ''"
          :class="[
            'px-3 py-1.5 rounded-full text-sm font-medium border transition',
            itemType === t.value
              ? 'bg-primary-600 text-white border-primary-600'
              : 'bg-white text-gray-600 border-gray-300 hover:border-primary-400'
          ]">
          {{ t.label }}
        </button>
      </div>
      <input v-if="itemType === 'custom'" v-model="customItemType"
        class="border rounded px-3 py-1.5 text-sm w-64" placeholder="Nhập tên hạng mục, VD: Gia cố taluy" />
      <div class="flex items-center gap-3 mt-3">
        <p class="text-xs text-gray-400">Hạng mục đã chọn: <strong>{{ activeItemType }}</strong></p>
        <button @click="downloadTemplate"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-primary-700 bg-primary-50 border border-primary-200 rounded-lg hover:bg-primary-100 transition">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
          Tải file mẫu (.xlsx)
        </button>
      </div>
    </div>

    <!-- Step 2: Upload -->
    <div class="bg-white rounded-lg border p-5 mb-4">
      <h2 class="font-semibold text-gray-700 mb-3">2. Chọn file Excel</h2>
      <div class="flex items-center gap-3">
        <label class="cursor-pointer inline-flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 text-sm font-medium">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
          Chọn file .xlsx / .xlsm
          <input type="file" accept=".xlsx,.xlsm,.xls" class="hidden" @change="onFileSelect" />
        </label>
        <span v-if="fileName" class="text-sm text-gray-600">{{ fileName }}</span>
      </div>
      <p class="text-xs text-gray-400 mt-2">Cấu trúc: STT | TC (tên cọc) | LT (lý trình, m) | TL (lớp) | DT (diện tích, m²)</p>
    </div>

    <!-- Step 3: Sheet selection -->
    <div v-if="sheets.length" class="bg-white rounded-lg border p-5 mb-4">
      <h2 class="font-semibold text-gray-700 mb-3">3. Chọn sheet và bên (T/P)</h2>
      <div class="space-y-2">
        <div v-for="s in sheets" :key="s.name"
          class="flex items-center gap-3 p-3 rounded-lg border"
          :class="s.selected ? 'border-primary-300 bg-primary-50' : 'border-gray-200'">
          <input type="checkbox" v-model="s.selected" :id="'sh_'+s.name" class="rounded" />
          <label :for="'sh_'+s.name" class="text-sm font-medium text-gray-700 flex-1 cursor-pointer">
            {{ s.name }} <span class="text-gray-400 font-normal">({{ s.rowCount }} dòng)</span>
          </label>
          <select v-model="s.side" class="text-sm border rounded px-2 py-1 w-20">
            <option value="T">Trái (T)</option>
            <option value="P">Phải (P)</option>
          </select>
          <input v-model="s.kmRange" class="text-sm border rounded px-2 py-1 w-40" placeholder="VD: 64+500-67+000" />
        </div>
      </div>
      <button @click="parseSelected" :disabled="!sheets.some(s => s.selected) || parsing"
        class="mt-4 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 text-sm font-medium disabled:opacity-50">
        {{ parsing ? 'Đang xử lý...' : 'Đọc dữ liệu' }}
      </button>
    </div>

    <!-- Step 4: Preview -->
    <div v-if="parsedRows.length" class="bg-white rounded-lg border p-5 mb-4">
      <h2 class="font-semibold text-gray-700 mb-3">
        4. Xem trước dữ liệu
        <span class="font-normal text-gray-400 text-sm ml-2">{{ parsedRows.length }} bản ghi · {{ activeItemType }}</span>
      </h2>

      <!-- Stats -->
      <div class="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-4">
        <div class="bg-gray-50 rounded p-3 text-center">
          <div class="text-lg font-bold text-primary-600">{{ stats.totalRows }}</div>
          <div class="text-xs text-gray-500">Bản ghi</div>
        </div>
        <div class="bg-gray-50 rounded p-3 text-center">
          <div class="text-lg font-bold text-primary-600">{{ stats.stations }}</div>
          <div class="text-xs text-gray-500">Lý trình</div>
        </div>
        <div class="bg-gray-50 rounded p-3 text-center">
          <div class="text-lg font-bold text-primary-600">{{ stats.maxLayer }}</div>
          <div class="text-xs text-gray-500">Lớp max</div>
        </div>
        <div class="bg-gray-50 rounded p-3 text-center">
          <div class="text-lg font-bold text-primary-600">{{ stats.skipped }}</div>
          <div class="text-xs text-gray-500">Bỏ qua (DT≤0)</div>
        </div>
        <div class="bg-gray-50 rounded p-3 text-center">
          <div class="text-lg font-bold text-primary-600">{{ activeItemType }}</div>
          <div class="text-xs text-gray-500">Hạng mục</div>
        </div>
      </div>

      <!-- Sample table -->
      <div class="overflow-x-auto max-h-72 overflow-y-auto border rounded">
        <table class="min-w-full text-xs">
          <thead class="bg-gray-50 sticky top-0">
            <tr>
              <th class="px-2 py-1.5 text-left">#</th>
              <th class="px-2 py-1.5 text-left">HM</th>
              <th class="px-2 py-1.5 text-left">Bên</th>
              <th class="px-2 py-1.5 text-left">Tên cọc</th>
              <th class="px-2 py-1.5 text-right">Lý trình (m)</th>
              <th class="px-2 py-1.5 text-right">Lớp</th>
              <th class="px-2 py-1.5 text-right">DT (m²)</th>
              <th class="px-2 py-1.5 text-left">Nguồn</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(r, i) in previewRows" :key="i" class="border-t hover:bg-gray-50">
              <td class="px-2 py-1 text-gray-400">{{ i + 1 }}</td>
              <td class="px-2 py-1 text-primary-600 font-medium">{{ r.item_type }}</td>
              <td class="px-2 py-1">{{ r.side }}</td>
              <td class="px-2 py-1">{{ r.section_name }}</td>
              <td class="px-2 py-1 text-right font-mono">{{ r.station }}</td>
              <td class="px-2 py-1 text-right">{{ r.layer }}</td>
              <td class="px-2 py-1 text-right font-mono">{{ r.area }}</td>
              <td class="px-2 py-1 text-gray-400">{{ r.km_range }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-if="parsedRows.length > 50" class="text-xs text-gray-400 mt-1">Hiện 50 / {{ parsedRows.length }} bản ghi</p>

      <!-- Import options -->
      <div class="mt-4 flex items-center gap-4">
        <label class="flex items-center gap-2 text-sm text-gray-600">
          <input type="checkbox" v-model="deleteExisting" class="rounded" />
          Xóa dữ liệu cũ cùng hạng mục + km_range + bên trước khi nhập
        </label>
      </div>

      <div class="mt-4 flex gap-3">
        <button @click="doImport" :disabled="importing"
          class="px-5 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium disabled:opacity-50">
          {{ importing ? `Đang nhập... ${importProgress}/${parsedRows.length}` : `Nhập ${parsedRows.length} bản ghi` }}
        </button>
        <button @click="parsedRows = []; sheets.forEach(s => s.selected = false)"
          class="px-4 py-2 border rounded-lg text-sm text-gray-600 hover:bg-gray-50">Hủy</button>
      </div>
    </div>

    <!-- Step 5: Result -->
    <div v-if="importResult" class="rounded-lg border p-5"
      :class="importResult.success ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'">
      <h2 class="font-semibold mb-2" :class="importResult.success ? 'text-green-700' : 'text-red-700'">
        {{ importResult.success ? '✓ Nhập dữ liệu thành công' : '✗ Có lỗi khi nhập' }}
      </h2>
      <p class="text-sm" :class="importResult.success ? 'text-green-600' : 'text-red-600'">
        {{ importResult.message }}
      </p>
    </div>

    <!-- Existing data summary -->
    <div v-if="existingSummary.length" class="bg-white rounded-lg border p-5 mt-4">
      <h2 class="font-semibold text-gray-700 mb-3">Dữ liệu đã có trong hệ thống</h2>
      <div class="overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left">Hạng mục</th>
              <th class="px-3 py-2 text-left">Bên</th>
              <th class="px-3 py-2 text-left">Km range</th>
              <th class="px-3 py-2 text-right">Số bản ghi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(s, i) in existingSummary" :key="i" class="border-t">
              <td class="px-3 py-2 font-medium">{{ s.item_type }}</td>
              <td class="px-3 py-2">{{ s.side }}</td>
              <td class="px-3 py-2">{{ s.km_range }}</td>
              <td class="px-3 py-2 text-right font-mono">{{ s.count }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import * as XLSX from 'xlsx'

definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { currentProject } = useProject()
const { isAdmin } = useAuth()

// --- Hạng mục ---
const ITEM_TYPES = [
  { label: 'Đắp K95', value: 'K95' },
  { label: 'Đắp K98', value: 'K98' },
  { label: 'Xử lý nền đất yếu', value: 'XLNDY' },
  { label: 'Đắp bù lún', value: 'BUL' },
  { label: 'CPĐD loại I', value: 'CPDD1' },
  { label: 'CPĐD GCXM', value: 'CPDD_GCXM' },
  { label: 'CPĐD loại II', value: 'CPDD2' },
  { label: 'BTN rỗng 25', value: 'BTN_R25' },
  { label: 'BTN chặt 19', value: 'BTN_C19' },
  { label: 'BTN chặt 12.5', value: 'BTN_C125' },
  { label: 'Khác...', value: 'custom' },
]

// Template metadata per item type for sample file generation
// unit: 'm3' → areas = diện tích mặt cắt (m²); 'm2' → areas = chiều rộng mặt rải (m)
const TEMPLATE_META: Record<string, { layers: number; areas: number[]; note: string; unit: 'm3' | 'm2' }> = {
  K95:       { layers: 5, areas: [12.5, 11.8, 10.3, 9.1, 8.0], note: 'Đắp nền K≥0.95', unit: 'm3' },
  K98:       { layers: 2, areas: [13.2, 12.8], note: 'Đắp nền K≥0.98 (50cm trên cùng)', unit: 'm3' },
  XLNDY:     { layers: 3, areas: [15.0, 14.2, 13.5], note: 'Xử lý nền đất yếu', unit: 'm3' },
  BUL:       { layers: 2, areas: [3.5, 3.2], note: 'Đắp bù lún', unit: 'm3' },
  CPDD1:     { layers: 2, areas: [5.76, 5.76], note: 'CPĐD loại I, dày 48cm', unit: 'm3' },
  CPDD_GCXM: { layers: 1, areas: [1.92], note: 'CPĐD GCXM 4%, dày 16cm', unit: 'm3' },
  CPDD2:     { layers: 1, areas: [4.80], note: 'CPĐD loại II', unit: 'm3' },
  BTN_R25:   { layers: 1, areas: [12.0], note: 'BTN rỗng 25, dày 10cm — chiều rộng mặt rải (m)', unit: 'm2' },
  BTN_C19:   { layers: 1, areas: [12.0], note: 'BTN chặt 19, dày 6cm — chiều rộng mặt rải (m)', unit: 'm2' },
  BTN_C125:  { layers: 1, areas: [12.0], note: 'BTN chặt 12.5, dày 6cm — chiều rộng mặt rải (m)', unit: 'm2' },
}

const itemType = ref('K95')
const customItemType = ref('')
const activeItemType = computed(() =>
  itemType.value === 'custom' ? (customItemType.value.trim() || 'Chưa đặt tên') : itemType.value
)

// --- Download template ---
function downloadTemplate() {
  const code = activeItemType.value
  const meta = TEMPLATE_META[code] || { layers: 1, areas: [1.0], note: code, unit: 'm3' as const }
  const isBTN = meta.unit === 'm2'
  const colELabel = isBTN ? 'Chiều rộng mặt rải (m)' : 'Diện tích mặt cắt ngang (m²)'
  const kmRange = 'Km59+000-59+200'
  const sampleStations = [
    { name: 'CC1', station: 59000 },
    { name: 'CC2', station: 59020 },
    { name: 'CC3', station: 59040 },
    { name: 'CC4', station: 59060 },
    { name: 'CC5', station: 59080 },
    { name: 'CC6', station: 59100 },
  ]

  const wb = XLSX.utils.book_new()

  // Info sheet
  const infoData = [
    ['FILE MẪU IMPORT ĐTPL'],
    [''],
    [`Hạng mục: ${ITEM_TYPES.find(t => t.value === code)?.label || code}`],
    [`Mã item_type: ${code}`],
    [`Ghi chú: ${meta.note}`],
    [''],
    ['HƯỚNG DẪN:'],
    ['- Mỗi sheet = 1 bên (T/P) + 1 đoạn Km'],
    ['- Tên sheet phải chứa T hoặc P ở cuối (bên Trái/Phải)'],
    ['- Cột A: STT (bỏ qua)'],
    ['- Cột B: Tên cắt (merged = carry forward)'],
    ['- Cột C: Lý trình (m) — số nguyên, VD: 59000 = Km59+000'],
    ['- Cột D: Thứ tự lớp (1 = trên cùng)'],
    [`- Cột E: ${colELabel}`],
    [''],
    [`Khi import, chọn hạng mục "${code}" trên trang Import.`],
    [`Số lớp điển hình: ${meta.layers}`],
    ...(isBTN ? [
      [''],
      ['⚠️ LƯU Ý: Hạng mục BTN dùng chiều rộng mặt rải (m), KHÔNG phải diện tích mặt cắt.'],
      ['Hệ thống sẽ tính diện tích bề mặt (m²) = tích phân chiều rộng × chiều dài đoạn.'],
    ] : []),
  ]
  const wsInfo = XLSX.utils.aoa_to_sheet(infoData)
  wsInfo['!cols'] = [{ wch: 60 }]
  XLSX.utils.book_append_sheet(wb, wsInfo, 'Hướng dẫn')

  // Data sheets for both sides
  for (const side of ['T', 'P']) {
    const rows: any[][] = [['STT', 'Tên cắt', 'Lý trình (m)', 'Thứ tự lớp', colELabel]]
    let stt = 1
    for (let si = 0; si < sampleStations.length; si++) {
      const s = sampleStations[si]
      for (let layer = 1; layer <= meta.layers; layer++) {
        const baseArea = meta.areas[layer - 1] ?? meta.areas[meta.areas.length - 1]
        const area = Math.round(baseArea * (1 + (si - 2) * 0.03) * 1000) / 1000
        rows.push([
          stt,
          layer === 1 ? s.name : null,
          layer === 1 ? s.station : null,
          layer,
          area,
        ])
        stt++
      }
    }
    const ws = XLSX.utils.aoa_to_sheet(rows)
    ws['!cols'] = [{ wch: 5 }, { wch: 12 }, { wch: 14 }, { wch: 10 }, { wch: 16 }]
    XLSX.utils.book_append_sheet(wb, ws, `${kmRange} ${side}`)
  }

  const buf = XLSX.write(wb, { bookType: 'xlsx', type: 'array' })
  const blob = new Blob([buf], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `DTPL-${code}-mau.xlsx`
  a.click()
  URL.revokeObjectURL(url)
}

// --- State ---
const fileName = ref('')
const sheets = ref<{ name: string; side: string; kmRange: string; selected: boolean; rowCount: number; data: any[][] }[]>([])
const parsing = ref(false)
const parsedRows = ref<{ side: string; station: number; layer: number; area: number; section_name: string; km_range: string; item_type: string }[]>([])
const deleteExisting = ref(true)
const importing = ref(false)
const importProgress = ref(0)
const importResult = ref<{ success: boolean; message: string } | null>(null)
const existingSummary = ref<{ item_type: string; side: string; km_range: string; count: number }[]>([])

const previewRows = computed(() => parsedRows.value.slice(0, 50))

const stats = computed(() => {
  const rows = parsedRows.value
  const stations = new Set(rows.map(r => `${r.side}_${r.station}`))
  const maxLayer = rows.reduce((m, r) => Math.max(m, r.layer), 0)
  return {
    totalRows: rows.length,
    stations: stations.size,
    maxLayer,
    skipped: skippedCount.value,
  }
})
const skippedCount = ref(0)

// --- Load existing summary ---
async function loadExistingSummary() {
  const pid = currentProject.value?.id
  if (!pid) return

  const { data } = await $supabase
    .from('layer_sections')
    .select('item_type, side, km_range')
    .eq('project_id', pid)

  if (!data) return

  const map = new Map<string, number>()
  for (const r of data) {
    const key = `${r.item_type || 'K95'}|${r.side}|${r.km_range}`
    map.set(key, (map.get(key) || 0) + 1)
  }

  existingSummary.value = Array.from(map.entries()).map(([k, count]) => {
    const [item_type, side, km_range] = k.split('|')
    return { item_type, side, km_range, count }
  }).sort((a, b) => a.item_type.localeCompare(b.item_type))
}

onMounted(loadExistingSummary)

// --- File handling ---
function onFileSelect(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  fileName.value = file.name
  importResult.value = null
  parsedRows.value = []

  const reader = new FileReader()
  reader.onload = (evt) => {
    const data = new Uint8Array(evt.target!.result as ArrayBuffer)
    const wb = XLSX.read(data, { type: 'array' })

    sheets.value = wb.SheetNames
      .filter(n => !['xpq', 'Sheet1'].includes(n))
      .map(name => {
        const ws = wb.Sheets[name]
        const json = XLSX.utils.sheet_to_json(ws, { header: 1 }) as any[][]
        const side = name.toUpperCase().endsWith('T') ? 'T'
          : name.toUpperCase().endsWith('P') ? 'P'
          : 'T'
        const kmMatch = name.match(/(\d+\+?\d*)\s*[-–]\s*(\d+\+?\d*)/)
        const kmRange = kmMatch ? kmMatch[0].replace('–', '-') : name

        return {
          name,
          side,
          kmRange,
          selected: true,
          rowCount: json.length - 1,
          data: json,
        }
      })
  }
  reader.readAsArrayBuffer(file)
}

// --- Parse selected sheets ---
function parseSelected() {
  parsing.value = true
  const rows: typeof parsedRows.value = []
  let skipped = 0
  const iType = activeItemType.value

  for (const sheet of sheets.value) {
    if (!sheet.selected) continue
    const data = sheet.data
    if (data.length < 2) continue

    let currentTC = ''
    let currentLT: number | null = null

    for (let i = 1; i < data.length; i++) {
      const row = data[i]
      if (!row || row.length < 5) continue

      const tcVal = row[1]
      if (tcVal !== null && tcVal !== undefined && String(tcVal).trim() !== '') {
        currentTC = String(tcVal).trim()
      }

      const ltVal = row[2]
      if (ltVal !== null && ltVal !== undefined && String(ltVal).trim() !== '') {
        const parsed = Number(ltVal)
        if (!isNaN(parsed) && parsed > 0) currentLT = parsed
      }

      const tlVal = Number(row[3])
      if (isNaN(tlVal) || tlVal < 1) continue

      const dtVal = Number(row[4])
      if (isNaN(dtVal) || dtVal <= 0) {
        skipped++
        continue
      }

      if (currentLT === null) continue

      rows.push({
        side: sheet.side,
        station: currentLT,
        layer: Math.round(tlVal),
        area: Math.round(dtVal * 1000) / 1000,
        section_name: currentTC,
        km_range: sheet.kmRange,
        item_type: iType,
      })
    }
  }

  parsedRows.value = rows
  skippedCount.value = skipped
  parsing.value = false
}

// --- Import to Supabase ---
async function doImport() {
  const pid = currentProject.value?.id
  if (!pid) {
    importResult.value = { success: false, message: 'Chưa chọn dự án' }
    return
  }

  importing.value = true
  importProgress.value = 0
  importResult.value = null

  try {
    if (deleteExisting.value) {
      const groups = new Map<string, Set<string>>()
      for (const r of parsedRows.value) {
        const key = `${r.km_range}|${r.side}`
        if (!groups.has(key)) groups.set(key, new Set())
        groups.get(key)!.add(r.item_type)
      }
      for (const [key] of groups) {
        const [km, side] = key.split('|')
        await $supabase
          .from('layer_sections')
          .delete()
          .eq('project_id', pid)
          .eq('km_range', km)
          .eq('side', side)
          .eq('item_type', activeItemType.value)
      }
    }

    const BATCH = 500
    let inserted = 0
    const allRows = parsedRows.value.map(r => ({
      project_id: pid,
      station: r.station,
      layer: r.layer,
      side: r.side,
      area: r.area,
      section_name: r.section_name,
      km_range: r.km_range,
      item_type: r.item_type,
    }))

    for (let i = 0; i < allRows.length; i += BATCH) {
      const batch = allRows.slice(i, i + BATCH)
      const { error } = await $supabase
        .from('layer_sections')
        .upsert(batch, { onConflict: 'project_id,side,station,layer,item_type' })

      if (error) throw error
      inserted += batch.length
      importProgress.value = inserted
    }

    importResult.value = {
      success: true,
      message: `Đã nhập ${inserted} bản ghi (${activeItemType.value}) thành công.`,
    }
    parsedRows.value = []
    await loadExistingSummary()
  } catch (e: any) {
    importResult.value = {
      success: false,
      message: e.message || 'Lỗi không xác định',
    }
  } finally {
    importing.value = false
  }
}
</script>
