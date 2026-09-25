# Tóm tắt dự án — Ngày 1

> Bản tóm tắt tự chứa các quyết định quan trọng của Ngày 1 để bàn giao cho coding agent. Hướng dẫn chuẩn tắc vẫn nằm trong `AGENTS.md`; roadmap đầy đủ nằm trong `docs/CHALLENGE_VI_ROADMAP.md`. Cập nhật khi quyết định hoặc trạng thái triển khai đổi.

## Người dùng và vấn đề

AI Field Assistant trước hết dành cho **nhân viên bảo trì tòa nhà** ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. Ứng dụng hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Luồng màn hình đã thống nhất

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng thiết kế Ngày 1, không có nghĩa tất cả màn hình đã được triển khai. Mã nguồn hiện chỉ có hai khu vực: **Tạo báo cáo** (giới thiệu quy trình dự kiến) và **Lịch sử** (empty state). Tab dưới cùng chuyển màn hình được; nội dung hai trang chưa có thao tác tạo, sửa hay lưu báo cáo. Theo phạm vi đã chọn, chưa dựng màn hình kết quả/chỉnh sửa/chi tiết bằng dữ liệu giả.

## Schema báo cáo đã thống nhất

Các trường nội dung lõi: `category`, `location`, `priority`, `issue`, `suggested_action`, `summary`. `needs_confirmation` là danh sách tên trường cần người dùng xem lại/bổ sung/xác nhận.

| Trường | Bản nháp | Trước khi lưu |
|---|---|---|
| `category` | Chuỗi rỗng nếu thiếu căn cứ phân loại. | Có thể giữ trống sau khi người dùng xác nhận không xác định được. |
| `location` | Chuỗi rỗng nếu đầu vào không nêu địa điểm; không tự suy đoán. | Có thể giữ trống sau khi người dùng xác nhận không có thông tin. |
| `priority` | Chỉ `low`, `medium`, `high` hoặc `null` khi chưa đủ căn cứ; không tự mặc định `medium`. | Có thể giữ `null` sau khi người dùng xác nhận chưa xác định được. |
| `issue` | Có thể rỗng nếu chưa rõ và khi đó cần xác nhận. | Bắt buộc có nội dung trước khi lưu. |
| `suggested_action` | Chuỗi rỗng nếu không có đề xuất đủ an toàn; nếu có thì chỉ là đề xuất, không phải việc đã thực hiện. | Có thể giữ trống sau khi người dùng xem lại. |
| `summary` | Có thể rỗng nếu chưa đủ dữ kiện; nếu có thì chỉ tóm tắt dữ kiện đã xác nhận. | Có thể giữ trống sau khi người dùng xem lại. |
| `needs_confirmation` | Danh sách tên trường đang cần người dùng xem lại. | Người dùng phải xử lý từng mục bằng cách bổ sung dữ liệu hoặc xác nhận dữ liệu đó không có; sau xác nhận trường được phép tiếp tục trống. |

`created_at`, đường dẫn ảnh và trạng thái báo cáo là metadata, không thuộc các trường nội dung lõi. Đây là quyết định schema ở tài liệu; chưa có model/parser tương ứng trong Dart.

## Công nghệ, hiện trạng và giới hạn

- **Flutter/Dart**, Android-first; Web bật để xem trước giao diện. UI dùng Material 3, `NavigationBar` và `IndexedStack`; chưa thêm dependency nghiệp vụ.
- Điểm vào UI: `lib/main.dart`. Widget test: `test/widget_test.dart`.
- Chưa có nhập mô tả/ảnh, camera, AI service, report model, parser, lưu trữ cục bộ, dữ liệu lịch sử hoặc màn hình kết quả/chi tiết hoạt động.
- Không có API key trong source. Nếu tích hợp AI sau này, dùng backend/proxy hoặc cơ chế phù hợp cho ứng dụng di động.

## Chạy và kiểm chứng

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
flutter analyze
flutter test
flutter build apk --debug
```

Đã kiểm chứng trong môi trường phát triển: `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build web --release` và `flutter build apk --debug` đều thành công. APK debug được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.

Chủ dự án xác nhận đã mở APK bằng Android Studio và chạy trên điện thoại Android thật; hai ảnh cung cấp thể hiện hai tab. Trong các lần rà soát của coding agent không có Android device kết nối để kiểm chứng độc lập. Ở trạng thái kiểm tra hiện tại, `flutter devices` chỉ nhận Windows/Chrome/Edge.

## Tài liệu liên quan

- `AGENTS.md` — hướng dẫn coding agent và các ràng buộc sản phẩm.
- `README.md` — giới thiệu, kiến trúc, schema, cách chạy và hạn chế.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và kế hoạch 7 ngày.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng.
- `docs/AI_WORKLOG.md` — công cụ AI, lỗi thực tế và kiểm chứng.
- `docs/WALKTHROUGH.md` — cách chạy và kiểm tra giao diện hiện có.
