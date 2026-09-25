# Kế hoạch triển khai — Ngày 2: Nhập mô tả và ảnh

> **Trạng thái:** Đã triển khai phần nhập mô tả/ảnh và validation theo kế hoạch. Kết quả test/build và giới hạn kiểm tra thiết bị được ghi ở mục 9. Bám theo `docs/CHALLENGE_VI_ROADMAP.md` và `AGENTS.md`.

## 1. Mục tiêu và tiêu chí hoàn thành

Hoàn thiện màn hình **Tạo báo cáo** để nhân viên bảo trì tòa nhà có thể nhập mô tả sự cố, chụp ảnh hoặc chọn một ảnh có sẵn, xem trước đầu vào và tiếp tục sử dụng ứng dụng nếu camera/thư viện bị từ chối hoặc gặp lỗi.

Ngày 2 được xem là hoàn thành khi:

- Mô tả sự cố có thể nhập và được giữ nguyên trong suốt thao tác chọn/chụp ảnh, hủy chọn hoặc lỗi.
- Có thể mở camera hoặc thư viện từ thao tác tương ứng, chọn tối đa một ảnh và xem trước ảnh đó.
- Hủy chọn ảnh không làm mất mô tả hoặc ảnh đã chọn trước đó.
- Đầu vào rỗng bị chặn trước khi tiếp tục; ảnh vượt giới hạn có hướng dẫn dễ hiểu.
- Từ chối quyền, không có camera, plugin lỗi hoặc ảnh không đọc được không làm ứng dụng crash/mất nội dung nhập.
- Bố cục dùng được trên màn hình nhỏ, bàn phím không che vùng nhập hoặc thao tác chính.
- `flutter analyze`, `flutter test`, APK debug và kiểm tra trên Android device/emulator hoàn tất; kết quả thực tế được ghi lại.

## 2. Phạm vi

### Làm trong Ngày 2

1. Thay phần giới thiệu tĩnh ở tab **Tạo báo cáo** bằng form nhập đầu vào.
2. Thêm trường mô tả nhiều dòng.
3. Thêm thao tác **Chụp ảnh** và **Chọn ảnh**; chỉ hỏi quyền lúc người dùng chọn thao tác cần quyền.
4. Hiển thị ảnh đã chọn, cho phép thay ảnh trước khi tiếp tục.
5. Kiểm tra mô tả/ảnh rỗng và giới hạn kích thước ảnh.
6. Hiển thị lỗi có hướng dẫn, xử lý trường hợp hủy/từ chối quyền và giữ nội dung nhập.
7. Có thao tác xem lại đầu vào cục bộ; nói rõ dữ liệu chưa gửi đi và chưa được lưu.

### Chưa làm trong Ngày 2

- Không gọi AI, không có nút hoặc nội dung khiến người dùng tưởng AI đã phân tích.
- Không tạo/lưu báo cáo, không thêm database, cloud hoặc đăng nhập.
- Không triển khai voice-to-text, GPS, danh sách lịch sử có dữ liệu hoặc màn hình chi tiết.
- Không tạo dữ liệu mẫu giả để minh họa kết quả.

## 3. Giả định và mặc định đề xuất

Các mặc định dưới đây giúp bắt đầu triển khai mà không phải mở rộng phạm vi; có thể điều chỉnh trước khi code nếu chủ dự án có yêu cầu khác:

- Mỗi lần nhập giữ **một ảnh**; người dùng có thể thay ảnh trước khi tiếp tục.
- Đầu vào hợp lệ khi có ít nhất một trong hai: mô tả không rỗng sau `trim()` hoặc ảnh đã chọn. Không cho tiếp tục khi cả hai đều trống.
- Giới hạn đề xuất: ảnh sau xử lý không quá **10 MiB**; yêu cầu picker resize cạnh dài tối đa khoảng **1600 px**, chất lượng JPEG khoảng **85**. Cần kiểm tra kích thước thực nhận sau xử lý và báo lỗi nếu vẫn vượt giới hạn.
- Thư viện ưu tiên: `image_picker`, sau khi xác nhận phiên bản ổn định tương thích với Flutter/Dart và Android Gradle hiện tại.
- Chưa thêm `permission_handler` hoặc permission rộng cho thư viện ảnh. Trước khi sửa Android manifest, kiểm tra tài liệu đúng phiên bản `image_picker` và chỉ khai báo quyền thật sự cần thiết.

## 4. Kiến trúc dự kiến

Giữ kiến trúc nhỏ, không thêm AI service, repository hay report model ở bước này:

