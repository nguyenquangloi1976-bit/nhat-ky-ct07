-- ============================================================
-- Tab 1: Tài liệu đệ trình (theo Điều 15, NĐ 207/2026/NĐ-CP)
-- ============================================================
CREATE TABLE IF NOT EXISTS submission_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  group_code TEXT NOT NULL CHECK (group_code IN ('A','B','C','D')),
  -- A: BPTC & An toàn, B: Chất lượng & TN, C: Tiến độ & Tổ chức, D: Thiết kế
  sort_order INT NOT NULL DEFAULT 0,
  doc_name TEXT NOT NULL,
  doc_number TEXT,           -- số hiệu văn bản đã nộp
  submitted_date DATE,       -- ngày nộp
  status TEXT NOT NULL DEFAULT 'chua_nop'
    CHECK (status IN ('chua_nop','da_nop','dang_xem_xet','chap_thuan','yeu_cau_sua')),
  approved_date DATE,        -- ngày chấp thuận
  reviewer_notes TEXT,       -- ghi chú của TVGS
  notes TEXT,                -- ghi chú chung
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE submission_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "submission_documents_all" ON submission_documents
  FOR ALL USING (true) WITH CHECK (true);

-- Index
CREATE INDEX idx_subdocs_project ON submission_documents(project_id);

-- ============================================================
-- Tab 2: Nguồn vật liệu đầu vào (theo khoản 5–7, Điều 14)
-- ============================================================
CREATE TABLE IF NOT EXISTS material_sources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  material_name TEXT NOT NULL,       -- tên vật liệu (đất K95, đá, cát, xi măng...)
  supplier TEXT,                     -- nhà cung cấp / mỏ / trạm trộn
  supplier_address TEXT,             -- địa chỉ nguồn cung
  distance_km NUMERIC,              -- khoảng cách vận chuyển (km)
  status TEXT NOT NULL DEFAULT 'chua_trinh'
    CHECK (status IN ('chua_trinh','da_thi_nghiem','da_nghiem_thu','chap_thuan')),
  -- Hồ sơ chất lượng (checklist)
  has_cert_quality BOOLEAN DEFAULT false,     -- CN chất lượng nhà SX
  has_cert_origin BOOLEAN DEFAULT false,      -- chứng từ xuất xứ
  has_cert_compliance BOOLEAN DEFAULT false,  -- giấy CN hợp quy
  has_test_result BOOLEAN DEFAULT false,      -- kết quả thí nghiệm
  has_mining_permit BOOLEAN DEFAULT false,    -- giấy phép khai thác mỏ
  approved_date DATE,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE material_sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "material_sources_all" ON material_sources
  FOR ALL USING (true) WITH CHECK (true);

-- Index
CREATE INDEX idx_matsrc_project ON material_sources(project_id);

-- ============================================================
-- Seed dữ liệu mẫu cho submission_documents (project CT07)
-- ============================================================
INSERT INTO submission_documents (project_id, group_code, sort_order, doc_name) VALUES
  -- Nhóm A: BPTC & An toàn
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'A', 1, 'Biện pháp thi công (kèm BP bảo đảm an toàn)'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'A', 2, 'Biện pháp bảo đảm an toàn thi công (Phụ lục III, NĐ 207)'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'A', 3, 'Kế hoạch an toàn giao thông'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'A', 4, 'Kế hoạch bảo vệ môi trường thi công'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'A', 5, 'Kế hoạch phòng cháy chữa cháy'),
  -- Nhóm B: Chất lượng & Thí nghiệm
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'B', 1, 'Kế hoạch kiểm soát chất lượng vật liệu, sản phẩm, cấu kiện'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'B', 2, 'Kế hoạch tổ chức thí nghiệm, kiểm tra, kiểm định'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'B', 3, 'Kế hoạch kiểm tra, nghiệm thu công việc / giai đoạn'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'B', 4, 'Hồ sơ năng lực phòng thí nghiệm (LAS-XD, VILAS)'),
  -- Nhóm C: Tiến độ & Tổ chức
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'C', 1, 'Tiến độ thi công chi tiết'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'C', 2, 'Chương trình huy động (nhân sự, thiết bị, mặt bằng)'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'C', 3, 'Hệ thống quản lý thi công (sơ đồ tổ chức, phân công)'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'C', 4, 'Danh sách nhân sự chủ chốt'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'C', 5, 'Danh mục thiết bị thi công (kèm giấy kiểm định)'),
  -- Nhóm D: Thiết kế
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'D', 1, 'Hồ sơ TKKT / BVTC được phê duyệt'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'D', 2, 'Chỉ dẫn kỹ thuật (CDKT)'),
  ('3115cd1d-b3c3-47ff-b5d2-ed1f4793576d', 'D', 3, 'Đề cương thi công đại trà (sau đoạn thí điểm)')
ON CONFLICT DO NOTHING;
