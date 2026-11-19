/**
 * Composable tính khối lượng (m³) và diện tích bề mặt (m²) từ bảng ĐTPL.
 *
 * Bảng layer_sections lưu:
 * - Diện tích mặt cắt ngang (m²) cho hạng mục m³ (K95, K98, XLNDY, BUL, CPĐD)
 * - Chiều rộng mặt rải (m) cho hạng mục m² (BTN rỗng, BTN chặt)
 *
 * Khối lượng (m³) = Σ (DT_i + DT_{i+1}) / 2 × (station_{i+1} - station_i)
 * Diện tích (m²)  = Σ (W_i + W_{i+1}) / 2 × (station_{i+1} - station_i)
 *
 * Lớp 1 = trên cùng (đắp sau cùng), lớp N = dưới cùng (đắp đầu tiên).
 */

export interface LayerSection {
  station: number   // lý trình (m)
  layer: number     // số lớp
  side: string      // 'T' | 'P'
  area: number      // diện tích (m²) hoặc chiều rộng (m) cho BTN
  section_name: string | null
}

export interface VolumeResult {
  volume: number          // m³
  sections: LayerSection[]  // mặt cắt tham gia tính
  formula: string         // diễn giải công thức
}

export interface AreaResult {
  area: number            // m² (diện tích bề mặt)
  sections: LayerSection[]  // mặt cắt tham gia tính (area = chiều rộng)
  formula: string         // diễn giải công thức
}

