-- ============================================================
-- FIX RLS POLICIES (infinite recursion) + SEED DATA
-- Chạy trong Supabase SQL Editor
-- ============================================================

-- ============ 1. TẠO FUNCTION is_admin() ============
-- Dùng SECURITY DEFINER để bypass RLS khi check admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- ============ 2. SỬA TẤT CẢ RLS POLICIES ============

-- --- profiles ---
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_admin" ON profiles;

CREATE POLICY "profiles_select_own" ON profiles FOR SELECT
  USING (id = auth.uid() OR is_admin());
CREATE POLICY "profiles_update_admin" ON profiles FOR UPDATE
  USING (is_admin());

-- --- structure_types ---
DROP POLICY IF EXISTS "st_admin_insert" ON structure_types;
DROP POLICY IF EXISTS "st_admin_update" ON structure_types;
DROP POLICY IF EXISTS "st_admin_delete" ON structure_types;

CREATE POLICY "st_admin_insert" ON structure_types FOR INSERT
  WITH CHECK (is_admin());
CREATE POLICY "st_admin_update" ON structure_types FOR UPDATE
  USING (is_admin());
CREATE POLICY "st_admin_delete" ON structure_types FOR DELETE
  USING (is_admin());

-- --- structures ---
DROP POLICY IF EXISTS "s_admin_insert" ON structures;
DROP POLICY IF EXISTS "s_admin_update" ON structures;
DROP POLICY IF EXISTS "s_admin_delete" ON structures;

CREATE POLICY "s_admin_insert" ON structures FOR INSERT
  WITH CHECK (is_admin());
CREATE POLICY "s_admin_update" ON structures FOR UPDATE
  USING (is_admin());
CREATE POLICY "s_admin_delete" ON structures FOR DELETE
  USING (is_admin());

-- --- work_items ---
DROP POLICY IF EXISTS "wi_admin_insert" ON work_items;
DROP POLICY IF EXISTS "wi_admin_update" ON work_items;
DROP POLICY IF EXISTS "wi_admin_delete" ON work_items;

CREATE POLICY "wi_admin_insert" ON work_items FOR INSERT
  WITH CHECK (is_admin());
CREATE POLICY "wi_admin_update" ON work_items FOR UPDATE
  USING (is_admin());
CREATE POLICY "wi_admin_delete" ON work_items FOR DELETE
  USING (is_admin());

-- --- diary_entries ---
DROP POLICY IF EXISTS "de_update" ON diary_entries;
DROP POLICY IF EXISTS "de_delete" ON diary_entries;

CREATE POLICY "de_update" ON diary_entries FOR UPDATE
  USING (
    (created_by = auth.uid() AND is_locked = false)
    OR is_admin()
  );
CREATE POLICY "de_delete" ON diary_entries FOR DELETE
  USING (is_admin());

-- --- diary_lines ---
DROP POLICY IF EXISTS "dl_insert" ON diary_lines;
DROP POLICY IF EXISTS "dl_update" ON diary_lines;
DROP POLICY IF EXISTS "dl_delete" ON diary_lines;

CREATE POLICY "dl_insert" ON diary_lines FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM diary_entries de
    WHERE de.id = entry_id AND de.is_locked = false
    AND (de.created_by = auth.uid() OR is_admin())
  ));
CREATE POLICY "dl_update" ON diary_lines FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM diary_entries de
    WHERE de.id = entry_id AND de.is_locked = false
    AND (de.created_by = auth.uid() OR is_admin())
  ));
CREATE POLICY "dl_delete" ON diary_lines FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM diary_entries de
    WHERE de.id = entry_id
    AND (de.created_by = auth.uid() OR is_admin())
  ));

-- --- work_item_catalog ---
DROP POLICY IF EXISTS "work_item_catalog_admin_write" ON work_item_catalog;
CREATE POLICY "work_item_catalog_admin_write" ON work_item_catalog
  FOR ALL USING (is_admin());

-- ============ 3. SEED DATA ============

-- 3.1 Structure Types
INSERT INTO structure_types (code, name, sort_order) VALUES
  ('DUONG',  'Đường',            1),
  ('CAU',    'Cầu',              2),
  ('HAM_PL', 'Hầm Phú Lương',   3),
  ('HAM_DS', 'Hầm chui dân sinh', 4),
  ('TUONG',  'Tường chắn',       5),
  ('CONG',   'Cống',             6)
