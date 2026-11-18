-- ============================================================
-- MULTI-PROJECT: Thêm bảng projects, cập nhật structures & diary_entries
-- Chạy trong Supabase SQL Editor
-- Giữ nguyên toàn bộ dữ liệu CT07
-- ============================================================

-- ============ 1. TẠO BẢNG PROJECTS ============
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  km_range TEXT,
  consortium TEXT,
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES auth.users(id)
);

-- RLS cho projects
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "projects_select_all" ON projects FOR SELECT
  USING (true);
CREATE POLICY "projects_admin_insert" ON projects FOR INSERT
  WITH CHECK (is_admin());
CREATE POLICY "projects_admin_update" ON projects FOR UPDATE
  USING (is_admin());
CREATE POLICY "projects_admin_delete" ON projects FOR DELETE
  USING (is_admin());

-- ============ 2. INSERT DỰ ÁN CT07 ============
INSERT INTO projects (code, name, description, km_range, consortium, start_date, end_date)
VALUES (
  'CT07',
  'Gói thầu TV-08 – CT.07 Hà Nội – Thái Nguyên – Chợ Mới',
  'TVGS đoạn TEDI phụ trách: Km59+000–Km68+700 và Km82+000–Km95+600 (~23.3 km)',
  'Km59+000–Km68+700, Km82+000–Km95+600',
  'TEDI – CTGT2 – Viện KHCN GTVT – Phúc Lộc',
  '2026-11-01',
  '2027-12-31'
)
ON CONFLICT (code) DO NOTHING;

-- ============ 3. THÊM project_id VÀO structures ============
-- Bước 1: Thêm cột nullable
ALTER TABLE structures ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;

-- Bước 2: Gán tất cả structures hiện có cho CT07
UPDATE structures
SET project_id = (SELECT id FROM projects WHERE code = 'CT07')
WHERE project_id IS NULL;

-- Bước 3: Đặt NOT NULL (chỉ khi tất cả đã có project_id)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM structures WHERE project_id IS NULL) THEN
    ALTER TABLE structures ALTER COLUMN project_id SET NOT NULL;
  END IF;
END $$;

-- Index
CREATE INDEX IF NOT EXISTS idx_structures_project ON structures(project_id);

-- ============ 4. THÊM project_id VÀO diary_entries ============
ALTER TABLE diary_entries ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;

-- Gán diary_entries hiện có cho CT07 thông qua structure
UPDATE diary_entries de
SET project_id = s.project_id
FROM structures s
WHERE de.structure_id = s.id AND de.project_id IS NULL;

-- Đặt NOT NULL
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM diary_entries WHERE project_id IS NULL) THEN
    ALTER TABLE diary_entries ALTER COLUMN project_id SET NOT NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_diary_entries_project ON diary_entries(project_id);

-- ============ 5. CẬP NHẬT UNIQUE CONSTRAINT ============
-- structures: code phải unique trong phạm vi project (không global nữa)
-- Drop unique constraint cũ trên code
ALTER TABLE structures DROP CONSTRAINT IF EXISTS structures_code_key;
-- Thêm unique constraint mới: (project_id, code)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'structures_project_code_key'
  ) THEN
    ALTER TABLE structures ADD CONSTRAINT structures_project_code_key UNIQUE (project_id, code);
  END IF;
END $$;

-- diary_entries: unique(structure_id, entry_date) vẫn giữ nguyên (đã thuộc project qua structure)

-- ============ 6. CẬP NHẬT VIEW v_summary ============
DROP VIEW IF EXISTS v_summary;
CREATE OR REPLACE VIEW v_summary AS
SELECT
  s.project_id,
  st.code AS type_code,
  st.name AS type_name,
  s.id AS structure_id,
  s.code AS structure_code,
  s.name AS structure_name,
  wi.id AS work_item_id,
  wi.name AS work_item_name,
  wi.unit,
  wi.design_quantity,
  dl.side,
  SUM(dl.quantity) AS total_quantity
FROM structures s
JOIN structure_types st ON st.id = s.type_id
JOIN work_items wi ON wi.structure_id = s.id
LEFT JOIN diary_lines dl ON dl.work_item_id = wi.id
LEFT JOIN diary_entries de ON de.id = dl.entry_id
GROUP BY s.project_id, st.code, st.name, s.id, s.code, s.name,
         wi.id, wi.name, wi.unit, wi.design_quantity, dl.side;

-- ============ DONE ============
-- Bảng projects đã tạo, CT07 là dự án đầu tiên
-- Tất cả structures và diary_entries hiện có đã gán cho CT07
