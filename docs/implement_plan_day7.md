# Kế hoạch Ngày 7 — Kiểm tra cuối, video demo và nộp bài

> **Kết quả chuẩn bị (01/10/2026):** format/analyze/135 test intended submission PASS; APK release `0.2.0+2` build, verify chữ ký, cài trên PKG110 Android 16/API 36; AI text-only và text + sơ đồ tổng hợp PASS, lưu/history/restart cho report text PASS, PDF save/render PASS. Video, link GitHub/Drive, offline, ảnh persistence, camera và submit còn thiếu. Người dùng tự quay video; các chi tiết ở [SUBMISSION_STATUS](SUBMISSION_STATUS.md) và [testcase_day7](testcase_day7.txt). Phần kế hoạch nền bên dưới mô tả trạng thái trước khi chạy các kiểm tra này.

> Nhánh: `codex/day7`, tạo từ `origin/main` tại commit `a8026ff` (merge PR #2 — UI/UX refresh; cây làm việc trùng `0c93ea1`). Baseline tracked tree sạch; `docs/HOME_DEVICE_TEST_CHECKLIST.md` là tệp chưa được theo dõi có trước và phải giữ nguyên, không đưa vào commit Ngày 7.
>
> Hạn nộp ghi trên đề bài: **23:59 ngày 01/10/2026**. Ngày 7 là ngày cuối cùng; toàn bộ kế hoạch ưu tiên **kiểm tra – đóng gói – nộp sớm**, không thêm tính năng mới.
>
> Nguồn phạm vi: mục "Ngày 7" và mục 6/9/10 trong `docs/CHALLENGE_VI_ROADMAP.md`, `AGENTS.md`, trạng thái source hiện tại và các tài liệu Day 4–6/PDF.

## 1. Mục tiêu

Đưa sản phẩm từ trạng thái "đã có mã và bằng chứng lịch sử" sang **bài nộp thống nhất, kiểm chứng được và gửi trước hạn**:

1. Chạy đúng kịch bản demo trên **bản build cuối cùng**, không dùng artifact cũ làm bằng chứng mới.
2. Rà sạch secret/API key/token/dữ liệu nhạy cảm khỏi GitHub, file cấu hình công khai, ảnh chụp màn hình và video.
3. Kiểm tra link tải/demo truy cập được từ cửa sổ riêng tư hoặc thiết bị khác.
4. So khớp repo, README, `docs/AI_WORKLOG.md`, video và bản build; sửa mọi mô tả không còn đúng.
5. Điền biểu mẫu nộp: có ít nhất một prompt đã dùng, mô tả quy trình ≥ 30 ký tự, số giờ tiết kiệm có căn cứ, tùy chọn chia sẻ showcase.
6. Xóa tên/logo cá nhân khỏi các tệp cần chấm ẩn danh.
7. Nộp trước hạn và lưu bằng chứng nộp.

**Không thuộc Ngày 7:** thêm tính năng (voice/GPS, đăng nhập, sync, dashboard), đổi schema/AI/repository, thêm dependency/quyền, viết lại lịch sử Git, hoặc hoàn thiện release signing/production App Check.

## 2. Trạng thái đầu vào đã biết (tính đến 01/10/2026)

- `main` (`a8026ff`) đã merge PR #1 (PDF export) và PR #2 (UI/UX refresh); cây làm việc trùng nhánh `codex/ui-ux-refresh` (`0c93ea1`).
- UI/UX refresh chỉ đổi trình bày: theme, shell, 4 màn, widget, launcher icon, skill + docs; **không đổi** service AI, model, schema, repository, quyền hoặc dependency.
- Source hiện có **126 khai báo test** trên 9 tệp `test/*.dart` (đếm tĩnh). Test suite **chưa được chạy trên source UI refresh**; `README.md` đang nêu 126/126 trong khi `docs/CONTEXT_SUMMARY.md` ghi "Test suite chưa chạy" — cần chốt lại bằng lần chạy thật ở Task 1.
- APK debug lịch sử ngày 01/10/2026 (sau chỉnh CTA): 184.518.504 byte, SHA-256 `6D2650D5AD58BAB54F972F7DA6775D386880E39016D60AE57A7D65575FAC45FA`, artifact ở ngoài repo. Đây là kết quả đã ghi, phải build/đối chiếu lại trên HEAD cuối nếu dùng để nộp.
- Request Gemini thật gần nhất trong tài liệu từng thành công 27/09/2026; lần thử mới hơn bị App Check chặn. Quota/model chỉ là ảnh chụp lịch sử, cần xem Console trước demo.
- Đã kiểm chứng trên Android (lịch sử): report text-only sống qua force-stop/relaunch. **Chưa** xác minh: persistence ảnh sau restart, save/read offline, PDF/document picker/share sheet/Zalo trên thiết bị, UX đầy đủ trên source UI refresh.
- Video demo **chưa quay**. Kịch bản nền: `docs/DEMO_SCRIPT_DAY6.md` (mốc 4:40).
- `android/app/build.gradle.kts` ký release bằng debug key ⇒ artifact chỉ dùng demo/đánh giá nội bộ, không phải bản phát hành production.
- App không khai báo quyền runtime (xác minh qua manifest); camera qua Intent hệ thống, ảnh qua Photo Picker.

## 3. Nguyên tắc thực hiện

1. **Feature freeze:** chỉ sửa lỗi chặn demo/nộp, tài liệu, artifact và bằng chứng. Không refactor, không thêm tính năng.
2. **Bằng chứng tách biệt:** kết quả host, APK build, thiết bị thật, AVD, dịch vụ AI và video là các nguồn riêng; không suy nguồn này từ nguồn khác.
3. **Không giả lập:** nếu App Check/quota/thiết bị/công cụ quay không sẵn sàng, ghi `BLOCKED`/`NOT RUN` và trình bày trung thực; không tạo output AI giả hoặc video giả.
4. **Giữ thay đổi có trước:** không reset, clean, stash, checkout hay ghi đè; `docs/HOME_DEVICE_TEST_CHECKLIST.md` vẫn untracked và không bị stage.
5. **Không đưa secret vào bất kỳ đâu:** không token, debug token, serial/IP, prompt/response đầy đủ, ảnh/dữ liệu hiện trường, raw log.
6. **Dữ liệu demo tổng hợp:** chỉ dùng mô tả/ảnh tổng hợp; free tier có thể dùng dữ liệu để cải thiện sản phẩm Google.
7. **Mọi kết luận PASS phải có lệnh/quan sát thật trong phiên;** số liệu trong tài liệu cũ chỉ là lịch sử.
8. **Nộp trước hạn:** dành thời gian đệm cho lỗi link/xác thực/biểu mẫu; không để sát 23:59.

## 4. Trình tự công việc

### Task 1 — Baseline, feature freeze và chạy kiểm tra host trên đúng HEAD

**Các bước**

1. Xác nhận `git status --short --branch`, HEAD, upstream, remote; phân biệt staged/modified/untracked. Giữ nguyên checklist untracked.
2. Đọc lại mục Ngày 7 + checklist nộp trong `docs/CHALLENGE_VI_ROADMAP.md`, `docs/DEMO_SCRIPT_DAY6.md`, `docs/implement_plan_day6.md` và các phiếu kiểm thử Day 4–5.
3. Chốt phạm vi "chỉ sửa lỗi chặn nộp" và ghi rõ nếu có ngoại lệ.
4. Xác nhận môi trường: Flutter/Dart, Android SDK/platform-tools, thiết bị/AVD, công cụ quay màn hình; không ghi serial/IP/token.
5. Chạy trên đúng HEAD (ghi lệnh, exit code, số test, cảnh báo):

   ```powershell
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze --no-pub
   flutter test --no-pub --reporter compact
   flutter test test/local_report_repository_test.dart --no-pub --reporter compact
   ```

   Đây là lần chạy test đầu tiên cho source UI refresh; kết quả này thay thế mọi suy diễn từ số liệu Day 6.
6. Liệt kê danh sách việc chặn nộp (blocker) và quyết định mục nào sẽ xử lý, mục nào ghi `BLOCKED`.

**Đầu ra:** baseline gắn commit, kết quả host thật, danh sách blocker trước demo.

### Task 2 — Kiểm chứng bản build cuối và bản demo

**Các bước**

1. Build artifact cuối từ đúng HEAD. Mặc định dùng `flutter build apk --debug` (release đang ký debug key); nếu buộc dùng bản release thì ghi rõ "ký bằng debug key".
2. Ghi version, kích thước, SHA-256, cảnh báo build; đối chiếu artifact đích với output build.
3. Nếu có thiết bị/AVD phù hợp: `adb install -r` (không gỡ app, không clear data) và kiểm tra theo thứ tự ưu tiên:
   - mở app, form render, validation input rỗng (không phát sinh request);
   - một luồng tổng hợp: mô tả (+ ảnh nếu chọn được fixture) → **Phân tích bằng AI** (chỉ khi App Check token đã đăng ký và quota còn) → review/sửa → xác nhận lưu → History → detail;
   - loading/lỗi/retry và giữ dữ liệu khi lỗi;
   - PDF: Lưu PDF → chọn vị trí → mở lại tệp; Chia sẻ PDF → share sheet (ghi rõ nếu thiếu Zalo).
4. Nếu App Check/quota chặn: ghi `BLOCKED` cho case AI, không retry liên tục, không bật billing; chuẩn bị nhánh demo dự phòng trung thực (dừng ở thông báo lỗi/giữ input và giải thích).
5. Nếu có điều kiện và thời gian, kiểm tra carry-over: ảnh sau restart, save/read offline (chỉ tắt mạng khi có kênh điều khiển độc lập với Wi-Fi; nếu không, để `BLOCKED`).
6. Ghi kết quả từng case vào phiếu mới `docs/testcase_day7.txt` (hoặc cập nhật phiếu phù hợp), kèm môi trường, APK hash và trạng thái `PASS`/`PARTIAL`/`FAIL`/`BLOCKED`/`NOT RUN`.

**Đầu ra:** artifact cuối + hash + phiếu kết quả theo từng case, phân biệt host/AVD/thiết bị thật.

### Task 3 — Video demo dưới 5 phút

**Các bước**

1. Đối chiếu kịch bản `docs/DEMO_SCRIPT_DAY6.md` với UI hiện tại; nếu khác đáng kể, tạo `docs/DEMO_SCRIPT_DAY7.md`; nếu không, ghi chú dùng lại kịch bản Day 6.
2. Kịch bản mục tiêu (≤ 5:00): giới thiệu người dùng/vấn đề → nhập mô tả/chọn ảnh → AI (thật nếu chạy được; nếu lỗi thì trình bày nhánh lỗi và cách khôi phục) → review/sửa/xác nhận → lưu → History/detail → PDF → kiến trúc, giới hạn và hướng cải thiện.
3. Quay bằng công cụ thật (`adb shell screenrecord`, screen record của thiết bị/AVD hoặc công cụ desktop). Chỉ dùng dữ liệu tổng hợp; không để lộ debug token, thông báo hệ thống chứa thông tin cá nhân hoặc raw log.
4. Xem lại video: thời lượng < 5:00, chữ đọc được, không có màn chờ dài, nội dung khớp tính năng đã kiểm chứng.
5. Lưu video ở vị trí nộp phù hợp (link Drive/tệp nộp). **Không commit video hoặc file build lớn vào Git.**

**Đầu ra:** video tồn tại và đã được xem lại, hoặc `NOT RUN` với lý do rõ; script được cập nhật nếu cần.

### Task 4 — Riêng tư, secret và ẩn danh

**Các bước**

1. Quét working tree, staged diff, docs mới và file cấu hình công khai cho marker secret phổ biến (API key, private key, token, keystore). Chỉ báo đường dẫn/loại phát hiện, **không in giá trị**.
2. Xác nhận bản chất các file Firebase (`lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`): đây là cấu hình client nhận diện project, không phải Gemini Developer API key. Không có API key/secret mới được thêm trong Ngày 7.
3. Kiểm tra ảnh chụp màn hình, video và artifact không chứa: token, serial/IP, dữ liệu/ảnh hiện trường, tên/logo cá nhân.
4. Xóa tên/logo cá nhân khỏi các tệp sẽ chấm ẩn danh (README/docs/ảnh/video). Lưu ý: lịch sử Git và URL repo vẫn gắn tài khoản GitHub; viết lại lịch sử **không** nằm trong scope trừ khi chủ dự án yêu cầu repo ẩn danh riêng.
5. Không stage artifact ngoài repo (`D:\Download`), keystore, `.env`, raw log hoặc file build (`.gitignore` đã bỏ `build/`, `.dart_tool/`).

**Đầu ra:** kết quả scan có phạm vi, danh sách file đã ẩn danh, xác nhận không thêm secret.

### Task 5 — Đồng bộ tài liệu với bản build cuối

**Các bước**

1. Chạy lại đúng kịch bản demo trên bản build cuối; sửa README nếu mô tả khác hành vi quan sát được.
2. Sửa mâu thuẫn đang tồn tại: mục UI/UX trong `README.md` nêu 126/126 trong khi `docs/CONTEXT_SUMMARY.md` ghi test suite chưa chạy — cập nhật theo kết quả Task 1, gắn số test với đúng commit/lượt.
3. Thêm entry Ngày 7 vào `docs/AI_WORKLOG.md`: công cụ, việc đã làm, test/build/video thật, lỗi AI quan sát được (nếu có) và cách kiểm chứng, giới hạn còn lại. Không viết hồi cứu, không dựng ví dụ AI sai.
4. Rà `README.md`, `docs/CONTEXT_SUMMARY.md`, `docs/WALKTHROUGH.md`: phân biệt rõ **đã chạy / placeholder / chưa triển khai**; giữ nguyên các giới hạn ảnh persistence, offline, PDF và App Check production.
5. Rà liên kết Markdown cục bộ và tên tài liệu (ví dụ `docs/MANUAL_TESTCASES_APK.md` vs `docs/MANUAL_TESTCASES_APK_DEBUG.md`) để người đánh giá không mở sai file.
6. Không ghi lùi hoặc nâng nhãn kết quả: `PARTIAL`/`BLOCKED` vẫn giữ nguyên nhãn.

**Đầu ra:** bộ tài liệu khớp artifact và kết quả thật; worklog có entry Ngày 7.

### Task 6 — Đóng gói bài nộp và kiểm tra quyền truy cập

**Các bước**

1. Chốt sản phẩm nộp: APK/đường dẫn tải demo + source GitHub + README + video + `docs/AI_WORKLOG.md`.
2. Kiểm tra link tải/demo trong cửa sổ riêng tư hoặc trên thiết bị khác; xác nhận quyền truy cập và tệp mở được.
3. Chuẩn bị nội dung biểu mẫu nộp:
   - ít nhất một prompt đã dùng (ví dụ prompt sinh draft báo cáo);
   - mô tả quy trình ≥ 30 ký tự;
   - số giờ tiết kiệm ước tính **có căn cứ** (chỉ nêu nếu đã đo/ước lượng hợp lý, không bịa số);
   - quyết định bật/tắt chia sẻ showcase và nhật ký prompt.
4. Kiểm tra ẩn danh lần cuối trên đúng file/tệp sẽ nộp.

**Đầu ra:** checklist nộp đầy đủ, link đã xác nhận, bản nháp nội dung biểu mẫu.

### Task 7 — Nộp bài trước hạn và lưu bằng chứng

**Các bước**

1. Nộp trước 23:59 ngày 01/10/2026, không đợi phút cuối.
2. Lưu ảnh chụp/xác nhận nộp kèm thời điểm và link.
3. Push commit cuối (plan/docs/bằng chứng mới) lên `codex/day7`; kiểm tra remote SHA khớp HEAD; không force-push. Nếu `origin/main` thay đổi tiếp, fetch và xử lý không viết lại lịch sử.
4. Sau khi nộp, hạn chế sửa thêm; nếu buộc phải sửa, ghi rõ thời điểm và lý do.

**Đầu ra:** xác nhận nộp + trạng thái Git cuối + remote SHA đã đối chiếu.

## 5. Điều kiện nghiệm thu

- [ ] Baseline Ngày 7 gắn đúng commit; thay đổi có trước (checklist untracked) được giữ nguyên.
- [ ] Format/analyze/full test/SQLite FFI chạy trên đúng HEAD cuối và có kết quả thật; mâu thuẫn 126/126 được giải quyết.
- [ ] APK/artifact cuối có version + SHA-256; nếu cài thiết bị thì chỉ cài đè, không xóa dữ liệu.
- [ ] Kịch bản demo chạy được trên bản build cuối; case AI/PDF/ảnh/offline có nhãn đúng thực tế (`PASS`/`PARTIAL`/`BLOCKED`/`NOT RUN`).
- [ ] Video dưới 5 phút đã quay và xem lại, hoặc `NOT RUN` với lý do; không có video/output AI giả.
- [ ] Không phát hiện secret mới trong diff/tài liệu/ảnh/video; tên/logo cá nhân đã xử lý trên tệp nộp.
- [ ] README, `CONTEXT_SUMMARY.md`, `WALKTHROUGH.md`, `AI_WORKLOG.md` khớp bản build cuối và phân biệt rõ hoàn thành/chưa hoàn thành/giới hạn.
- [ ] Link sản phẩm đã kiểm tra trong cửa sổ riêng tư/thiết bị khác; biểu mẫu có prompt, mô tả ≥ 30 ký tự, số giờ tiết kiệm có căn cứ.
- [ ] Bài được nộp trước 23:59 01/10/2026 và có bằng chứng nộp.
- [ ] Nhánh `codex/day7` được push; remote SHA khớp local sau commit cuối.

## 6. Ranh giới bằng chứng

| Nguồn | Chứng minh được | Không chứng minh được |
|---|---|---|
| Widget/service test (fake) | Logic UI, parser, retry, ánh xạ lỗi | Mạng, Gemini, App Check, plugin Android |
| SQLite FFI trên Windows | Hợp đồng repository, retry/conflict | `sqflite`/`path_provider` trên Android |
| APK build exit 0 | Compile/đóng gói thành công | App chạy đúng trên thiết bị, AI/PDF hoạt động |
| AVD/emulator | Smoke UI, cài đặt | UX vật lý, camera/Photo Picker, hiệu năng máy thật |
| Request Gemini thật | Dịch vụ/App Check/quota tại thời điểm chạy | Tính ổn định lâu dài, các đầu vào khác |
| Video demo | Luồng đã diễn ra trong bản quay | Mọi trường hợp và mọi thiết bị |

Nếu một mục không có bằng chứng đúng mức, ghi `BLOCKED`/`NOT RUN` thay vì suy diễn hoặc đổi nhãn.

## 7. Điều kiện dừng

- Dừng build/kiểm tra nếu HEAD hoặc artifact không khớp source đang xét.
- Dừng case AI nếu App Check/quota không rõ hoặc lỗi lặp lại; không tắt App Check, không bật billing, không retry liên tục.
- Dừng case offline nếu không có kênh điều khiển độc lập với Wi-Fi.
- Dừng case ảnh nếu fixture tổng hợp không xuất hiện trong Photo Picker; không dùng media cá nhân.
- Dừng quay nếu video sẽ lộ token/dữ liệu nhạy cảm hoặc vượt 5 phút mà không cắt được.
- Dừng và báo blocker nếu phát hiện secret trong file/artifact; không sao chép giá trị vào chat/tài liệu.
- Dừng mọi thay đổi tính năng: nếu phát hiện lỗi không chặn nộp, ghi vào phần "hướng cải thiện" thay vì sửa trong Ngày 7.

## 8. Rủi ro và phương án dự phòng

| Rủi ro | Phương án |
|---|---|
| App Check chặn request thật khi quay demo | Đăng ký lại debug token trong Console trước; nếu vẫn chặn, quay nhánh lỗi trung thực + giải thích; không giả AI. |
| Quota model chính cạn | Fallback `gemini-3.5-flash-lite` đã có; ghi rõ model dùng thực tế nếu quan sát được; không hứa chất lượng. |
| Không có thiết bị thật | Dùng AVD và ghi rõ giới hạn; không tuyên bố UX vật lý; ưu tiên video từ AVD nếu không còn lựa chọn. |
| Không có công cụ quay | Thử `adb shell screenrecord`/screen record hệ thống; nếu thất bại, giữ script và đánh dấu video `NOT RUN`, không tạo video giả. |
| Hết thời gian trước hạn | Thứ tự ưu tiên: (1) nộp được + tài liệu chính xác, (2) README/worklog khớp, (3) video, (4) UX đầy đủ, (5) PDF/ảnh/offline. Ghi rõ phần bỏ qua. |
| Push cần xác thực và bị chặn | Giữ commit local, không lưu credential, báo chính xác bước đăng nhập cần thiết. |
| `origin/main` tiếp tục thay đổi | Branch day7 tách từ `a8026ff`; fetch trước khi push, chỉ fast-forward, không force/viết lại lịch sử. |
| Tài liệu còn mâu thuẫn (ví dụ số test) | Sửa theo kết quả thật của Task 1; không giữ hai con số khác nguồn trong cùng mô tả. |

**Thứ tự ưu tiên gợi ý trong ngày:** Task 1 → Task 2 → Task 4/5 (song song với chờ build) → Task 3 (quay) → Task 6 → Task 7. Không bắt đầu Task 3 khi chưa có bản build cuối.

## 9. Lệnh dự kiến (chưa chạy trong phiên lập kế hoạch này)

```powershell
# Kiểm tra host
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub --reporter compact
flutter test test/local_report_repository_test.dart --no-pub --reporter compact

# Artifact cuối
flutter build apk --debug --no-pub

# Thiết bị (nếu có)
adb devices -l
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk

# Git cuối ngày
git status --short --branch
git log --oneline -3
git ls-remote --heads origin codex/day7
```

- Chỉ chạy lệnh phù hợp với môi trường thực tế; ghi chính xác lệnh nào đã chạy và kết quả.
- Không chạy `flutter build apk --release` trừ khi cần artifact nộp và chấp nhận ghi rõ "debug-signed".
- Không đưa `<device-id>` thật, serial hoặc IP vào tài liệu chia sẻ.
