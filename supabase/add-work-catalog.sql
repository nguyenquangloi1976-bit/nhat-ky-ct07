-- ============================================================
-- Bảng danh mục hạng mục khối lượng (Work Item Catalog)
-- Master list of all possible construction work items
-- Admin selects from this catalog to assign to each structure
-- ============================================================

CREATE TABLE IF NOT EXISTS work_item_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_code TEXT NOT NULL,  -- Loại công trình: DUONG, CAU, HAM_PL, HAM_DS, TUONG, CONG
  group_name TEXT NOT NULL, -- Nhóm: Bê tông, Cốt thép, Đất, ...
  name TEXT NOT NULL,       -- Tên hạng mục: Bê tông mố, Cốt thép dầm, ...
  unit TEXT NOT NULL,       -- Đơn vị: m³, tấn, m², ...
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(type_code, group_name, name)
);

-- RLS
ALTER TABLE work_item_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "work_item_catalog_read" ON work_item_catalog
  FOR SELECT USING (true);

CREATE POLICY "work_item_catalog_admin_write" ON work_item_catalog
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Index
CREATE INDEX idx_wic_type ON work_item_catalog(type_code);

-- ============================================================
-- Seed data: common work items per structure type
-- ============================================================

INSERT INTO work_item_catalog (type_code, group_name, name, unit, sort_order) VALUES
-- ĐƯỜNG
('DUONG', 'Nền đường', 'Đào nền đường', 'm³', 1),
('DUONG', 'Nền đường', 'Đắp nền đường K95', 'm³', 2),
('DUONG', 'Nền đường', 'Đắp nền đường K98', 'm³', 3),
('DUONG', 'Nền đường', 'Gia cố nền đất yếu', 'm²', 4),
('DUONG', 'Mặt đường', 'Cấp phối đá dăm loại I', 'm³', 10),
('DUONG', 'Mặt đường', 'Cấp phối đá dăm loại II', 'm³', 11),
('DUONG', 'Mặt đường', 'Bê tông nhựa C19', 'tấn', 12),
('DUONG', 'Mặt đường', 'Bê tông nhựa C12.5', 'tấn', 13),
('DUONG', 'Mặt đường', 'Bê tông xi măng mặt đường', 'm³', 14),
('DUONG', 'Thoát nước', 'Rãnh thoát nước dọc', 'm', 20),
('DUONG', 'Thoát nước', 'Rãnh thoát nước ngang', 'm', 21),
('DUONG', 'An toàn GT', 'Hộ lan tôn sóng', 'm', 30),
('DUONG', 'An toàn GT', 'Hộ lan bê tông', 'm', 31),
('DUONG', 'An toàn GT', 'Vạch sơn kẻ đường', 'm²', 32),

-- CẦU
('CAU', 'Móng', 'Cọc khoan nhồi D1000', 'm', 1),
('CAU', 'Móng', 'Cọc khoan nhồi D1200', 'm', 2),
('CAU', 'Móng', 'Cọc khoan nhồi D1500', 'm', 3),
('CAU', 'Móng', 'Bê tông bệ trụ', 'm³', 4),
('CAU', 'Móng', 'Bê tông bệ mố', 'm³', 5),
('CAU', 'Kết cấu phần dưới', 'Bê tông thân trụ', 'm³', 10),
('CAU', 'Kết cấu phần dưới', 'Bê tông thân mố', 'm³', 11),
('CAU', 'Kết cấu phần dưới', 'Bê tông tường cánh', 'm³', 12),
('CAU', 'Kết cấu phần dưới', 'Cốt thép trụ', 'tấn', 13),
('CAU', 'Kết cấu phần dưới', 'Cốt thép mố', 'tấn', 14),
('CAU', 'Kết cấu phần trên', 'Bê tông dầm chủ', 'm³', 20),
('CAU', 'Kết cấu phần trên', 'Bê tông bản mặt cầu', 'm³', 21),
('CAU', 'Kết cấu phần trên', 'Cốt thép dầm', 'tấn', 22),
('CAU', 'Kết cấu phần trên', 'Cáp DƯL', 'tấn', 23),
('CAU', 'Kết cấu phần trên', 'Lao lắp dầm', 'dầm', 24),
('CAU', 'Phụ trợ', 'Gối cầu', 'cái', 30),
('CAU', 'Phụ trợ', 'Khe co giãn', 'm', 31),
('CAU', 'Phụ trợ', 'Lan can cầu', 'm', 32),
('CAU', 'Phụ trợ', 'Lớp phủ mặt cầu', 'm²', 33),

