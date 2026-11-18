-- =============================================================
-- Danh mục hạng mục loại ĐƯỜNG lấy theo sheet DM.Duong của file Excel
-- Tien-do-ngay-Cau-Duong-TEDI-CT07_v5.xlsx (47 hạng mục, 8 bộ phận)
-- Chạy trong Supabase SQL Editor. Thay thế toàn bộ danh mục mẫu cũ của loại Đường;
-- không đụng tới danh mục các loại khác và không đụng tới nhật ký đã ghi.
-- =============================================================

DELETE FROM work_item_catalog WHERE type_code = 'DUONG';

INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
-- Nền đường
('DUONG', 'Nền đường', 'Phát quang, dọn dẹp mặt bằng', 'm²', true, 101),
('DUONG', 'Nền đường', 'Đào bóc hữu cơ', 'm³', true, 102),
('DUONG', 'Nền đường', 'Đào nền đường', 'm³', true, 103),
('DUONG', 'Nền đường', 'Đánh cấp', 'm³', true, 104),
('DUONG', 'Nền đường', 'Đắp nền đường K95', 'm³', true, 105),
('DUONG', 'Nền đường', 'Đắp nền đường K98', 'm³', true, 106),
('DUONG', 'Nền đường', 'Lu lèn nền đường', 'm²', true, 107),
('DUONG', 'Nền đường', 'Gia cố mái taluy', 'm²', true, 108),
('DUONG', 'Nền đường', 'Trồng cỏ mái taluy', 'm²', true, 109),
-- Xử lý nền đất yếu
('DUONG', 'Xử lý nền đất yếu', 'Đào thay đất yếu', 'm³', true, 201),
('DUONG', 'Xử lý nền đất yếu', 'Rải vải địa kỹ thuật', 'm²', true, 202),
('DUONG', 'Xử lý nền đất yếu', 'Đệm cát thoát nước', 'm³', true, 203),
('DUONG', 'Xử lý nền đất yếu', 'Cắm bấc thấm', 'm', true, 204),
('DUONG', 'Xử lý nền đất yếu', 'Đắp gia tải', 'm³', true, 205),
('DUONG', 'Xử lý nền đất yếu', 'Dỡ tải', 'm³', true, 206),
('DUONG', 'Xử lý nền đất yếu', 'Quan trắc lún', 'điểm', true, 207),
-- Móng đường
('DUONG', 'Móng đường', 'CPĐD loại I (48cm)', 'm³', true, 301),
('DUONG', 'Móng đường', 'CPĐD GCXM 4% (16cm)', 'm³', true, 302),
-- Mặt đường
('DUONG', 'Mặt đường', 'Tưới nhựa thấm bám', 'm²', true, 401),
('DUONG', 'Mặt đường', 'BTN rỗng 25 (10cm)', 'm²', true, 402),
('DUONG', 'Mặt đường', 'Tưới nhựa dính bám', 'm²', true, 403),
('DUONG', 'Mặt đường', 'BTN chặt 19 (6cm)', 'm²', true, 404),
('DUONG', 'Mặt đường', 'BTN chặt 12.5 (6cm)', 'm²', true, 405),
('DUONG', 'Mặt đường', 'BTN siêu mỏng tạo nhám', 'm²', true, 406),
-- Thoát nước
('DUONG', 'Thoát nước', 'Rãnh thoát nước dọc', 'm', true, 501),
('DUONG', 'Thoát nước', 'Rãnh đỉnh', 'm', true, 502),
('DUONG', 'Thoát nước', 'Đào móng cống', 'm³', true, 503),
('DUONG', 'Thoát nước', 'BT móng cống', 'm³', true, 504),
('DUONG', 'Thoát nước', 'Lắp đặt ống cống', 'm', true, 505),
('DUONG', 'Thoát nước', 'BT tường đầu, tường cánh cống', 'm³', true, 506),
('DUONG', 'Thoát nước', 'Đắp đất mang cống', 'm³', true, 507),
('DUONG', 'Thoát nước', 'Hố ga, hố thu', 'cái', true, 508),
-- An toàn giao thông
('DUONG', 'An toàn giao thông', 'Hộ lan mềm (tôn sóng)', 'm', true, 601),
('DUONG', 'An toàn giao thông', 'Hộ lan cứng (BT)', 'm', true, 602),
('DUONG', 'An toàn giao thông', 'Dải phân cách giữa', 'm', true, 603),
('DUONG', 'An toàn giao thông', 'Biển báo', 'cái', true, 604),
('DUONG', 'An toàn giao thông', 'Vạch sơn', 'm²', true, 605),
('DUONG', 'An toàn giao thông', 'Cọc tiêu, cọc H, cột Km', 'cái', true, 606),
-- Đường gom
('DUONG', 'Đường gom', 'Đào nền đường gom', 'm³', true, 701),
('DUONG', 'Đường gom', 'Đắp nền đường gom', 'm³', true, 702),
('DUONG', 'Đường gom', 'Móng CPĐD đường gom', 'm³', true, 703),
('DUONG', 'Đường gom', 'Mặt đường gom', 'm²', true, 704),
('DUONG', 'Đường gom', 'Rãnh thoát nước đường gom', 'm', true, 705),
-- Công tác khác
('DUONG', 'Công tác khác', 'Đảm bảo giao thông thi công', 'ca', true, 801),
('DUONG', 'Công tác khác', 'Di dời công trình hạ tầng', 'vị trí', true, 802),
('DUONG', 'Công tác khác', 'Hoàn trả đường địa phương', 'm²', true, 803),
('DUONG', 'Công tác khác', 'Công tác khác', '', true, 804);
