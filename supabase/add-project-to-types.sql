-- ============================================================
-- Thêm project_id vào structure_types
-- Mỗi dự án có loại công trình riêng
-- Giữ nguyên dữ liệu CT07
-- ============================================================

-- 1. Thêm cột project_id (nullable trước)
ALTER TABLE structure_types ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE CASCADE;

-- 2. Gán tất cả types hiện có cho CT07
UPDATE structure_types
SET project_id = (SELECT id FROM projects WHERE code = 'CT07')
WHERE project_id IS NULL;

-- 3. Đặt NOT NULL
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM structure_types WHERE project_id IS NULL) THEN
    ALTER TABLE structure_types ALTER COLUMN project_id SET NOT NULL;
  END IF;
END $$;

-- 4. Index
CREATE INDEX IF NOT EXISTS idx_structure_types_project ON structure_types(project_id);

-- 5. Cập nhật unique constraint: (code) → (project_id, code)
ALTER TABLE structure_types DROP CONSTRAINT IF EXISTS structure_types_code_key;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'structure_types_project_code_key'
  ) THEN
    ALTER TABLE structure_types ADD CONSTRAINT structure_types_project_code_key UNIQUE (project_id, code);
  END IF;
END $$;

-- 6. Thêm cột has_left_right vào bảng projects (Mở rộng = true → có T/P, Đường mới = false)
ALTER TABLE projects ADD COLUMN IF NOT EXISTS has_left_right BOOLEAN DEFAULT false;

-- CT07: mở rộng (có T/P)
UPDATE projects SET has_left_right = true WHERE code = 'CT07';

-- ============ DONE ============
