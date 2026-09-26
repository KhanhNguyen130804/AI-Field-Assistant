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

App shell ở `lib/main.dart`; form nằm trong `lib/screens/create_report_screen.dart`. Schema/parser bản nháp ở `lib/models/report_draft.dart`, prompt chưa chạy ở `lib/services/report_draft_prompt.dart`; chưa nối tới Firebase AI Logic. Widget tests ở `test/widget_test.dart`; model tests ở `test/report_draft_test.dart`.

## Luồng màn hình đã chốt

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất cho thiết kế. Hiện **Tạo báo cáo** cho nhập và xem lại đầu vào cục bộ; **Lịch sử** vẫn rỗng. AI draft, màn hình kết quả/chỉnh sửa, lưu và chi tiết chưa được dựng hay giả lập bằng dữ liệu mẫu.

## Quy trình AI dự kiến — chưa tích hợp

Khi triển khai, luồng mục tiêu là:

```text
Mô tả/ảnh
  → Firebase AI Logic SDK trong Flutter
  → Firebase-managed proxy + App Check
  → Gemini Developer API
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

`created_at`, đường dẫn ảnh và trạng thái báo cáo là metadata riêng, không phải trường nội dung cốt lõi. `ReportDraft` Dart model/parser và prompt đã được tạo nhưng chưa chạy với model; prompt yêu cầu summary chỉ tóm tắt dữ kiện người dùng nêu rõ. AI chỉ được phép tạo bản nháp, `suggested_action` không phải hành động đã thực hiện. Đã chọn Firebase AI Logic trên Spark với Gemini Developer API `gemini-3.8-flash`; Firebase SDK chưa được nối vào app và chưa có màn hình draft hoặc cơ sở dữ liệu.

## Quyết định kỹ thuật

- **Flutter/Dart:** ưu tiên một codebase Android-first phù hợp với prototype di động.
- **Web preview:** bật Web để xem giao diện trong môi trường chưa có Android device/emulator kết nối.
- **Material 3, `NavigationBar`, `IndexedStack`:** tạo điều hướng đơn giản, trạng thái chọn tab rõ ràng và chuyển màn hình không cần thư viện ngoài.
- **`image_picker` 1.2.3:** dùng system picker cho camera/thư viện; preview đọc bytes trong phiên hiện tại. Không thêm `permission_handler` hoặc quyền Android rộng trong bước này.
- Ảnh được yêu cầu resize tối đa 1600×1600, JPEG quality 85; kiểm tra file nhận được không quá 10 MiB. Đây là ngưỡng hiện tại của prototype.
- **AI đã chọn, chưa tích hợp:** Firebase AI Logic trên Spark, Gemini Developer API `gemini-3.8-flash`. Firebase-managed proxy giữ Gemini API key phía server; không có Cloud Run backend hoặc Secret Manager do dự án tự quản lý.
- Task 2 đã thêm `ReportDraft` schema/parser và prompt chưa chạy; response schema cho Firebase SDK, network call và JSON output thật vẫn chưa được triển khai.
- Firebase Console đã bật API, AI monitoring và đăng ký app Android/Web; FlutterFire tạo `lib/firebase_options.dart`. App Check hiện vẫn báo **Unregistered** cho hai app; SDK/App Check chưa được nối vào code.
- Firebase AI Logic quota `Generate content requests` đã được đặt 5 RPM cho từng vùng Asia trong bảng quota (per-user/per-region); quota riêng của Gemini Developer API free tier vẫn có thể thấp hơn. Quota Bidi chưa đổi vì app không dùng streaming.
- Spark/free tier không cần thẻ hoặc Cloud Billing. Free-tier input có thể được dùng để cải thiện sản phẩm Google, nên chỉ thử bằng mô tả/ảnh tổng hợp, không dùng dữ liệu hiện trường thật. Paid tier và mục tiêu USD 5/tháng chưa áp dụng; việc bật billing sau này cần xác nhận riêng.
- Firebase AI Logic giới hạn tổng request 20 MB và ảnh inline base64 7 MB. Ngưỡng gửi ảnh dự kiến tối đa 4 MiB bytes gốc để còn chỗ cho base64 overhead; form hiện vẫn cho chọn ảnh đến 10 MiB nên giới hạn gửi AI chưa được triển khai.

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
- Firebase AI Logic đã được bật trong Console nhưng Flutter chưa gửi request; chỉ dùng dữ liệu tổng hợp khi tích hợp free tier.
- App Check Android/Web chưa đăng ký provider (`Unregistered`); cần cấu hình debug provider cho local trước khi gọi AI Logic và provider production trước khi phân phối.
- Tab Lịch sử luôn rỗng; chưa có lưu trữ cục bộ hoặc dữ liệu lịch sử.
- `ReportDraft` model/parser và prompt có trong mã, nhưng chưa được gọi bởi Firebase AI Logic; chưa có dữ liệu draft thực từ Gemini.
- Gallery picker và preview đã được chủ dự án thử trên điện thoại thật; camera, từ chối quyền và hủy picker chưa có bằng chứng thử thủ công.
- Ảnh rỗng/quá lớn/không nhận diện được signature bị từ chối trước khi thay ảnh hiện có; lỗi decode còn lại có fallback hiển thị nhưng chưa được kiểm chứng trên thiết bị.
- Chưa có kiểm thử lỗi mạng/API, timeout hoặc JSON không hợp lệ vì chưa có AI/network flow.
- Đầu vào không được lưu sau khi app đóng; Web build thành công nhưng tương tác camera/picker trên trình duyệt chưa được kiểm chứng.
- Sau khi FlutterFire tạo `lib/firebase_options.dart`, `flutter analyze` toàn dự án báo thiếu `firebase_core` vì dependencies Firebase chưa được nối (Task 3). Task 2 tests và analyze theo các file Task 2 đã đạt; xem kết quả cụ thể trong `docs/AI_WORKLOG.md`.

Ưu tiên tiếp theo là nối Firebase Core/AI Logic/App Check vào Flutter, thêm model/prompt/response validation và loading/error/retry, rồi cho người dùng sửa/xác nhận và lưu/đọc lịch sử cục bộ. Chỉ cân nhắc voice/GPS sau khi luồng cốt lõi chạy ổn.

## Tài liệu dự án

- `AGENTS.md` — hướng dẫn dành cho coding agent.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và roadmap sản phẩm.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng Ngày 1.
- `docs/AI_WORKLOG.md` — nhật ký sử dụng và kiểm chứng AI.
- `docs/CONTEXT_SUMMARY.md` — tóm tắt trạng thái để bàn giao coding agent.
- `docs/WALKTHROUGH.md` — hướng dẫn chạy và kiểm tra giao diện hiện tại.
- `docs/implement_plan_day3.md` — kế hoạch tích hợp Firebase AI Logic và trạng thái Task 1.
