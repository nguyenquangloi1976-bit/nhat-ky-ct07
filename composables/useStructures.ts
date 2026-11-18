export interface StructureType {
  id: string
  code: string
  name: string
  project_id: string
  sort_order: number
}

export interface Structure {
  id: string
  type_id: string
  project_id: string
  code: string
  name: string
  station: string | null
  section: string | null
  design_length: number | null
  design_unit: string | null
  has_left_right: boolean
  metadata: Record<string, any>
  sort_order: number
  structure_types?: StructureType
}

export interface WorkItem {
  id: string
  structure_id: string
  name: string
  unit: string
  design_quantity: number | null
  group_name: string | null
  sort_order: number
  is_default: boolean
}

export function useStructures() {
  const { $supabase } = useNuxtApp()
  const { currentProject } = useProject()

  async function getTypes(): Promise<StructureType[]> {
    let query = $supabase
      .from('structure_types')
      .select('*')
      .order('sort_order')

    if (currentProject.value) {
      query = query.eq('project_id', currentProject.value.id)
    }

    const { data, error } = await query
    if (error) throw error
    return data || []
  }

  async function addType(t: Partial<StructureType>): Promise<StructureType> {
    if (!currentProject.value) throw new Error('No project selected')
    const { data, error } = await $supabase
      .from('structure_types')
      .insert({ ...t, project_id: currentProject.value.id })
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function updateType(id: string, updates: Partial<StructureType>) {
    const { error } = await $supabase
      .from('structure_types')
      .update(updates)
      .eq('id', id)
    if (error) throw error
  }

  async function deleteType(id: string) {
    const { error } = await $supabase
      .from('structure_types')
      .delete()
      .eq('id', id)
    if (error) throw error
  }

  async function getStructures(typeId?: string): Promise<Structure[]> {
    let query = $supabase
      .from('structures')
      .select('*, structure_types(*)')
      .order('sort_order')

    // Filter by current project
    if (currentProject.value) {
      query = query.eq('project_id', currentProject.value.id)
    }
    if (typeId) query = query.eq('type_id', typeId)

    const { data, error } = await query
    if (error) throw error
    return data || []
  }

  async function getWorkItems(structureId: string): Promise<WorkItem[]> {
    const { data, error } = await $supabase
      .from('work_items')
      .select('*')
      .eq('structure_id', structureId)
      .order('sort_order')
    if (error) throw error
    return data || []
  }

  async function addWorkItem(item: Partial<WorkItem>): Promise<WorkItem> {
    const { data, error } = await $supabase
      .from('work_items')
      .insert({ ...item, is_default: false })
      .select()
      .single()
    if (error) throw error
    return data
  }

  // Thêm nhiều hạng mục một lần (vd: tạo hạng mục theo bộ phận cầu)
  async function addWorkItems(items: Partial<WorkItem>[]): Promise<WorkItem[]> {
    if (!items.length) return []
    const { data, error } = await $supabase
      .from('work_items')
      .insert(items.map(it => ({ ...it, is_default: false })))
      .select()
    if (error) throw error
    return data || []
  }

  async function updateWorkItem(id: string, updates: Partial<WorkItem>) {
    const { error } = await $supabase
      .from('work_items')
      .update(updates)
      .eq('id', id)
    if (error) throw error
  }

  async function deleteWorkItem(id: string) {
    const { error } = await $supabase
      .from('work_items')
      .delete()
      .eq('id', id)
    if (error) throw error
  }

  // Admin: add structure to current project
  // Tự động gán tất cả hạng mục is_active từ work_item_catalog theo type_code
  async function addStructure(s: Partial<Structure>): Promise<Structure> {
    if (!currentProject.value) throw new Error('No project selected')
    const { data, error } = await $supabase
      .from('structures')
      .insert({ ...s, project_id: currentProject.value.id })
      .select('*, structure_types(*)')
      .single()
    if (error) throw error

    // Auto-assign catalog items for this structure's type_code
    const typeCode = data.structure_types?.code
    if (typeCode) {
      try {
        const { data: catalogItems } = await $supabase
          .from('work_item_catalog')
          .select('*')
          .eq('type_code', typeCode)
          .eq('is_active', true)
          .order('sort_order')

        if (catalogItems && catalogItems.length > 0) {
          const workItems = catalogItems.map((c: any) => ({
            structure_id: data.id,
            group_name: c.group_name,
            name: c.name,
            unit: c.unit,
            design_quantity: null,
            sort_order: c.sort_order || 0,
            is_default: false,
          }))
          await $supabase.from('work_items').insert(workItems)
        }
      } catch (e) {
        // Không block việc tạo structure nếu auto-assign lỗi
        console.error('Auto-assign catalog items failed:', e)
      }
    }

    return data
  }

  async function updateStructure(id: string, updates: Partial<Structure>) {
    const { error } = await $supabase
      .from('structures')
      .update(updates)
      .eq('id', id)
    if (error) throw error
  }

  async function deleteStructure(id: string) {
    const { error } = await $supabase
      .from('structures')
      .delete()
      .eq('id', id)
    if (error) throw error
  }

  return {
    getTypes,
    addType,
    updateType,
    deleteType,
    getStructures,
    getWorkItems,
    addWorkItem,
    addWorkItems,
    updateWorkItem,
    deleteWorkItem,
    addStructure,
    updateStructure,
    deleteStructure,
  }
}
