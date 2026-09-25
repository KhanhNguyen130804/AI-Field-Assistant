# AI Field Assistant

Ứng dụng Android-first dành trước hết cho nhân viên bảo trì tòa nhà ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. AI Field Assistant hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Trạng thái hiện tại

Đã có hai khu vực điều hướng bằng tab tiếng Việt:

- **Tạo báo cáo:** nhập mô tả, chụp/chọn một ảnh, xem preview và xem lại đầu vào cục bộ.
- **Lịch sử:** trạng thái rỗng cho báo cáo đã lưu trong tương lai.

Mô tả nằm trong state của màn hình; ảnh dùng `XFile` tạm do picker cung cấp. Đầu vào không gửi qua mạng và chưa được lưu thành báo cáo. Chưa tích hợp AI, tạo/sửa báo cáo, lưu trữ, lịch sử có dữ liệu, voice-to-text, GPS, đăng nhập hoặc cloud; app không đảm bảo giữ đầu vào sau khi đóng.

## Kiến trúc hiện tại

```text
Flutter Material 3 app
└── lib/main.dart
    ├── AiFieldAssistantApp — theme và tên ứng dụng
    └── _HomeScreen — NavigationBar + IndexedStack
        ├── CreateReportScreen — mô tả, image picker và preview cục bộ
        └── _HistoryScreen — empty state
```

App shell ở `lib/main.dart`; form nằm trong `lib/screens/create_report_screen.dart`. `test/widget_test.dart` kiểm tra điều hướng, validation, preview, lỗi picker và bố cục ở viewport 320×568. Chưa tạo AI service, report model hay repository.

## Luồng màn hình đã chốt

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất cho thiết kế. Hiện **Tạo báo cáo** cho nhập và xem lại đầu vào cục bộ; **Lịch sử** vẫn rỗng. AI draft, màn hình kết quả/chỉnh sửa, lưu và chi tiết chưa được dựng hay giả lập bằng dữ liệu mẫu.

## Quy trình AI dự kiến — chưa tích hợp

Khi triển khai, luồng mục tiêu là:

```text
Mô tả/ảnh
  → AI service qua backend/proxy phù hợp cho ứng dụng di động
  → parse và kiểm tra JSON/schema
  → người dùng xem, sửa và xác nhận bản nháp
  → lưu cục bộ
  → hiển thị trong Lịch sử
```

Schema thiết kế cho báo cáo gồm `category`, `location`, `priority`, `issue`, `suggested_action`, `summary` và `needs_confirmation`. Quy tắc giá trị trống:

| Trường | Quy tắc trong bản nháp | Điều kiện trước khi lưu |
|---|---|---|
| `category` | Chuỗi rỗng nếu không đủ căn cứ phân loại. | Có thể để trống sau khi người dùng xác nhận không xác định được. |
| `location` | Chuỗi rỗng nếu mô tả/ảnh không cung cấp địa điểm; không tự suy đoán. | Có thể để trống sau khi người dùng xác nhận không có thông tin. |
| `priority` | `low`, `medium`, `high` hoặc `null` nếu chưa đủ căn cứ; không tự mặc định `medium`. | Có thể để `null` sau khi người dùng xác nhận chưa xác định được. |
| `issue` | Có thể rỗng trong bản nháp và khi đó cần xác nhận. | Bắt buộc có nội dung trước khi lưu. |
| `suggested_action` | Chuỗi rỗng nếu không thể đề xuất an toàn. Đây luôn là đề xuất, không phải việc đã làm. | Có thể để trống sau khi người dùng xem lại. |
| `summary` | Có thể rỗng nếu chưa đủ dữ kiện; nếu có nội dung, chỉ tóm tắt dữ kiện đã xác nhận. | Có thể để trống sau khi người dùng xem lại. |
| `needs_confirmation` | Danh sách tên các trường cần bổ sung hoặc xác nhận. | Người dùng phải xem từng mục; có thể xác nhận trường không có dữ liệu và giữ trống. |

`created_at`, đường dẫn ảnh và trạng thái báo cáo là metadata riêng, không phải trường nội dung cốt lõi. Đây mới là schema thiết kế; chưa có model/parser trong Dart. AI chỉ tạo bản nháp; `suggested_action` không phải hành động đã thực hiện. Hiện chưa chọn nhà cung cấp AI, chưa có prompt chạy trong ứng dụng, backend/proxy, parser hay cơ sở dữ liệu; không có API key trong source code.

