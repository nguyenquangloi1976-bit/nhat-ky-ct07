<template>
  <div>
    <div class="flex flex-wrap justify-between items-center gap-3 mb-4">
      <div>
        <h1 class="text-xl font-bold text-gray-800">Cắt dọc tiến độ thi công</h1>
        <p class="text-sm text-gray-500">
          Mỗi dải là một lớp, xếp từ lớp trên cùng xuống lớp dưới cùng. Đoạn tô màu = đã có nhật ký thi công trên lý trình đó.
        </p>
      </div>
    </div>

    <!-- Điều khiển -->
    <div class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="flex flex-wrap items-end gap-3">
        <div>
          <label class="block text-xs text-gray-500 mb-1">Công trình (đoạn tuyến)</label>
          <select v-model="structureId" @change="onStructureChange" class="input-sm min-w-[220px]">
            <optgroup v-for="g in structureGroups" :key="g.id" :label="g.name">
              <option v-for="s in g.items" :key="s.id" :value="s.id">{{ s.name }}</option>
            </optgroup>
          </select>
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Lý trình đầu</label>
          <input v-model="fromText" @change="applyRange" placeholder="Km59+000"
            :class="['input-sm w-28 text-center', fromText && parseKm(fromText) === null ? 'border-red-500 bg-red-50' : '']" />
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Lý trình cuối</label>
          <input v-model="toText" @change="applyRange" placeholder="Km68+700"
            :class="['input-sm w-28 text-center', toText && parseKm(toText) === null ? 'border-red-500 bg-red-50' : '']" />
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Tỷ lệ ngang</label>
          <div class="inline-flex rounded-lg border border-gray-300 overflow-hidden">
            <button v-for="z in zooms" :key="z.px" @click="pxPer100 = z.px"
              :class="['px-3 py-1.5 text-sm', pxPer100 === z.px ? 'bg-primary-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-50']">
              {{ z.label }}
            </button>
          </div>
        </div>
        <button @click="showSetup = !showSetup" class="px-3 py-1.5 text-sm border border-gray-300 rounded hover:bg-gray-50">
          {{ showSetup ? 'Ẩn thiết lập lớp' : 'Thiết lập lớp' }}
        </button>
        <button @click="reload" class="px-3 py-1.5 text-sm text-primary-600 hover:underline">Tải lại</button>
      </div>

      <!-- Thiết lập số lớp -->
      <div v-if="showSetup" class="mt-4 border-t pt-3">
        <p class="text-xs text-gray-500 mb-2">
          Số lớp con của từng lớp (vd: Đắp K95 gồm 10 lớp). Nhập 0 để ẩn lớp. Lưu trên trình duyệt này, riêng cho từng công trình.
        </p>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-x-6 gap-y-1.5">
          <label v-for="l in layerDefs" :key="l.name" class="flex items-center justify-between gap-2 text-sm">
            <span class="flex items-center gap-2 min-w-0">
              <span class="w-3 h-3 rounded-sm flex-shrink-0" :style="{ background: l.color }"></span>
              <span class="truncate text-gray-700">{{ l.name }}</span>
            </span>
            <input type="number" min="0" max="30" :value="liftCount(l.name)"
              @change="setLiftCount(l.name, Number(($event.target as HTMLInputElement).value))"
              class="input-sm w-16 text-center py-1" />
          </label>
        </div>
      </div>
    </div>

    <div v-if="loading" class="bg-white rounded-lg border p-12 text-center text-gray-400">Đang tải...</div>

    <div v-else-if="!structureId" class="bg-white rounded-lg border p-12 text-center text-gray-400">
      Chưa có công trình. Vào <NuxtLink to="/admin/structures" class="text-primary-600 underline">Quản lý công trình</NuxtLink> để thêm đoạn tuyến.
    </div>

    <div v-else-if="rangeStart === null || rangeEnd === null" class="bg-white rounded-lg border p-12 text-center text-gray-500">
      Nhập lý trình đầu và lý trình cuối của đoạn tuyến (dạng Km59+000) để vẽ cắt dọc.
    </div>

    <template v-else>
      <div v-if="missingKmCount" class="mb-3 px-3 py-2 bg-yellow-50 border border-yellow-200 rounded text-sm text-yellow-800">
        Có {{ missingKmCount }} dòng nhật ký của công trình này chưa nhập lý trình nên chưa thể hiện trên cắt dọc.
      </div>
      <div v-if="!layerRows.length" class="bg-white rounded-lg border p-12 text-center text-gray-500">
        Chưa có lớp nào để vẽ. Hãy ghi nhật ký có lý trình cho công trình này, hoặc bật "Thiết lập lớp".
      </div>

      <div v-else class="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div class="overflow-x-auto">
          <div :style="{ width: labelW + trackW + 'px' }">
            <!-- Trục lý trình -->
            <div class="flex border-b border-gray-300 bg-gray-50 sticky top-0 z-10">
              <div class="sticky left-0 z-20 bg-gray-50 border-r border-gray-300 flex-shrink-0 px-2 py-1 text-xs font-semibold text-gray-500 uppercase"
                :style="{ width: labelW + 'px' }">
                Lớp · đã thi công
              </div>
              <div class="relative h-7" :style="{ width: trackW + 'px' }">
                <div v-for="t in ticks" :key="t.m" class="absolute top-0 h-full border-l border-gray-300 text-[10px] text-gray-500 pl-1 whitespace-nowrap leading-7"
                  :style="{ left: xOf(t.m) + 'px' }">
                  {{ t.label }}
                </div>
              </div>
            </div>

            <!-- Các khối: Trái / Phải -->
            <template v-for="blk in blocks" :key="blk.key">
              <div class="flex bg-primary-700 text-white">
                <div class="sticky left-0 z-10 bg-primary-700 px-2 py-1 text-xs font-bold uppercase tracking-wide flex-shrink-0"
                  :style="{ width: labelW + 'px' }">
                  {{ blk.label }}
                </div>
                <div :style="{ width: trackW + 'px' }"></div>
              </div>

              <div v-for="row in blk.rows" :key="blk.key + row.key"
                :class="['flex border-b border-gray-100', row.firstOther ? 'border-t-2 border-t-gray-300' : '']">
                <div class="sticky left-0 z-10 bg-white border-r border-gray-300 flex-shrink-0 px-2 flex items-center justify-between gap-2"
                  :style="{ width: labelW + 'px', height: rowH + 'px' }">
                  <span class="truncate text-xs text-gray-800" :title="row.label">{{ row.label }}</span>
                  <span class="text-[11px] text-gray-500 whitespace-nowrap">
                    {{ Math.round(row.done) }} m · {{ pct(row.done) }}
                  </span>
                </div>
                <div class="relative track" :style="{ width: trackW + 'px', height: rowH + 'px', backgroundSize: gridPx + 'px 100%' }">
                  <div v-for="seg in row.segments" :key="seg.id"
                    class="absolute top-[2px] bottom-[2px] rounded-[1px] hover:ring-2 hover:ring-yellow-400 cursor-default"
                    :style="{ left: xOf(seg.a) + 'px', width: Math.max(2, xOf(seg.b) - xOf(seg.a)) + 'px', background: row.color }"
                    :title="seg.title"></div>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>

      <p class="mt-3 text-xs text-gray-500">
        Cách ghi để lên cắt dọc: ở trang Nhật ký, mỗi dòng nhập Từ Km – Đến Km, cột Đợt/Lớp là số lớp con (lớp đắp thứ mấy)
        <template v-if="showLeftRight">, cột Bên chọn T hoặc P (để trống = cả hai bên)</template>.
        Rê chuột vào đoạn tô màu để xem ngày và khối lượng.
      </p>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { getTypes, getStructures, getWorkItems } = useStructures()
