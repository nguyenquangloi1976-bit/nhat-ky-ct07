export interface SubmissionDoc {
  id: string
  project_id: string
  group_code: 'A' | 'B' | 'C' | 'D'
  sort_order: number
  doc_name: string
  doc_number: string | null
  submitted_date: string | null
  status: 'chua_nop' | 'da_nop' | 'dang_xem_xet' | 'chap_thuan' | 'yeu_cau_sua'
  approved_date: string | null
  file_url: string | null
  reviewer_notes: string | null
  notes: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

const GROUP_LABELS: Record<string, string> = {
  A: 'BPTC & An toàn',
  B: 'Chất lượng & Thí nghiệm',
  C: 'Tiến độ & Tổ chức',
  D: 'Thiết kế',
}

const STATUS_LABELS: Record<string, string> = {
  chua_nop: 'Chưa nộp',
  da_nop: 'Đã nộp',
  dang_xem_xet: 'Đang xem xét',
  chap_thuan: 'Chấp thuận',
  yeu_cau_sua: 'Yêu cầu sửa đổi',
}

const STATUS_COLORS: Record<string, string> = {
  chua_nop: 'bg-gray-100 text-gray-600',
  da_nop: 'bg-blue-100 text-blue-700',
  dang_xem_xet: 'bg-yellow-100 text-yellow-700',
  chap_thuan: 'bg-green-100 text-green-700',
  yeu_cau_sua: 'bg-red-100 text-red-700',
}

export function useSubmissionDocs() {
  const { $supabase } = useNuxtApp()
  const { currentProject } = useProject()

  const docs = ref<SubmissionDoc[]>([])
  const loading = ref(false)

  async function loadDocs() {
    if (!currentProject.value) return
    loading.value = true
    const { data, error } = await $supabase
      .from('submission_documents')
      .select('*')
      .eq('project_id', currentProject.value.id)
      .order('group_code')
      .order('sort_order')
    if (error) console.error('loadDocs error:', error)
    docs.value = data || []
    loading.value = false
  }

  async function addDoc(doc: Partial<SubmissionDoc>) {
    if (!currentProject.value) return
    const { data, error } = await $supabase
      .from('submission_documents')
      .insert({ ...doc, project_id: currentProject.value.id })
      .select()
      .single()
    if (error) throw error
    docs.value.push(data)
    return data
  }

  async function updateDoc(id: string, updates: Partial<SubmissionDoc>) {
    const { error } = await $supabase
      .from('submission_documents')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
    const idx = docs.value.findIndex(d => d.id === id)
    if (idx >= 0) Object.assign(docs.value[idx], updates)
  }

  async function deleteDoc(id: string) {
    const { error } = await $supabase
      .from('submission_documents')
      .delete()
      .eq('id', id)
    if (error) throw error
    docs.value = docs.value.filter(d => d.id !== id)
  }

  const grouped = computed(() => {
    const groups: Record<string, SubmissionDoc[]> = { A: [], B: [], C: [], D: [] }
    for (const d of docs.value) {
      if (groups[d.group_code]) groups[d.group_code].push(d)
    }
    return groups
  })

  const stats = computed(() => {
    const total = docs.value.length
    const approved = docs.value.filter(d => d.status === 'chap_thuan').length
    const pending = docs.value.filter(d => d.status === 'dang_xem_xet' || d.status === 'da_nop').length
    const needFix = docs.value.filter(d => d.status === 'yeu_cau_sua').length
    return { total, approved, pending, needFix }
  })

  return {
    docs: readonly(docs),
    loading: readonly(loading),
    grouped,
    stats,
    loadDocs,
    addDoc,
    updateDoc,
    deleteDoc,
    GROUP_LABELS,
    STATUS_LABELS,
    STATUS_COLORS,
  }
}