ON CONFLICT (code) DO NOTHING;

-- 3.2 Structures — CẦU CHÍNH TUYẾN ĐOẠN 1
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, has_left_right, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, v.section, v.len, 'm', v.lr, v.meta::jsonb, v.so
FROM structure_types st,
(VALUES
  ('CAU','C_ThinhDan',   'Cầu Thịnh Đán',     'Km63+371', 'Đoạn 1', 139.35, true,  '{"loai_dam":"Dầm bản 21m"}', 1),
  ('CAU','C_SonTien',    'Cầu Sơn Tiến',      'Km65+127', 'Đoạn 1',  23.10, true,  '{"loai_dam":"Dầm bản 12m"}', 2),
  ('CAU','C_NuocHai',    'Cầu Nước Hai',       'Km65+267', 'Đoạn 1',  31.10, true,  '{"loai_dam":"Dầm bản 18m"}', 3),
  ('CAU','C_LangUm',     'Cầu Làng Um',        'Km66+354', 'Đoạn 1',  46.20, true,  '{"loai_dam":"Dầm I 33m"}',   4),
  ('CAU','C_PhucHa',     'Cầu Phúc Hà',        'Km67+754', 'Đoạn 1', 251.40, true,  '{"loai_dam":"Dầm SPT 38.2m"}', 5),
  ('CAU','C_TanLong',    'Cầu Tân Long',       'Km68+297', 'Đoạn 1',  46.20, true,  '{"loai_dam":"Dầm I 33m"}',   6)
) AS v(type_code, code, name, station, section, len, lr, meta, so)
WHERE st.code = v.type_code
ON CONFLICT (code) DO NOTHING;

-- CẦU CHÍNH TUYẾN ĐOẠN 2
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, has_left_right, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, v.section, v.len, 'm', v.lr, v.meta::jsonb, v.so
FROM structure_types st,
(VALUES
  ('CAU','C_Km86830',    'Cầu Km86+830',              'Km86+830',          'Đoạn 2',  78.20, false, '{"loai_dam":"Dầm I"}',      7),
  ('CAU','C_Can89_chinh','Cầu cạn Km89+600 (chính)',  'Km88+801–Km89+771', 'Đoạn 2', 970.05, false, '{"loai_dam":"Super T, 22 nhịp"}', 8),
  ('CAU','C_Can89_trai', 'Cầu cạn Km89+600 (trái)',   'Km89+771–Km90+425', 'Đoạn 2', 655.00, false, '{"loai_dam":"Super T"}',    9),
  ('CAU','C_Can89_phai', 'Cầu cạn Km89+600 (phải)',   'Km89+771–Km90+411', 'Đoạn 2', 640.85, false, '{"loai_dam":"Super T"}',   10),
  ('CAU','C_Km93520',    'Cầu Km93+520',              'Km93+520',          'Đoạn 2',  46.10, false, '{"loai_dam":"Dầm I"}',     11)
) AS v(type_code, code, name, station, section, len, lr, meta, so)
WHERE st.code = v.type_code
ON CONFLICT (code) DO NOTHING;

-- CẦU TRONG NÚT GIAO
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, has_left_right, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, v.section, v.len, 'm', false, v.meta::jsonb, v.so
FROM structure_types st,
(VALUES
  ('CAU','C_TanLap_CVN', 'Nút Tân Lập – cầu vượt ngang', 'Km61+925', 'Đoạn 1',  77.21, '{"loai_dam":"Dầm I 33m, B=9m"}',    12),
  ('CAU','C_TanLap_N2',  'Nút Tân Lập – nhánh 2',        'Km61+925', 'Đoạn 1', 443.88, '{"loai_dam":"Dầm I 30m, B=8m"}',    13),
  ('CAU','C_TanLap_N6',  'Nút Tân Lập – nhánh 6',        'Km61+925', 'Đoạn 1', 495.07, '{"loai_dam":"Dầm I 33.28m, B=8m"}', 14),
  ('CAU','C_VoTranh',    'Cầu nút Vô Tranh',             'Km82–95.6','Đoạn 2',  87.40, '{"loai_dam":"Super T, B=12m"}',     15)
) AS v(type_code, code, name, station, section, len, meta, so)
WHERE st.code = v.type_code
ON CONFLICT (code) DO NOTHING;

