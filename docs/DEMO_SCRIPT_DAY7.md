# Kịch bản video nộp — tối đa 4 phút 40 giây

Kịch bản dành cho APK ứng viên 0.2.0+2. Hai request AI thật (text-only và text kèm sơ đồ tổng hợp) vừa trả draft trên PKG110; video vẫn chưa được quay. Dùng nội dung tổng hợp, không quay Console, raw log, dữ liệu/ảnh cá nhân hoặc thông báo hệ thống. Chỉ quay nhánh thành công nếu request AI thật trả draft trong lượt quay.

| Mốc | Thao tác thật cần quay | Lời dẫn đề xuất |
|---|---|---|
| 0:00–0:25 | Mở app, màn Tạo báo cáo | Nhân viên bảo trì cần ghi nhận sự cố nhanh và thống nhất. AI Field Assistant giúp lập bản nháp, còn người dùng kiểm tra nội dung. |
| 0:25–0:55 | Nhập: “Máy lạnh tại lễ tân tầng 1 không hoạt động, phòng đang nóng. Chưa kiểm tra nguyên nhân.”; có thể chọn sơ đồ tổng hợp đã có nhãn nếu muốn demo ảnh | Tôi nhập những gì quan sát được. Sơ đồ demo là tổng hợp, không phải ảnh hiện trường. Ảnh là tùy chọn; ứng dụng không tự thu thập vị trí. |
| 0:55–1:35 | Bấm Phân tích bằng AI một lần; quay loading và kết quả thật | Yêu cầu đi qua Firebase AI Logic. App Check bản release xác minh tự động; người nhận không đăng ký debug token. Đây là bản nháp đề xuất. |
| 1:35–2:25 | Review trường thiếu, sửa bằng dữ kiện, xác nhận và lưu; khi demo ảnh, đầu vào cho biết sơ đồ là tổng hợp | Tôi kiểm tra từng trường. Thông tin không có căn cứ được để trống và cần xác nhận. Hành động đề xuất không phải việc đã làm. |
| 2:25–2:55 | History, detail đúng report vừa lưu | Báo cáo đã xác nhận được lưu cục bộ và xem lại. Khả năng sống qua restart được kiểm tra riêng, không suy từ màn hình này. |
| 2:55–3:35 | Lưu PDF bằng picker, mở tệp hoặc chia sẻ qua share sheet nếu case đã đạt | PDF tạo từ report đã lưu. Việc lưu và chia sẻ dùng cơ chế Android; tôi chỉ mô tả ứng dụng nhận chia sẻ đã được quan sát. |
| 3:35–4:05 | Quay lại form, gửi đầu vào rỗng, thấy validation | Ứng dụng chặn dữ liệu rỗng và giữ nội dung khi dịch vụ lỗi. |
| 4:05–4:40 | Màn kiến trúc/giới hạn hoặc lời kết trên app | Flutter, Firebase AI Logic, JSON parser, SQLite và PDF. AI cần mạng/quota; người dùng vẫn chịu trách nhiệm kiểm chứng. Những case chưa thử được ghi rõ trong hồ sơ. |

## Nhánh dự phòng trung thực

Nếu AI bị App Check/quota/network chặn: dừng retry, quay lỗi thật và input còn nguyên, nói rõ AI trên artifact này chưa đạt. Không mở report dựng sẵn rồi mô tả là đầu ra của request vừa chạy. Không coi video nhánh lỗi là nghiệm thu mục tiêu AI trên máy người nhận.

## Checklist quay và review

- Đúng artifact/hash ở SUBMISSION_STATUS và phiếu Day 7; không quay bản debug rồi gắn nhãn release.
- Bắt đầu ở màn app với dữ liệu tổng hợp; PKG110 đã được gỡ app debug theo cho phép của chủ dự án, rồi cài release 0.2.0+2.
- Không mở History chứa report cá nhân khác; chỉ report synthetic của lượt test được chọn để demo.
- Thời lượng <5:00, chữ đọc được, không có notification/token/screen Console.
- Video phải tồn tại và được xem lại trước upload Drive; link được kiểm tra ngoài tài khoản chủ sở hữu.