const { listLines } = useDiary()
const { currentProject } = useProject()
const { error: showError } = useToast()
const { parseKm, formatKm, parseKmRange } = useStation()

const labelW = 250
const rowH = 22
const zooms = [
  { px: 4, label: 'Nhỏ' },
  { px: 10, label: 'Vừa' },
  { px: 25, label: 'Lớn' },
  { px: 60, label: 'Rất lớn' },
]

const loading = ref(true)
const types = ref<any[]>([])
const structures = ref<any[]>([])
const structureId = ref('')
const workItems = ref<any[]>([])
const catalogItems = ref<any[]>([])
const lines = ref<any[]>([])

const fromText = ref('')
const toText = ref('')
const rangeStart = ref<number | null>(null)
const rangeEnd = ref<number | null>(null)
const pxPer100 = ref(10)
const showSetup = ref(false)
const liftCfg = ref<Record<string, number>>({})

const showLeftRight = computed(() => currentProject.value?.has_left_right ?? false)

const structureGroups = computed(() => types.value
  .map(t => ({ id: t.id, name: t.name, items: structures.value.filter(s => s.type_id === t.id) }))
  .filter(g => g.items.length))

// ----- Thứ tự lớp: số nhỏ = nằm trên. null = không phải lớp kết cấu -----
const LAYER_RULES: { test: RegExp; rank: number; color: string }[] = [
  { test: /tạo nhám/, rank: 1, color: '#111827' },
  { test: /12[.,]5/, rank: 2, color: '#1f2937' },
  { test: /c\s*19|chặt 19|lớp dưới/, rank: 3, color: '#374151' },
  { test: /rỗng/, rank: 4, color: '#4b5563' },
  { test: /bê tông nhựa|btn/, rank: 5, color: '#4b5563' },
  { test: /bê tông xi măng mặt đường|btxm/, rank: 6, color: '#64748b' },
  { test: /gcxm|gia cố xi măng/, rank: 7, color: '#6b7280' },
  { test: /(cpđd|đá dăm)[^,;]*loại ii\b|cpđd ii\b/, rank: 9, color: '#a8a29e' },
  { test: /(cpđd|đá dăm)[^,;]*loại i\b|cpđd i\b/, rank: 8, color: '#9ca3af' },
  { test: /k\s*98/, rank: 10, color: '#7c2d12' },
  { test: /k\s*95/, rank: 11, color: '#c2410c' },
  { test: /đắp nền/, rank: 12, color: '#ea580c' },
  { test: /vải địa|lưới địa|bấc thấm|giếng cát|cọc xi măng|đệm cát/, rank: 13, color: '#0e7490' },
  { test: /đào nền|đánh cấp/, rank: 14, color: '#a16207' },
  { test: /bóc hữu cơ/, rank: 15, color: '#4d7c0f' },
]
const OTHER_COLOR = '#7c3aed'

