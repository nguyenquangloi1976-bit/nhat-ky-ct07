-- =============================================================
-- SEED: Danh mục hạng mục công việc mẫu cho dự án cao tốc
-- Dùng cho bảng work_item_catalog
-- Chạy trong Supabase SQL Editor
-- =============================================================

-- Xóa dữ liệu cũ nếu cần (comment dòng này nếu muốn giữ)
-- DELETE FROM work_item_catalog;

-- ===================== ĐƯỜNG (DUONG) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
-- Nền đường
('DUONG', 'Nền đường', 'Đào nền đường', 'm³', true, 1),
('DUONG', 'Nền đường', 'Đắp nền đường bằng đất', 'm³', true, 2),
('DUONG', 'Nền đường', 'Đắp nền đường bằng cát', 'm³', true, 3),
('DUONG', 'Nền đường', 'Lu lèn nền đường', 'm²', true, 4),
('DUONG', 'Nền đường', 'Đắp K95', 'm³', true, 5),
('DUONG', 'Nền đường', 'Đắp K98', 'm³', true, 6),
-- Xử lý nền đất yếu
('DUONG', 'Xử lý nền đất yếu', 'Bấc thấm (PVD)', 'md', true, 10),
('DUONG', 'Xử lý nền đất yếu', 'Giếng cát', 'md', true, 11),
('DUONG', 'Xử lý nền đất yếu', 'Cọc xi măng đất', 'md', true, 12),
('DUONG', 'Xử lý nền đất yếu', 'Vải địa kỹ thuật', 'm²', true, 13),
('DUONG', 'Xử lý nền đất yếu', 'Lưới địa kỹ thuật', 'm²', true, 14),
('DUONG', 'Xử lý nền đất yếu', 'Đắp gia tải', 'm³', true, 15),
-- Kết cấu áo đường
('DUONG', 'Kết cấu áo đường', 'Cấp phối đá dăm loại II (CPĐD II)', 'm³', true, 20),
('DUONG', 'Kết cấu áo đường', 'Cấp phối đá dăm loại I (CPĐD I)', 'm³', true, 21),
('DUONG', 'Kết cấu áo đường', 'Bê tông nhựa chặt lớp dưới (C19)', 'tấn', true, 22),
('DUONG', 'Kết cấu áo đường', 'Bê tông nhựa chặt lớp trên (C12.5)', 'tấn', true, 23),
('DUONG', 'Kết cấu áo đường', 'Bê tông nhựa tạo nhám', 'tấn', true, 24),
('DUONG', 'Kết cấu áo đường', 'Tưới nhựa dính bám', 'm²', true, 25),
('DUONG', 'Kết cấu áo đường', 'Bê tông xi măng mặt đường', 'm³', true, 26),
-- Công trình phụ trợ
('DUONG', 'Công trình phụ trợ', 'Bó vỉa bê tông', 'md', true, 30),
('DUONG', 'Công trình phụ trợ', 'Rãnh thoát nước dọc', 'md', true, 31),
('DUONG', 'Công trình phụ trợ', 'Gia cố mái taluy', 'm²', true, 32),
('DUONG', 'Công trình phụ trợ', 'Dải phân cách giữa bê tông', 'md', true, 33),
('DUONG', 'Công trình phụ trợ', 'Lề đường', 'm²', true, 34);

