export interface MaterialSource {
  id: string
  project_id: string
  material_name: string
  supplier: string | null
  supplier_address: string | null
  distance_km: number | null
  status: 'chua_trinh' | 'da_thi_nghiem' | 'da_nghiem_thu' | 'chap_thuan'
  has_cert_quality: boolean
  has_cert_origin: boolean
  has_cert_compliance: boolean
  has_test_result: boolean
  has_mining_permit: boolean
  approved_date: string | null
  notes: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

const MAT_STATUS_LABELS: Record<string, string> = {
  chua_trinh: 'Chưa trình',
  da_thi_nghiem: 'Đã thí nghiệm',
  da_nghiem_thu: 'Đã nghiệm thu',
  chap_thuan: 'Được chấp thuận',
}

const MAT_STATUS_COLORS: Record<string, string> = {
  chua_trinh: 'bg-gray-100 text-gray-600',
  da_thi_nghiem: 'bg-blue-100 text-blue-700',
  da_nghiem_thu: 'bg-yellow-100 text-yellow-700',
  chap_thuan: 'bg-green-100 text-green-700',
}

export function useMaterialSources() {
  const { $supabase } = useNuxtApp()
  const { currentProject } = useProject()

  const sources = ref<MaterialSource[]>([])
  const loading = ref(false)

  async function loadSources() {
    if (!currentProject.value) return
    loading.value = true
    const { data, error } = await $supabase
      .from('material_sources')
      .select('*')
      .eq('project_id', currentProject.value.id)
      .order('material_name')
    if (error) console.error('loadSources error:', error)
    sources.value = data || []
    loading.value = false
  }

  async function addSource(src: Partial<MaterialSource>) {
    if (!currentProject.value) return
    const { data, error } = await $supabase
      .from('material_sources')
      .insert({ ...src, project_id: currentProject.value.id })
      .select()
      .single()
    if (error) throw error
    sources.value.push(data)
    return data
  }

  async function updateSource(id: string, updates: Partial<MaterialSource>) {
    const { error } = await $supabase
      .from('material_sources')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
    const idx = sources.value.findIndex(s => s.id === id)
    if (idx >= 0) Object.assign(sources.value[idx], updates)
  }

  async function deleteSource(id: string) {
    const { error } = await $supabase
      .from('material_sources')
      .delete()
      .eq('id', id)
    if (error) throw error
    sources.value = sources.value.filter(s => s.id !== id)
  }

  const stats = computed(() => {
    const total = sources.value.length
    const approved = sources.value.filter(s => s.status === 'chap_thuan').length
    const pending = sources.value.filter(s => s.status === 'chua_trinh').length
    return { total, approved, pending }
  })

  return {
    sources: readonly(sources),
    loading: readonly(loading),
    stats,
    loadSources,
    addSource,
    updateSource,
    deleteSource,
    MAT_STATUS_LABELS,
    MAT_STATUS_COLORS,
  }
}
