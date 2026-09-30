# Kịch bản demo — AI Field Assistant (dưới 5 phút)

> **Thời lượng mục tiêu:** 4 phút 40 giây. Kịch bản chờ kiểm tra trên đúng APK Android; đây là kịch bản, không phải video hay bằng chứng thao tác đã quay. Chỉ dùng mô tả và ảnh tổng hợp. Không để lộ debug token, thông báo có credential, thông tin cá nhân hoặc raw log.

| Mốc | Hình ảnh/thao tác | Lời dẫn |
|---|---|---|
| 0:00–0:25 | Mở đầu trên màn Tạo báo cáo. | “Nhân viên bảo trì cần ghi nhận sự cố nhanh nhưng vẫn phải kiểm tra thông tin trước khi lưu. AI Field Assistant biến mô tả hiện trường thành bản nháp có cấu trúc.” |
| 0:25–0:55 | Nhập mô tả tổng hợp: “Máy lạnh khu vực lễ tân không hoạt động; phòng đang nóng.” Chọn ảnh tổng hợp JPEG/PNG/WebP nếu fixture có sẵn; không dùng thư viện ảnh cá nhân. | “Người dùng cung cấp dữ kiện và có thể đính kèm ảnh. Ảnh gửi AI bị giới hạn định dạng và kích thước.” |
| 0:55–1:35 | Bấm **Phân tích bằng AI** đúng một lần. Chỉ tiếp tục nhánh thành công nếu dịch vụ thực sự trả draft. | “Ứng dụng gửi yêu cầu qua Firebase AI Logic. Nếu App Check hoặc mạng chặn request, nội dung đầu vào được giữ và lỗi được trình bày; không thay bằng kết quả giả.” |
| 1:35–2:25 | Nếu có draft thật, sửa một trường dựa trên dữ kiện; review từng trường, xác nhận trường thiếu/trống và lưu qua hộp thoại cuối. | “AI chỉ đề xuất. Người dùng phải xem lại từng trường; `issue` bắt buộc có nội dung và hành động luôn được gắn nhãn đề xuất.” |
| 2:25–2:55 | Mở History, chọn report vừa lưu, xem chi tiết. | “Báo cáo đã xác nhận được lưu cục bộ trên Android và mở lại từ lịch sử.” |
| 2:55–3:35 | Thao tác **Lưu PDF** hoặc **Chia sẻ PDF** nếu đã được xác minh trên Android; không khẳng định Zalo nếu chưa quan sát. | “PDF được tạo cục bộ từ report đã lưu. Lưu dùng document picker; chia sẻ dùng Android share sheet.” |
| 3:35–4:05 | Quay lại form, thử gửi đầu vào rỗng; cho thấy validation. Nếu quay nhánh App Check, cho thấy lỗi thật và input còn nguyên. | “Ứng dụng chặn đầu vào trống trước khi gọi AI. Lỗi dịch vụ giữ nội dung để người dùng thử lại.” |
| 4:05–4:40 | Màn hình kiến trúc/README và giới hạn. | “Flutter kết nối Firebase AI Logic, SQLite cục bộ và PDF export. Lưu report text-only đã được kiểm chứng sau restart; ảnh sau restart, offline và provider App Check production còn chờ xác minh.” |

## Quy tắc quay và cắt

- Quay một lượt trên APK gắn với commit đã ghi trong phiếu Day 6; ghi phiên bản và SHA-256 APK ngoài khung hình.
- Bắt đầu từ form sạch nếu dữ liệu synthetic có thể được tạo an toàn; không gỡ app hoặc xóa app data để dọn thiết bị.
- Chỉ giữ nhánh draft thành công khi AI thật trả kết quả trong lượt quay. Nếu App Check chặn, có thể quay nhánh lỗi/giữ input nhưng không mô tả đó là demo AI đầu-cuối.
- Không thêm phản hồi AI dựng sẵn, dữ liệu người dùng, token, raw log hoặc màn hình không thuộc ứng dụng.
- Xem lại video hoàn chỉnh: thời lượng dưới 5 phút, chữ đọc được, mọi thao tác được thể hiện đúng và không có thông tin nhạy cảm.

## Trạng thái

- Script: đã chuẩn bị.
- Quay/xem lại video: chưa thực hiện. Follow-up đã xác nhận OnePlus PKG110 Android 16/API 36 và app debug v0.1.0, nhưng chưa đọc UI hay thử công cụ ghi màn hình; kết quả AI/App Check phải được xác nhận tại thời điểm quay.