function ruleOf(name: string) {
  const n = name.toLowerCase()
  if (n.includes('đường gom')) return null // đường gom không thuộc mặt cắt tuyến chính
  return LAYER_RULES.find(r => r.test.test(n)) || null
}

// Dòng nhật ký có lý trình, gom theo tên hạng mục
const stationLines = computed(() => lines.value.filter(l => l.km_from !== null && l.km_from !== undefined))
const missingKmCount = computed(() => lines.value.length - stationLines.value.length)

// Danh sách lớp: hạng mục của công trình + danh mục mẫu cùng loại (để thấy cả lớp chưa thi công)
const layerDefs = computed(() => {
  const names = new Set<string>()
  for (const w of workItems.value) names.add(w.name)
  for (const c of catalogItems.value) names.add(c.name)
  const withData = new Set(stationLines.value.map(l => l.work_items?.name).filter(Boolean))
  const defs: { name: string; rank: number; color: string; isLayer: boolean }[] = []
  for (const name of names) {
    const rule = ruleOf(name)
    if (rule) defs.push({ name, rank: rule.rank, color: rule.color, isLayer: true })
    else if (withData.has(name)) defs.push({ name, rank: 99, color: OTHER_COLOR, isLayer: false })
  }
  return defs.sort((a, b) => a.rank - b.rank || a.name.localeCompare(b.name, 'vi'))
})

// Max layer count từ ĐTPL (layer_sections) cho mỗi item_type → tên hạng mục
const dtplLayerCounts = ref<Record<string, number>>({})
// Station-level max layer: key = "itemType:side", value = sorted array of {station, maxLayer}
const dtplStationMaxLayer = ref<Record<string, { station: number; maxLayer: number }[]>>({})

// Map item_type → regex khớp tên hạng mục (ngược lại ITEM_TYPE_MAP trong reports)
const ITEM_TYPE_NAME_MAP: { itemType: string; pattern: RegExp }[] = [
  { itemType: 'K95', pattern: /k95/i },
  { itemType: 'K98', pattern: /k98/i },
  { itemType: 'XLNDY', pattern: /xử lý nền|xlndy|xử lí nền/i },
  { itemType: 'BUL', pattern: /bù lún|bul/i },
  { itemType: 'CPDD1', pattern: /cpđd[^,;]*loại i\b|cpđd i\b|cpdd.?loai.?i\b|cpđd.?i(?!i)/i },
  { itemType: 'CPDD_GCXM', pattern: /gcxm|gia cố xi măng/i },
  { itemType: 'CPDD2', pattern: /cpđd[^,;]*loại ii\b|cpđd ii\b|cpdd.?loai.?ii\b/i },
  { itemType: 'BTN_R25', pattern: /btn.?rỗng|btn.?r.?25/i },
  { itemType: 'BTN_C19', pattern: /btn.?chặt.?19|btn.?c.?19/i },
  { itemType: 'BTN_C125', pattern: /btn.?chặt.?12[,.]?5|btn.?c.?12[,.]?5/i },
]

