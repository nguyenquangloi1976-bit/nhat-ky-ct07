export interface DiaryEntry {
  id: string
  structure_id: string
  project_id: string
  entry_date: string
  weather: string | null
  notes: string | null
  created_by: string
  is_locked: boolean
  locked_at: string | null
  created_at: string
  structures?: any
  profiles?: any
}

export interface DiaryLine {
  id: string
  entry_id: string
  work_item_id: string
  side: 'T' | 'P' | null
  batch_number: number
  quantity: number
  notes: string | null
  km_from?: number | null // lý trình đầu (m)
  km_to?: number | null   // lý trình cuối (m)
  work_items?: any
}

export function useDiary() {
  const { $supabase } = useNuxtApp()
  const { currentProject } = useProject()

  // List diary entries with filters
  async function listEntries(filters: {
    structureId?: string
    dateFrom?: string
    dateTo?: string
    createdBy?: string
  } = {}): Promise<DiaryEntry[]> {
    let query = $supabase
      .from('diary_entries')
      .select('*, structures(name, code, structure_types(name, code)), profiles(full_name)')
      .order('entry_date', { ascending: false })

    // Filter by current project
    if (currentProject.value) {
      query = query.eq('project_id', currentProject.value.id)
    }

    if (filters.structureId) query = query.eq('structure_id', filters.structureId)
    if (filters.dateFrom) query = query.gte('entry_date', filters.dateFrom)
    if (filters.dateTo) query = query.lte('entry_date', filters.dateTo)
    if (filters.createdBy) query = query.eq('created_by', filters.createdBy)

    const { data, error } = await query
    if (error) throw error
    return data || []
  }

  // Get or create entry for a structure + date
  async function getOrCreateEntry(structureId: string, date: string): Promise<DiaryEntry> {
    // Check existing
    const { data: existing } = await $supabase
      .from('diary_entries')
      .select('*')
      .eq('structure_id', structureId)
      .eq('entry_date', date)
      .single()

    if (existing) return existing

    // Create new — include project_id
    const { data: { user } } = await $supabase.auth.getUser()

    // Get project_id from the structure
    const { data: structure } = await $supabase
      .from('structures')
      .select('project_id')
      .eq('id', structureId)
      .single()

    const { data, error } = await $supabase
      .from('diary_entries')
      .insert({
        structure_id: structureId,
        entry_date: date,
        created_by: user?.id,
        project_id: structure?.project_id || currentProject.value?.id,
      })
      .select()
      .single()
    if (error) throw error
    return data
  }

  // Get entry by ID with lines
  async function getEntry(id: string): Promise<{ entry: DiaryEntry; lines: DiaryLine[] }> {
    const { data: entry, error: e1 } = await $supabase
      .from('diary_entries')
      .select('*, structures(name, code, has_left_right, structure_types(name, code)), profiles(full_name)')
      .eq('id', id)
      .single()
    if (e1) throw e1

    const { data: lines, error: e2 } = await $supabase
      .from('diary_lines')
      .select('*, work_items(name, unit, design_quantity, group_name)')
      .eq('entry_id', id)
      .order('created_at')
    if (e2) throw e2

    return { entry, lines: lines || [] }
  }

  // Update entry metadata
  async function updateEntry(id: string, updates: Partial<DiaryEntry>) {
    const { error } = await $supabase
      .from('diary_entries')
      .update(updates)
      .eq('id', id)
    if (error) throw error
  }

  // Upsert diary line
  // Lý trình (km_from, km_to) chỉ có sau khi chạy supabase/add-stations-to-lines.sql.
  // Nếu CSDL chưa có 2 cột này thì lưu lại không kèm lý trình và báo cho trang gọi.
  async function saveLine(line: Partial<DiaryLine>): Promise<DiaryLine & { _kmSkipped?: boolean }> {
    const hasKm = 'km_from' in line || 'km_to' in line
    const run = async (withKm: boolean) => {
      if (line.id) {
        const updates: Record<string, any> = {
          quantity: line.quantity,
          notes: line.notes,
          side: line.side,
        }
        if (line.batch_number !== undefined) updates.batch_number = line.batch_number
        if (withKm && hasKm) {
          updates.km_from = line.km_from ?? null
          updates.km_to = line.km_to ?? null
        }
        return await $supabase.from('diary_lines').update(updates).eq('id', line.id).select().single()
      }
      const row: Record<string, any> = { ...line }
      delete row.id
      if (!withKm) {
        delete row.km_from
        delete row.km_to
      }
      return await $supabase.from('diary_lines').insert(row).select().single()
    }

    let { data, error } = await run(true)
    let kmSkipped = false
    if (error && hasKm && /km_from|km_to/.test(error.message || '')) {
      ;({ data, error } = await run(false))
      kmSkipped = true
    }
    if (error) throw error
    return kmSkipped ? { ...data, _kmSkipped: true } : data
  }

  // Toàn bộ dòng nhật ký của dự án hiện tại (kèm công trình, hạng mục), lọc theo khoảng ngày.
  // Tải theo trang 1000 dòng để không bị giới hạn mặc định của Supabase.
  async function listLines(filters: {
    dateFrom?: string
    dateTo?: string
    structureId?: string
  } = {}): Promise<any[]> {
    const pageSize = 1000
    const all: any[] = []
    for (let from = 0; ; from += pageSize) {
      let query = $supabase
        .from('diary_lines')
        .select(
          '*, work_items(id, name, unit, group_name, design_quantity), ' +
          'diary_entries!inner(id, entry_date, weather, notes, is_locked, created_by, project_id, structure_id, ' +
          'profiles(full_name), structures(id, name, code, station, type_id, structure_types(id, name, code)))'
        )
        .order('created_at')
        .range(from, from + pageSize - 1)

      if (currentProject.value) query = query.eq('diary_entries.project_id', currentProject.value.id)
      if (filters.structureId) query = query.eq('diary_entries.structure_id', filters.structureId)
      if (filters.dateFrom) query = query.gte('diary_entries.entry_date', filters.dateFrom)
      if (filters.dateTo) query = query.lte('diary_entries.entry_date', filters.dateTo)

      const { data, error } = await query
      if (error) throw error
      all.push(...(data || []))
      if (!data || data.length < pageSize) break
    }
    return all
  }

  // Delete line
  async function deleteLine(id: string) {
    const { error } = await $supabase
      .from('diary_lines')
      .delete()
      .eq('id', id)
    if (error) throw error
  }

  // Lock entry
  async function lockEntry(id: string) {
    const { error } = await $supabase
      .from('diary_entries')
      .update({ is_locked: true, locked_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
  }

  // Unlock entry (admin only)
  async function unlockEntry(id: string) {
    const { error } = await $supabase
      .from('diary_entries')
      .update({ is_locked: false, locked_at: null })
      .eq('id', id)
    if (error) throw error
  }

  // Delete entry and all its lines (admin only)
  async function deleteEntry(id: string) {
    // Xóa lines trước (FK constraint)
    const { error: e1 } = await $supabase
      .from('diary_lines')
      .delete()
      .eq('entry_id', id)
    if (e1) throw e1
    // Xóa entry
    const { error: e2 } = await $supabase
      .from('diary_entries')
      .delete()
      .eq('id', id)
    if (e2) throw e2
  }

  // Get summary (v_summary view) — filter by project
  async function getSummary(filters: {
    typeCode?: string
    structureId?: string
  } = {}) {
    let query = $supabase.from('v_summary').select('*')
    if (currentProject.value) {
      query = query.eq('project_id', currentProject.value.id)
    }
    if (filters.typeCode) query = query.eq('type_code', filters.typeCode)
    if (filters.structureId) query = query.eq('structure_id', filters.structureId)
    const { data, error } = await query
    if (error) throw error
    return data || []
  }

  return {
    listEntries,
    getOrCreateEntry,
    getEntry,
    updateEntry,
    saveLine,
    listLines,
    deleteLine,
    lockEntry,
    unlockEntry,
    deleteEntry,
    getSummary,
  }
}
