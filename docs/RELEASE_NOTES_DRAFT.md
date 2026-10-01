# AI Field Assistant 0.2.0 — bản nháp GitHub Release

Trạng thái: release candidate local; chưa publish. APK cài và mở trên PKG110 Android 16/API 36; AI thật trả bản nháp cho case text-only và text kèm sơ đồ tổng hợp. Link download/video còn thiếu.

## Chức năng

- Nhập mô tả và chọn/chụp ảnh sự cố.
- Gọi AI tạo draft có cấu trúc; kiểm tra JSON và đánh dấu thông tin cần xác nhận.
- Sửa/xác nhận trước lưu SQLite; History/detail và PDF từ report đã lưu.
- Android release dùng App Check reCAPTCHA, debug tiếp tục chỉ phục vụ phát triển.
- Loading/lỗi/thử lại và giữ input; startup chặn mở app nếu khởi tạo không thành công.

## Tệp đính kèm dự kiến

- `ai-field-assistant-0.2.0+2.apk`
- `SHA256SUMS.txt`
- Hướng dẫn cài và trạng thái kiểm chứng.

APK universal: `ai-field-assistant-0.2.0+2.apk`, 59.831.252 byte, SHA-256 `8E622C5580C1C18B1E397FBD000B0E48950D84CC8C397040288D5620545B8883`. Chữ ký/v2/zipalign đã xác minh; không đưa private signing hoặc token vào assets.

## Giới hạn

AI cần mạng và quota; provider còn Preview và không cam kết mọi máy PASS. Kết quả host/build khác với Android/AI thật. Case nào chưa kiểm chứng giữ BLOCKED/NOT RUN trong phiếu kèm bản release. Không có login/sync/voice/GPS.

Video Drive và link cuối: chủ dự án sẽ tự quay/review theo script rồi mới publication. Mục số giờ tiết kiệm chưa có ước lượng có căn cứ.