function _itemTypeForName(name: string): string | null {
  const n = name.toLowerCase()
  for (const m of ITEM_TYPE_NAME_MAP) {
    if (m.pattern.test(n)) return m.itemType
  }
  return null
}

async function loadDtplLayerCounts() {
  const pid = currentProject.value?.id
  if (!pid) return
  const { data, error } = await $supabase
    .from('layer_sections')
    .select('item_type, layer, side, station')
    .eq('project_id', pid)
  if (error || !data) return
  const maxByType: Record<string, number> = {}
  const stationMap: Record<string, Map<number, number>> = {}
  for (const row of data) {
    const t = row.item_type || 'K95'
    if (!maxByType[t] || row.layer > maxByType[t]) maxByType[t] = row.layer
    // Station-level: key = itemType:side hoặc itemType (nếu không có side)
    const sideKey = row.side ? `${t}:${row.side}` : t
    if (!stationMap[sideKey]) stationMap[sideKey] = new Map()
    const cur = stationMap[sideKey].get(row.station) || 0
    if (row.layer > cur) stationMap[sideKey].set(row.station, row.layer)
  }
  dtplLayerCounts.value = maxByType
  const result: Record<string, { station: number; maxLayer: number }[]> = {}
  for (const [key, map] of Object.entries(stationMap)) {
    result[key] = Array.from(map.entries())
      .map(([station, maxLayer]) => ({ station, maxLayer }))
      .sort((a, b) => a.station - b.station)
  }
  dtplStationMaxLayer.value = result
}

// Tìm max layer ĐTPL trong đoạn [kmFrom, kmTo] (mở rộng 500m hai bên)
function getMaxLayerForRange(itemType: string, side: string | null, kmFrom: number, kmTo: number): number {
  const keys = side ? [`${itemType}:${side}`, itemType] : [itemType]
  for (const key of keys) {
    const arr = dtplStationMaxLayer.value[key]
    if (!arr || arr.length === 0) continue
    let maxL = 0
    for (const s of arr) {
      if (s.station >= kmFrom && s.station <= kmTo) {
        if (s.maxLayer > maxL) maxL = s.maxLayer
      }
    }
    if (maxL > 0) return maxL
  }
  return 0  // không có cọc ĐTPL trong đoạn → không xác nhận
}

function liftCount(name: string) {
  const userCfg = liftCfg.value[name]
  if (userCfg === 0) return 0  // user tắt hẳn
  const itemType = _itemTypeForName(name)
  const dtpl = itemType ? (dtplLayerCounts.value[itemType] || 0) : 0
  // Lấy max giữa ĐTPL và userCfg để hiển thị đủ hàng
  if (dtpl > 0) return userCfg !== undefined ? Math.max(dtpl, userCfg) : dtpl
  if (userCfg !== undefined) return userCfg
  return 1
}
function setLiftCount(name: string, n: number) {
  liftCfg.value = { ...liftCfg.value, [name]: Math.max(0, Math.min(30, Math.floor(n) || 0)) }
  saveLocal()
}

function unionLength(segs: { a: number; b: number }[]) {
  const s = segs.map(x => [x.a, x.b] as [number, number]).sort((p, q) => p[0] - q[0])
  let total = 0
  let cur: [number, number] | null = null
  for (const [a, b] of s) {
    if (!cur || a > cur[1]) {
      if (cur) total += cur[1] - cur[0]
      cur = [a, b]
    } else if (b > cur[1]) {
      cur[1] = b
    }
  }
  return total + (cur ? cur[1] - cur[0] : 0)
}

function fmtDate(s: string) {
  if (!s) return ''
  const [y, m, d] = s.split('-')
  return `${d}/${m}/${y}`
}

