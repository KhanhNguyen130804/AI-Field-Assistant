# Kế hoạch nâng cấp UI/UX — AI Field Assistant

> Nhánh: `codex/ui-ux-refresh`, tạo từ `18e3ea7f5dc900bbd8099e9ed99ee54b14c43187` (`codex/day6`). Phạm vi: chỉ trình bày và nhận diện thương hiệu cho toàn bộ màn hình hiện có, gồm launcher logo. Giữ nguyên checklist untracked có sẵn.

## 1. Mục tiêu

Áp dụng ngôn ngữ thị giác Apple product gallery trong tệp style reference vào ứng dụng Android dùng khi nhân viên bảo trì thao tác nhanh. Kết quả cần có nền sáng, chữ rõ, nhịp khoảng cách thoáng, card không đổ bóng, điều khiển nhất quán và logo riêng của sản phẩm. Thiết kế phải giữ người dùng tập trung vào công việc, thay vì mô phỏng trang giới thiệu/bán điện thoại.

## 2. Nguyên tắc chuyển đổi từ reference sang app

| Reference | Cách dùng trong app |
|---|---|
| Gallery White `#ffffff`, Studio Mist `#f5f5f7`, Paper Frost `#fafafc` | Nền sáng; dùng Mist để nhóm vùng/list và White cho nội dung chính; Frost chỉ dùng cho trạng thái chọn/phụ. |
| Ink `#1d1d1f`, Slate `#707070`, Steel `#86868b` | Phân cấp chữ/icon chính, phụ và viền điều khiển. Hairline Silver `#d6d6d6` làm đường chia mảnh. |
| Apple Blue `#0066cc`, Pricing Blue `#0071e3` | Blue cho link/text action; nút hành động chính dùng xanh có độ tương phản phù hợp, xanh sáng dành cho nhấn gọn. Không tô xanh mọi control. |
| SF Pro Display/Text, hero 80px | Dùng font hệ thống Android/Roboto để tránh font Apple không có giấy phép/bundle. Headline điện thoại 28–34sp, body 16–17sp, label 12–14sp, weight 400/500/600. Không dùng hero 80px trong form. |
| Lưới 4px, card ảnh 28px, nút pill, ít bóng | Dùng nhịp 4dp; gutter 16–24dp; card nội dung 28dp; ảnh 20–28dp; nút dạng pill; loại bỏ elevation trang trí. Input nhiều dòng vẫn là rounded rectangle. |
| Trang kể chuyện bằng ảnh sản phẩm và các section rộng | Dùng section title, card/phân vùng nhẹ và khoảng thở để quét nhanh report. Không thêm ảnh điện thoại gập, carousel, pricing badge, nội dung tiếp thị hoặc điều hướng mua hàng. |

Giữ trạng thái lỗi/ưu tiên/review có ngữ nghĩa và không chỉ phân biệt bằng màu. Mục tiêu tương phản và vùng chạm quan trọng hơn việc khớp tuyệt đối pixel của trang web.

## 3. Phạm vi mã và cách triển khai

### A. Design system và shell

- Thêm `lib/theme/app_theme.dart` chứa palette, type scale và `ThemeData` dùng chung cho nền, AppBar, card, input, button, chip, dialog, progress, divider, snackbar và bottom navigation.
- Thêm `lib/widgets/field_assistant_logo.dart` làm mark vector/code-native dùng cạnh tên ứng dụng trong app bar.
- Cập nhật `lib/main.dart`: dùng theme dùng chung; làm app bar và tab bar gọn, sáng, phân cấp chữ/icon nhất quán. Giữ `IndexedStack`, điều hướng, repository và refresh token nguyên trạng.

### B. Tạo báo cáo

- Restyle `lib/screens/create_report_screen.dart`: headline gọn; mô tả/hint có khoảng thở; khu vực ảnh thành một nhóm rõ với hai nút Chụp/Chọn đặt cạnh nhau khi đủ chỗ; preview bo góc lớn; CTA AI là hành động chính; Xem lại đầu vào là phụ.
- Giữ nguyên keys, giới hạn MIME/kích thước, trạng thái đang chọn ảnh/phân tích, validation, bảo toàn input, retry và xử lý ảnh bị hỏng. Không đổi thứ tự/dữ liệu gửi AI.
- Làm thông báo privacy dùng bề mặt trung tính, vẫn chỉ rõ request gửi khi người dùng chủ động bấm.

### C. Bản nháp và review

- Restyle `lib/screens/report_draft_screen.dart`: tiêu đề/notice phân biệt rõ “chưa lưu”; tiến độ review đọc nhanh; field cards và input theo theme; trạng thái chờ/đã xác nhận/đã xác nhận thiếu dữ liệu vẫn có chữ/icon rõ; vùng ảnh nguồn, lỗi lưu, retry và CTA cuối thống nhất.
- Giữ nguyên contract review, bắt buộc `issue`, xác nhận absence, yêu cầu review lại summary, xử lý save mơ hồ, retry cùng ID và cảnh báo Back.