```text
_HomeScreen / NavigationBar / IndexedStack
└── CreateReportScreen (StatefulWidget)
    ├── mô tả sự cố + validation
    ├── image_picker: camera hoặc gallery
    ├── một XFile? + preview
    └── xem lại đầu vào cục bộ
```

- Tách màn hình tạo báo cáo khỏi `lib/main.dart` để form có `TextEditingController`, state ảnh và lifecycle riêng.
- Dùng `XFile` làm tham chiếu ảnh. Vì dự án bật Web preview, ưu tiên preview qua bytes (`XFile.readAsBytes`/`Image.memory`) thay vì phụ thuộc trực tiếp vào `dart:io File`; nếu Web picker không hỗ trợ trường hợp nào thì ghi rõ giới hạn đó.
- Dispose controller đúng lifecycle, kiểm tra `mounted` trước `setState` sau thao tác bất đồng bộ.
- Giữ state của tab tạo báo cáo khi chuyển sang Lịch sử nhờ `IndexedStack`; không hứa giữ dữ liệu sau khi người dùng đóng hẳn ứng dụng.
- Nếu Android hủy activity trong khi mở camera/picker, kiểm tra hướng dẫn plugin và dùng `retrieveLostData()` nếu phiên bản đang dùng yêu cầu.

## 5. Các bước triển khai

### Bước 0 — Preflight và bảo toàn working tree

1. Chạy `git status --short --branch` và xem diff trước khi sửa.
2. Xác định rõ mọi thay đổi sẵn có trong `pubspec.yaml`, Android Gradle/Manifest, Web và `.gitignore`; không reset hoặc ghi đè thay đổi chưa rõ nguồn gốc.
3. Kiểm tra min SDK, compile SDK, Flutter/Dart hiện tại và tài liệu plugin.
4. Xác nhận thiết bị/emulator Android dùng để thử camera, thư viện và luồng từ chối quyền.

**Ghi chú tại thời điểm lập kế hoạch:** working tree báo modified nhiều file cấu hình Flutter/Android/Web và `pubspec.yaml`. `git diff` khi kiểm tra không hiện hunk nội dung, chỉ có cảnh báo line ending LF/CRLF. Hãy kiểm tra lại trạng thái ngay trước khi code; không tự xóa hoặc stage hàng loạt các thay đổi này.

### Bước 1 — Thêm và xác nhận plugin ảnh

1. Kiểm tra tài liệu `image_picker` phiên bản ổn định tương thích với project.
2. Thêm dependency bằng Flutter CLI và kiểm tra phần thay đổi trong `pubspec.yaml`/`pubspec.lock`.
3. Xác nhận riêng hành vi Android cho camera, photo picker/thư viện, hủy chọn, permission denied và lost activity data.
4. Không thêm permission trong manifest hoặc package permission thứ hai nếu plugin không yêu cầu.

**Đầu ra:** plugin resolve được; cấu hình Android/Web không chứa quyền thừa hoặc secret.

### Bước 2 — Xây form nhập mô tả

1. Tạo `lib/screens/create_report_screen.dart` với `StatefulWidget`.
2. Thêm nhãn tiếng Việt rõ ràng, `TextField` nhiều dòng, helper text ngắn và giới hạn nhập hợp lý nếu có yêu cầu sản phẩm.
3. Lưu nội dung trong controller/state; không log nội dung mô tả.
4. Thêm thao tác **Xem lại đầu vào** thật sự: kiểm tra đầu vào rỗng rồi mở phần preview cục bộ; không gọi network, không tạo kết quả AI.
5. Ở preview, hiển thị lại mô tả/ảnh và ghi rõ **“Chưa gửi AI, chưa lưu báo cáo”**.

### Bước 3 — Chụp/chọn ảnh và preview

1. Hiển thị hai thao tác thật: **Chụp ảnh** và **Chọn từ thư viện**; chỉ mở picker sau khi người dùng chạm.
2. Truyền giới hạn resize/chất lượng theo mặc định đã chọn ở mục 3.
3. Khi có ảnh: kiểm tra size, cache bytes để preview, hiển thị tỷ lệ phù hợp màn hình và thao tác thay ảnh.
4. Nếu người dùng hủy picker, không hiển thị lỗi và giữ nguyên mô tả/ảnh hiện tại.
5. Nếu ảnh mới vượt giới hạn hoặc không đọc được, giữ state trước đó và chỉ thông báo lỗi cho ảnh mới.