-- HẦM PHÚ LƯƠNG
('HAM_PL', 'Đào hầm', 'Đào hầm bằng NATM', 'm³', 1),
('HAM_PL', 'Đào hầm', 'Đào hầm bằng khoan nổ', 'm³', 2),
('HAM_PL', 'Gia cố', 'Phun bê tông vỏ hầm', 'm²', 10),
('HAM_PL', 'Gia cố', 'Lắp đặt neo đá', 'cái', 11),
('HAM_PL', 'Gia cố', 'Lắp đặt vì thép', 'tấn', 12),
('HAM_PL', 'Vỏ hầm', 'Bê tông vỏ hầm chính', 'm³', 20),
('HAM_PL', 'Vỏ hầm', 'Chống thấm vỏ hầm', 'm²', 21),
('HAM_PL', 'Hệ thống', 'Hệ thống thông gió', 'bộ', 30),
('HAM_PL', 'Hệ thống', 'Hệ thống chiếu sáng', 'bộ', 31),
('HAM_PL', 'Hệ thống', 'Hệ thống PCCC', 'bộ', 32),

-- HẦM CHUI ĐƯỜNG SẮT
('HAM_DS', 'Đào', 'Đào hố móng', 'm³', 1),
('HAM_DS', 'Kết cấu', 'Bê tông đáy hầm', 'm³', 10),
('HAM_DS', 'Kết cấu', 'Bê tông tường hầm', 'm³', 11),
('HAM_DS', 'Kết cấu', 'Bê tông nắp hầm', 'm³', 12),
('HAM_DS', 'Kết cấu', 'Cốt thép hầm chui', 'tấn', 13),
('HAM_DS', 'Phụ trợ', 'Chống thấm', 'm²', 20),
('HAM_DS', 'Phụ trợ', 'Thoát nước hầm', 'm', 21),

-- TƯỜNG CHẮN
('TUONG', 'Móng', 'Đào móng tường', 'm³', 1),
('TUONG', 'Móng', 'Bê tông móng tường', 'm³', 2),
('TUONG', 'Kết cấu', 'Bê tông thân tường', 'm³', 10),
('TUONG', 'Kết cấu', 'Cốt thép tường chắn', 'tấn', 11),
('TUONG', 'Kết cấu', 'Tường chắn BTCT đúc sẵn', 'tấm', 12),
('TUONG', 'Đắp', 'Đắp đất sau tường', 'm³', 20),
('TUONG', 'Thoát nước', 'Lỗ thoát nước tường', 'cái', 30),

-- CỐNG
('CONG', 'Đào', 'Đào hố móng cống', 'm³', 1),
('CONG', 'Kết cấu', 'Cống tròn BTCT D1000', 'm', 10),
('CONG', 'Kết cấu', 'Cống tròn BTCT D1500', 'm', 11),
('CONG', 'Kết cấu', 'Cống hộp BTCT', 'm', 12),
('CONG', 'Kết cấu', 'Bê tông tường đầu cống', 'm³', 13),
('CONG', 'Kết cấu', 'Bê tông sân cống', 'm³', 14),
('CONG', 'Phụ trợ', 'Đắp đất trên cống', 'm³', 20),
('CONG', 'Phụ trợ', 'Gia cố thượng hạ lưu', 'm²', 21)

ON CONFLICT (type_code, group_name, name) DO NOTHING;