-- ===================== CẦU (CAU) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
-- Kết cấu phần dưới
('CAU', 'Kết cấu phần dưới', 'Cọc khoan nhồi', 'md', true, 1),
('CAU', 'Kết cấu phần dưới', 'Cọc ống thép', 'md', true, 2),
('CAU', 'Kết cấu phần dưới', 'Cọc BTCT đúc sẵn', 'md', true, 3),
('CAU', 'Kết cấu phần dưới', 'Bê tông bệ cọc', 'm³', true, 4),
('CAU', 'Kết cấu phần dưới', 'Bê tông bệ trụ', 'm³', true, 5),
('CAU', 'Kết cấu phần dưới', 'Bê tông thân trụ', 'm³', true, 6),
('CAU', 'Kết cấu phần dưới', 'Bê tông xà mũ trụ', 'm³', true, 7),
('CAU', 'Kết cấu phần dưới', 'Bê tông mố', 'm³', true, 8),
('CAU', 'Kết cấu phần dưới', 'Bê tông tường cánh', 'm³', true, 9),
('CAU', 'Kết cấu phần dưới', 'Cốt thép trụ', 'tấn', true, 10),
('CAU', 'Kết cấu phần dưới', 'Cốt thép mố', 'tấn', true, 11),
-- Kết cấu phần trên
('CAU', 'Kết cấu phần trên', 'Dầm Super-T', 'dầm', true, 20),
('CAU', 'Kết cấu phần trên', 'Dầm I BTCT DƯL', 'dầm', true, 21),
('CAU', 'Kết cấu phần trên', 'Dầm bản BTCT', 'dầm', true, 22),
('CAU', 'Kết cấu phần trên', 'Dầm thép liên hợp', 'tấn', true, 23),
('CAU', 'Kết cấu phần trên', 'Lao lắp dầm', 'dầm', true, 24),
('CAU', 'Kết cấu phần trên', 'Bản mặt cầu BTCT', 'm³', true, 25),
('CAU', 'Kết cấu phần trên', 'Cốt thép bản mặt cầu', 'tấn', true, 26),
('CAU', 'Kết cấu phần trên', 'Dầm ngang', 'm³', true, 27),
-- Hoàn thiện cầu
('CAU', 'Hoàn thiện', 'Lớp phòng nước mặt cầu', 'm²', true, 30),
('CAU', 'Hoàn thiện', 'Lớp phủ BTN mặt cầu', 'tấn', true, 31),
('CAU', 'Hoàn thiện', 'Lan can cầu', 'md', true, 32),
('CAU', 'Hoàn thiện', 'Khe co giãn', 'bộ', true, 33),
('CAU', 'Hoàn thiện', 'Gối cầu', 'bộ', true, 34),
('CAU', 'Hoàn thiện', 'Ống thoát nước cầu', 'bộ', true, 35),
('CAU', 'Hoàn thiện', 'Bản quá độ', 'm³', true, 36),
('CAU', 'Hoàn thiện', 'Đá kê gối', 'bộ', true, 37);

-- ===================== HẦM (HAM) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('HAM', 'Đào hầm', 'Đào hầm bằng khoan nổ (NATM)', 'm³', true, 1),
('HAM', 'Đào hầm', 'Đào hầm bằng TBM', 'md', true, 2),
('HAM', 'Đào hầm', 'Đào hở', 'm³', true, 3),
('HAM', 'Gia cố tạm', 'Neo đá', 'cái', true, 5),
('HAM', 'Gia cố tạm', 'Bê tông phun (shotcrete)', 'm³', true, 6),
('HAM', 'Gia cố tạm', 'Lưới thép gia cố', 'm²', true, 7),
('HAM', 'Gia cố tạm', 'Vì thép hình', 'tấn', true, 8),
('HAM', 'Kết cấu vỏ hầm', 'Bê tông vỏ hầm (vỏ trong)', 'm³', true, 10),
('HAM', 'Kết cấu vỏ hầm', 'Cốt thép vỏ hầm', 'tấn', true, 11),
('HAM', 'Kết cấu vỏ hầm', 'Bê tông lót hầm', 'm³', true, 12),
('HAM', 'Kết cấu vỏ hầm', 'Chống thấm vỏ hầm', 'm²', true, 13),
('HAM', 'Kết cấu vỏ hầm', 'Bê tông mặt đường trong hầm', 'm³', true, 14),
('HAM', 'Hệ thống cơ điện', 'Hệ thống thông gió', 'bộ', true, 20),
('HAM', 'Hệ thống cơ điện', 'Hệ thống chiếu sáng hầm', 'bộ', true, 21),
('HAM', 'Hệ thống cơ điện', 'Hệ thống PCCC hầm', 'bộ', true, 22),
('HAM', 'Hệ thống cơ điện', 'Hệ thống thoát nước hầm', 'bộ', true, 23),
('HAM', 'Hệ thống cơ điện', 'Hệ thống giám sát hầm', 'bộ', true, 24);