### Bước 4 — Validation, quyền và lỗi

| Trường hợp | Hành vi mong đợi |
|---|---|
| Không có mô tả và không có ảnh | Chặn xem tiếp; hiển thị hướng dẫn nhập mô tả hoặc chọn ảnh. |
| Có mô tả, không ảnh | Cho xem lại đầu vào; không yêu cầu ảnh bắt buộc. |
| Có ảnh, mô tả trống | Cho xem lại nếu dùng mặc định “ít nhất một nguồn đầu vào”; ghi rõ ảnh chưa được phân tích. |
| Hủy camera/gallery | Không báo lỗi; giữ nguyên nội dung và ảnh cũ. |
| Permission bị từ chối | Thông báo quyền bị từ chối và cách thử lại/chọn phương án còn dùng được; không crash, không xóa mô tả. |
| Không có camera hoặc picker lỗi | Hiển thị thông báo tiếng Việt có hướng xử lý; các nguồn nhập khác vẫn sử dụng được. |
| Ảnh lớn hơn 10 MiB sau xử lý | Không tiếp tục với ảnh đó; hướng dẫn chọn ảnh khác/giảm kích thước. |
| Bytes rỗng hoặc signature không hỗ trợ | Báo lỗi, giữ nguyên mô tả và ảnh đã chọn trước. |
| Flutter decoder không render được ảnh có signature hợp lệ | `Image.errorBuilder` hiển thị fallback; cần kiểm chứng thêm trên thiết bị. |

Thông báo người dùng không hiển thị stack trace hoặc tên class exception. Không ghi nội dung mô tả, ảnh hay đường dẫn riêng tư vào log.

### Bước 5 — Bố cục và trải nghiệm điện thoại

- Dùng vùng cuộn cho form; kiểm tra bàn phím không che trường hiện tại và nút xem lại.
- Giữ thao tác chính ở vùng dễ chạm một tay; tránh hai CTA cạnh nhau nếu chiều ngang hẹp.
- Có trạng thái đang mở picker để ngăn chạm lặp; bật lại sau khi picker trả kết quả.
- Nút preview phản hồi bằng validation hoặc preview thật; không để CTA giả chỉ đổi chữ/loading.
- Giữ bottom navigation hiện tại và đảm bảo nội dung cuộn không bị nó che.

### Bước 6 — Test tự động và chạy Android

Mở rộng `test/widget_test.dart`; test thuần widget không thay thế kiểm tra quyền/picker trên thiết bị.

| Kiểm tra | Kỳ vọng |
|---|---|
| Mô tả hợp lệ, không ảnh | Xem lại được nội dung, không có overflow. |
| Mô tả rỗng, không ảnh | Thấy validation, không đi tiếp. |
| Chọn/preview ảnh | Thumbnail xuất hiện, layout không tràn. |
| Hủy chọn ảnh hoặc thay ảnh thất bại | Mô tả và ảnh đang có không mất. |
| Picker trả lỗi/permission denied | Có thông báo dễ hiểu, widget không crash. |
| Ảnh quá giới hạn | Bị chặn, state trước đó còn nguyên. |
| Viewport 320×568 + bàn phím mở | Form có thể cuộn tới CTA; không có render exception. |

Chạy:

```bash
dart format lib test
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter devices
```

Trên Android device/emulator, kiểm tra thực tế: chọn ảnh từ thư viện, chụp ảnh, hủy picker, từ chối quyền (nếu hệ điều hành/plugin yêu cầu), quay lại ứng dụng sau picker, thử ảnh quá lớn và xác nhận mô tả không mất. Ghi model Android/API level và kết quả thật vào worklog nếu có.

### Bước 7 — Đồng bộ tài liệu

Sau khi triển khai và kiểm chứng thật:

- Cập nhật `README.md`, `docs/CONTEXT_SUMMARY.md` và `docs/WALKTHROUGH.md` để chỉ mô tả picker/preview/validation đã chạy.
- Ghi package, cách xử lý quyền/lỗi, thiết bị đã thử và mọi lỗi/sửa chữa thực tế trong `docs/AI_WORKLOG.md`.
- Phân biệt rõ đầu vào đang ở state trong bộ nhớ với dữ liệu đã lưu; chưa tuyên bố offline persistence.

## 6. Danh sách file dự kiến