-- CẦU VƯỢT NGANG
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, has_left_right, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, v.section, v.len, 'm', false, '{}'::jsonb, v.so
FROM structure_types st,
(VALUES
  ('CAU','C_VN_Km83511', 'Cầu vượt ngang Km83+511', 'Km83+511', 'Đoạn 2', 0, 16),
  ('CAU','C_VN_Km84540', 'Cầu vượt ngang Km84+540', 'Km84+540', 'Đoạn 2', 0, 17)
) AS v(type_code, code, name, station, section, len, so)
WHERE st.code = v.type_code
ON CONFLICT (code) DO NOTHING;

-- ĐƯỜNG (2 đoạn)
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, has_left_right, sort_order)
SELECT st.id, v.code, v.name, v.station, v.section, v.len, 'km', false, v.so
FROM structure_types st,
(VALUES
  ('DUONG','D_Doan1', 'Đường – Đoạn 1', 'Km59+000–Km68+700', 'Đoạn 1', 9.7,  1),
  ('DUONG','D_Doan2', 'Đường – Đoạn 2', 'Km82+000–Km95+600', 'Đoạn 2', 13.6, 2)
) AS v(type_code, code, name, station, section, len, so)
WHERE st.code = v.type_code
ON CONFLICT (code) DO NOTHING;

-- HẦM PHÚ LƯƠNG
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, has_left_right, sort_order)
SELECT st.id, 'H_PhuLuong', 'Hầm Phú Lương (NATM)', 'Km90–Km91', 'Đoạn 2', NULL, 'm', false, 1
FROM structure_types st WHERE st.code = 'HAM_PL'
ON CONFLICT (code) DO NOTHING;

