# Kế hoạch triển khai — Xuất PDF báo cáo đã lưu

## 1. Mục tiêu và quyết định đã chốt

Thêm chức năng cho phép người dùng tạo PDF bản đầy đủ từ một báo cáo **đã được người dùng xác nhận và lưu**, mở từ màn hình chi tiết, sau đó:

1. Lưu tệp vào vị trí người dùng chọn trên thiết bị Android (mặc định gợi ý Downloads/Tải xuống).
2. Chia sẻ PDF qua bảng chia sẻ của Android. Zalo có thể được chọn nếu đã cài và hệ điều hành hiển thị ứng dụng đó cho tệp PDF; không tích hợp API/tài khoản Zalo trực tiếp.

PDF được tạo cục bộ từ `Report` và ảnh cục bộ, không gọi AI, mạng hoặc dịch vụ cloud. Nội dung phải phản ánh bản report đã lưu, không xuất draft chưa xác nhận.

## 1.1 Trạng thái thực hiện

- Nhánh làm việc: `codex/report-pdf-export`, tạo từ `codex/day5` tại `eb54b34`; giữ nguyên `docs/HOME_DEVICE_TEST_CHECKLIST.md` chưa theo dõi.
- Đã thêm service dựng PDF, adapter lưu/chia sẻ, hai thao tác ở detail screen, font Roboto được bundle cùng license và test tự động.
- Dependency đã khóa trong `pubspec.lock`: `pdf` 3.13.1, `printing` 5.15.1, `flutter_file_saver` 0.10.0 và `image` 4.10.1. `image` trực tiếp được dùng để xác thực/chuẩn hóa WebP khi nhúng vào PDF.
- Host verification đạt: 126/126 tests, analyzer sạch, format check 29 file/0 thay đổi; APK debug build thành công.
- `flutter devices` trong lượt triển khai không thấy Android device/emulator. Chưa kiểm tra lưu/mở PDF, share sheet hay Zalo trên thiết bị thật.

## 2. Khảo sát mã hiện có

- `ReportDetailScreen` tải một `Report` đã lưu bằng `ReportRepository.findById(reportId)` và ảnh bằng `readPhotoBytes(photoPath)`; màn đã hiển thị sáu field, trạng thái đã xác nhận, mô tả gốc và ảnh/fallback.
- `Report` mang `createdAt` UTC, `sourceDescription`, `photoPath`, `confirmedAbsentFields` và các trường nội dung; `suggestedAction` luôn là đề xuất.
- Android factory dùng `LocalReportRepository`; repository Web hiện không hỗ trợ lưu trữ. Tính năng trong kế hoạch này ưu tiên Android và không được tuyên bố Web hỗ trợ lưu/chia sẻ tệp nếu chưa có bằng chứng.
- Ảnh không đọc được hiện có trạng thái lỗi và retry; khi xuất không được âm thầm bỏ ảnh khỏi PDF.

## 3. Phạm vi PDF

### Nội dung

- Tiêu đề “Báo cáo sự cố”, mã báo cáo và thời gian tạo được định dạng theo múi giờ thiết bị.
- `category`, `location`, `priority`, `issue`, `suggested_action`, `summary`.
- Hiển thị rõ field đã xác nhận không có dữ liệu (phân biệt `priority == null` với text rỗng).
- Mô tả gốc của người dùng.
- Ảnh đã lưu nếu báo cáo có ảnh; giữ đúng tỷ lệ và hỗ trợ nhiều trang.
- Nhãn “Hành động đề xuất” và lưu ý rằng đây không phải hành động đã thực hiện.

### Bố cục và văn bản

- A4, lề dễ đọc, bố cục nhất quán, có header/footer và số trang khi nội dung tràn trang.
- Nhúng font TTF có glyph tiếng Việt và giấy phép phù hợp để PDF hiển thị đúng trên máy không cài font đó.
- Sinh PDF bằng dữ liệu trong bộ nhớ; không log nội dung, ảnh hoặc bytes PDF.

### Ngoài phạm vi

- PDF từ draft chưa lưu; DOCX; chữ ký; mẫu tùy biến; chỉnh sửa PDF; gửi qua backend; đồng bộ cloud; tích hợp Zalo API; gửi tự động đến người nhận.

## 4. Thiết kế triển khai

### A. Sinh tài liệu

- Thêm `lib/services/report_pdf_service.dart` với API tạo `Uint8List` từ `Report` và ảnh bytes tùy chọn. Service thuần dữ liệu, không phụ thuộc `BuildContext`, repository hay widget.
- Dùng thư viện `pdf` tạo trang nhiều trang và nhúng font tiếng Việt dạng asset nội bộ. Không tải font lúc chạy để giữ xuất PDF hoạt động offline.
- Kiểm tra và chuẩn hóa tên tệp an toàn, ví dụ `bao-cao-<id-rut-gon>-<yyyyMMdd>.pdf`; không dùng mô tả người dùng làm tên tệp.

### B. Lưu và chia sẻ

- Thêm một lớp mỏng quản lý thao tác tệp, có thể thay thế trong widget tests.
- Lưu bằng native document picker Android (`ACTION_CREATE_DOCUMENT` qua `flutter_file_saver` nếu API/SDK/giấy phép và smoke test phù hợp); người dùng chọn thư mục/tên và có thể hủy. Không xin quyền ghi bộ nhớ rộng.
- Chia sẻ PDF qua Android share sheet bằng API tệp của `printing` (hoặc một adapter tương đương nếu tương thích hiện hành không đạt). Không giả định một ứng dụng nhắn tin cụ thể luôn xuất hiện.
- Tạo bytes một lần cho mỗi thao tác; giữ trong cache trong thời gian cần thiết, xử lý lỗi/hủy rõ ràng và dọn tệp tạm an toàn nếu adapter phải tạo tệp trung gian.

