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
      <table class="table-auto text-sm w-full">
        <thead>
          <tr class="border-b">
            <th class="text-left p-1">Station</th>
            <th class="text-right p-1">Layer</th>
            <th class="text-right p-1">Area (m²)</th>
            <th class="text-left p-1">Section</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in result.sections" :key="s.station" class="border-b">
            <td class="p-1">{{ s.station }} (Km{{ Math.floor(s.station/1000) }}+{{ String(s.station % 1000).padStart(3,'0') }})</td>
            <td class="text-right p-1">{{ s.layer }}</td>
            <td class="text-right p-1">{{ s.area }}</td>
            <td class="p-1">{{ s.section_name }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Show all stations in range -->
    <div v-if="allStations.length" class="bg-white border rounded p-4">
      <h2 class="font-bold mb-2">Tất cả MC trong khoảng mở rộng (± 2km)</h2>
      <table class="table-auto text-sm w-full">
        <thead>
          <tr class="border-b">
            <th class="text-left p-1">Station</th>
            <th class="text-right p-1">Layer</th>
            <th class="text-right p-1">Area (m²)</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in allStations" :key="s.station+'-'+s.layer" 
            :class="[s.station >= kmFrom && s.station <= kmTo ? 'bg-green-50 font-bold' : '', 'border-b']">
            <td class="p-1">{{ s.station }} (Km{{ Math.floor(s.station/1000) }}+{{ String(s.station % 1000).padStart(3,'0') }})</td>
            <td class="text-right p-1">{{ s.layer }}</td>
            <td class="text-right p-1">{{ s.area }}</td>
          </tr>
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
const allStations = ref<any[]>([])

async function run() {
  const pid = currentProject.value?.id
  if (!pid) { alert('Chọn project trước'); return }

  // 1. Tính KL bằng calcVolume
  result.value = await calcVolume({
    side: side.value as 'T' | 'P',
    layer: layer.value,
    kmFrom: kmFrom.value,
    kmTo: kmTo.value,
  })

  // 2. Query tất cả stations mở rộng để xem
  const expand = 2000
  const { data } = await $supabase
    .from('layer_sections')
    .select('station, layer, side, area, section_name')
    .eq('project_id', pid)
    .eq('side', side.value)
    .eq('layer', layer.value)
    .eq('item_type', 'K95')
    .gte('station', kmFrom.value - expand)
    .lte('station', kmTo.value + expand)
    .order('station')
  
  allStations.value = data || []
}
</script>
