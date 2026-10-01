# Trạng thái gói nộp — 01/10/2026

Ứng viên **0.2.0+2**, package `com.example.ai_field_assistant`, nhánh `codex/release-app-check`; build từ base `28b0a9c` cộng thay đổi signing/version/manifest/helper đang chưa commit. Đây là gói chuẩn bị local, chưa publish hoặc nộp bài.

## Bằng chứng mới trong lượt chuẩn bị

| Gate | Kết quả và giới hạn |
|---|---|
| Signing | PASS: keystore riêng ngoài repo; mật khẩu DPAPI ngoài repo, ACL giới hạn. Gradle chặn release khi thiếu cấu hình, không fallback debug. Backup độc lập/chuyển máy chưa được chủ dự án xác nhận. |
| Format/analyzer | PASS: format kiểm tra `lib test`, 35 tệp, 0 đổi; analyzer No issues, exit 0. |
| Tests | PASS **135/135** của bộ dự kiến nộp: dùng bản chính xác từ HEAD cho hai test modified có trước trong thư mục ignored; giữ nguyên bản working tree. Không tuyên bố hai test đang sửa đã PASS. |
| APK | PASS: universal, 59.831.252 byte, versionName 0.2.0/versionCode 2, minSdk 24/targetSdk 36; arm64-v8a/armeabi-v7a/x86_64; INTERNET; không debuggable. apksigner verify PASS, v2; zipalign 16 KiB PASS. |
| Cài mới | PASS: người dùng cho phép gỡ debug app/mất dữ liệu; uninstall, install release và mở app trên PKG110 Android 16/API 36 thành công. Không đăng ký debug token mới. |
| AI text-only | PASS: agent nhập mô tả tổng hợp, bấm phân tích một lần, quan sát loading rồi bản nháp thật. Category Điều hòa, địa điểm Lễ tân tầng 1; ưu tiên chưa xác định. Không suy model chính/fallback thực tế từ UI. |
| Review/save/history | PASS quan sát: sửa được issue; xác nhận các trường; report tổng hợp xuất hiện trong History. Có thao tác trên điện thoại xen giữa các snapshot cuối, nên không quy toàn bộ chuỗi xác nhận/lưu cho agent. |
| Persistence text-only | PASS: agent force-stop/relaunch, mở History và detail đúng report tổng hợp còn tồn tại. Không suy persistence ảnh từ case này. |
| PDF | PASS: document picker ColorOS lưu vào Download, app báo đã lưu; pull đúng tệp PDF 39.431 byte, parse 1 trang và render xem đủ trang, tiếng Việt đọc được, không cắt nội dung. Bản demo có ký tự gõ thừa trong summary đã lưu; không đính kèm PDF này như mẫu công khai. |
| Share | PASS mở share sheet `com.android.intentresolver` rồi hủy; chưa gửi tới ứng dụng/người nhận, chưa kiểm chứng Zalo/Drive nhận tệp. |
| Đầu vào rỗng | PASS: app báo “Nhập mô tả hoặc chọn ảnh trước khi phân tích.” |
| Chọn ảnh | PASS: push sơ đồ tổng hợp có nhãn rõ, xác minh thumbnail khớp fixture, chọn bằng Photo Picker, preview trong app và xem lại đầu vào. Không lấy/chọn ảnh cá nhân. |
| AI kèm ảnh tổng hợp | PASS: chọn sơ đồ 24.480 byte gắn nhãn “không phải ảnh hiện trường”, xác minh thumbnail khớp fixture (mean pixel difference 5,31), app preview và review input, gửi một lần, loading rồi bản nháp thật. Không kết luận ảnh làm tăng độ chính xác hoặc model/provider riêng từ UI. |
| Lưu/persistence ảnh sau restart | NOT RUN: case ảnh đã nhận draft nhưng chưa tới bước save trước khi ADB mất kết nối. Case text-only đã lưu và qua restart. |
| Offline/lỗi mạng/timeout trên APK | NOT RUN: `adb get-devpath` chưa xác nhận USB độc lập; không tắt mạng có thể cắt ADB. Host tests lỗi/timeout là bằng chứng riêng. |
| Camera/từ chối quyền | NOT RUN trên artifact này; không tự chụp môi trường cá nhân. |
| Video | BLOCKED tại công cụ: screenrecord bị Permission denied ở /sdcard, Movies và /data/local/tmp. Không có video thành công. Người dùng chọn tự quay theo script sau khi kiểm tra. |
| Console | Không đọc được live Console vì browser runtime lỗi. Ảnh Registered/quota/billing là bằng chứng lịch sử; không chứng minh saved enforcement/quota Mobile hoặc billing hiện tại. AI thành công chứng minh request trên máy này tại thời điểm thử. |
| Link/nộp | Chưa publish GitHub Release/upload Drive, chưa kiểm tra quyền link, chưa bấm Submit. Deadline/form live chưa đọc được; dùng roadmap như bản ghi đề bài. |

## Artifact

- Local: `build/submission/ai-field-assistant-0.2.0+2.apk`, `SHA256SUMS.txt`, `BUILD_MANIFEST.json`.
- APK SHA-256: `8E622C5580C1C18B1E397FBD000B0E48950D84CC8C397040288D5620545B8883`.
- Chứng thư signing SHA-256 (công khai): `FA7C4750F7A3CEFD0F3BDF6BA16895B5AE9E285212974D6FFF44882D321E90CF`.
- Keystore và DPAPI không nằm trong bundle. Không đưa site key thực tế, token, serial/IP, XML picker, raw logs hay ảnh màn hình có dữ liệu cá nhân vào bài nộp.
- `SUBMISSION_PACKET.md`: bản nháp form/prompt/kiến trúc; chủ dự án cho phép showcase và chia sẻ nhật ký prompt. Chưa có số giờ tiết kiệm có căn cứ.
- `DEMO_SCRIPT_DAY7.md`: script; `INSTALL_RELEASE.md`: hướng dẫn cài; `RELEASE_NOTES_DRAFT.md`: release notes.

## Còn phải hoàn tất trước nộp

1. Chủ dự án giữ backup signing an toàn, gồm cách khôi phục mật khẩu độc lập với DPAPI hiện tại.
2. Quay video thật theo script, dưới 5 phút, review dữ liệu/notification trước upload Drive. Không dùng PDF demo có lỗi gõ trong summary làm tài liệu mẫu.
3. Bổ sung kiểm chứng native còn thiếu nếu kịp; giữ nhãn NOT RUN nếu chưa thử.
4. Điền số giờ tiết kiệm có căn cứ; chủ dự án đã cho phép showcase và chia sẻ nhật ký prompt.
5. Review phạm vi source/bundle, commit/push và tạo GitHub Release khi được chốt; upload video Drive, kiểm tra hai link ngoài tài khoản chủ sở hữu.
6. Chủ dự án xác minh deadline/form, review nội dung và bấm nộp; lưu xác nhận.

Hai test modified và `HOME_DEVICE_TEST_CHECKLIST.md` untracked có trước vẫn được bảo toàn, không thuộc phạm vi publication chuẩn bị này. Cache/build bị ignore, không xóa công việc hiện có.