### C. Tích hợp UI

- Thêm các nút “Lưu PDF” và “Chia sẻ PDF” tại `lib/screens/report_detail_screen.dart`, chỉ khi report đã tải thành công.
- Với report có ảnh, dùng bytes đã tải hoặc đọc qua repository. Nếu ảnh lỗi/không hợp lệ, yêu cầu người dùng tải lại hoặc xác nhận rõ trước khi xuất bản không ảnh; không âm thầm tạo bản bị thiếu ảnh.
- Có trạng thái đang tạo/lưu/chia sẻ; khóa double tap; báo thành công/hủy/lỗi bằng thông báo tiếng Việt. Lỗi xuất không thay đổi hay xóa report.
- Với repository/nền tảng không hỗ trợ, ẩn hoặc vô hiệu hóa thao tác và giải thích ngắn gọn.

## 5. Dependency và kiểm soát tương thích

- `pdf` để tạo PDF nhiều trang, ảnh và dùng font TTF.
- `printing` để mở share sheet cho bytes PDF bằng MIME phù hợp.
- `flutter_file_saver` làm adapter lưu qua document picker Android nếu đánh giá source, API, minSdk và dependency graph cho thấy phù hợp. Trước khi chốt dependency, xác minh package hiện hành, giấy phép, phiên bản Flutter/Dart, tích hợp Android và behavior khi hủy/ghi lỗi. Nếu không đạt, dùng một MethodChannel Android nhỏ gọi `ACTION_CREATE_DOCUMENT` thay vì xin quyền storage rộng.
- Không thêm `share_plus` nếu `printing` đã đáp ứng luồng chia sẻ; tránh hai plugin cùng chức năng.

## 6. Kế hoạch file

- Tạo: `docs/implement_plan_pdf_export.md` (tệp kế hoạch này).
- Tạo: `lib/services/report_pdf_service.dart` và lớp adapter save/share ở `lib/services/` nếu cần tách rõ.
- Sửa: `lib/screens/report_detail_screen.dart`, `pubspec.yaml`, `pubspec.lock` và `README.md`.
- Thêm font TTF có giấy phép phù hợp trong `assets/fonts/` và khai báo asset nếu cần.
- Tạo test cho PDF/service/adapter hoặc cập nhật `test/report_detail_screen_test.dart` theo các seam được triển khai.
- Ghi entry mới vào `docs/AI_WORKLOG.md` sau khi có kết quả thực thi thật; cập nhật `docs/CONTEXT_SUMMARY.md` và `docs/WALKTHROUGH.md` khi chức năng đạt kiểm chứng.
- Không sửa/xóa/stage `docs/HOME_DEVICE_TEST_CHECKLIST.md` hoặc thay đổi không thuộc tính năng này.

## 7. Kiểm thử và nghiệm thu

### Tự động

- Kiểm tra PDF sinh thành công, header PDF hợp lệ, giá trị từng field, tiếng Việt, field đã xác nhận vắng mặt, summary/mô tả dài nhiều trang, trường hợp có/không ảnh và ảnh lỗi.
- Widget tests: nút chỉ xuất hiện sau khi report tải; report không ảnh; đang tải; save/share thành công, hủy và lỗi; double tap không tạo hai thao tác; lỗi ảnh cần lựa chọn rõ; lỗi export không ảnh hưởng nội dung report.
- Chạy formatter, `flutter analyze` và toàn bộ test liên quan; ghi chính xác lệnh/kết quả. Không tuyên bố Android đã xác minh dựa trên fake tests.

### Android thật

- Build/cài APK từ nhánh/source mới và ghi nhận đúng build.
- Tạo PDF tổng hợp không ảnh và có ảnh; kiểm tra tiếng Việt, nội dung đầy đủ, chiều ảnh, nhiều trang và mã/timestamp.
- Lưu vào Downloads hoặc thư mục chọn được, đóng ứng dụng, mở lại tệp bằng file manager/PDF viewer.
- Bật chế độ máy bay sau khi report đã lưu và xác nhận tạo/lưu PDF vẫn chạy cục bộ.
- Mở share sheet; xác nhận file được gửi dưới dạng PDF đến ứng dụng có trên thiết bị. Chỉ ghi Zalo PASS nếu đã quan sát thao tác đó trên thiết bị; nếu không, ghi chưa kiểm chứng.
- Thử hủy picker, lỗi đọc ảnh và lỗi lưu/chia sẻ có kiểm soát; không xóa report đã lưu.

### Điều kiện hoàn tất

- Người dùng xuất được đúng report đã xác nhận từ màn hình chi tiết, lưu tệp ở vị trí tự chọn và mở lại được.
- Chia sẻ đưa đúng PDF (MIME/đuôi `.pdf`) vào bảng chia sẻ Android; không yêu cầu Zalo phải được cài.
- Bản PDF hiển thị đúng nội dung tiếng Việt, ảnh và các giá trị đã xác nhận; lỗi không làm mất report hoặc tạo cảm giác đã lưu/gửi thành công khi chưa có bằng chứng.
- README/worklog phân biệt test host, Android thật, Zalo cụ thể và các phần chưa kiểm chứng.
