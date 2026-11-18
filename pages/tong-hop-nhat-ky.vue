<template>
  <div>
    <div class="flex flex-wrap justify-between items-center gap-3 mb-4">
      <div>
        <h1 class="text-xl font-bold text-gray-800">Toàn bộ nhật ký thi công</h1>
        <p class="text-sm text-gray-500">{{ periodLabel }}</p>
      </div>
      <button @click="exportExcel" :disabled="!filtered.length"
        class="px-4 py-1.5 bg-green-600 text-white rounded text-sm hover:bg-green-700 disabled:opacity-40">
        Xuất Excel
      </button>
    </div>

    <!-- Bộ lọc kỳ -->
    <div class="bg-white rounded-lg shadow-sm border p-4 mb-4">
      <div class="flex flex-wrap items-end gap-3">
        <div>
          <label class="block text-xs text-gray-500 mb-1">Kỳ xem</label>
          <div class="inline-flex rounded-lg border border-gray-300 overflow-hidden">
            <button v-for="m in modes" :key="m.value" @click="setMode(m.value)"
              :class="['px-3 py-1.5 text-sm', mode === m.value ? 'bg-primary-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-50']">
              {{ m.label }}
            </button>
          </div>
        </div>

        <!-- Tuần / Tháng: lùi, tiến -->
        <div v-if="mode === 'week' || mode === 'month'" class="flex items-end gap-1">
          <button @click="shift(-1)" class="nav-btn" title="Kỳ trước">‹</button>
          <div>
            <label class="block text-xs text-gray-500 mb-1">{{ mode === 'week' ? 'Một ngày trong tuần' : 'Tháng' }}</label>
            <input v-if="mode === 'week'" type="date" v-model="anchor" @change="load" class="input-sm" />
            <input v-else type="month" v-model="monthValue" @change="load" class="input-sm" />
          </div>
          <button @click="shift(1)" class="nav-btn" title="Kỳ sau">›</button>
          <button @click="goToday" class="ml-1 px-3 py-1.5 text-sm text-primary-600 hover:underline">Hôm nay</button>
        </div>

        <!-- Khoảng ngày -->
        <template v-if="mode === 'range'">
          <div>
            <label class="block text-xs text-gray-500 mb-1">Từ ngày</label>
            <input type="date" v-model="rangeFrom" @change="load" class="input-sm" />
          </div>
          <div>
            <label class="block text-xs text-gray-500 mb-1">Đến ngày</label>
            <input type="date" v-model="rangeTo" @change="load" class="input-sm" />
          </div>
        </template>

        <div>
          <label class="block text-xs text-gray-500 mb-1">Loại công trình</label>
          <select v-model="typeId" @change="structureId = ''" class="input-sm">
            <option value="">Tất cả</option>
            <option v-for="t in types" :key="t.id" :value="t.id">{{ t.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-xs text-gray-500 mb-1">Công trình</label>
          <select v-model="structureId" class="input-sm">
            <option value="">Tất cả</option>
            <option v-for="s in structuresForType" :key="s.id" :value="s.id">{{ s.name }}</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Chuyển chế độ xem -->
    <div class="flex items-center justify-between mb-2">
      <div class="inline-flex rounded-lg border border-gray-300 overflow-hidden">
        <button @click="view = 'detail'"
          :class="['px-3 py-1.5 text-sm', view === 'detail' ? 'bg-gray-800 text-white' : 'bg-white text-gray-600 hover:bg-gray-50']">
          Nhật ký chi tiết
        </button>
        <button @click="view = 'summary'"
          :class="['px-3 py-1.5 text-sm', view === 'summary' ? 'bg-gray-800 text-white' : 'bg-white text-gray-600 hover:bg-gray-50']">
          Khối lượng trong kỳ
        </button>
      </div>
      <span class="text-sm text-gray-500">
        {{ filtered.length }} dòng nhật ký · {{ dayCount }} ngày thi công
      </span>
    </div>

    <div class="bg-white rounded-lg shadow-sm border">
      <div v-if="loading" class="p-8 text-center text-gray-400">Đang tải...</div>
      <div v-else-if="!filtered.length" class="p-8 text-center text-gray-400">
        Không có nhật ký nào trong kỳ này
      </div>

      <!-- Chi tiết theo ngày -->
      <div v-else-if="view === 'detail'" class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wide">
            <tr>
              <th class="text-left px-3 py-2">Công trình</th>
              <th class="text-left px-3 py-2 min-w-[200px]">Hạng mục</th>
              <th class="text-center px-2 py-2">Đợt/Lớp</th>
              <th v-if="showLeftRight" class="text-center px-2 py-2">Bên</th>
              <th class="text-center px-2 py-2">Lý trình</th>
              <th class="text-center px-2 py-2">ĐV</th>
              <th class="text-right px-3 py-2">Khối lượng</th>
              <th class="text-left px-3 py-2">Ghi chú</th>
              <th class="text-center px-2 py-2">Thời tiết</th>
              <th class="text-left px-3 py-2">Người ghi</th>
              <th class="px-2 py-2 w-16"></th>
            </tr>
          </thead>
          <tbody v-for="g in groups" :key="g.date">
            <tr class="bg-primary-50 border-t border-primary-100">
              <td :colspan="showLeftRight ? 11 : 10" class="px-3 py-1.5 font-semibold text-primary-800">
                {{ weekdayName(g.date) }}, {{ formatDate(g.date) }}
                <span class="font-normal text-primary-600 ml-2">{{ g.rows.length }} dòng</span>
              </td>
            </tr>
            <tr v-for="r in g.rows" :key="r.id" class="border-t border-gray-100 hover:bg-gray-50">
              <td class="px-3 py-1.5">
                <div class="font-medium text-gray-800">{{ r.structureName }}</div>
                <div class="text-xs text-gray-400">{{ r.typeName }}</div>
              </td>
              <td class="px-3 py-1.5">
                <div class="text-gray-800">{{ r.itemName }}</div>
                <div v-if="r.groupName" class="text-xs text-gray-400">{{ r.groupName }}</div>
              </td>
              <td class="px-2 py-1.5 text-center">{{ r.batch }}</td>
              <td v-if="showLeftRight" class="px-2 py-1.5 text-center">{{ sideName(r.side) }}</td>
              <td class="px-2 py-1.5 text-center whitespace-nowrap text-gray-600">{{ r.station }}</td>
              <td class="px-2 py-1.5 text-center text-gray-500">{{ r.unit }}</td>
              <td class="px-3 py-1.5 text-right font-medium">{{ formatQty(r.quantity) }}</td>
              <td class="px-3 py-1.5 text-gray-600">{{ r.notes }}</td>
              <td class="px-2 py-1.5 text-center text-gray-500">{{ r.weather }}</td>
              <td class="px-3 py-1.5 text-gray-600 text-sm whitespace-nowrap">{{ r.creatorName }}</td>
              <td class="px-2 py-1.5 text-right">
                <NuxtLink :to="`/diary?date=${r.date}&structure=${r.structureId}`" class="text-primary-600 hover:underline text-xs">
                  {{ r.locked ? 'Xem' : 'Sửa' }}
                </NuxtLink>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Khối lượng trong kỳ -->
      <div v-else class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wide">
            <tr>
              <th class="text-left px-3 py-2">Công trình</th>
              <th class="text-left px-3 py-2">Nhóm</th>
              <th class="text-left px-3 py-2">Hạng mục</th>
              <th class="text-center px-2 py-2">ĐV</th>
              <th class="text-right px-3 py-2">KL trong kỳ</th>
              <th class="text-center px-2 py-2">Số dòng NK</th>
              <th class="text-center px-2 py-2">Ngày gần nhất</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="s in summary" :key="s.key" class="border-t border-gray-100">
              <td class="px-3 py-1.5 font-medium text-gray-800">{{ s.structureName }}</td>
              <td class="px-3 py-1.5 text-gray-500">{{ s.groupName }}</td>
              <td class="px-3 py-1.5">{{ s.itemName }}</td>
              <td class="px-2 py-1.5 text-center text-gray-500">{{ s.unit }}</td>
              <td class="px-3 py-1.5 text-right font-semibold">{{ formatQty(s.quantity) }}</td>
              <td class="px-2 py-1.5 text-center">{{ s.count }}</td>
              <td class="px-2 py-1.5 text-center text-gray-500">{{ formatDate(s.lastDate) }}</td>
            </tr>
          </tbody>
        </table>
        <p class="px-3 py-2 text-xs text-gray-400 border-t">
          Cách cộng: các dòng có lý trình thì cộng dồn; các dòng không có lý trình thì lấy khối lượng lớn nhất của mỗi đợt rồi cộng các đợt (giống trang Báo cáo).
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { getTypes, getStructures } = useStructures()
const { listLines } = useDiary()
const { currentProject } = useProject()
const { error: showError } = useToast()
const { formatKm } = useStation()

type Mode = 'week' | 'month' | 'range' | 'all'
const modes: { value: Mode; label: string }[] = [
  { value: 'week', label: 'Tuần' },
  { value: 'month', label: 'Tháng' },
  { value: 'range', label: 'Khoảng ngày' },
  { value: 'all', label: 'Tất cả' },
]

// ----- Ngày tháng (theo giờ máy) -----
function iso(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}
function fromIso(s: string) {
  const [y, m, d] = s.split('-').map(Number)
  return new Date(y, m - 1, d)
}
function formatDate(s: string) {
  if (!s) return ''
  const [y, m, d] = s.split('-')
  return `${d}/${m}/${y}`
}
function weekdayName(s: string) {
  return ['Chủ nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'][fromIso(s).getDay()]
}

// ----- State -----
const mode = ref<Mode>('week')
const anchor = ref(iso(new Date()))          // một ngày bất kỳ trong tuần
const monthValue = ref(iso(new Date()).slice(0, 7)) // YYYY-MM
const rangeFrom = ref('')
const rangeTo = ref('')
const typeId = ref('')
const structureId = ref('')
const view = ref<'detail' | 'summary'>('detail')

const types = ref<any[]>([])
const structures = ref<any[]>([])
const rawLines = ref<any[]>([])
const loading = ref(true)

const showLeftRight = computed(() => currentProject.value?.has_left_right ?? false)
const structuresForType = computed(() =>
  typeId.value ? structures.value.filter(s => s.type_id === typeId.value) : structures.value)

// Khoảng ngày của kỳ đang chọn (tuần: thứ Hai → Chủ nhật)
const period = computed<{ from?: string; to?: string }>(() => {
  if (mode.value === 'week') {
    if (!anchor.value) return {}
    const d = fromIso(anchor.value)
    const mondayOffset = (d.getDay() + 6) % 7
    const mon = new Date(d.getFullYear(), d.getMonth(), d.getDate() - mondayOffset)
    const sun = new Date(mon.getFullYear(), mon.getMonth(), mon.getDate() + 6)
    return { from: iso(mon), to: iso(sun) }
  }
  if (mode.value === 'month') {
    if (!monthValue.value) return {}
    const [y, m] = monthValue.value.split('-').map(Number)
    return { from: iso(new Date(y, m - 1, 1)), to: iso(new Date(y, m, 0)) }
  }
  if (mode.value === 'range') {
    return { from: rangeFrom.value || undefined, to: rangeTo.value || undefined }
  }
  return {}
})

const periodLabel = computed(() => {
  const p = period.value
  if (mode.value === 'week' && p.from) return `Nhật ký tuần: ${formatDate(p.from)} – ${formatDate(p.to!)}`
  if (mode.value === 'month' && p.from) return `Nhật ký tháng ${monthValue.value.slice(5)}/${monthValue.value.slice(0, 4)}`
  if (mode.value === 'range') {
    if (p.from && p.to) return `Từ ${formatDate(p.from)} đến ${formatDate(p.to)}`
    if (p.from) return `Từ ${formatDate(p.from)}`
    if (p.to) return `Đến ${formatDate(p.to)}`
  }
  return 'Tất cả các ngày'
})

function setMode(m: Mode) {
  mode.value = m
  load()
}
function shift(step: number) {
  if (mode.value === 'week') {
    const d = fromIso(anchor.value || iso(new Date()))
    anchor.value = iso(new Date(d.getFullYear(), d.getMonth(), d.getDate() + step * 7))
  } else {
    const [y, m] = (monthValue.value || iso(new Date()).slice(0, 7)).split('-').map(Number)
    monthValue.value = iso(new Date(y, m - 1 + step, 1)).slice(0, 7)
  }
  load()
}
function goToday() {
  anchor.value = iso(new Date())
  monthValue.value = anchor.value.slice(0, 7)
  load()
}

// ----- Dữ liệu -----
const rowsAll = computed(() => rawLines.value.map((l: any) => {
  const e = l.diary_entries || {}
  const s = e.structures || {}
  const a = formatKm(l.km_from)
  const b = formatKm(l.km_to)
  return {
    id: l.id,
    entryId: e.id,
    date: e.entry_date as string,
    weather: e.weather || '',
    locked: !!e.is_locked,
    structureId: e.structure_id,
    structureName: s.name || '',
    typeId: s.type_id,
    typeName: s.structure_types?.name || '',
    workItemId: l.work_item_id,
    itemName: l.work_items?.name || '',
    groupName: l.work_items?.group_name || '',
    unit: l.work_items?.unit || '',
    batch: l.batch_number,
    side: l.side as string | null,
    hasKm: l.km_from !== null && l.km_from !== undefined,
    station: a && b ? `${a} – ${b}` : a || b,
    quantity: Number(l.quantity) || 0,
    notes: l.notes || '',
    creatorName: e.profiles?.full_name || '',
    createdAt: l.created_at as string,
  }
}))

const filtered = computed(() => rowsAll.value
  .filter(r => (!typeId.value || r.typeId === typeId.value) && (!structureId.value || r.structureId === structureId.value))
  .sort((x, y) => x.date.localeCompare(y.date)
    || x.structureName.localeCompare(y.structureName, 'vi')
    || (x.createdAt || '').localeCompare(y.createdAt || '')))

const groups = computed(() => {
  const out: { date: string; rows: any[] }[] = []
  for (const r of filtered.value) {
    const last = out[out.length - 1]
    if (last && last.date === r.date) last.rows.push(r)
    else out.push({ date: r.date, rows: [r] })
  }
  return out
})

const dayCount = computed(() => groups.value.length)

// Khối lượng trong kỳ theo công trình + hạng mục
const summary = computed(() => {
  const items = new Map<string, any>()
  for (const r of filtered.value) {
    const key = `${r.structureId}|${r.workItemId}`
    let it = items.get(key)
    if (!it) {
      it = { key, structureName: r.structureName, groupName: r.groupName, itemName: r.itemName, unit: r.unit,
        count: 0, lastDate: '', sum: 0, maxByBatch: new Map<string, number>() }
      items.set(key, it)
    }
    it.count++
    if (r.date > it.lastDate) it.lastDate = r.date
    if (r.hasKm) {
      it.sum += r.quantity
    } else {
      const bk = `${r.side ?? ''}|${r.batch ?? ''}`
      it.maxByBatch.set(bk, Math.max(it.maxByBatch.get(bk) ?? 0, r.quantity))
    }
  }
  return Array.from(items.values()).map(it => ({
    ...it,
    quantity: it.sum + Array.from(it.maxByBatch.values() as Iterable<number>).reduce((a, b) => a + b, 0),
  }))
})

function sideName(s: string | null) {
  return s === 'T' ? 'Trái' : s === 'P' ? 'Phải' : '—'
}
function formatQty(n: number) {
  return (Math.round(n * 1000) / 1000).toLocaleString('vi-VN')
}

async function load() {
  loading.value = true
  try {
    rawLines.value = await listLines({ dateFrom: period.value.from, dateTo: period.value.to })
  } catch (e: any) {
    showError(e.message)
    rawLines.value = []
  } finally {
    loading.value = false
  }
}

async function exportExcel() {
  try {
    const XLSX = await import('xlsx')
    const detail = filtered.value.map((r, i) => ({
      'STT': i + 1,
      'Ngày': formatDate(r.date),
      'Thứ': weekdayName(r.date),
      'Loại công trình': r.typeName,
      'Công trình': r.structureName,
      'Nhóm': r.groupName,
      'Hạng mục': r.itemName,
      'Đợt/Lớp': r.batch,
      'Bên': sideName(r.side),
      'Lý trình': r.station,
      'ĐV': r.unit,
      'Khối lượng': r.quantity,
      'Ghi chú': r.notes,
      'Thời tiết': r.weather,
      'Người ghi': r.creatorName,
      'Trạng thái': r.locked ? 'Đã khóa' : 'Nháp',
    }))
    const sum = summary.value.map((s, i) => ({
      'STT': i + 1,
      'Công trình': s.structureName,
      'Nhóm': s.groupName,
      'Hạng mục': s.itemName,
      'ĐV': s.unit,
      'KL trong kỳ': s.quantity,
      'Số dòng NK': s.count,
      'Ngày gần nhất': formatDate(s.lastDate),
    }))
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(detail), 'Nhật ký')
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(sum), 'Khối lượng kỳ')
    const code = currentProject.value?.code || 'du-an'
    const tag = period.value.from ? `${period.value.from}_${period.value.to || ''}` : 'tat-ca'
    XLSX.writeFile(wb, `nhat-ky-${code}-${tag}.xlsx`)
  } catch (e: any) {
    showError(e.message)
  }
}

async function init() {
  try {
    ;[types.value, structures.value] = await Promise.all([getTypes(), getStructures()])
  } catch (e: any) {
    showError(e.message)
  }
  await load()
}

onMounted(init)
// Dự án được nạp sau khi trang mở (hoặc đổi dự án): tải lại theo dự án đó
watch(() => currentProject.value?.id, (id, old) => { if (id !== old) init() })
</script>

<style scoped>
.input-sm {
  @apply px-3 py-1.5 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
.nav-btn {
  @apply px-2.5 py-1.5 border border-gray-300 rounded text-gray-600 hover:bg-gray-50 text-sm leading-5;
}
</style>