| File | Thay đổi dự kiến |
|---|---|
| `pubspec.yaml`, `pubspec.lock` | Thêm/khóa phiên bản plugin ảnh đã xác nhận tương thích. |
| `lib/main.dart` | Giữ app shell/tab; thay widget tạo báo cáo tĩnh bằng màn hình form mới. |
| `lib/screens/create_report_screen.dart` | Form, state mô tả/ảnh, picker, preview, validation và lỗi. |
| `test/widget_test.dart` | Test form, validation, preview, lỗi và màn hình hẹp. |
| `android/app/src/main/AndroidManifest.xml` | Chỉ sửa nếu tài liệu plugin xác nhận cần cấu hình thêm. |
| `android/gradle.properties` | Đặt `kotlin.incremental=false` để workaround lỗi Kotlin cross-drive trên Windows; build chậm hơn nhưng không cần cờ riêng cho Android Studio. |
| `README.md`, `docs/WALKTHROUGH.md`, `docs/CONTEXT_SUMMARY.md`, `docs/AI_WORKLOG.md` | Chỉ cập nhật sau khi tính năng và kiểm chứng thực tế hoàn tất. |

Không đổi Gradle version, target SDK hoặc quyền Android ngoài phạm vi ảnh. Ngoại lệ duy nhất là Kotlin incremental flag ở `android/gradle.properties` để build được trong workspace Windows hai ổ đĩa.

## 7. Rủi ro và điểm cần xác nhận khi bắt đầu

1. **Working tree có cấu hình đang modified:** xác định thay đổi thật trước khi code; không dùng `git restore`, `reset` hoặc `clean` để làm sạch.
2. **Permission thay đổi theo Android/API và plugin:** dựa vào tài liệu đúng phiên bản và thử trên thiết bị; không đoán từ tên quyền.
3. **Dung lượng/độ phân giải:** 10 MiB, 1600 px, quality 85 là mặc định đề xuất; đánh giá trên ảnh thực tế trước khi xem là cố định.
4. **Mất state khi Android thu hồi process:** xử lý lost picker data theo hướng dẫn plugin; không tuyên bố văn bản được lưu bền nếu chưa có persistence.
5. **Web preview:** giữ được preview bytes nếu khả thi; hành vi camera/permission Web không thay cho acceptance test Android.

## 8. Điều kiện dừng Ngày 2

Kết thúc khi người dùng nhập mô tả, chụp/chọn và xem trước ảnh, lỗi đầu vào/quyền được báo rõ, app không mất mô tả khi picker bị hủy/lỗi, giao diện dùng được trên màn hình nhỏ, và các kiểm tra/thiết bị được ghi nhận trung thực. Dừng trước AI, database, lưu lịch sử, voice/GPS và các màn hình chi tiết thuộc ngày sau.

## 9. Kết quả triển khai

- Đã thêm `image_picker` 1.2.3 và màn hình `lib/screens/create_report_screen.dart` cho nhập mô tả, chụp/chọn một ảnh, preview và sheet xem lại đầu vào cục bộ.
- Có kiểm tra đầu vào rỗng, giới hạn 10 MiB, resize tối đa 1600×1600/quality 85, thông báo permission/picker error và giữ mô tả/ảnh cũ khi hủy hoặc ảnh mới bị từ chối do size, bytes rỗng hoặc signature không hợp lệ. Nếu Flutter decoder không render được ảnh có signature hợp lệ, preview dùng error fallback; nhánh này chưa được kiểm chứng trên thiết bị.
- Không thêm quyền Android rộng hoặc `permission_handler`; `requestFullMetadata` tắt để không đọc metadata đầy đủ.
- **Đã chạy:** `dart format lib test`, `flutter analyze` (không vấn đề), `flutter test` (8 tests đạt), `flutter build web --release` và APK debug.
- APK build đầu tiên vướng lỗi Kotlin incremental cache vì source plugin nằm trên ổ `C:` còn project ở ổ `D:`. Đã thêm `kotlin.incremental=false` vào `android/gradle.properties`; lệnh build chuẩn `flutter build apk --debug` sau đó thành công. Tradeoff: Kotlin có thể build lại lâu hơn.
- Chủ dự án cung cấp hai ảnh từ Android thật, xác nhận gallery picker mở và ảnh được chọn/preview cùng mô tả; ảnh nguồn được báo lớn hơn 10 MiB, nhưng byte length sau xử lý không được hiển thị. Camera và permission denial chưa có bằng chứng thử. `flutter devices` trong môi trường agent chỉ nhận Windows/Chrome/Edge.
- Chưa gọi AI, chưa lưu dữ liệu, chưa tạo lịch sử có dữ liệu; các giới hạn này vẫn đúng sau Ngày 2.
