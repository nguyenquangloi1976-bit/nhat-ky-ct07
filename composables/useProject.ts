export interface Project {
  id: string
  code: string
  name: string
  description: string | null
  km_range: string | null
  consortium: string | null
  start_date: string | null
  end_date: string | null
  is_active: boolean
  has_left_right: boolean
  drive_folder_url: string | null
  created_at: string
}

const projects = ref<Project[]>([])
const currentProject = ref<Project | null>(null)
const loadingProjects = ref(false)

export function useProject() {
  const { $supabase } = useNuxtApp()

  async function loadProjects() {
    loadingProjects.value = true
    const { data, error } = await $supabase
      .from('projects')
      .select('*')
      .eq('is_active', true)
      .order('code')
    if (error) {
      console.error('loadProjects error:', error)
    }
    projects.value = data || []

    // Restore from localStorage or pick first
    if (projects.value.length > 0 && !currentProject.value) {
      const savedId = typeof localStorage !== 'undefined'
        ? localStorage.getItem('selectedProjectId')
        : null
      const saved = savedId
        ? projects.value.find(p => p.id === savedId)
        : null
      currentProject.value = saved || projects.value[0]
    }
    loadingProjects.value = false
  }

  function selectProject(project: Project) {
    currentProject.value = project
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem('selectedProjectId', project.id)
    }
  }

  // Admin: CRUD
  async function createProject(p: Partial<Project>): Promise<Project> {
    const { data, error } = await $supabase
      .from('projects')
      .insert(p)
      .select()
      .single()
    if (error) throw error
    projects.value.push(data)
    return data
  }

  async function updateProject(id: string, updates: Partial<Project>) {
    const { error } = await $supabase
      .from('projects')
      .update(updates)
      .eq('id', id)
    if (error) throw error
    const idx = projects.value.findIndex(p => p.id === id)
    if (idx >= 0) Object.assign(projects.value[idx], updates)
    if (currentProject.value?.id === id) {
      Object.assign(currentProject.value, updates)
    }
  }

  async function deleteProject(id: string) {
    // Cascade delete: diary_lines → diary_entries → work_items → structures → structure_types → project
    // 1. Lấy tất cả structure_ids thuộc project
    const { data: structs } = await $supabase
      .from('structures')
      .select('id')
      .eq('project_id', id)
    const structIds = (structs || []).map((s: any) => s.id)

    if (structIds.length > 0) {
      // 2. Lấy tất cả entry_ids thuộc các structures
      const { data: entries } = await $supabase
        .from('diary_entries')
        .select('id')
        .in('structure_id', structIds)
      const entryIds = (entries || []).map((e: any) => e.id)

      // 3. Xóa diary_lines
      if (entryIds.length > 0) {
        const { error: e1 } = await $supabase
          .from('diary_lines')
          .delete()
          .in('entry_id', entryIds)
        if (e1) throw e1
      }

      // 4. Xóa diary_entries
      const { error: e2 } = await $supabase
        .from('diary_entries')
        .delete()
        .in('structure_id', structIds)
      if (e2) throw e2

      // 5. Xóa work_items
      const { error: e3 } = await $supabase
        .from('work_items')
        .delete()
        .in('structure_id', structIds)
      if (e3) throw e3
    }

    // 6. Xóa structures
    const { error: e4 } = await $supabase
      .from('structures')
      .delete()
      .eq('project_id', id)
    if (e4) throw e4

    // 7. Xóa structure_types
    const { error: e5 } = await $supabase
      .from('structure_types')
      .delete()
      .eq('project_id', id)
    if (e5) throw e5

    // 8. Xóa project
    const { error: e6 } = await $supabase
      .from('projects')
      .delete()
      .eq('id', id)
    if (e6) throw e6

    projects.value = projects.value.filter(p => p.id !== id)
    if (currentProject.value?.id === id) {
      currentProject.value = projects.value[0] || null
    }
  }

  return {
    projects: readonly(projects),
    currentProject: readonly(currentProject),
    loadingProjects: readonly(loadingProjects),
    loadProjects,
    selectProject,
    createProject,
    updateProject,
    deleteProject,
  }
}