-- HẦM CHUI DÂN SINH – ĐOẠN 1
INSERT INTO structures (type_id, code, name, station, section, design_unit, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, 'Đoạn 1', 'cái', '{"khau_do":"2x3x2m"}'::jsonb, v.so
FROM structure_types st,
(VALUES
  ('HC_59240',  'Hầm chui DS Km59+240',  'Km59+240',  1),
  ('HC_60490',  'Hầm chui DS Km60+490',  'Km60+490',  2),
  ('HC_61200',  'Hầm chui DS Km61+200',  'Km61+200',  3),
  ('HC_62500',  'Hầm chui DS Km62+500',  'Km62+500',  4),
  ('HC_63100',  'Hầm chui DS Km63+100',  'Km63+100',  5),
  ('HC_64300',  'Hầm chui DS Km64+300',  'Km64+300',  6),
  ('HC_65050',  'Hầm chui DS Km65+050',  'Km65+050',  7),
  ('HC_66100',  'Hầm chui DS Km66+100',  'Km66+100',  8),
  ('HC_67200',  'Hầm chui DS Km67+200',  'Km67+200',  9),
  ('HC_68060',  'Hầm chui DS Km68+060',  'Km68+060', 10)
) AS v(code, name, station, so)
WHERE st.code = 'HAM_DS'
ON CONFLICT (code) DO NOTHING;

-- HẦM CHUI DÂN SINH – ĐOẠN 2
INSERT INTO structures (type_id, code, name, station, section, design_unit, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, 'Đoạn 2', 'cái', '{"khau_do":"2x3x2m"}'::jsonb, v.so
FROM structure_types st,
(VALUES
  ('HC_83390',  'Hầm chui DS Km83+390',  'Km83+390', 11),
  ('HC_84700',  'Hầm chui DS Km84+700',  'Km84+700', 12),
  ('HC_86100',  'Hầm chui DS Km86+100',  'Km86+100', 13),
  ('HC_87730',  'Hầm chui DS Km87+730',  'Km87+730', 14)
) AS v(code, name, station, so)
WHERE st.code = 'HAM_DS'
ON CONFLICT (code) DO NOTHING;

-- TƯỜNG CHẮN TRỌNG LỰC (H<6m) – ĐOẠN 2
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, 'Đoạn 2', v.len, 'm', '{"loai":"Trọng lực","H":"<6m"}'::jsonb, v.so
FROM structure_types st,
(VALUES
  ('TC_TL1', 'Tường chắn TL Km84+300', 'Km84+300', 60,  1),
  ('TC_TL2', 'Tường chắn TL Km84+700', 'Km84+700', 80,  2),
  ('TC_TL3', 'Tường chắn TL Km85+100', 'Km85+100', 50,  3),
  ('TC_TL4', 'Tường chắn TL Km85+500', 'Km85+500', 70,  4),
  ('TC_TL5', 'Tường chắn TL Km85+860', 'Km85+860', 80,  5)
) AS v(code, name, station, len, so)
WHERE st.code = 'TUONG'
ON CONFLICT (code) DO NOTHING;

-- TƯỜNG CHẮN DÂN SINH (H≈5m) – ĐOẠN 1
INSERT INTO structures (type_id, code, name, station, section, design_length, design_unit, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, 'Đoạn 1', v.len, 'm', '{"loai":"Dân sinh","H":"≈5m"}'::jsonb, v.so
FROM structure_types st,
(VALUES
  ('TC_DS01','Tường chắn DS Km62+100','Km62+100', 250, 6),
  ('TC_DS02','Tường chắn DS Km62+500','Km62+500', 300, 7),
  ('TC_DS03','Tường chắn DS Km62+900','Km62+900', 280, 8),
  ('TC_DS04','Tường chắn DS Km63+200','Km63+200', 260, 9),
  ('TC_DS05','Tường chắn DS Km63+600','Km63+600', 310, 10),
  ('TC_DS06','Tường chắn DS Km64+000','Km64+000', 270, 11),
  ('TC_DS07','Tường chắn DS Km64+400','Km64+400', 290, 12),
  ('TC_DS08','Tường chắn DS Km64+800','Km64+800', 250, 13),
  ('TC_DS09','Tường chắn DS Km65+100','Km65+100', 270, 14),
  ('TC_DS10','Tường chắn DS Km65+500','Km65+500', 280, 15),
  ('TC_DS11','Tường chắn DS Km65+900','Km65+900', 260, 16),
  ('TC_DS12','Tường chắn DS Km66+200','Km66+200', 300, 17),
  ('TC_DS13','Tường chắn DS Km66+600','Km66+600', 250, 18),
  ('TC_DS14','Tường chắn DS Km67+000','Km67+000', 270, 19),
  ('TC_DS15','Tường chắn DS Km67+300','Km67+300', 240, 20),
  ('TC_DS16','Tường chắn DS Km67+600','Km67+600', 260, 21),
  ('TC_DS17','Tường chắn DS Km67+900','Km67+900', 233.51, 22),
  ('TC_DS18','Tường chắn DS Km68+200','Km68+200', 250, 23)
) AS v(code, name, station, len, so)
WHERE st.code = 'TUONG'
ON CONFLICT (code) DO NOTHING;

-- CỐNG
INSERT INTO structures (type_id, code, name, station, section, design_unit, metadata, sort_order)
SELECT st.id, v.code, v.name, v.station, v.section, v.unit, v.meta::jsonb, v.so
FROM structure_types st,
(VALUES
  ('CONG','CO_Tron_D1','Cống tròn D1000/D1500/D2000 – Đoạn 1','Km59–Km68.7','Đoạn 1','cống','{"loai":"Tròn","uoc_tinh":true}', 1),
  ('CONG','CO_Tron_D2','Cống tròn D1000/D1500/D2000 – Đoạn 2','Km82–Km95.6','Đoạn 2','cống','{"loai":"Tròn","uoc_tinh":true}', 2),
  ('CONG','CO_Hop_D1', 'Cống hộp BxH – Đoạn 1',              'Km59–Km68.7','Đoạn 1','cống','{"loai":"Hộp","uoc_tinh":true}',  3),
  ('CONG','CO_Hop_D2', 'Cống hộp BxH – Đoạn 2',              'Km82–Km95.6','Đoạn 2','cống','{"loai":"Hộp","uoc_tinh":true}',  4)
) AS v(type_code, code, name, station, section, unit, meta, so)
WHERE st.code = v.type_code
ON CONFLICT (code) DO NOTHING;

-- ============ 3.3 WORK ITEMS ============

-- === CẦU LỚN ===
DO $$
DECLARE
  s_id UUID;
  bridge_codes TEXT[] := ARRAY['C_ThinhDan','C_PhucHa','C_Can89_chinh','C_Can89_trai','C_Can89_phai'];
  bc TEXT;
BEGIN
  FOREACH bc IN ARRAY bridge_codes LOOP
    SELECT id INTO s_id FROM structures WHERE code = bc;
    IF s_id IS NOT NULL THEN
      INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
        (s_id, 'Móng cọc khoan nhồi', 'cọc', 'Kết cấu phần dưới', 1),
        (s_id, 'Mố cầu',              'm³',  'Kết cấu phần dưới', 2),
        (s_id, 'Trụ cầu',             'm³',  'Kết cấu phần dưới', 3),
        (s_id, 'Mũ mố / mũ trụ',     'm³',  'Kết cấu phần dưới', 4),
        (s_id, 'Dầm',                 'dầm', 'Kết cấu phần trên', 5),
        (s_id, 'Bản mặt cầu',        'm²',  'Kết cấu phần trên', 6),
        (s_id, 'Lan can',             'm',   'Kết cấu phần trên', 7),
        (s_id, 'Khe co giãn',        'bộ',  'Phụ trợ',           8),
        (s_id, 'Gối cầu',            'bộ',  'Phụ trợ',           9),
        (s_id, 'Thoát nước mặt cầu', 'm',   'Phụ trợ',          10),
        (s_id, 'Lớp phủ mặt cầu',   'm²',  'Phụ trợ',          11)
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END $$;

-- === CẦU NHỎ ===
DO $$
DECLARE
  s_id UUID;
  bridge_codes TEXT[] := ARRAY['C_SonTien','C_NuocHai','C_LangUm','C_TanLong','C_Km86830','C_Km93520'];
  bc TEXT;
BEGIN
  FOREACH bc IN ARRAY bridge_codes LOOP
    SELECT id INTO s_id FROM structures WHERE code = bc;
    IF s_id IS NOT NULL THEN
      INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
        (s_id, 'Móng cọc',           'cọc', 'Kết cấu phần dưới', 1),
        (s_id, 'Mố trụ cầu',        'm³',  'Kết cấu phần dưới', 2),
        (s_id, 'Dầm',               'dầm', 'Kết cấu phần trên', 3),
        (s_id, 'Bản mặt cầu + lan can', 'm²', 'Kết cấu phần trên', 4)
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END $$;

-- === CẦU NÚT GIAO + CẦU VƯỢT ===
DO $$
DECLARE
  s_id UUID;
  bridge_codes TEXT[] := ARRAY['C_TanLap_CVN','C_TanLap_N2','C_TanLap_N6','C_VoTranh','C_VN_Km83511','C_VN_Km84540'];
  bc TEXT;
BEGIN
  FOREACH bc IN ARRAY bridge_codes LOOP
    SELECT id INTO s_id FROM structures WHERE code = bc;
    IF s_id IS NOT NULL THEN
      INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
        (s_id, 'Móng cọc khoan nhồi', 'cọc', 'Kết cấu phần dưới', 1),
        (s_id, 'Mố, trụ cầu',        'm³',  'Kết cấu phần dưới', 2),
        (s_id, 'Dầm',                 'dầm', 'Kết cấu phần trên', 3),
        (s_id, 'Bản mặt cầu + lan can', 'm²', 'Kết cấu phần trên', 4)
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END $$;

-- === ĐƯỜNG ===
DO $$
DECLARE
  s_id UUID;
  road_codes TEXT[] := ARRAY['D_Doan1','D_Doan2'];
  rc TEXT;
BEGIN
  FOREACH rc IN ARRAY road_codes LOOP
    SELECT id INTO s_id FROM structures WHERE code = rc;
    IF s_id IS NOT NULL THEN
      INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
        (s_id, 'Đào nền đường',           'm³', 'I. Nền đường',  1),
        (s_id, 'Đắp nền đường',           'm³', 'I. Nền đường',  2),
        (s_id, 'Xử lý nền đất yếu',      'm³', 'I. Nền đường',  3),
        (s_id, 'Lu lèn nền đường',        'm²', 'I. Nền đường',  4),
        (s_id, 'CPĐD loại I (48cm)',      'm³', 'II. Mặt đường', 5),
        (s_id, 'CPĐD GCXM 4% (16cm)',     'm³', 'II. Mặt đường', 6),
        (s_id, 'BTN rỗng 25 (10cm)',      'm²', 'II. Mặt đường', 7),
        (s_id, 'BTN chặt 19 (6cm)',       'm²', 'II. Mặt đường', 8),
        (s_id, 'BTN chặt 12.5 (6cm)',     'm²', 'II. Mặt đường', 9),
        (s_id, 'Rãnh thoát nước dọc',     'm',  'III. Thoát nước', 10),
        (s_id, 'Cống thoát nước ngang',   'cống','III. Thoát nước', 11),
        (s_id, 'Hộ lan mềm/cứng',        'm',  'IV. ATGT',       12),
        (s_id, 'Biển báo, vạch sơn',      'bộ', 'IV. ATGT',       13),
        (s_id, 'Thi công đường gom',      'km', 'V. Đường gom',   14)
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END $$;

-- === HẦM PHÚ LƯƠNG ===
DO $$
DECLARE s_id UUID;
BEGIN
  SELECT id INTO s_id FROM structures WHERE code = 'H_PhuLuong';
  IF s_id IS NOT NULL THEN
    INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
      (s_id, 'GPMB cửa hầm',               'm²',    'I. Chuẩn bị',        1),
      (s_id, 'Đường công vụ vào cửa hầm',   'km',    'I. Chuẩn bị',        2),
      (s_id, 'Hệ thống cấp điện, nước TC',  'HT',    'I. Chuẩn bị',        3),
      (s_id, 'Lắp đặt TB đào hầm NATM',    'bộ',    'I. Chuẩn bị',        4),
      (s_id, 'Đào hầm ống trái',            'm',     'II. Đào hầm',        5),
      (s_id, 'Đào hầm ống phải',            'm',     'II. Đào hầm',        6),
      (s_id, 'Vận chuyển đất đá thải',      'm³',    'II. Đào hầm',        7),
      (s_id, 'Neo đá (rock bolt)',           'thanh', 'III. Gia cố',        8),
      (s_id, 'Lưới thép gia cố',            'm²',    'III. Gia cố',        9),
      (s_id, 'Phun bê tông (shotcrete)',     'm³',    'III. Gia cố',       10),
      (s_id, 'Vòm thép chống đỡ',           'bộ',    'III. Gia cố',       11),
      (s_id, 'Chống thấm (tấm PVC)',        'm²',    'IV. Vỏ hầm',       12),
      (s_id, 'Đổ bê tông vỏ hầm',           'm³',    'IV. Vỏ hầm',       13),
      (s_id, 'Cốt thép vỏ hầm',             'tấn',   'IV. Vỏ hầm',       14),
      (s_id, 'Hệ thống thông gió',          'bộ',    'V. HT kỹ thuật',   15),
      (s_id, 'Hệ thống chiếu sáng',         'bộ',    'V. HT kỹ thuật',   16),
      (s_id, 'Hệ thống PCCC',               'bộ',    'V. HT kỹ thuật',   17)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- === HẦM CHUI DÂN SINH ===
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT id FROM structures WHERE code LIKE 'HC_%' ORDER BY sort_order LOOP
    INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
      (r.id, 'Đào đất hố móng',                  'm³', 'Thi công', 1),
      (r.id, 'Bê tông móng',                     'm³', 'Thi công', 2),
      (r.id, 'Lắp đặt khung hầm (2x3x2m)',      'bộ', 'Thi công', 3),
      (r.id, 'Đắp đất hoàn trả',                 'm³', 'Thi công', 4),
      (r.id, 'Hoàn thiện (lan can, chiếu sáng)',  'bộ', 'Hoàn thiện', 5)
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

-- === TƯỜNG CHẮN ===
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT id FROM structures WHERE code LIKE 'TC_%' ORDER BY sort_order LOOP
    INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
      (r.id, 'Đào đất hố móng',      'm³',  'Thi công', 1),
      (r.id, 'Bê tông móng',         'm³',  'Thi công', 2),
      (r.id, 'Bê tông thân tường',   'm³',  'Thi công', 3),
      (r.id, 'Cốt thép',             'tấn', 'Thi công', 4),
      (r.id, 'Đắp đất sau tường',    'm³',  'Thi công', 5),
      (r.id, 'Thoát nước sau tường', 'm',   'Thi công', 6)
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

-- === CỐNG ===
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT id FROM structures WHERE code LIKE 'CO_%' ORDER BY sort_order LOOP
    INSERT INTO work_items (structure_id, name, unit, group_name, sort_order) VALUES
      (r.id, 'Đào đất hố móng',       'm³', 'Thi công', 1),
      (r.id, 'Bê tông móng',          'm³', 'Thi công', 2),
      (r.id, 'Lắp đặt ống/hộp cống', 'm',  'Thi công', 3),
      (r.id, 'Đắp đất hoàn trả',     'm³', 'Thi công', 4),
      (r.id, 'Gia cố cửa cống',      'm³', 'Thi công', 5)
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

-- ============ DONE ============
-- Sửa xong RLS + Seed data hoàn chỉnh
