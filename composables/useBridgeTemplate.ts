// Mẫu hạng mục công việc của cầu, chia theo BỘ PHẬN (mố, trụ, đúc dầm, nhịp, hoàn thiện).
// Danh sách và đơn vị lấy theo file Excel nhật ký cầu của dự án (sheet DM.*).
// Mỗi bộ phận là một nhóm (group_name) trong bảng work_items; bên Trái/Phải ghi ở cột Bên.

export interface BridgeItem {
  group_name: string
  name: string
  unit: string
}

type Tpl = [name: string, unit: string][]

const PILE_AND_FOOTING: Tpl = [
  ['Thi công cọc', 'cọc'],
  ['Đổ BT cọc', 'm³'],
  ['Đào hố móng', 'm³'],
  ['BT lót móng', 'm³'],
]

export const BRIDGE_TEMPLATES: Record<'abutment' | 'pier' | 'girder' | 'span' | 'finishing', Tpl> = {
  abutment: [
    ...PILE_AND_FOOTING,
    ['BT bệ mố', 'm³'],
    ['CT bệ mố', 'kg'],
    ['BT thân mố', 'm³'],
    ['CT thân mố', 'kg'],
    ['BT tường cánh', 'm³'],
    ['CT tường cánh', 'kg'],
    ['BT tường đỉnh', 'm³'],
    ['Đắp đất sau mố', 'm³'],
  ],
  pier: [
    ...PILE_AND_FOOTING,
    ['BT bệ trụ', 'm³'],
    ['CT bệ trụ', 'kg'],
    ['BT thân trụ', 'm³'],
    ['CT thân trụ', 'kg'],
  ],
  girder: [
    ['Gia công CT dầm', 'kg'],
    ['Lắp dựng ván khuôn', 'm²'],
    ['Đổ BT dầm', 'm³'],
    ['Bảo dưỡng dầm', 'ngày'],
    ['Căng kéo cáp DƯL', 'sợi'],
    ['Vận chuyển dầm', 'dầm'],
  ],
  span: [
    ['Lao lắp dầm', 'dầm'],
    ['Đổ BT bản mặt cầu', 'm³'],
    ['CT bản mặt cầu', 'kg'],
    ['Khe co giãn', 'm'],
    ['Lan can, tay vịn', 'm'],
    ['Lớp phủ mặt cầu', 'm²'],
  ],
  finishing: [
    ['Taluy cone mố', 'm²'],
    ['Hệ thống thoát nước', 'm'],
    ['Sơn kẻ mặt cầu', 'm²'],
    ['Biển báo, cọc tiêu', 'bộ'],
    ['Dọn dẹp công trường', 'm²'],
  ],
}

/** Tên các bộ phận theo đúng thứ tự thi công: Mố A1, Mố A2, Trụ T1…Tn, Đúc dầm, Nhịp 1…m, Hoàn thiện */
export function bridgePartNames(piers: number, spans: number): { name: string; kind: keyof typeof BRIDGE_TEMPLATES }[] {
  const parts: { name: string; kind: keyof typeof BRIDGE_TEMPLATES }[] = [
    { name: 'Mố A1', kind: 'abutment' },
    { name: 'Mố A2', kind: 'abutment' },
  ]
  for (let i = 1; i <= piers; i++) parts.push({ name: `Trụ T${i}`, kind: 'pier' })
  parts.push({ name: 'Đúc dầm', kind: 'girder' })
  for (let i = 1; i <= spans; i++) parts.push({ name: `Nhịp ${i}`, kind: 'span' })
  parts.push({ name: 'Hoàn thiện', kind: 'finishing' })
  return parts
}

/** Toàn bộ hạng mục của một cầu có 2 mố, `piers` trụ, `spans` nhịp */
export function buildBridgeItems(piers: number, spans: number): BridgeItem[] {
  const items: BridgeItem[] = []
  for (const part of bridgePartNames(piers, spans)) {
    for (const [name, unit] of BRIDGE_TEMPLATES[part.kind]) {
      items.push({ group_name: part.name, name, unit })
    }
  }
  return items
}

/** Các loại công trình ghi theo bộ phận, không ghi theo lý trình */
export const NON_LINEAR_TYPE_CODES = ['CAU', 'CONG', 'HAM_CHUI', 'TRAM_THU_PHI']