-- ===================== CỐNG (CONG) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('CONG', 'Thi công cống', 'Đào móng cống', 'm³', true, 1),
('CONG', 'Thi công cống', 'Bê tông móng cống', 'm³', true, 2),
('CONG', 'Thi công cống', 'Lắp đặt ống cống tròn BTCT', 'md', true, 3),
('CONG', 'Thi công cống', 'Bê tông cống hộp', 'm³', true, 4),
('CONG', 'Thi công cống', 'Cốt thép cống', 'tấn', true, 5),
('CONG', 'Thi công cống', 'Lắp đặt cống hộp', 'đốt', true, 6),
('CONG', 'Hoàn thiện cống', 'Tường đầu cống', 'm³', true, 10),
('CONG', 'Hoàn thiện cống', 'Tường cánh cống', 'm³', true, 11),
('CONG', 'Hoàn thiện cống', 'Gia cố thượng lưu', 'm²', true, 12),
('CONG', 'Hoàn thiện cống', 'Gia cố hạ lưu', 'm²', true, 13),
('CONG', 'Hoàn thiện cống', 'Sân cống', 'm²', true, 14),
('CONG', 'Hoàn thiện cống', 'Đắp đất trên cống', 'm³', true, 15),
('CONG', 'Hoàn thiện cống', 'Chống thấm mối nối cống', 'md', true, 16);

-- ===================== TƯỜNG CHẮN (TUONG_CHAN) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('TUONG_CHAN', 'Kết cấu móng', 'Cọc khoan nhồi tường chắn', 'md', true, 1),
('TUONG_CHAN', 'Kết cấu móng', 'Bê tông móng tường chắn', 'm³', true, 2),
('TUONG_CHAN', 'Kết cấu móng', 'Cốt thép móng tường chắn', 'tấn', true, 3),
('TUONG_CHAN', 'Kết cấu thân', 'Bê tông thân tường chắn', 'm³', true, 5),
('TUONG_CHAN', 'Kết cấu thân', 'Cốt thép thân tường chắn', 'tấn', true, 6),
('TUONG_CHAN', 'Kết cấu thân', 'Tường chắn đất có cốt (MSE)', 'm²', true, 7),
('TUONG_CHAN', 'Kết cấu thân', 'Cốt gia cường (strip/grid)', 'm²', true, 8),
('TUONG_CHAN', 'Kết cấu thân', 'Tấm mặt tường chắn', 'm²', true, 9),
('TUONG_CHAN', 'Hoàn thiện', 'Đất đắp sau tường', 'm³', true, 10),
('TUONG_CHAN', 'Hoàn thiện', 'Vải địa kỹ thuật sau tường', 'm²', true, 11),
('TUONG_CHAN', 'Hoàn thiện', 'Thoát nước sau tường', 'md', true, 12),
('TUONG_CHAN', 'Hoàn thiện', 'Chống thấm tường chắn', 'm²', true, 13);

-- ===================== HẦM CHUI DÂN SINH (HAM_CHUI) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('HAM_CHUI', 'Kết cấu', 'Đào hở hầm chui', 'm³', true, 1),
('HAM_CHUI', 'Kết cấu', 'Bê tông bản đáy', 'm³', true, 2),
('HAM_CHUI', 'Kết cấu', 'Bê tông tường bên', 'm³', true, 3),
('HAM_CHUI', 'Kết cấu', 'Bê tông bản nắp', 'm³', true, 4),
('HAM_CHUI', 'Kết cấu', 'Cốt thép hầm chui', 'tấn', true, 5),
('HAM_CHUI', 'Kết cấu', 'Lắp đặt cống hộp hầm chui', 'đốt', true, 6),
('HAM_CHUI', 'Hoàn thiện', 'Chống thấm hầm chui', 'm²', true, 10),
('HAM_CHUI', 'Hoàn thiện', 'Hệ thống thoát nước hầm chui', 'bộ', true, 11),
('HAM_CHUI', 'Hoàn thiện', 'Đắp đất trên hầm chui', 'm³', true, 12),
('HAM_CHUI', 'Hoàn thiện', 'Mặt đường trong hầm chui', 'm²', true, 13),
('HAM_CHUI', 'Hoàn thiện', 'Tường đầu hầm chui', 'm³', true, 14);

