-- Bảng lưu diện tích phân lớp đắp (DTPL) cho từng mặt cắt ngang
-- Dữ liệu import từ file Excel DTPL thiết kế
-- Khối lượng thiết kế toàn mặt cắt = SUM(area) tại 1 lý trình

CREATE TABLE IF NOT EXISTS layer_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  station integer NOT NULL,          -- lý trình (m), VD: 64500 = Km64+500
  layer integer NOT NULL,            -- số lớp (1=trên cùng, số lớn=dưới cùng đắp trước)
  side text NOT NULL CHECK (side IN ('T', 'P')),  -- T=Trái, P=Phải
  area numeric NOT NULL,             -- diện tích mặt cắt lớp (m²)
  section_name text,                 -- tên cọc/mặt cắt (H5, 21, CO, ND27…)
  km_range text,                     -- nguồn ("64+500-67+000", "71-73")
  created_at timestamptz DEFAULT now()
);

-- Unique: 1 lý trình + 1 lớp + 1 bên = 1 diện tích
CREATE UNIQUE INDEX IF NOT EXISTS idx_layer_sections_unique
  ON layer_sections (project_id, side, station, layer);

-- Index cho truy vấn tính khối lượng (tìm mặt cắt trong khoảng lý trình)
CREATE INDEX IF NOT EXISTS idx_layer_sections_range
  ON layer_sections (project_id, side, layer, station);

-- RLS
ALTER TABLE layer_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "layer_sections_read" ON layer_sections
  FOR SELECT USING (true);

CREATE POLICY "layer_sections_write" ON layer_sections
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'admin' OR profiles.title = 'TVGS trưởng')
    )
  );
