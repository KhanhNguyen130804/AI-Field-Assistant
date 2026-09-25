# AI Field Assistant

Ứng dụng Android-first dành trước hết cho nhân viên bảo trì tòa nhà ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. AI Field Assistant hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Trạng thái hiện tại

Đã có hai khu vực điều hướng bằng tab tiếng Việt:

- **Tạo báo cáo:** giới thiệu quy trình dự kiến.
- **Lịch sử:** trạng thái rỗng cho báo cáo đã lưu trong tương lai.

Chưa tích hợp nhập mô tả, camera/chọn ảnh, AI, lưu trữ, voice-to-text, GPS, đăng nhập hoặc cloud. Vì vậy chưa có dữ liệu báo cáo, loading/error state hay lịch sử hoạt động.

## Kiến trúc hiện tại

```text
Flutter Material 3 app
└── lib/main.dart
    ├── AiFieldAssistantApp — theme và tên ứng dụng
    └── _HomeScreen — NavigationBar + IndexedStack
        ├── _CreateReportScreen — giới thiệu quy trình dự kiến
        └── _HistoryScreen — empty state
```

Prototype giữ giao diện trong một file để dễ hiểu và chưa tạo service, model hay repository trước khi có tính năng cần dùng chúng. `test/widget_test.dart` kiểm tra điều hướng giữa hai tab và bố cục ở viewport 320×568.

## Luồng màn hình đã chốt

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất cho thiết kế. Trong mã nguồn hiện tại mới có màn hình khung **Tạo báo cáo** và trạng thái rỗng **Lịch sử**; màn hình xem/chỉnh sửa và chi tiết chưa được dựng. Chúng không được giả lập bằng dữ liệu AI hoặc báo cáo mẫu.

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
- **Chưa thêm dependency nghiệp vụ:** camera, AI và lưu trữ chỉ được chọn khi bắt đầu triển khai các luồng tương ứng.
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

## Kiểm tra

```bash
dart format lib test
flutter analyze
flutter test
```

Trong lần kiểm tra nền tảng Ngày 1, các lệnh trên cùng `flutter build web --release` và `flutter build apk --debug` đều hoàn tất thành công. Chủ dự án xác nhận đã mở APK trong Android Studio và chạy trên điện thoại Android thật; hai ảnh đính kèm thể hiện hai tab tương ứng. Trong lần rà soát bằng coding agent không có Android device kết nối để chạy kiểm chứng độc lập.

## Hạn chế đã biết và hướng tiếp theo

- Hai màn hình hiện là giao diện khung; chưa có nhập liệu/chụp ảnh, AI thật, chỉnh sửa/xác nhận báo cáo hay lưu trữ.
- Tab Lịch sử luôn rỗng; chưa có model báo cáo hoặc cơ sở dữ liệu cục bộ.
- Chưa có kiểm thử lỗi mạng/API, timeout, JSON không hợp lệ hoặc quyền camera/thư viện vì các luồng này chưa tồn tại.
- Coding agent chưa kiểm tra trực tiếp trên Android trong phiên này; chủ dự án xác nhận đã chạy APK trên thiết bị thật. Web cũng được bật để xem trước trong giai đoạn phát triển.

Ưu tiên tiếp theo là hoàn thiện nhập mô tả/ảnh và xác thực đầu vào, tích hợp AI an toàn với schema được kiểm tra, cho người dùng sửa/xác nhận, rồi lưu và đọc lại báo cáo cục bộ. Chỉ cân nhắc voice/GPS sau khi luồng cốt lõi chạy ổn.

## Tài liệu dự án

- `AGENTS.md` — hướng dẫn dành cho coding agent.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và roadmap sản phẩm.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng Ngày 1.
- `docs/AI_WORKLOG.md` — nhật ký sử dụng và kiểm chứng AI.
- `docs/CONTEXT_SUMMARY.md` — tóm tắt trạng thái để bàn giao coding agent.
- `docs/WALKTHROUGH.md` — hướng dẫn chạy và kiểm tra giao diện hiện tại.