-- ===================== NÚT GIAO (NUT_GIAO) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('NUT_GIAO', 'Nền đường', 'Đào nền nút giao', 'm³', true, 1),
('NUT_GIAO', 'Nền đường', 'Đắp nền nút giao', 'm³', true, 2),
('NUT_GIAO', 'Kết cấu mặt đường', 'CPĐD loại II nút giao', 'm³', true, 5),
('NUT_GIAO', 'Kết cấu mặt đường', 'CPĐD loại I nút giao', 'm³', true, 6),
('NUT_GIAO', 'Kết cấu mặt đường', 'Bê tông nhựa nút giao', 'tấn', true, 7),
('NUT_GIAO', 'Phụ trợ', 'Bó vỉa đảo giao thông', 'md', true, 10),
('NUT_GIAO', 'Phụ trợ', 'Hệ thống thoát nước nút giao', 'bộ', true, 11),
('NUT_GIAO', 'Phụ trợ', 'Đèn tín hiệu giao thông', 'bộ', true, 12),
('NUT_GIAO', 'Phụ trợ', 'Biển báo nút giao', 'bộ', true, 13),
('NUT_GIAO', 'Phụ trợ', 'Vạch sơn kẻ đường nút giao', 'm²', true, 14);

-- ===================== TRẠM THU PHÍ (TRAM_THU_PHI) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('TRAM_THU_PHI', 'Kết cấu', 'Bê tông móng nhà trạm', 'm³', true, 1),
('TRAM_THU_PHI', 'Kết cấu', 'Kết cấu thép mái trạm', 'tấn', true, 2),
('TRAM_THU_PHI', 'Kết cấu', 'Mặt đường khu vực trạm', 'm²', true, 3),
('TRAM_THU_PHI', 'Kết cấu', 'Cabin thu phí', 'bộ', true, 4),
('TRAM_THU_PHI', 'Hệ thống', 'Hệ thống ETC', 'bộ', true, 10),
('TRAM_THU_PHI', 'Hệ thống', 'Hệ thống chiếu sáng trạm', 'bộ', true, 11),
('TRAM_THU_PHI', 'Hệ thống', 'Hệ thống PCCC trạm', 'bộ', true, 12),
('TRAM_THU_PHI', 'Hệ thống', 'Hệ thống camera/giám sát', 'bộ', true, 13),
('TRAM_THU_PHI', 'Hệ thống', 'Hệ thống cấp thoát nước', 'bộ', true, 14);

-- ===================== HỆ THỐNG THOÁT NƯỚC (HE_THONG_THOAT_NUOC) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('HE_THONG_THOAT_NUOC', 'Rãnh', 'Rãnh biên bê tông', 'md', true, 1),
('HE_THONG_THOAT_NUOC', 'Rãnh', 'Rãnh đỉnh bê tông', 'md', true, 2),
('HE_THONG_THOAT_NUOC', 'Rãnh', 'Rãnh giữa dải phân cách', 'md', true, 3),
('HE_THONG_THOAT_NUOC', 'Ống/cống', 'Ống thoát nước D300', 'md', true, 5),
('HE_THONG_THOAT_NUOC', 'Ống/cống', 'Ống thoát nước D400', 'md', true, 6),
('HE_THONG_THOAT_NUOC', 'Ống/cống', 'Ống thoát nước D600', 'md', true, 7),
('HE_THONG_THOAT_NUOC', 'Ống/cống', 'Cống ngang qua đường', 'md', true, 8),
('HE_THONG_THOAT_NUOC', 'Công trình', 'Hố ga thu nước', 'hố', true, 10),
('HE_THONG_THOAT_NUOC', 'Công trình', 'Hố ga kiểm tra', 'hố', true, 11),
('HE_THONG_THOAT_NUOC', 'Công trình', 'Bể lắng', 'bể', true, 12),
('HE_THONG_THOAT_NUOC', 'Công trình', 'Gia cố cửa xả', 'm²', true, 13);

