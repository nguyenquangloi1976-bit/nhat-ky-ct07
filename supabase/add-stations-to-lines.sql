-- =============================================================
-- Thêm lý trình cho dòng nhật ký (phục vụ trang Cắt dọc)
-- Chạy 1 lần trong Supabase SQL Editor. Chạy lại không gây lỗi.
-- =============================================================

-- 1. Lý trình đầu / cuối của đoạn thi công, tính bằng mét (Km60+100 = 60100)
ALTER TABLE diary_lines ADD COLUMN IF NOT EXISTS km_from NUMERIC;
ALTER TABLE diary_lines ADD COLUMN IF NOT EXISTS km_to   NUMERIC;

-- 2. Cho phép ghi cùng một hạng mục nhiều đoạn lý trình trong một ngày
--    (bỏ ràng buộc UNIQUE mỗi hạng mục chỉ 1 dòng theo bên + đợt)
DO $$
DECLARE c RECORD;
BEGIN
  FOR c IN
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.diary_lines'::regclass AND contype = 'u'
  LOOP
    EXECUTE format('ALTER TABLE public.diary_lines DROP CONSTRAINT %I', c.conname);
  END LOOP;
END $$;

-- 3. Chỉ mục để trang Cắt dọc tải nhanh
CREATE INDEX IF NOT EXISTS idx_diary_lines_km ON diary_lines(work_item_id, km_from, km_to);

-- 4. Bổ sung lớp "Đào bóc hữu cơ" vào danh mục mẫu loại Đường (bỏ qua nếu đã có)
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
  ('DUONG', 'Nền đường', 'Đào bóc hữu cơ', 'm³', true, 0)
ON CONFLICT (type_code, group_name, name) DO NOTHING;
