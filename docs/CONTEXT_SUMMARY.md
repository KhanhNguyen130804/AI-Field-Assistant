# Tóm tắt dự án — đến Ngày 2

> Bản tóm tắt tự chứa các quyết định quan trọng của Ngày 1 để bàn giao cho coding agent. Hướng dẫn chuẩn tắc vẫn nằm trong `AGENTS.md`; roadmap đầy đủ nằm trong `docs/CHALLENGE_VI_ROADMAP.md`. Cập nhật khi quyết định hoặc trạng thái triển khai đổi.

## Người dùng và vấn đề

AI Field Assistant trước hết dành cho **nhân viên bảo trì tòa nhà** ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. Ứng dụng hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Luồng màn hình đã thống nhất

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất; chưa có nghĩa tất cả màn hình đã được triển khai. Hiện **Tạo báo cáo** có nhập mô tả, chụp/chọn một ảnh và xem lại đầu vào cục bộ; **Lịch sử** vẫn là empty state. Tab dưới cùng chuyển màn hình được. AI draft, màn hình kết quả/chỉnh sửa, lưu và chi tiết chưa được dựng hay giả lập bằng dữ liệu mẫu.

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

- **Flutter/Dart**, Android-first; Web bật để xem trước giao diện. UI dùng Material 3, `NavigationBar` và `IndexedStack`.
- Image picker: `image_picker` 1.2.3; yêu cầu resize tối đa 1600×1600, JPEG quality 85 và giới hạn 10 MiB. Không thêm `permission_handler` hoặc quyền storage rộng.
- Điểm vào app shell: `lib/main.dart`; form: `lib/screens/create_report_screen.dart`; widget tests: `test/widget_test.dart`.
- Ngày 2 đã thêm nhập mô tả, camera/gallery picker, preview cục bộ, validation đầu vào và thông báo lỗi. Chưa có AI service, report model, parser, lưu trữ cục bộ, dữ liệu lịch sử hoặc màn hình kết quả/chi tiết hoạt động.
- Mô tả nằm trong state của màn hình; ảnh là `XFile` tạm của picker. Không gửi qua mạng, không lưu thành báo cáo và không đảm bảo giữ sau khi app bị đóng.
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

Đã kiểm chứng trong môi trường phát triển: `dart format lib test`, `flutter analyze`, `flutter test` (8 tests), `flutter build web --release` và `flutter build apk --debug` đều thành công. APK debug được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.

Chủ dự án xác nhận đã chạy app trên Android thật. Ảnh Ngày 2 cho thấy photo picker mở được và ảnh được chọn/preview cùng mô tả; chủ dự án báo ảnh nguồn lớn hơn 10 MiB. Ảnh không cho biết byte length trước/sau xử lý. Camera và từ chối quyền chưa được xác nhận thử thủ công. `flutter devices` trong môi trường agent chỉ nhận Windows/Chrome/Edge.

Trong Windows workspace này, Kotlin incremental cache từng lỗi khi project ở ổ `D:` và Pub Cache ở ổ `C:`. `android/gradle.properties` hiện đặt `kotlin.incremental=false`; build chuẩn `flutter build apk --debug` đã thành công. Kotlin compile có thể chậm hơn do không dùng incremental cache.

## Tài liệu liên quan

- `AGENTS.md` — hướng dẫn coding agent và các ràng buộc sản phẩm.
- `README.md` — giới thiệu, kiến trúc, schema, cách chạy và hạn chế.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và kế hoạch 7 ngày.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng.
- `docs/AI_WORKLOG.md` — công cụ AI, lỗi thực tế và kiểm chứng.
- `docs/WALKTHROUGH.md` — cách chạy và kiểm tra giao diện hiện có.
- `docs/implement_plan_day2.md` — phạm vi và tiêu chí triển khai Ngày 2.