-- ===================== ĐIỆN CHIẾU SÁNG (DIEN_CHIEU_SANG) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('DIEN_CHIEU_SANG', 'Cột đèn', 'Cột đèn chiếu sáng cao áp', 'cột', true, 1),
('DIEN_CHIEU_SANG', 'Cột đèn', 'Cột đèn chiếu sáng thấp áp', 'cột', true, 2),
('DIEN_CHIEU_SANG', 'Cột đèn', 'Đèn LED chiếu sáng', 'bộ', true, 3),
('DIEN_CHIEU_SANG', 'Cột đèn', 'Cần đèn', 'cái', true, 4),
('DIEN_CHIEU_SANG', 'Hệ thống dây/cáp', 'Cáp điện ngầm', 'md', true, 10),
('DIEN_CHIEU_SANG', 'Hệ thống dây/cáp', 'Ống luồn cáp', 'md', true, 11),
('DIEN_CHIEU_SANG', 'Hệ thống dây/cáp', 'Hố cáp/hố ga điện', 'hố', true, 12),
('DIEN_CHIEU_SANG', 'Hệ thống dây/cáp', 'Hệ thống nối đất', 'bộ', true, 13),
('DIEN_CHIEU_SANG', 'Tủ điều khiển', 'Tủ điều khiển chiếu sáng', 'tủ', true, 15),
('DIEN_CHIEU_SANG', 'Tủ điều khiển', 'Trạm biến áp chiếu sáng', 'trạm', true, 16);

-- ===================== AN TOÀN GIAO THÔNG (AN_TOAN_GT) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('AN_TOAN_GT', 'Hộ lan', 'Hộ lan tôn sóng (W-beam)', 'md', true, 1),
('AN_TOAN_GT', 'Hộ lan', 'Hộ lan bê tông (New Jersey)', 'md', true, 2),
('AN_TOAN_GT', 'Hộ lan', 'Hộ lan cáp (cable barrier)', 'md', true, 3),
('AN_TOAN_GT', 'Hộ lan', 'Đầu hộ lan giảm chấn', 'bộ', true, 4),
('AN_TOAN_GT', 'Biển báo', 'Biển báo hiệu giao thông', 'biển', true, 10),
('AN_TOAN_GT', 'Biển báo', 'Biển báo VMS (biển điện tử)', 'biển', true, 11),
('AN_TOAN_GT', 'Biển báo', 'Cột km/cột H', 'cột', true, 12),
('AN_TOAN_GT', 'Biển báo', 'Cọc tiêu', 'cọc', true, 13),
('AN_TOAN_GT', 'Biển báo', 'Cọc phản quang', 'cọc', true, 14),
('AN_TOAN_GT', 'Sơn/vạch', 'Vạch sơn kẻ đường', 'm²', true, 20),
('AN_TOAN_GT', 'Sơn/vạch', 'Đinh phản quang', 'cái', true, 21),
('AN_TOAN_GT', 'Sơn/vạch', 'Gồ giảm tốc', 'bộ', true, 22),
('AN_TOAN_GT', 'Khác', 'Hàng rào bảo vệ', 'md', true, 25),
('AN_TOAN_GT', 'Khác', 'Hàng rào chống chói', 'md', true, 26),
('AN_TOAN_GT', 'Khác', 'Đèn cảnh báo năng lượng mặt trời', 'bộ', true, 27);

-- ===================== CÂY XANH (CAY_XANH) =====================
INSERT INTO work_item_catalog (type_code, group_name, name, unit, is_active, sort_order) VALUES
('CAY_XANH', 'Trồng cây', 'Trồng cây bóng mát', 'cây', true, 1),
('CAY_XANH', 'Trồng cây', 'Trồng cây bụi dải phân cách', 'cây', true, 2),
('CAY_XANH', 'Trồng cây', 'Trồng hoa dải phân cách', 'm²', true, 3),
('CAY_XANH', 'Trồng cỏ', 'Trồng cỏ mái taluy', 'm²', true, 5),
('CAY_XANH', 'Trồng cỏ', 'Trồng cỏ thảm dải phân cách', 'm²', true, 6),
('CAY_XANH', 'Trồng cỏ', 'Trồng vetiver chống xói', 'm²', true, 7),
('CAY_XANH', 'Hệ thống tưới', 'Hệ thống tưới tự động', 'bộ', true, 10),
('CAY_XANH', 'Hệ thống tưới', 'Ống dẫn nước tưới', 'md', true, 11);

-- ===================== DONE =====================
-- Tổng cộng: ~150 hạng mục mẫu cho 12 loại công trình