// side: 'T' | 'P' | null (null = vẽ mọi dòng, dùng khi dự án không tách trái/phải)
function buildRows(side: 'T' | 'P' | null) {
  const start = rangeStart.value!
  const end = rangeEnd.value!
  const rows: any[] = []
  let otherSeen = false
  for (const def of layerDefs.value) {
    const mine = stationLines.value.filter(l =>
      l.work_items?.name === def.name && (side === null || !l.side || l.side === side))
    const maxBatch = mine.reduce((m, l) => Math.max(m, Number(l.batch_number) || 0), 0)
    const itemType = _itemTypeForName(def.name)
    const cfg = liftCount(def.name)
    if (cfg === 0) continue
    const count = Math.max(cfg, cfg > 1 || maxBatch > 1 ? maxBatch : 1)
    // Lớp 1 = trên cùng, lớp N = đáy (đắp đầu tiên)
    // Ghi lớp X → đã đắp từ đáy (N) lên đến lớp X → tô lớp X→N
    for (let lift = 1; lift <= count; lift++) {
      const segs = mine
        .filter(l => {
          if (count === 1) return true
          const bn = Number(l.batch_number) || count
          if (lift < bn) return false  // lớp trên lớp đã ghi → chưa đắp
          if (lift === bn) return true  // đúng lớp đã ghi → luôn hiện
          // lift > bn: lớp dưới lớp đã ghi → chỉ tô nếu ĐTPL xác nhận đoạn có lớp đó
          if (itemType) {
            const a0 = Number(l.km_from)
            const b0 = l.km_to === null || l.km_to === undefined ? a0 : Number(l.km_to)
            const maxInRange = getMaxLayerForRange(itemType, side, Math.min(a0, b0), Math.max(a0, b0))
            if (maxInRange > 0) return lift <= maxInRange  // ĐTPL có → giới hạn theo ĐTPL
            return false  // ĐTPL chưa có dữ liệu → không mở rộng
          }
          return false  // không xác định item_type → không mở rộng
        })
        .map(l => {
          const a0 = Number(l.km_from)
          const b0 = l.km_to === null || l.km_to === undefined ? a0 : Number(l.km_to)
          const a = Math.max(start, Math.min(a0, b0))
          const b = Math.min(end, Math.max(a0, b0))
          const e = l.diary_entries || {}
          const lineLift = Number(l.batch_number) || 1
          return {
            id: l.id, a, b,
            title: `${def.name}${count > 1 ? ' – lớp ' + lift : ''}` +
              (lineLift !== lift ? ` (đắp đến lớp ${lineLift})` : '') +
              `\n${fmtDate(e.entry_date)} · ${formatKm(a0)} – ${formatKm(b0)}` +
              `\nKL: ${l.quantity} ${l.work_items?.unit || ''}${l.notes ? '\n' + l.notes : ''}`,
          }
        })
        .filter(sg => sg.b >= sg.a && sg.a <= end && sg.b >= start)
      rows.push({
        key: `${def.name}#${lift}`,
        label: count > 1 ? `${def.name} – lớp ${lift}` : def.name,
        color: def.color,
        segments: segs,
        done: unionLength(segs),
        firstOther: !def.isLayer && !otherSeen,
      })
      if (!def.isLayer) otherSeen = true
    }
  }
  return rows
}

const blocks = computed(() => {
  if (rangeStart.value === null || rangeEnd.value === null) return []
  if (!showLeftRight.value) return [{ key: 'all', label: 'Toàn mặt cắt', rows: buildRows(null) }]
  return [
    { key: 'T', label: 'Bên trái', rows: buildRows('T') },
    { key: 'P', label: 'Bên phải', rows: buildRows('P') },
  ]
})
const layerRows = computed(() => blocks.value[0]?.rows || [])

// ----- Hình học -----
const totalLen = computed(() => (rangeEnd.value ?? 0) - (rangeStart.value ?? 0))
const trackW = computed(() => Math.max(200, Math.round(totalLen.value / 100 * pxPer100.value)))
const gridPx = computed(() => pxPer100.value >= 10 ? pxPer100.value : pxPer100.value * 10) // vạch 100 m hoặc 1 km
function xOf(m: number) {
  return (m - (rangeStart.value ?? 0)) / 100 * pxPer100.value
}
const ticks = computed(() => {
  if (rangeStart.value === null || rangeEnd.value === null) return []
  const step = [100, 200, 500, 1000, 2000, 5000].find(s => s / 100 * pxPer100.value >= 70) || 5000
  const out: { m: number; label: string }[] = []
  for (let m = Math.ceil(rangeStart.value / step) * step; m < rangeEnd.value; m += step) {
    out.push({ m, label: formatKm(m) })
  }
  return out
})
function pct(done: number) {
  return totalLen.value > 0 ? (done / totalLen.value * 100).toFixed(1) + '%' : ''
}

