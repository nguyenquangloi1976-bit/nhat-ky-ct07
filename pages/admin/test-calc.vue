<template>
  <div class="max-w-4xl mx-auto p-4">
    <h1 class="text-xl font-bold mb-4">Test tính KL từ DTPL</h1>
    
    <div class="flex flex-wrap gap-3 mb-4">
      <div>
        <label class="text-xs text-gray-500">Bên</label>
        <select v-model="side" class="input-sm">
          <option value="T">T</option>
          <option value="P">P</option>
        </select>
      </div>
      <div>
        <label class="text-xs text-gray-500">Lớp</label>
        <input v-model.number="layer" type="number" class="input-sm w-20" />
      </div>
      <div>
        <label class="text-xs text-gray-500">Từ KM (m)</label>
        <input v-model.number="kmFrom" type="number" class="input-sm w-28" />
      </div>
      <div>
        <label class="text-xs text-gray-500">Đến KM (m)</label>
        <input v-model.number="kmTo" type="number" class="input-sm w-28" />
      </div>
      <button @click="run" class="btn-primary mt-auto">Tính</button>
    </div>

    <div v-if="result" class="bg-white border rounded p-4 mb-4">
      <h2 class="font-bold text-lg mb-2">Kết quả: {{ result.volume }} m³</h2>
      <p class="text-sm text-gray-600 mb-2">Công thức: {{ result.formula }}</p>
      <p class="text-xs text-gray-400 mb-2">DT tại mỗi MC = tổng DT các lớp từ {{ layer }} đến lớp đáy</p>
      <table class="table-auto text-sm w-full">
        <thead>
          <tr class="border-b bg-gray-50">
            <th class="text-left p-1">Station</th>
            <th class="text-right p-1">Σ Area (m²)</th>
            <th class="text-left p-1">Section</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in result.sections" :key="s.station" class="border-b">
            <td class="p-1">{{ s.station }} (Km{{ Math.floor(s.station/1000) }}+{{ String(s.station % 1000).padStart(3,'0') }})</td>
            <td class="text-right p-1 font-mono">{{ s.area }}</td>
            <td class="p-1">{{ s.section_name }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Chi tiết từng lớp tại mỗi station -->
    <div v-if="layerDetail.length" class="bg-white border rounded p-4">
      <h2 class="font-bold mb-2">Chi tiết từng lớp (layer {{ layer }}→đáy) trong khoảng</h2>
      <table class="table-auto text-sm w-full">
        <thead>
          <tr class="border-b bg-gray-50">
            <th class="text-left p-1">Station</th>
            <th class="text-right p-1">Layer</th>
            <th class="text-right p-1">Area (m²)</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="st in groupedDetail" :key="st.station">
            <tr v-for="(r, i) in st.rows" :key="r.station+'-'+r.layer" 
              :class="[i === 0 ? 'border-t-2 border-gray-300' : '', 'border-b border-gray-100']">
              <td class="p-1">{{ i === 0 ? `${r.station} (Km${Math.floor(r.station/1000)}+${String(r.station % 1000).padStart(3,'0')})` : '' }}</td>
              <td class="text-right p-1">{{ r.layer }}</td>
              <td class="text-right p-1 font-mono">{{ r.area }}</td>
            </tr>
            <tr class="bg-green-50 font-bold border-b">
              <td class="p-1 text-right" colspan="2">Σ</td>
              <td class="text-right p-1 font-mono">{{ st.total }}</td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
const { $supabase } = useNuxtApp()
const { currentProject } = useProject()
const { calcVolume } = useLayerVolume()

const side = ref('T')
const layer = ref(27)
const kmFrom = ref(66000)
const kmTo = ref(66320)
const result = ref<any>(null)
const layerDetail = ref<any[]>([])

const groupedDetail = computed(() => {
  const map = new Map<number, { rows: any[], total: number }>()
  for (const r of layerDetail.value) {
    if (!map.has(r.station)) map.set(r.station, { rows: [], total: 0 })
    const g = map.get(r.station)!
    g.rows.push(r)
    g.total = Math.round((g.total + r.area) * 1000) / 1000
  }
  return Array.from(map.entries())
    .sort((a, b) => a[0] - b[0])
    .map(([station, data]) => ({ station, ...data }))
})

async function run() {
  const pid = currentProject.value?.id
  if (!pid) { alert('Chọn project trước'); return }

  // 1. Tính KL bằng calcVolume (đã sửa: gộp các lớp)
  result.value = await calcVolume({
    side: side.value as 'T' | 'P',
    layer: layer.value,
    kmFrom: kmFrom.value,
    kmTo: kmTo.value,
  })

  // 2. Query chi tiết từng lớp để verify
  const { data } = await $supabase
    .from('layer_sections')
    .select('station, layer, area')
    .eq('project_id', pid)
    .eq('side', side.value)
    .gte('layer', layer.value)
    .eq('item_type', 'K95')
    .gte('station', kmFrom.value)
    .lte('station', kmTo.value)
    .order('station')
    .order('layer')
  
  layerDetail.value = data || []
}
</script>
