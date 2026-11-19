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
   * Lấy mặt cắt lân cận gần nhất nằm ngoài khoảng [kmFrom, kmTo].
   * Dùng để nội suy diện tích tại biên khi mặt cắt không trùng đầu/cuối đoạn.
   */
  async function getAdjacentSection(params: {
    side: 'T' | 'P'
    layer: number
    station: number
    direction: 'before' | 'after'
    itemType?: string
  }): Promise<LayerSection | null> {
    const pid = currentProject.value?.id
    if (!pid) return null

    const query = $supabase
      .from('layer_sections')
      .select('station, layer, side, area, section_name')
      .eq('project_id', pid)
      .eq('side', params.side)
      .eq('layer', params.layer)
      .eq('item_type', params.itemType || 'K95')

    const { data, error } = params.direction === 'before'
      ? await query.lt('station', params.station).order('station', { ascending: false }).limit(1)
      : await query.gt('station', params.station).order('station', { ascending: true }).limit(1)

    if (error || !data || data.length === 0) return null
    return data[0]
  }

  /**
   * Nội suy diện tích tại 1 lý trình dựa trên 2 mặt cắt bao quanh.
   */
  function interpolateArea(targetStation: number, s1: LayerSection, s2: LayerSection): number {
    if (s1.station === s2.station) return s1.area
    const ratio = (targetStation - s1.station) / (s2.station - s1.station)
    return s1.area + (s2.area - s1.area) * ratio
  }

  /**
   * Tính khối lượng (m³) bằng phương pháp hình thang.
   * Hỗ trợ:
   * - Nhiều mặt cắt: tính bình thường
   * - 1 mặt cắt: nội suy tại biên hoặc dùng DT × L
   * - Nội suy tại đầu/cuối đoạn nếu mặt cắt không trùng biên
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
      // Thử tìm 2 mặt cắt bao quanh để nội suy
      const before = await getAdjacentSection({ ...params, station: params.kmFrom, direction: 'before' })
      const after = await getAdjacentSection({ ...params, station: params.kmTo, direction: 'after' })
      if (before && after) {
        const areaFrom = interpolateArea(params.kmFrom, before, after)
        const areaTo = interpolateArea(params.kmTo, before, after)
        const V = ((areaFrom + areaTo) / 2) * rangeLen
        return {
          volume: Math.round(V * 100) / 100,
          sections: [before, after],
          formula: `Nội suy: (${areaFrom.toFixed(3)}+${areaTo.toFixed(3)})/2×${rangeLen}=${V.toFixed(2)}`,
        }
      }
      return { volume: 0, sections: [], formula: 'Không tìm thấy mặt cắt trong khoảng lý trình' }
    }

    if (sections.length === 1) {
      const s = sections[0]
      // Tìm mặt cắt lân cận để nội suy tại hai đầu
      const before = s.station > params.kmFrom
        ? await getAdjacentSection({ ...params, station: params.kmFrom, direction: 'before' })
        : null
      const after = s.station < params.kmTo
        ? await getAdjacentSection({ ...params, station: params.kmTo, direction: 'after' })
        : null

      let volume = 0
      const parts: string[] = []

      // Đoạn trước mặt cắt (từ kmFrom đến station)
      if (s.station > params.kmFrom) {
        const L1 = s.station - params.kmFrom
        if (before) {
          const areaFrom = interpolateArea(params.kmFrom, before, s)
          const V1 = ((areaFrom + s.area) / 2) * L1
          volume += V1
          parts.push(`(${areaFrom.toFixed(3)}+${s.area})/2×${L1}=${V1.toFixed(2)}`)
        } else {
          // Không có mặt cắt trước → dùng chính diện tích mặt cắt
          const V1 = s.area * L1
          volume += V1
          parts.push(`${s.area}×${L1}=${V1.toFixed(2)}`)
        }
      }

      // Đoạn sau mặt cắt (từ station đến kmTo)
      if (s.station < params.kmTo) {
        const L2 = params.kmTo - s.station
        if (after) {
          const areaTo = interpolateArea(params.kmTo, s, after)
          const V2 = ((s.area + areaTo) / 2) * L2
          volume += V2
          parts.push(`(${s.area}+${areaTo.toFixed(3)})/2×${L2}=${V2.toFixed(2)}`)
        } else {
          // Không có mặt cắt sau → dùng chính diện tích mặt cắt
          const V2 = s.area * L2
          volume += V2
          parts.push(`${s.area}×${L2}=${V2.toFixed(2)}`)
        }
      }

      // Trường hợp station trùng đúng kmFrom hoặc kmTo và không có đoạn nào
      if (volume === 0) {
        const V = s.area * rangeLen
        volume = V
        parts.push(`${s.area}×${rangeLen}=${V.toFixed(2)}`)
      }

      return {
        volume: Math.round(volume * 100) / 100,
        sections,
        formula: parts.join(' + '),
      }
    }

    // >= 2 mặt cắt: tính hình thang giữa các mặt cắt liên tiếp
    let volume = 0
    const parts: string[] = []

    // Nội suy đoạn đầu (từ kmFrom đến section đầu tiên) nếu cần
    if (sections[0].station > params.kmFrom) {
      const before = await getAdjacentSection({ ...params, station: params.kmFrom, direction: 'before' })
      const L0 = sections[0].station - params.kmFrom
      if (before) {
        const areaFrom = interpolateArea(params.kmFrom, before, sections[0])
        const V0 = ((areaFrom + sections[0].area) / 2) * L0
        volume += V0
        parts.push(`(${areaFrom.toFixed(3)}+${sections[0].area})/2×${L0}=${V0.toFixed(2)}`)
      } else {
        const V0 = sections[0].area * L0
        volume += V0
        parts.push(`${sections[0].area}×${L0}=${V0.toFixed(2)}`)
      }
    }

    // Giữa các mặt cắt
    for (let i = 0; i < sections.length - 1; i++) {
      const s1 = sections[i]
      const s2 = sections[i + 1]
      const L = s2.station - s1.station
      const V = ((s1.area + s2.area) / 2) * L
      volume += V
      parts.push(`(${s1.area}+${s2.area})/2×${L}=${V.toFixed(2)}`)
    }

    // Nội suy đoạn cuối (từ section cuối đến kmTo) nếu cần
    const last = sections[sections.length - 1]
    if (last.station < params.kmTo) {
      const after = await getAdjacentSection({ ...params, station: params.kmTo, direction: 'after' })
      const LN = params.kmTo - last.station
      if (after) {
        const areaTo = interpolateArea(params.kmTo, last, after)
        const VN = ((last.area + areaTo) / 2) * LN
        volume += VN
        parts.push(`(${last.area}+${areaTo.toFixed(3)})/2×${LN}=${VN.toFixed(2)}`)
      } else {
        const VN = last.area * LN
        volume += VN
        parts.push(`${last.area}×${LN}=${VN.toFixed(2)}`)
      }
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