export function useLayerVolume() {
  const { $supabase } = useNuxtApp()
  const { currentProject } = useProject()

  /**
   * Truy vấn các mặt cắt trong khoảng lý trình, cho 1 lớp + 1 bên.
   */
  async function getSections(params: {
    side: 'T' | 'P'
    layer: number
    kmFrom: number  // meters
    kmTo: number    // meters
    itemType?: string // default 'K95'
  }): Promise<LayerSection[]> {
    const pid = currentProject.value?.id
    if (!pid) return []

    const { data, error } = await $supabase
      .from('layer_sections')
      .select('station, layer, side, area, section_name')
      .eq('project_id', pid)
      .eq('side', params.side)
      .eq('layer', params.layer)
      .eq('item_type', params.itemType || 'K95')
      .gte('station', params.kmFrom)
      .lte('station', params.kmTo)
      .order('station')

    if (error) {
      console.error('getSections error:', error)
      return []
    }
    return data || []
  }

  /**
   * Tính khối lượng (m³) bằng phương pháp hình thang.
   */
  /**
   * Tính khối lượng (m³) bằng phương pháp hình thang.
   *
   * Quy tắc biên: tại đầu/cuối đoạn thi công (kmFrom, kmTo),
   * nếu không có mặt cắt trùng đúng biên → diện tích tại biên = 0.
   * Công thức: (F_biên + F_mc) / 2 × khoảng cách = (0 + F) / 2 × L
   */
  async function calcVolume(params: {
    side: 'T' | 'P'
    layer: number
    kmFrom: number
    kmTo: number
    itemType?: string
  }): Promise<VolumeResult> {
    const sections = await getSections(params)
    const rangeLen = params.kmTo - params.kmFrom

    if (sections.length === 0) {
      return { volume: 0, sections: [], formula: 'Không tìm thấy mặt cắt trong khoảng lý trình' }
    }

    let volume = 0
    const parts: string[] = []

    // Đoạn đầu: từ kmFrom đến MC đầu tiên
    // Tại kmFrom, nếu không có MC trùng → DT = 0
    if (sections[0].station > params.kmFrom) {
      const L = sections[0].station - params.kmFrom
      const V = (0 + sections[0].area) / 2 * L
      volume += V
      parts.push(`(0+${sections[0].area})/2×${L}=${V.toFixed(2)}`)
    }

    // Giữa các mặt cắt liên tiếp
    for (let i = 0; i < sections.length - 1; i++) {
      const s1 = sections[i]
      const s2 = sections[i + 1]
      const L = s2.station - s1.station
      const V = ((s1.area + s2.area) / 2) * L
      volume += V
      parts.push(`(${s1.area}+${s2.area})/2×${L}=${V.toFixed(2)}`)
    }

    // Đoạn cuối: từ MC cuối đến kmTo
    // Tại kmTo, nếu không có MC trùng → DT = 0
    const last = sections[sections.length - 1]
    if (last.station < params.kmTo) {
      const L = params.kmTo - last.station
      const V = (last.area + 0) / 2 * L
      volume += V
      parts.push(`(${last.area}+0)/2×${L}=${V.toFixed(2)}`)
    }

    return {
      volume: Math.round(volume * 100) / 100,
      sections,
      formula: parts.join(' + '),
    }
  }

  /**
   * Lấy tổng số lớp tại 1 lý trình (= số lớp thiết kế).
   */
  async function getLayerCount(params: {
    side: 'T' | 'P'
    station: number
    itemType?: string
  }): Promise<number> {
    const pid = currentProject.value?.id
    if (!pid) return 0

    const { count, error } = await $supabase
      .from('layer_sections')
      .select('id', { count: 'exact', head: true })
      .eq('project_id', pid)
      .eq('side', params.side)
      .eq('station', params.station)
      .eq('item_type', params.itemType || 'K95')

    if (error) return 0
    return count || 0
  }

  /**
   * Lấy tổng diện tích thiết kế (tất cả lớp) tại 1 lý trình = KL thiết kế mặt cắt.
   */
  async function getDesignArea(params: {
    side: 'T' | 'P'
    station: number
    itemType?: string
  }): Promise<number> {
    const pid = currentProject.value?.id
    if (!pid) return 0

    const { data, error } = await $supabase
      .from('layer_sections')
      .select('area')
      .eq('project_id', pid)
      .eq('side', params.side)
      .eq('station', params.station)
      .eq('item_type', params.itemType || 'K95')

    if (error || !data) return 0
    return data.reduce((sum: number, r: { area: number }) => sum + r.area, 0)
  }

  /**
   * Tính khối lượng lũy kế: tổng các lớp từ đáy (layer max) đến layer hiện tại.
   * Dùng cho báo cáo.
   */
  async function calcCumulativeVolume(params: {
    side: 'T' | 'P'
    currentLayer: number  // lớp hiện đang đắp (đã hoàn thành đến lớp này)
    kmFrom: number
    kmTo: number
    itemType?: string
  }): Promise<number> {
    const pid = currentProject.value?.id
    if (!pid) return 0

    // Lấy tất cả mặt cắt cho các lớp từ currentLayer trở xuống (số lớn hơn = dưới)
    const { data, error } = await $supabase
      .from('layer_sections')
      .select('station, layer, area')
      .eq('project_id', pid)
      .eq('side', params.side)
      .eq('item_type', params.itemType || 'K95')
      .gte('layer', params.currentLayer) // lớp hiện tại và các lớp dưới
      .gte('station', params.kmFrom)
      .lte('station', params.kmTo)
      .order('layer')
      .order('station')

    if (error || !data || data.length === 0) return 0

    // Group by layer, tính volume cho mỗi lớp
    const byLayer = new Map<number, { station: number; area: number }[]>()
    for (const r of data) {
      if (!byLayer.has(r.layer)) byLayer.set(r.layer, [])
      byLayer.get(r.layer)!.push({ station: r.station, area: r.area })
    }

    let total = 0
    for (const [, sections] of byLayer) {
      sections.sort((a, b) => a.station - b.station)
      for (let i = 0; i < sections.length - 1; i++) {
        const L = sections[i + 1].station - sections[i].station
        total += ((sections[i].area + sections[i + 1].area) / 2) * L
      }
    }

    return Math.round(total * 100) / 100
  }

  return {
    getSections,
    calcVolume,
    getLayerCount,
    getDesignArea,
    calcCumulativeVolume,
  }
}
