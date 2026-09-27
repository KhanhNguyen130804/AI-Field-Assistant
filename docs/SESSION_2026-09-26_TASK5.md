# Tổng kết phiên — 2026-09-26/27: Task 5 Ngày 3 và sự cố vận hành AI

> File này là bản ghi phiên chat giữa chủ dự án và coding agent (ZCode, model GLM) cho Task 5 Ngày 3, gồm: triển khai, các sự cố gặp trên thiết bị thật, chẩn đoán, fix và trạng thái cuối. Tài liệu chuẩn tắc vẫn ở `AGENTS.md`, `docs/implement_plan_day3.md`, `docs/AI_WORKLOG.md` và `docs/CONTEXT_SUMMARY.md` (đã cập nhật đồng bộ theo phiên này).

## 1. Phạm vi phiên

1. Khảo sát repo (không sửa) — báo cáo trạng thái dự án đầu phiên.
2. Triển khai **Task 5 Ngày 3** đúng kế hoạch trong `docs/implement_plan_day3.md`.
3. Viết bộ test case thủ công cho luồng AI trên thiết bị thật (`docs/MANUAL_TESTCASES_TASK5.md`).
4. Chẩn đoán và xử lý 2 sự cố khi chủ dự án test trên điện thoại: thông báo lỗi sai nguyên nhân (App Check) và quota hết (limit 20/ngày).
5. Triển khai **model fallback** giải bài toán "chất lượng cao + hạn mức thấp".
6. Ghi nhận trạng thái và cập nhật tài liệu (chính là phần này).

## 2. Task 5 đã triển khai — những gì chạy được

**Files mới:**

- `lib/screens/report_draft_screen.dart` — màn hình "Bản nháp AI": tiêu đề **"Bản nháp AI — cần kiểm tra, chưa lưu"**; chỉ hiển thị trường có nội dung; `needs_confirmation` hiện thành khối cảnh báo + badge "Cần xác nhận" từng trường; `suggested_action` kèm dòng "Đây là hành động đề xuất, chưa phải việc đã thực hiện."; phần "Mô tả bạn đã nhập" và "Ảnh bạn đã chọn" hiển thị đầu vào gốc; **không có nút lưu/sửa/xác nhận** (thuộc ngày sau).
- `lib/widgets/status_notice.dart` — widget thông báo dùng chung (info/error), trích từ `_StatusNotice` cục bộ cũ.
- `docs/MANUAL_TESTCASES_TASK5.md` — 31 test case thủ công cho luồng AI trên thiết bị thật (mục 0–8 + bảng ghi kết quả).

**Files sửa:**

- `lib/screens/create_report_screen.dart` — CTA **"Phân tích bằng AI"** (`analyze-button`): chặn mô tả+ảnh rỗng; chặn ảnh > 4 MiB **trước khi gọi service** (thông báo "Ảnh vượt quá giới hạn 4 MiB để gửi phân tích…"); loading (`LinearProgressIndicator` + dòng "Đang phân tích…") và **khóa cả 4 nút** trong lúc chạy; lỗi hiện thông báo tiếng Việt từ `ReportDraftException`, **giữ nguyên mô tả + ảnh**, bấm lại được (retry thủ công); helper text form đổi thành "Mô tả và ảnh chỉ được gửi khi bạn bấm 'Phân tích bằng AI'."; khối thông báo rõ dữ liệu gửi tới Gemini.
- `lib/services/gemini_report_service.dart` — xuất public constant `maxImageBytesForAi` (4 MiB); thêm log chẩn đoán debug-only (`ReportDraft request failed: …` trong `kDebugMode`, không log prompt/ảnh); **sửa bug ánh xạ lỗi App Check** (chi tiết mục 4); **thêm model fallback** (chi tiết mục 6); seam `senderFactory` thay `modelFactory`.
- `lib/main.dart` — seam `reportService` truyền qua app widget cho widget test.
- `test/widget_test.dart` — thêm 8 widget test: chặn input rỗng, thành công mở draft, `needs_confirmation` + badge, nhãn suggested_action, loading khóa nút + giữ input, lỗi service giữ input + retry, lỗi timeout/quota, chặn ảnh 4 MiB, viewport hẹp. `_FakeReportService` extend `GeminiReportService`.
- `test/gemini_report_service_test.dart` — thêm test ánh xạ `FirebaseException` App Check thật và 3 test fallback.

**Kiểm chứng tự động (đã chạy, cuối phiên):** `dart format` sạch; `flutter analyze` — No issues; `flutter test` — **45/45 đạt** (13 widget + 5 model + 27 service, gồm cả test fallback); `flutter build web --release` và `flutter build apk --debug` thành công; APK đã cài và chạy trên điện thoại thật.