### D. Lịch sử và chi tiết

- Restyle `lib/screens/history_screen.dart`: có heading cho danh sách, mỗi row scan được issue/location/priority/time, chevron và hit target rõ; empty, loading, refresh, unavailable, error/retry dùng cùng ngôn ngữ thị giác.
- Restyle `lib/screens/report_detail_screen.dart`: status/time thành header có cấp bậc; các field, mô tả gốc, ảnh/error/retry dùng card/spacing thống nhất; action bar PDF giữ hai thao tác và trạng thái đang xuất.
- Giữ nguyên thứ tự/list refresh, truy vấn theo ID, nội dung đã xác nhận, PDF generation/save/share và lựa chọn xác nhận khi xuất thiếu ảnh.

### E. Trạng thái dùng chung và launcher identity

- Restyle `lib/widgets/status_notice.dart`, dialog, chip, progress, lỗi/empty và snackbar qua theme; không thay đổi message/branch logic.
- Thay biểu tượng Flutter mặc định bằng mark “phiếu sự cố + dấu xác nhận” qua Android vector/adaptive icon resources. Màu dùng Ink, Gallery White/Studio Mist và một điểm nhấn Apple Blue. Không dùng logo Apple hoặc thêm package tạo icon.
- Không sửa Firebase, permission, Gradle signing, schema, AI, repository, PDF content hoặc workflow sản phẩm.

### F. Tài liệu và ghi nhận

- Tạo skill dùng lại tại `.agents/skills/field-assistant-apple-gallery-ui/SKILL.md` từ reference đã gửi, điều chỉnh thành quy tắc UI điện thoại của dự án.
- Sau khi triển khai, cập nhật trạng thái hiện hành trong README, thêm entry mới vào `docs/AI_WORKLOG.md`, và thêm follow-up mới trong `docs/CONTEXT_SUMMARY.md` mà không viết lại lịch sử Day 6. Kế hoạch này là file kế hoạch duy nhất.

## 4. Ngoài phạm vi

- Không đổi luồng, schema, nội dung AI, API, storage, quyền thiết bị, điều hướng sản phẩm hoặc dependencies.
- Không thêm voice, GPS, đăng nhập, sync, dashboard hay hành vi chưa có.
- Tác vụ triển khai ban đầu dừng trước commit/push; việc publish được thực hiện theo yêu cầu follow-up riêng của người dùng.
- Không dùng ảnh marketing/ảnh thiết bị gập; không đưa proprietary SF Pro vào app.

## 5. Thứ tự thực hiện

1. Tạo theme và mark dùng trong Flutter; cập nhật shell, AppBar, bottom navigation.
2. Restyle form tạo báo cáo và feedback.
3. Restyle draft/review/save và dialog.
4. Restyle History cùng mọi trạng thái; restyle detail, ảnh và PDF action bar.
5. Thay launcher icon Flutter bằng vector/adaptive icon cùng mark.
6. Cập nhật README/worklog/context, rà diff và giữ checklist untracked ngoài scope.
7. Chạy `dart format` cho Dart đã sửa và `flutter analyze`; không chạy test/build/thiết bị nếu không được yêu cầu xác minh. Ghi chính xác mọi phần chưa kiểm chứng.

## 6. Tiêu chí nghiệm thu

- Tất cả màn hiện có (Tạo báo cáo, Bản nháp AI, History, Chi tiết, trạng thái rỗng/lỗi/loading, dialog và PDF actions) sử dụng một bộ màu, chữ, surface, radius và điều khiển nhất quán.
- Logo app trong shell và launcher Android dùng nhận diện mới, không còn biểu tượng Flutter mặc định ở cấu hình launcher được chọn.
- Layout còn cuộn/đọc được ở màn điện thoại hẹp, giữ hỗ trợ text scale; control có hit target phù hợp và phân biệt trạng thái bằng nhãn/icon.
- Các keys/callbacks/validation/loading/error/retry/review/save/history/PDF behavior hiện tại được bảo toàn; không đổi dữ liệu hoặc network/service flow.
- `dart format` và `flutter analyze` có kết quả được ghi. Test suite, APK và thiết bị chỉ được báo PASS nếu thật sự chạy trong phiên.
- Working tree không chứa thay đổi ngoài scope; `docs/HOME_DEVICE_TEST_CHECKLIST.md` vẫn nguyên vẹn và untracked.

## 7. Rủi ro cần rà soát

- Card radius/spacing lớn có thể làm màn draft dài hơn; phải giữ cuộn mượt, không che nút lưu ở viewport nhỏ.
- CTA xanh phải đọc được với chữ trắng; disabled state, lỗi, focus và selected state phải đủ tương phản.
- Android adaptive icon cần resource fallback hợp lệ cho API cũ; không chỉ thay logo trong Flutter app bar.
- Theme-wide styles có thể đổi diện mạo dialog/chip đang được widget tests tìm theo nhãn/key; giữ semantic label và stable keys.