// ----- Lưu thiết lập theo công trình (trên trình duyệt) -----
function localKey() {
  return `catdoc:${structureId.value}`
}
function saveLocal() {
  try {
    localStorage.setItem(localKey(), JSON.stringify({
      from: fromText.value, to: toText.value, lifts: liftCfg.value, px: pxPer100.value,
    }))
  } catch { /* trình duyệt chặn lưu: bỏ qua */ }
}
function readLocal(): any {
  try {
    return JSON.parse(localStorage.getItem(localKey()) || 'null')
  } catch {
    return null
  }
}
watch(pxPer100, saveLocal)

function applyRange() {
  const a = parseKm(fromText.value)
  const b = parseKm(toText.value)
  if (a !== null) fromText.value = formatKm(a)
  if (b !== null) toText.value = formatKm(b)
  if (a !== null && b !== null && a !== b) {
    rangeStart.value = Math.min(a, b)
    rangeEnd.value = Math.max(a, b)
  } else {
    rangeStart.value = null
    rangeEnd.value = null
  }
  saveLocal()
}

async function loadStructure() {
  if (!structureId.value) return
  loading.value = true
  try {
    const st = structures.value.find(s => s.id === structureId.value)
    const typeCode = types.value.find(t => t.id === st?.type_id)?.code
    const [wi, ln, cat] = await Promise.all([
      getWorkItems(structureId.value),
      listLines({ structureId: structureId.value }),
      typeCode
        ? $supabase.from('work_item_catalog').select('name').eq('type_code', typeCode).eq('is_active', true)
        : Promise.resolve({ data: [] as any[] }),
    ])
    workItems.value = wi
    lines.value = ln
    catalogItems.value = (cat as any).data || []

    // Load max layer counts from ĐTPL data
    await loadDtplLayerCounts()

    // Khoảng lý trình: ưu tiên thiết lập đã lưu → mô tả công trình → theo dữ liệu nhật ký
    const saved = readLocal()
    liftCfg.value = saved?.lifts || {}
    if (saved?.px) pxPer100.value = saved.px
    let a: number | null = parseKm(saved?.from)
    let b: number | null = parseKm(saved?.to)
    if (a === null || b === null) {
      const r = parseKmRange(st?.station) || parseKmRange(st?.name)
      if (r) { a = r.from; b = r.to }
    }
    if (a === null || b === null) {
      const withKm = ln.filter((l: any) => l.km_from !== null && l.km_from !== undefined)
      if (withKm.length) {
        a = Math.floor(Math.min(...withKm.map((l: any) => Number(l.km_from))) / 100) * 100
        b = Math.ceil(Math.max(...withKm.map((l: any) => Number(l.km_to ?? l.km_from))) / 100) * 100
      }
    }
    fromText.value = a !== null ? formatKm(a) : ''
    toText.value = b !== null ? formatKm(b) : ''
    rangeStart.value = a !== null && b !== null && a !== b ? Math.min(a, b) : null
    rangeEnd.value = a !== null && b !== null && a !== b ? Math.max(a, b) : null
  } catch (e: any) {
    showError(e.message)
  } finally {
    loading.value = false
  }
}

function onStructureChange() {
  loadStructure()
}
function reload() {
  loadStructure()
}

async function init() {
  loading.value = true
  try {
    ;[types.value, structures.value] = await Promise.all([getTypes(), getStructures()])
    // Mặc định chọn đoạn tuyến đầu tiên thuộc loại Đường, nếu không có thì công trình đầu tiên
    const roadType = types.value.find(t => t.code === 'DUONG')
    const first = structures.value.find(s => s.type_id === roadType?.id) || structures.value[0]
    structureId.value = first?.id || ''
    if (first) await loadStructure()
  } catch (e: any) {
    showError(e.message)
  } finally {
    loading.value = false
  }
}

onMounted(init)
// Dự án được nạp sau khi trang mở (hoặc đổi dự án): tải lại theo dự án đó
watch(() => currentProject.value?.id, (id, old) => { if (id !== old) init() })
</script>

<style scoped>
.input-sm {
  @apply px-3 py-1.5 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
/* Vạch chia dọc trên mỗi dải */
.track {
  background-image: linear-gradient(to right, #e5e7eb 1px, transparent 1px);
  background-repeat: repeat-x;
}
</style>