**Kiểm chứng thiết bị thật (bằng chứng từ `adb` + uiautomator dump, agent tự lái qua adb):**

- Luồng đầu-cuối chạy thật: nhập mô tả → bấm Phân tích → **màn hình "Bản nháp AI" mở với response Gemini thật**.
- Case mô tả mơ hồ (chỉ "Mayg"): AI trả đủ 6 trường rỗng + `needs_confirmation` toàn bộ — **không bịa dữ kiện** (TC-5.2.5 PASS).
- Case mô tả rõ ("Máy lạnh ở khu vực lễ tân không hoạt động"): draft có Sự cố "Máy lạnh không hoạt động", Địa điểm "Khu vực lễ tân", Hành động đề xuất phù hợp; priority null + cần xác nhận — không tự mặc định.
- Back từ draft về form: mô tả + ảnh giữ nguyên; phân tích lại được.

## 3. Task 5 — phần chưa làm / còn lại

- **Chưa chạy trọn bộ 31 test case thủ công** trong `docs/MANUAL_TESTCASES_TASK5.md`; mới có bằng chứng PASS cho một số case (5.2.1/5.2.5 và một phần mục 3/4/5 qua các lần chẩn đoán). Chủ dự án tiếp tục test theo bảng kết quả trong file đó.
- Các case gián đoạn (chuyển tab/xoay màn/Home giữa loading) vẫn ở trạng thái "ghi nhận hành vi thật", chưa chốt hành vi đúng.
- Nút **Xem lại đầu vào** đã có; chưa kiểm tra lại toàn bộ regression mục 6 của file test case trên bản Task 5.
- Chưa commit — giữ nguyên theo yêu cầu chủ dự án trước đây.

## 4. Sự cố 1 — "Không thể phân tích lúc này" dù có mạng

**Triệu chứng:** chủ dự án bấm Phân tích, app báo lỗi mạng; internet điện thoại bình thường.

**Chẩn đoán (agent tái hiện qua adb trên điện thoại thật):**

- Thêm log chẩn đoán debug-only vào service (giữ lại vĩnh viễn), build + cài + chạy qua `adb input`/`logcat`, bắt được lỗi gốc:
  `DebugAppCheckProvider: Failed to exchange debug token (4ce5d93c-…)` và
  `ReportDraft request failed: [firebase_app_check/unknown] … code: 403 body: App attestation failed.`
- **Nguyên nhân gốc:** App Check debug token của lần cài hiện tại chưa được đăng ký trong Firebase Console (cài đè/gỡ cài có thể đổi token). **Bug kèm theo trong app:** exception này là `FirebaseException` của plugin `firebase_app_check` (không phải `FirebaseAIException`), message chứa `app_check`/`App attestation` — `_mentionsAppCheck` cũ chỉ tìm `appcheck`/`app check` nên rơi vào nhánh "lỗi mạng chung", gây hiểu nhầm.

**Fix:**

- `_mapError` thêm case `FirebaseException`: plugin chứa `app_check` hoặc message nhắc App Check/attestation → `ReportDraftAppCheckException` (thông báo đúng: "Ứng dụng chưa được xác minh với dịch vụ AI (App Check)…").
- `_mentionsAppCheck` nhận message nullable + chuỗi hóa cả `-` và `_` + nhận diện "app attestation"/"attestation failed".
- Chủ dự án đã đăng ký token trong Console (bên ngoài phiên). Xác minh sau fix: màn hình hiển thị đúng thông báo App Check khi token chưa hợp lệ; khi token đã đăng ký, request đi được.

## 5. Sự cố 2 — "Đã đạt giới hạn số lần phân tích" (quota)

**Chẩn đoán:**

- Tái hiện qua adb; log cho thấy request Gemini **thành công sau khi qua cửa sổ quota** — thông báo quota của app ánh xạ đúng lỗi 429 thật.
- Screenshot Google Cloud Console của chủ dự án xác nhận: quota chặn là **"Request limit per model per day for a project in the free tier" — model `gemini-3.8-flash`, limit 20, dùng 24 (100%)**; các dòng RPM vùng Asia đều Unlimited. Kết luận: quota **ngày, theo model**, thuộc Gemini Developer API free tier — không phải RPM Firebase AI Logic đã hạ ở Task 1; **không thể sửa từ mã**.
- Chú ý: các request 429 thất bại cũng bị đếm vào usage, nên test tràn sẽ tự đẩy nhanh cạn quota.