## Quyết định kỹ thuật

- **Flutter/Dart:** ưu tiên một codebase Android-first phù hợp với prototype di động.
- **Web preview:** bật Web để xem giao diện trong môi trường chưa có Android device/emulator kết nối.
- **Material 3, `NavigationBar`, `IndexedStack`:** tạo điều hướng đơn giản, trạng thái chọn tab rõ ràng và chuyển màn hình không cần thư viện ngoài.
- **`image_picker` 1.2.3:** dùng system picker cho camera/thư viện; preview đọc bytes trong phiên hiện tại. Không thêm `permission_handler` hoặc quyền Android rộng trong bước này.
- Ảnh được yêu cầu resize tối đa 1600×1600, JPEG quality 85; kiểm tra file nhận được không quá 10 MiB. Đây là ngưỡng hiện tại của prototype.
- **Bảo vệ thông tin xác thực:** nếu tích hợp AI, không nhúng secret vào APK; dùng backend/proxy hoặc cơ chế dành cho client có giới hạn phù hợp.

## Chạy ứng dụng

Cần cài Flutter và Android SDK (để chạy Android). Lấy device ID bằng `flutter devices`.

```bash
flutter pub get
flutter run -d <device-id>
```

Xem trước trên Chrome bằng `flutter run -d chrome`. Nếu Flutter yêu cầu chấp nhận Android SDK licenses, chạy `flutter doctor --android-licenses`. Tạo APK debug bằng:

```bash
flutter build apk --debug
```

`android/gradle.properties` tắt Kotlin incremental để tránh lỗi cache khi project Windows và Pub Cache nằm ở hai ổ đĩa khác nhau. Điều này làm một số lần build Kotlin biên dịch lại lâu hơn, nhưng không cần thêm tham số cho Android Studio hoặc `flutter run`. APK được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.

## Kiểm tra

```bash
dart format lib test
flutter analyze
flutter test
flutter build web --release
```

Sau thay đổi Ngày 2, `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build web --release` và `flutter build apk --debug` đã thành công. Chủ dự án cung cấp ảnh chụp xác nhận đã mở photo picker và chọn ảnh trên điện thoại Android thật; ảnh đầu vào được báo là trên 10 MiB nhưng đã hiện preview sau xử lý. Ảnh không hiển thị số byte trước/sau xử lý. Coding agent không có Android device kết nối để kiểm tra lại.

## Hạn chế đã biết và hướng tiếp theo

- Nhập mô tả/chụp/chọn ảnh và xem lại đầu vào đã có; chưa có AI thật, chỉnh sửa/xác nhận báo cáo hay lưu trữ.
- Tab Lịch sử luôn rỗng; chưa có model báo cáo hoặc cơ sở dữ liệu cục bộ.
- Gallery picker và preview đã được chủ dự án thử trên điện thoại thật; camera, từ chối quyền và hủy picker chưa có bằng chứng thử thủ công.
- Ảnh rỗng/quá lớn/không nhận diện được signature bị từ chối trước khi thay ảnh hiện có; lỗi decode còn lại có fallback hiển thị nhưng chưa được kiểm chứng trên thiết bị.
- Chưa có kiểm thử lỗi mạng/API, timeout hoặc JSON không hợp lệ vì chưa có AI/network flow.
- Đầu vào không được lưu sau khi app đóng; Web build thành công nhưng tương tác camera/picker trên trình duyệt chưa được kiểm chứng.

Ưu tiên tiếp theo là hoàn thiện nhập mô tả/ảnh và xác thực đầu vào, tích hợp AI an toàn với schema được kiểm tra, cho người dùng sửa/xác nhận, rồi lưu và đọc lại báo cáo cục bộ. Chỉ cân nhắc voice/GPS sau khi luồng cốt lõi chạy ổn.

## Tài liệu dự án

- `AGENTS.md` — hướng dẫn dành cho coding agent.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và roadmap sản phẩm.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng Ngày 1.
- `docs/AI_WORKLOG.md` — nhật ký sử dụng và kiểm chứng AI.
- `docs/CONTEXT_SUMMARY.md` — tóm tắt trạng thái để bàn giao coding agent.
- `docs/WALKTHROUGH.md` — hướng dẫn chạy và kiểm tra giao diện hiện tại.