**Xử lý ngắn hạn:** chờ reset (midnight Pacific ≈ 14:00–15:00 giờ VN) hoặc chủ dự án chỉnh Edit quota trong Console (dòng "Adjustable: Yes").

## 6. Model fallback — giải pháp cuối cùng cho quota

**Vấn đề:** `gemini-3.8-flash` chất lượng tốt (nhận đúng sự cố từ ảnh) nhưng free tier chỉ **20 request/ngày**; `gemini-3.5-flash-lite` có **500 request/ngày** nhưng giảm chất lượng rõ rệt với cùng ảnh.

**Giải pháp đã triển khai (cả hai model dùng song song, tự động):**

- **Model chính** `gemini-3.8-flash` — chạy trước mọi request.
- Khi gặp lỗi quota (429/RESOURCE_EXHAUSTED/quota — ánh xạ qua `ReportDraftQuotaException` hoặc `QuotaExceeded`), **tự động thử `gemini-3.5-flash-lite` trong cùng lần bấm**, kèm log debug "primary quota exhausted, trying fallback".
- Lỗi **không phải quota** (blocked/App Check/500/timeout…) **không trigger fallback** — tránh che lỗi thật.
- Fallback cũng fail → ánh xạ lỗi fallback (fallback 429 → giữ thông báo quota).
- Mỗi model một `_GenerativeModelSender` riêng, tạo lười; seam `senderFactory(String)` cho test; giữ `requestSender` ưu tiên cao nhất cho widget test cũ.

**Kiểm chứng trên thiết bị thật (log 2026-09-27 04:24):**

```
I flutter: ReportDraft request failed: You exceeded your current quota…
I flutter: * Quota exceeded for metric: …generate_content_free_tier_requests, limit: 20, model: gemini-3.8-flash
I flutter: ReportDraft: primary quota exhausted, trying fallback (gemini-3.5-flash-lite)
→ Màn "Bản nháp AI" mở thành công
```

Draft từ fallback đủ trường, có badge "Cần xác nhận" cho trường AI chưa chắc — đúng cơ chế draft-chờ-xác-nhận.

**Hệ quả cần biết:** khi chạy trên fallback, chất lượng thấp hơn (đánh dấu cần xác nhận nhiều hơn). Người dùng không bị chặn; các request quan trọng (demo chấm điểm) nên thực hiện khi 3.8-flash còn quota (reset ~14:00–15:00 giờ VN) hoặc nâng quota trong Console.

## 7. Thay đổi hành vi/Giới hạn mới phát hiện trong phiên

- Nút Phân tích/Chụp ảnh/Chọn ảnh/Xem lại đều **disabled khi đang phân tích hoặc đang mở picker**.
- Helper text form và khối thông báo cuối form đã đổi để phản ánh đúng luồng gửi AI.
- `adb input text` không gõ được dấu cách trực tiếp — dùng mã hóa `%s` khi lái UI qua adb (ghi chú cho việc tái hiện test tự động).
- Logcat buffer điện thoại này 256 KiB trôi rất nhanh — phải dùng logcat streaming (`background_process`) hoặc lọc ngay sau tap khi chẩn đoán.
- Web debug provider App Check vẫn chưa verify; provider production chưa cấu hình (giữ nguyên như Task 3).

## 8. Trạng thái Git cuối phiên

- Nhánh `task/day3-firebase-ai-logic`; **chưa commit** phần Task 5.
- Modified: `lib/main.dart`, `lib/screens/create_report_screen.dart`, `lib/services/gemini_report_service.dart`, `test/gemini_report_service_test.dart`, `test/widget_test.dart`.
- Untracked: `docs/MANUAL_TESTCASES_TASK5.md`, `docs/SESSION_2026-09-26_TASK5.md` (file này), `lib/screens/report_draft_screen.dart`, `lib/widgets/`, cùng các docs cập nhật kèm phiên.
- HEAD vẫn là `509d6d5` (sync docs Task 4).

## 9. Việc tiếp theo gợi ý

1. Chủ dự án chạy tiếp `docs/MANUAL_TESTCASES_TASK5.md` (còn lại mục 3–6), ghi kết quả vào bảng.
2. Commit Task 5 khi chủ dự án yêu cầu (tách commit code / docs theo thông lệ trước đây).
3. Task 6: smoke test chính thức — đã có bằng chứng đầu-cuối từ phiên này nhưng nên chạy đủ bộ synthetic và ghi bảng vào worklog.
4. Task 7: rà tài liệu lần cuối ngày 3 (phần lớn đã sync trong phiên này).
5. Ngày 4: màn hình sửa/xác nhận + lưu cục bộ (draft hiện chỉ xem được, chưa sửa/lưu).
