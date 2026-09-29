# Kế hoạch triển khai — Ngày 4: Chỉnh sửa, xác nhận, lưu cục bộ và lịch sử

> **Trạng thái cập nhật (2026-09-29):** Task 1–6 đã triển khai. Task 7 được chủ dự án đánh dấu hoàn thành với ngoại lệ được chấp nhận: automated checks và text-only AI → review → save → History/detail → force-stop/relaunch đạt; marker còn sau restart. Persistence ảnh Android chưa kiểm chứng vì fixture không xuất hiện trong Photo Picker; offline chưa chạy do chỉ có ADB Wireless. Task 8 cập nhật tài liệu/bàn giao xong; nghiệm thu đầy đủ Ngày 4 vẫn thiếu các case ảnh/offline. Chi tiết từng case ở docs/testcase_task7_persistence_day4.txt.
>
> **Phạm vi:** Hoàn thiện MVP Android từ bản nháp AI đến báo cáo đã được người dùng xác nhận, lưu bền vững và mở lại trong lịch sử. Giữ Flutter và Firebase AI Logic hiện có; không thêm đăng nhập, đồng bộ cloud, voice/GPS, push notification hoặc backend mới.

## 1. Mục tiêu Ngày 4

Hoàn thiện lát chức năng có thể kiểm chứng:

```text
Nhập mô tả/chọn ảnh → Gemini tạo ReportDraft
  → xem đầu vào gốc, chỉnh sửa từng trường
  → bổ sung/xác nhận thông tin hoặc xác nhận không có dữ liệu
  → kiểm tra điều kiện lưu + người dùng chủ động xác nhận báo cáo
  → lưu nội dung vào database cục bộ và sao chép ảnh vào thư mục ứng dụng
  → Lịch sử → Chi tiết báo cáo
  → đóng/mở ứng dụng → báo cáo và ảnh vẫn đọc được
```

Ngày 4 được xem là hoàn thành khi người dùng thực hiện được toàn bộ luồng trên trên Android, lỗi lưu/đọc được xử lý rõ ràng và kết quả kiểm chứng được ghi trung thực. AI vẫn chỉ tạo bản nháp; mở màn kết quả hoặc sửa một trường không đồng nghĩa đã xác nhận toàn bộ báo cáo.

Không thêm sửa/xóa báo cáo đã lưu trong phạm vi bắt buộc. Nếu bổ sung xóa sau này, phải có xác nhận trước khi xóa và quản lý ảnh liên quan. Không tuyên bố tạo báo cáo AI được khi mất mạng; chỉ kiểm chứng khả năng xem lịch sử và lưu draft đã có mà không cần request AI mới.

## 2. Hiện trạng và quyết định đã có

- `lib/main.dart` khởi tạo Firebase, kích hoạt App Check trong debug, có hai tab qua `NavigationBar`/`IndexedStack`, tạo repository dùng chung cho form và HistoryScreen. `lib/screens/history_screen.dart` đọc danh sách khi vào tab/refresh, phân biệt loading/empty/error và hỗ trợ retry; Web hiện rõ không hỗ trợ persistence.
- `lib/screens/create_report_screen.dart` nhập mô tả, chọn/chụp một ảnh, preview, xem lại đầu vào và gọi `GeminiReportService`; thành công push `ReportDraftScreen`.
- `lib/screens/report_draft_screen.dart` cho sửa sáu trường, review riêng từng trường, xác nhận trường tùy chọn trống, giữ `issue` bắt buộc và yêu cầu review lại summary sau khi dữ kiện đổi; hiển thị draft AI, danh sách `needs_confirmation`, nhãn hành động đề xuất và mô tả/ảnh gốc.
- `ReportDraft` có parser/serializer cho sáu trường nội dung và `needs_confirmation`. Constructor tự thêm trường rỗng/null vào danh sách này; không dùng trực tiếp nó để biểu diễn báo cáo đã xác nhận không có thông tin.
- Task 3 đã thêm repository/database SQLite và path ảnh bền vững; Task 4 nối repository vào luồng lưu. Lưu yêu cầu người dùng xác nhận cuối, khóa thao tác trong lúc ghi, giữ nội dung/retry cùng ID khi lỗi, và chỉ xóa form nguồn sau khi lưu thành công. Task 5 nối danh sách lịch sử; Task 6 mở màn chi tiết theo ID. Task 7 đã xác minh một report text-only còn trong History/detail sau force-stop/relaunch trên Android; ảnh và hoạt động khi offline chưa xác minh.
- Luồng Gemini thật, App Check Android debug và fallback quota có **bằng chứng lịch sử Task 5 Ngày 3**. Task 3 đã xác minh test SQLite FFI 10/10, toàn suite 77/77 và APK/Web build thành công. ADB smoke ngày 28/09 dùng APK trước Task 4; Task 4 có các kết quả 85/85, PHONE/ADB/APK được ghi ở phần lịch sử bên dưới. Lượt triển khai Task 5 Ngày 4 kiểm tra format 5 file Dart (0 đổi), `flutter analyze` sạch, `flutter test test/history_screen_test.dart` 5/5 và toàn suite 90/90; widget tests dùng fake repository. Lượt ADB Wireless sau đó build/cài APK debug và kiểm tra thiết bị, không chạy lại analyze/test. Kết quả từng ADB case, hash APK và giới hạn được ghi trong `docs/testcase_task5_history_day4.txt` và `docs/AI_WORKLOG.md`.
- Git đầu Task 3 sạch, nhánh `codex/day4-preflight`, HEAD `155c223`. Kiểm tra lại trước mỗi task; không reset/restore/clean/stash hoặc ghi đè thay đổi mới của người dùng.

**Quyết định Task 1:** SQLite qua sqflite cho báo cáo có cấu trúc; ảnh lưu riêng trong thư mục application support qua path_provider, database giữ đường dẫn tương đối và dùng path để ghép/kiểm tra đường dẫn. Các phiên bản sqflite 2.4.4, path_provider 2.1.6, path 1.9.1 và dev dependency sqflite_common_ffi 2.4.3 được chốt bằng dry-run ở Task 1, sau đó đã thêm/resolve ở Task 3. APK/Web build và SQLite FFI test Windows thành công. Bằng chứng Android Task 7 hiện xác nhận được text-only save/read qua restart; ảnh và offline vẫn chưa xác minh.

**Web:** giữ khả năng preview UI và test qua repository inject; persistence Android là tiêu chí bắt buộc. Nếu lựa chọn SQLite không hỗ trợ Web trong cấu hình này, hiển thị rõ giới hạn và vô hiệu hóa thao tác lưu trên Web, không tự lưu vào RAM rồi báo thành công. Không mở rộng sang backend lưu Web để hoàn thành Ngày 4.

## 3. Quy tắc schema, xác nhận, dữ liệu và bảo mật

### Nội dung và metadata

- Giữ tên field lõi: `category`, `location`, `priority`, `issue`, `suggested_action`, `summary`.
- `priority` chỉ là `low`, `medium`, `high` hoặc `null`; không tự mặc định.
- Báo cáo lưu có metadata tối thiểu: ID ổn định, `created_at` UTC, trạng thái đã xác nhận, mô tả đầu vào gốc nếu có và đường dẫn ảnh tương đối nếu có.
- Lưu thêm danh sách field người dùng đã xác nhận không có thông tin để phân biệt giá trị trống đã được xử lý với field còn thiếu. Không dùng nhãn “đã xác nhận” cho draft chưa hoàn tất review.
- Không cần lưu một bản sao đầy đủ output AI để làm audit trong Ngày 4; không thêm dữ liệu ngoài mục đích báo cáo. Mô tả/ảnh gốc dùng để đối chiếu trong app, không log ra ngoài.

### Điều kiện trước khi lưu

| Trường/trạng thái | Điều kiện |
|---|---|
| `issue` | Bắt buộc có nội dung sau `trim()` và đã được người dùng xem lại; không có lựa chọn xác nhận trống. |
| `category`, `location`, `suggested_action`, `summary` | Có nội dung được người dùng chấp nhận, hoặc xác nhận rõ không có/không xác định được và giữ trống. |
| `priority` | Chọn giá trị hợp lệ hoặc xác nhận chưa xác định được và giữ `null`. |
| `needs_confirmation` | Mỗi mục phải được xử lý; chỉ sửa nội dung không tự hoàn tất xác nhận. |
| Nội dung có sẵn do AI tạo | Người dùng phải xem lại; danh sách AI rỗng không có nghĩa nội dung đã đúng hoặc đã được xác nhận. |
| Xác nhận cuối | Người dùng chủ động bấm lưu và xác nhận đã kiểm tra nội dung; không lưu tự động khi mở draft. |

- UI cho phép xác nhận từng trường, kể cả trường có nội dung nhưng AI đánh dấu chưa chắc. Hiển thị tách biệt “AI cần bạn xem lại”, “Đã xác nhận” và “Đã xác nhận không có thông tin”.
- Khi sửa một trường sau xác nhận, hủy xác nhận của trường đó. Khi nhập dữ liệu vào trường đã xác nhận trống, bỏ trạng thái xác nhận trống và yêu cầu xem lại giá trị mới.
- `suggested_action` luôn giữ nhãn đề xuất, kể cả trong báo cáo đã lưu; người dùng xác nhận nội dung đề xuất không đồng nghĩa đã thực hiện công việc đó.
- `summary` có nội dung chỉ được xác nhận sau các trường dữ kiện liên quan. Khi các trường nội dung khác thay đổi, hủy xác nhận summary và yêu cầu sửa/xóa/xác nhận lại để tránh lưu tóm tắt lỗi thời. Không tự gọi Gemini để viết lại summary; nếu người dùng không xác nhận được thì cho xóa và xác nhận không có tóm tắt.
- Validation có thể kiểm tra cấu trúc, field rỗng và trạng thái review; **không thể tự chứng minh summary đúng về ngữ nghĩa**. UI yêu cầu người dùng đối chiếu với dữ kiện đã xác nhận, không tuyên bố đã kiểm chứng bằng thuật toán.

### Lưu trữ và lỗi

- ID được giữ ổn định trong một phiên lưu/thử lại; chặn double-tap và tránh tạo báo cáo trùng khi kết quả lần lưu trước chưa rõ.
- Ảnh picker là file tạm. Phải tạo bản sao thuộc ứng dụng trước khi coi lưu hoàn tất; không di chuyển/xóa ảnh nguồn hoặc thay ảnh preview của người dùng.
- Database và filesystem không có chung transaction: cần trình tự sao chép ảnh → transaction ghi báo cáo → trả kết quả; thất bại phải xử lý rollback/ảnh mồ côi ở mức phù hợp, không thông báo thành công một phần.
- Lưu lỗi giữ nguyên form chỉnh sửa và trạng thái review để thử lại; không pop route hoặc xóa input. Thiếu ảnh đã lưu khi đọc lại phải có fallback, vẫn xem được nội dung báo cáo.
- Không log prompt, nội dung báo cáo, ảnh, đường dẫn riêng tư, key/token hoặc raw response. Không thay đổi Firebase project, App Check enforcement, billing/quota để thực hiện persistence.
- Lưu cục bộ không đồng nghĩa mã hóa, backup hoặc đồng bộ; gỡ app/xóa dữ liệu có thể mất báo cáo. Chưa tuyên bố bảo vệ dữ liệu nhạy cảm hoặc hỗ trợ dữ liệu hiện trường thật trên luồng AI free tier.

## 4. Task triển khai

### Task 1 — Preflight, chốt hợp đồng dữ liệu và phương án lưu

**Mục tiêu:** thống nhất state review, model đã lưu, API repository và nền tảng hỗ trợ trước khi viết persistence.

**Trạng thái:** Hoàn tất preflight/quyết định ngày 2026-09-27. Chưa triển khai các class/schema dưới đây; đây là hợp đồng cho Task 2–3.

**Cần làm:**

1. Đọc AGENTS/roadmap/context/plan, kiểm tra Git diff và mã hiện tại; bảo toàn mọi thay đổi người dùng.
2. Kiểm tra Flutter/Dart, Android tooling và thiết bị; ghi rõ công cụ thiếu thay vì tạo kết quả kiểm chứng giả.
3. Chốt tách `ReportDraft` khỏi model báo cáo đã xác nhận và state chỉnh sửa. Không sửa parser để bỏ xác nhận field thiếu chỉ nhằm lưu được.
4. Chốt schema SQLite phiên bản 1, ID ổn định, UTC timestamp, serialization priority, field xác nhận trống và đường dẫn ảnh tương đối. Không thêm migration giả cho phiên bản chưa tồn tại.
5. Chốt API repository tối thiểu: lưu một báo cáo đã hợp lệ, lấy danh sách mới nhất trước, đọc chi tiết theo ID; lỗi có thể chuyển thành thông báo UI. Chưa thêm CRUD tổng quát/framework lớn.
6. Kiểm tra dependency đề xuất; chọn cách kiểm thử SQLite thật trên host nếu phù hợp (có thể dùng adapter FFI chỉ cho test), hoặc integration test Android. Fake repository chỉ kiểm thử UI, không thay thế test database thật.
7. Chốt factory repository theo nền tảng: Web preview có giới hạn rõ; không để khởi tạo storage không hỗ trợ làm app crash trước khi mở UI.

**File dự kiến:** cập nhật phần quyết định của file kế hoạch này; `pubspec.yaml`/`pubspec.lock` chỉ khi dependency đã được chọn; README nếu có quyết định kiến trúc/giới hạn mới.

**Tránh:** gọi AI để chọn database, thêm Firestore/Auth, lưu báo cáo trong preferences như cơ sở dữ liệu hoặc fallback RAM giả như persistence.

**Kiểm thử/tiêu chí hoàn thành:** có hợp đồng dữ liệu/review/repository rõ, phiên bản dependency tương thích và phương án kiểm chứng storage thực. Ghi rõ Android bắt buộc và Web có/không hỗ trợ persistence.

**Kết quả Task 1 — hợp đồng đã chốt:**

#### A. Model và state review

- Giữ nguyên `ReportDraft` và parser AI; không dùng model này để deserialize báo cáo đã xác nhận trống.
- `ReportReview` (Task 2): giữ giá trị đang sửa, danh sách AI cần review ban đầu và trạng thái người dùng cho từng field: `pending`, `confirmedValue`, `confirmedAbsent`. Khởi tạo cả sáu field là `pending`, kể cả khi AI trả `needs_confirmation: []`.
- `confirmedValue` chỉ áp dụng với text không rỗng/priority hợp lệ; `confirmedAbsent` chỉ áp dụng với text rỗng/priority null và không áp dụng cho `issue`. Sửa giá trị hủy xác nhận field đó và xác nhận cuối; sửa field khác summary cũng hủy xác nhận summary. Summary có nội dung chỉ xác nhận được sau năm field còn lại đã review.
- Xác nhận trống là thao tác riêng, không tự xóa text đang có. Người dùng phải xóa/chọn null trước rồi xác nhận không có thông tin; UI không đánh dấu trống trong khi vẫn giữ giá trị có nội dung.
- `Report` (Task 2): immutable, chứa sáu field, `id`, `createdAt` UTC, `status = confirmed`, `sourceDescription`, `photoPath` nullable và `confirmedAbsentFields`. Toàn bộ nội dung được kiểm tra khi tạo đối tượng hợp lệ và khi deserialize; trạng thái review từng field chỉ sống trong editor, không cần lưu bản sao review/AI output.
- `confirmedAbsentFields` gồm **đúng các field tùy chọn hiện trống/null** đã được xác nhận, không chứa `issue`, không có tên lạ/trùng hoặc field đang có nội dung. Field nội dung khác được coi đã được người dùng chấp nhận khi report có trạng thái `confirmed` và xác nhận cuối đã hoàn tất. Báo cáo đã lưu không có `needs_confirmation` đang chờ xử lý.
- ID tạo bằng 16 byte `Random.secure()` từ Dart, encode base64url không padding; không thêm package UUID. ID gồm 22 ký tự an toàn cho tên file, validate trước khi ghép đường dẫn. Tạo ID/thời gian khi chốt snapshot cho lần lưu đầu tiên, không tạo lại khi retry cùng snapshot.
- Snapshot lưu gồm nội dung đã trim, review hoàn tất và bản sao bytes ảnh từ editor (nếu có). Snapshot là bất biến trong lần lưu/retry; nếu sửa nội dung sau lỗi phải giải quyết kết quả của ID cũ trước, rồi tạo snapshot/ID mới. Không dùng cùng ID để cập nhật một báo cáo đã lưu.

#### B. SQLite schema version 1

Database `reports.db` trong thư mục application support của app, bảng `reports`; schema version 1 được tạo qua `onCreate`. SQL sau là hợp đồng được triển khai ở Task 3:

```sql
CREATE TABLE reports (
  id TEXT NOT NULL PRIMARY KEY,
  category TEXT NOT NULL,
  location TEXT NOT NULL,
  priority TEXT CHECK (priority IS NULL OR priority IN ('low', 'medium', 'high')),
  issue TEXT NOT NULL CHECK (length(trim(issue)) > 0),
  suggested_action TEXT NOT NULL,
  summary TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status = 'confirmed'),
  source_description TEXT NOT NULL,
  photo_path TEXT,
  confirmed_absent_fields TEXT NOT NULL
);
CREATE INDEX reports_created_at_id ON reports(created_at DESC, id DESC);
```

- `created_at` là millisecondsSinceEpoch UTC, chỉ chuyển sang giờ địa phương khi hiển thị. Query danh sách dùng `ORDER BY created_at DESC, id DESC`.
- `confirmed_absent_fields` là JSON array tên field; kiểm tra bằng Dart, không phụ thuộc SQLite JSON extension. SQL constraint là lớp phụ, không thay validation Dart cho Unicode whitespace/schema/review.
- `source_description` có thể rỗng với image-only. `photo_path` là null với text-only; khi có ảnh chỉ nhận đường dẫn tương đối dưới `report_photos/`, không chứa `..`, không nhận path tuyệt đối/tùy ý từ UI hoặc picker.
- Deserialize gặp dữ liệu sai phải trả lỗi storage có thể hiển thị/retry; không coi là draft mới, không tự điền default hoặc reset DB.

#### C. API repository và vòng đời lưu ảnh

Hợp đồng Dart dự kiến (chưa có file implementation):

```dart
abstract interface class ReportRepository {
  Future<Report> save(Report report, {Uint8List? imageBytes});
  Future<List<Report>> listReports();
  Future<Report?> findById(String id);
  Future<void> close();
}
```

- Input `save`: Report đã qua review/xác nhận cuối, `photoPath = null`; bytes ảnh nullable, snapshot có ID và thời gian ổn định. Repository kiểm tra input, tạo đường dẫn ảnh thuộc app và trả Report có `photoPath` sau khi commit. Không cho UI tùy ý chọn đích ghi ảnh.
- `findById` trả null chỉ khi đọc thành công nhưng không có ID; lỗi đọc vẫn throw. `listReports` chỉ trả rỗng khi query thành công. Các lỗi tối thiểu phân biệt unsupported platform, input không hợp lệ, mở/đọc/ghi storage, ảnh không đọc/ghi được và ID conflict; thông báo không chứa payload hoặc raw path.
- Serialize thao tác lưu trong instance repository; app dùng một instance. Trong transaction dùng transaction object, không gọi ngược database handle. Không sử dụng `ConflictAlgorithm.replace` làm cơ chế retry.
- Lưu lần đầu: validate → kiểm tra ID hiện có → ghi file staging từ bytes dưới thư mục ảnh app → hoàn tất file đích → insert report trong transaction → trả kết quả. Nếu thất bại đã xác định rollback, chỉ dọn file do lần lưu này tạo và không được report nào tham chiếu; không xóa file nguồn.
- Retry ID đã tồn tại: nếu metadata/nội dung khớp snapshot, trả record hiện có; khi có ảnh phải đối chiếu bản sao bytes với ảnh đã lưu. Nếu nội dung/ảnh khác hoặc không thể xác minh, báo conflict/lỗi ảnh và không ghi đè. Giao diện có thể mở report qua ID để xử lý kết quả chưa rõ trước khi tạo lần lưu mới.
- Nếu không xác định được insert đã commit hay chưa, đọc lại theo ID trước cleanup. Nếu DB vẫn không đọc được, giữ file và trạng thái lỗi chưa rõ để retry; không xóa ảnh có thể đã thuộc record được commit. Crash giữa filesystem/DB có thể để lại file mồ côi; chưa hứa transaction xuyên cả hai hoặc cơ chế tự dọn toàn bộ.
- Task 3 giữ helper ảnh nhỏ để stage/đọc/check đường dẫn; Task 6 lấy root application support hiện tại để resolve `photoPath`. File ảnh mất/hỏng chỉ làm preview fallback, không làm mất text của báo cáo.

#### D. Nền tảng, dependency và cách kiểm chứng

| Package | Phiên bản dry-run | Mục đích / phạm vi |
|---|---|---|
| `sqflite` | 2.4.4 | SQLite Android production, transaction và schema version. |
| `path_provider` | 2.1.6 | `getApplicationSupportDirectory()` cho DB/ảnh. |
| `path` | 1.9.1 | Ghép/kiểm tra path; được khai báo direct vì implementation import package này. |
| `sqflite_common_ffi` | 2.4.3 | Dev-only: inject `databaseFactoryFfi` cho test repository trên Windows. |

- Pub resolver dry-run ở Task 1 chọn thêm `sqlite3 3.5.2` cho FFI và không đổi pubspec/lockfile ở phiên đó. Task 3 sau đó đã resolve và ghi lockfile các package thực tế.
- Đọc source package trong Pub Cache: `sqflite` yêu cầu Dart ^3.12.0/Flutter >=3.44.0; Android adapter ghi yêu cầu AGP 9.0, minSdk 19/Java 17. `path_provider` yêu cầu Dart ^3.10.0/Flutter >=3.38.0. Project dùng Flutter 3.47.1/Dart 3.13.1, AGP 9.1.0, Java target 17 và minSdk theo Flutter là 24; Android/Web build đã thành công trong Task 3.
- Chọn Android persistence; Web chỉ preview UI, không lưu. Task 3 factory dùng conditional import để Web không import implementation `dart:io` hoặc gọi native plugin; `ReportRepository.isSupported` cho UI capability để khóa lưu/hiển thị giới hạn. Không thêm Web SQLite, RAM fallback hoặc desktop app runtime. iOS/desktop chưa cấu hình Firebase nên không tuyên bố hỗ trợ.
- Repository test dùng SQLite thật qua FFI trong thư mục tạm độc lập và inject storage root, không gọi `path_provider` trên test host; đóng/mở DB để kiểm chứng round-trip, ảnh, retry và rollback. Fake chỉ dùng cho UI. Không ghi đè `databaseFactory` toàn cục làm ảnh hưởng các test khác.
- `sqflite_common_ffi 2.4.x` dùng sqlite3 v3/native build hooks; Task 3 đã xác minh runtime bằng 10 test SQLite FFI thực trên Windows.
- Android device/integration test vẫn cần để kiểm chứng plugin/path_provider và app restart ở Task 7; test host không thay thế bằng chứng này.

Nguồn maintainer đã đọc trong Task 1: [sqflite 2.4.4](https://pub.dev/packages/sqflite/versions/2.4.4), [path_provider 2.1.6](https://pub.dev/packages/path_provider/versions/2.1.6), [path 1.9.1](https://pub.dev/packages/path/versions/1.9.1), [sqflite_common_ffi 2.4.3](https://pub.dev/packages/sqflite_common_ffi/versions/2.4.3). Không sử dụng Web support thử nghiệm trong Ngày 4.

#### E. Preflight vừa chạy và giới hạn

- Git đầu task: nhánh `task/day3-firebase-ai-logic`, HEAD `d4e6cc1`; file kế hoạch Ngày 4 đang untracked từ phiên trước, giữ và cập nhật đúng file. Không reset/checkout/stash/stage/commit/push.
- `flutter --version`: Flutter 3.47.1 stable; `dart --version`: Dart 3.13.1.
- `flutter doctor -v`: Android SDK 36.0.0, Java runtime 25.0.2 của Android Studio; cảnh báo **Android license status unknown** và thiếu Visual Studio Desktop C++ workload. Java runtime khác Java target 17 trong Gradle là hai thông tin riêng.
- `flutter devices` và `adb devices -l`: thấy PKG110 qua Wi-Fi, Android 16/API 36; có Windows/Chrome/Edge. `adb version`: 1.0.41, platform-tools 37.0.1. Chỉ liệt kê thiết bị, không mở/gỡ app, đọc log hoặc gửi dữ liệu.
- `flutter pub add --dry-run 'sqflite:^2.4.4' 'path_provider:^2.1.6' 'path:^1.9.1' 'dev:sqflite_common_ffi:^2.4.3'`: exit 0. Đọc source package/config để kiểm tra yêu cầu; `git diff --exit-code -- pubspec.yaml pubspec.lock` không có thay đổi.
- Lệnh tooling ban đầu trong sandbox không trả output; `adb` và đọc package vừa tải bị Access denied. Dừng phiên lệnh treo do task tạo, chạy lại các kiểm tra được duyệt ngoài sandbox thành công; không dừng process Flutter/Dart của người dùng.
- Không chạy `flutter doctor --android-licenses` để tự chấp nhận điều khoản, không cài C++ workload. Cần xử lý/xác minh licenses khi build báo chặn; FFI/toolchain xác minh tại Task 3. Không khẳng định doctor sạch hoặc APK hiện tại build được.
- Không chạy format/analyze/test/build/Gemini, không truy vấn Console/quota. Task 1 hoàn tất ở mức preflight/hợp đồng; persistence và runtime verification vẫn thuộc task sau.

### Task 2 — Model báo cáo đã xác nhận và validation review

**Mục tiêu:** chỉ tạo đối tượng có thể lưu khi điều kiện xác nhận đã đủ.

**Trạng thái:** Hoàn tất ngày 2026-09-27; phụ thuộc hợp đồng Task 1.

**Cần làm:**

1. Thêm model báo cáo đã lưu và state review nhỏ, tách khỏi `ReportDraft`; tái sử dụng `ReportPriority` khi phù hợp.
2. Khởi tạo state từ draft; mọi field chưa được người dùng xác nhận, giữ cờ AI yêu cầu review riêng.
3. Triển khai chuyển trạng thái xác nhận nội dung/xác nhận trống, vô hiệu hóa xác nhận sau thay đổi và validation trước lưu theo Mục 3.
4. Chặn `issue` trống dù người dùng xác nhận cuối; không âm thầm điền dữ liệu mặc định.
5. Bảo đảm summary được xem lại sau khi dữ kiện thay đổi. Chuẩn hóa text bằng `trim()` tại ranh giới lưu, không thay nội dung khi người dùng đang gõ.
6. Serialization round-trip giữ priority null, Unicode tiếng Việt, timestamp và danh sách xác nhận trống; dữ liệu sai cấu trúc khi đọc phải thành lỗi có kiểm soát.

**File dự kiến:** `lib/models/report.dart`, `lib/models/report_review.dart` (hoặc state đặt cùng editor nếu đủ đơn giản); `test/report_test.dart`, `test/report_review_test.dart`. Tên file có thể điều chỉnh trong Task 1 nhưng trách nhiệm phải tách rõ.

**Tránh:** coi `needs_confirmation: []` là đã được người dùng xác nhận; tạo `ReportDraft` mới sau mỗi lần review khiến field trống bị đánh dấu lại; thêm abstraction không có nhu cầu.

**Kiểm thử/tiêu chí hoàn thành:** test field thiếu, issue trống, priority null/không hợp lệ, sửa sau xác nhận, xác nhận trống rồi nhập lại, summary lỗi thời và serialization. Chưa nối nút lưu vào UI ở task này.

**Đã triển khai và xác minh:** `Report` immutable, kiểm tra ID 22 ký tự base64url, issue bắt buộc, đường dẫn ảnh tương đối dưới `report_photos/`, và `confirmedAbsentFields` phải khớp chính xác các field tùy chọn rỗng/null. JSON strict giữ timestamp UTC milliseconds, Unicode và priority null; dữ liệu sai cấu trúc ném `FormatException`. `ReportReview.fromDraft` giữ cờ AI riêng nhưng bắt đầu mọi field ở trạng thái pending; sửa dữ liệu hủy xác nhận field và summary; chỉ chuyển thành `Report` khi mọi field đã review hợp lệ. Tách `ReportPriority` dùng chung và re-export từ `report_draft.dart` để giữ cách import hiện tại. Có unit test model/state trong hai file dự kiến; chưa nối UI hoặc persistence.

Kiểm chứng phiên này: `dart format` trên 6 file liên quan (exit 0, lần rà cuối 0 file cần format), `flutter analyze` — No issues found, `flutter test` — **67/67 đạt**. Các lệnh Flutter được gọi bằng Flutter SDK snapshot do sandbox chặn cache/lock mặc định. Không chạy APK/build, kiểm thử thiết bị hoặc request Gemini.

### Task 3 — Repository SQLite và ảnh bền vững

**Mục tiêu:** lưu/đọc báo cáo thực, độc lập với Firebase/network và file picker tạm.

**Trạng thái:** Hoàn tất ngày 2026-09-27; phụ thuộc Task 1–2.

**Cần làm:**

1. Thêm repository/interface nhỏ và implementation Android; khởi tạo database trong thư mục ứng dụng, có schema version rõ ràng.
2. Lưu sáu field nội dung và metadata; dùng ID duy nhất, đọc danh sách theo `created_at` mới nhất trước với thứ tự phụ ổn định khi cùng timestamp.
3. Nhận ảnh từ dữ liệu nguồn của phiên editor; sao chép sang thư mục ảnh riêng, tên do app tạo, đường dẫn tương đối trong database. Không dùng tên/path picker làm đường dẫn đích tùy ý.
4. Tách xử lý file đủ để kiểm thử ảnh tồn tại/mất và lỗi ghi. Chốt trình tự commit/cleanup; lỗi cleanup không được che lỗi lưu ban đầu, không xóa ảnh của báo cáo đã commit.
5. Với retry cùng ID, xác định kết quả bản ghi hiện có để tránh duplicate; không âm thầm ghi đè một báo cáo khác. Nếu insert đã thành công nhưng đọc phản hồi lỗi, cho khôi phục kết quả theo ID.
6. Ánh xạ lỗi mở/ghi/đọc database và ảnh thành lỗi storage; không catch rồi trả danh sách rỗng như thể chưa có báo cáo.
7. Đọc ảnh thiếu/hỏng có fallback; không xóa báo cáo hoặc sửa database tự động chỉ vì preview lỗi.

**File dự kiến:** `lib/repositories/report_repository.dart`, `lib/repositories/local_report_repository.dart`, helper ảnh cục bộ nếu cần; `test/local_report_repository_test.dart`; dependency đã chốt ở Task 1.

**Tránh:** lưu ảnh chỉ bằng đường dẫn cache; ghi báo cáo trước rồi bỏ qua lỗi copy ảnh; dùng database thật của người dùng cho test; reset database khi đọc lỗi.

**Kiểm thử/tiêu chí hoàn thành:** kiểm thử database thực trong thư mục tạm: lưu/đọc đủ dữ liệu, đóng/mở repository, nhiều bản ghi/thứ tự, retry cùng ID, lỗi ghi ảnh/DB và cleanup; ảnh được đọc từ bản sao sau khi nguồn tạm không còn. Test không gọi Gemini, không sửa dữ liệu ứng dụng đang dùng.

**Đã triển khai:** `lib/repositories/report_repository.dart` định nghĩa contract, các loại lỗi storage an toàn để UI hiển thị và thao tác đọc bytes ảnh. Factory dùng conditional import: Android trả `LocalReportRepository`, Web/nền tảng khác trả lỗi unsupported thay vì RAM fallback. `LocalReportRepository` tạo schema SQLite v1 trong application support, validate dữ liệu đọc, lưu metadata/path tương đối, sort ổn định, copy bytes ảnh vào `report_photos/`, serialize thao tác trong một instance, kiểm tra retry theo snapshot/bytes và dọn file chỉ khi biết insert chưa commit. Khi chưa xác định được kết quả transaction, giữ ảnh và báo lỗi thay vì xóa có thể làm mất dữ liệu.

**Dependency đã thêm:** `sqflite 2.4.4`, `path_provider 2.1.6`, `path 1.9.1`; dev-only `sqflite_common_ffi 2.4.3` cho SQLite thật trong test Windows.

**Kiểm chứng vừa chạy trong Task 3:** `dart format lib/repositories test/local_report_repository_test.dart` — 6 file đã xét, 0 file cần format ở lần rà cuối; `flutter analyze` — No issues found; `flutter test test/local_report_repository_test.dart` — 10/10 đạt; `flutter test` — 77/77 đạt. Test FFI dùng database và support root trong thư mục tạm. `flutter build apk --debug` và `flutter build web --release` đều thành công. APK build cảnh báo Firebase plugins dùng Kotlin Gradle Plugin; Web build có cảnh báo Cupertino icon font/Wasm dry-run. Không cài/mở app hoặc kiểm chứng persistence/plugin qua restart trên Android, không gọi Gemini. Các lệnh Flutter cần quyền ngoài sandbox để đọc Pub Cache/lock; dependency resolution và kiểm tra đều thành công.

**Giới hạn tại thời điểm kết thúc Task 3:** repository chưa được nối vào UI; màn draft chưa lưu được và lịch sử vẫn rỗng. Chưa có kiểm chứng storage qua `sqflite`/`path_provider` Android. Có thể còn file ảnh mồ côi nếu process dừng giữa copy file và commit DB; Task 3 chưa có cơ chế quét/dọn mồ côi.

**Kiểm chứng bổ sung sau Task 3 (2026-09-28):** APK debug được build lại, cài đè qua ADB không dây, package/version xác nhận (`0.1.0`, code 1), app mở foreground trên PKG110/Android 16/API 36. Input rỗng bị chặn, empty state Lịch sử, giữ mô tả khi chuyển tab, không có app fatal exception trong crash buffer; input thử chưa lưu mất sau force-stop/mở lại. ADB-03 còn partial vì không lặp picker/camera/ảnh lớn/mất mạng/AI. Không gửi Gemini request. Các phép thử này dùng APK trước Task 4 nên chưa gọi luồng repository/lưu mới; Task 7 vẫn cần build phiên bản hiện tại và kiểm chứng plugin SQLite/path_provider cùng persistence sau khi các màn History/detail sẵn sàng.

### Task 4 — Editor, xác nhận và thao tác lưu từ luồng AI

**Mục tiêu:** người dùng sửa/xác nhận rồi lưu draft bằng thao tác thật, có loading/lỗi/retry.

**Trạng thái:** Đã triển khai editor/review/luồng lưu và xác minh qua widget tests; lưu Android runtime cùng luồng nối sang Lịch sử/chi tiết sau lưu còn chờ các Task 5–7.

**Cần làm:**

1. Mở rộng `ReportDraftScreen` thành editor hoặc đổi sang màn riêng và cập nhật route; giữ đầu vào gốc cùng nhãn draft chưa lưu.
2. Cho sửa từng field, chọn priority hoặc chưa xác định; có control xác nhận rõ ràng và thông báo lỗi gần field.
3. Cho xác nhận không có dữ liệu ở field được phép; `issue` luôn yêu cầu bổ sung. Hiển thị tiến độ review, không chỉ dựa vào badge AI.
4. Thêm CTA lưu: validate → xác nhận cuối → loading khóa thao tác gây lưu lặp → gọi repository. Lỗi giữ nguyên nội dung/review và có retry; thành công trả ID báo cáo về app shell.
5. Sau lưu thành công, thông báo “Đã lưu trên thiết bị” và trả `Report` về form nguồn; chỉ xóa input nguồn sau khi lưu đã xác nhận thành công. Điều hướng/làm mới Lịch sử và chi tiết sẽ nối cùng Task 5–6 vì các màn đó hiện chưa triển khai.
6. Back khỏi editor chưa lưu cần xác nhận bỏ thay đổi nếu có chỉnh sửa/review; chọn ở lại giữ state. Không hứa draft chưa lưu còn sau khi process đóng.
7. Inject repository cho test; không khởi tạo Firebase trong widget test và không dùng draft fixture ở đường chạy production.
8. Sửa nhỏ tại `_analyzeWithAi()` nếu cần để bảo đảm bước đọc size ảnh nằm trong xử lý lỗi và khóa thao tác trước điểm `await`; lỗi file giữ input, không tạo nhiều request do tap lặp. Không gộp đổi model/quota hoặc tái cấu trúc toàn service vào task này.

**File dự kiến:** `lib/screens/report_draft_screen.dart`, `lib/screens/create_report_screen.dart`, `lib/main.dart`; test editor/save flow mới hoặc `test/widget_test.dart`.

**Tránh:** chỉ thêm nút “Lưu” nhưng không persistence; tự đánh dấu mọi field đã xác nhận; mất dữ liệu khi lỗi; reset form sau khi mở draft; gọi Gemini lại khi lưu.

**Kiểm thử/tiêu chí hoàn thành:** widget tests với fake repository cho edit/review, chặn lưu chưa đủ, issue bắt buộc, xác nhận trống hợp lệ, lưu đúng nội dung, double-tap, lỗi/retry, Back và viewport 320×568/bàn phím. Test lỗi đọc file trước AI bằng nguồn lỗi có kiểm soát. Có luồng thật lưu vào repository Task 3 trên Android ở Task 7.

**Bằng chứng Task 4 (2026-09-28):** `dart format lib/main.dart lib/screens/create_report_screen.dart lib/screens/report_draft_screen.dart test/widget_test.dart` exit 0; `flutter analyze` — No issues found; `flutter test` — **85/85 đạt**. Widget tests dùng fake repository, gồm xác nhận field, lưu đúng nội dung/ảnh, field tùy chọn rỗng, `issue` bắt buộc, retry cùng ID, kết quả lưu mơ hồ, Back, double-tap và viewport 320×568/bàn phím. `flutter build apk --debug` thành công; `adb install -r` trả `Success`; app mở và process/foreground được xác nhận qua ADB Wireless debugging.** Cập nhật 2026-09-29:** chốt lại format check (0 file đổi), `flutter analyze` sạch, `flutter test` 85/85; chủ dự án báo PHONE-D4-01–14 PASS. ADB-D4-01–06 và 09 được xác minh, gồm một request Gemini tổng hợp mở draft; ADB review/save, force-stop và disconnect chưa chạy. Không có xác minh độc lập SQLite/path_provider hoặc đọc lại persistence Android sau restart. Task 7 vẫn cần kiểm tra persistence đầu-cuối.

### Task 5 — Lịch sử từ dữ liệu cục bộ

**Mục tiêu:** thay empty state cố định bằng màn đọc danh sách báo cáo đã lưu.

**Trạng thái:** Hoàn tất. Danh sách dùng chung repository với luồng lưu; chạm dòng phát report ID và app điều hướng sang màn chi tiết (Task 6).

**Cần làm:**

1. Tách `HistoryScreen` khỏi `main.dart`; dùng cùng repository với editor.
2. Có loading, empty state chỉ khi đọc thành công và không có dữ liệu, lỗi đọc kèm thử lại, danh sách mới nhất trước.
3. Mỗi item hiển thị thông tin vừa đủ: sự cố, địa điểm nếu có, priority hoặc “Chưa xác định”, thời gian theo giờ địa phương và nhãn đã xác nhận.
4. Refresh khi lưu thành công và khi người dùng mở tab Lịch sử; tránh request đọc lặp mỗi lần `build()`. Không làm mất state form chỉ vì đổi tab.
5. Chạm item mở chi tiết theo ID; nếu item không còn hoặc lỗi đọc thì báo rõ, không tạo dữ liệu thay thế.

**File dự kiến:** `lib/screens/history_screen.dart`, `lib/main.dart`; `test/history_screen_test.dart`.

**Tránh:** danh sách demo hard-code, coi lỗi DB là lịch sử rỗng, đọc lại ảnh lớn của toàn bộ danh sách chỉ để hiển thị vài dòng text.

**Kiểm thử/tiêu chí hoàn thành:** loading/rỗng/danh sách/thứ tự/lỗi/retry, refresh sau lưu, mở đúng ID; giữ input nguồn khi đổi tab trước lưu.

**Kết quả Task 5 (2026-09-29):** `HistoryScreen` tải khi tab được mở hoặc refresh token đổi, chỉ hiển thị empty state sau lần đọc thành công, hỗ trợ lỗi/thử lại và pull-to-refresh; danh sách nhận từ repository, sắp thứ tự mới nhất theo contract repository và không đọc ảnh. `main.dart` dùng chung repository, tăng refresh token khi mở tab và sau save thành công; `IndexedStack` giữ form khi đổi tab. Tap item phát đúng report ID; điều hướng chi tiết thật còn chờ Task 6.

**Kiểm chứng lúc triển khai:** `dart format` trên các file Dart đổi; `flutter analyze` — No issues found; `flutter test test/history_screen_test.dart` — 5/5 đạt; kiểm tra viewport 320×568 đạt; `flutter test --reporter compact` — 90/90 đạt. Widget tests dùng fake repository; lượt này chưa build APK/Web, chạy ADB/device test hoặc Gemini request.

**Kiểm chứng ADB Wireless sau đó (2026-09-29):** `flutter build apk --debug` exit 0; APK 178,592,675 bytes, version 0.1.0 (code 1), SHA-256 `62A896D0F98EDFD19CBBA01016A67A347A393B02046EBF51ADC339E6B0C3B41`; cài đè bằng `adb install -r` thành công trên PKG110 Android 16/API 36. ADB-D4-HIS-01–05 PASS, ADB-D4-HIS-06 BLOCKED do không gặp lỗi đọc tự nhiên; chủ dự án báo PHONE-D4-HIS-01–09 PASS. Một request Gemini tổng hợp được review/lưu; report xuất hiện đầu danh sách sau khi đổi tab. Không chạy analyze/test trong lượt ADB; chưa xác minh report/ảnh sau force-stop/restart hoặc đọc database riêng tư. Chi tiết: `docs/testcase_task5_history_day4.txt`, `docs/AI_WORKLOG.md`.

### Task 6 — Chi tiết báo cáo đã lưu

**Mục tiêu:** xem lại nội dung đã xác nhận cùng đầu vào gốc và ảnh đã lưu, truy xuất từ repository theo report ID.

**Trạng thái:** Đã triển khai và kiểm tra bằng widget tests với fake repository. Android đọc SQLite/ảnh sau process restart chưa được kiểm chứng; tiêu chí persistence thiết bị thuộc Task 7.

**Cần làm:**

1. Thêm `ReportDetailScreen` đọc report theo ID từ repository, phân biệt rõ với màn draft.
2. Hiển thị field đã lưu, trạng thái xác nhận, thời gian, mô tả gốc và ảnh nếu có. Field đã xác nhận trống có nhãn phù hợp, không hiện như lỗi chưa xử lý.
3. Giữ nhãn `suggested_action` là đề xuất; nội dung đã được người dùng xác nhận không chứng minh công việc đã thực hiện.
4. Có loading, báo cáo không tồn tại, lỗi/retry và fallback ảnh thiếu/hỏng; Back trở về lịch sử.
5. Không thêm sửa/xóa/chia sẻ/xuất PDF trong task bắt buộc này.

**File dự kiến:** `lib/screens/report_detail_screen.dart`; `test/report_detail_screen_test.dart`.

**Tránh:** lấy draft trong RAM làm màn chi tiết rồi tuyên bố dữ liệu đã lưu; để lỗi ảnh ngăn xem nội dung text; tự sửa report khi đọc.

**Kết quả Task 6 (2026-09-29):** `ReportDetailScreen` truy vấn `findById` bằng ID được chọn, hiển thị trạng thái đã xác nhận, thời gian địa phương, các field, mô tả gốc và ảnh từ `readPhotoBytes`. Field đã xác nhận không có được phân biệt với field không có dữ liệu; `suggested_action` ghi rõ là đề xuất. Có loading, not-found, lỗi/thử lại; lỗi/bytes ảnh hỏng có fallback riêng, giữ phần text và cho retry. Nút Back trở về History. Không thêm edit/delete/share/PDF. Snackbar sau save đã bỏ nội dung cũ nói Lịch sử chưa hiển thị và hướng người dùng mở tab Lịch sử.

**Kiểm chứng vừa chạy:** `dart format` trên các file Dart đã đổi; `flutter analyze` — No issues found; `flutter test --reporter compact` — **99/99 đạt**; `flutter build apk --debug` — exit 0. Có 9 widget tests mới cho ID/field/source, loading, confirmed absence, not-found, report read error/retry, photo read/decode/fallback/retry và điều hướng History → detail → Back. Tests dùng fake repository. APK đã được build, cài và chạy qua ADB Wireless; UI smoke không thay thế xác minh persistence Android sau restart, phần này còn thuộc Task 7. PHONE/ADB case statuses và giới hạn fixture được ghi trong `docs/testcase_task6_detail_day4.txt`.

**Tiêu chí hoàn thành Task 6:** đọc theo ID từ repository, nội dung/null/trống được diễn giải đúng, giữ mô tả gốc, ảnh lỗi không chặn text, xử lý report không tồn tại/lỗi đọc, và màn không phụ thuộc draft trong RAM. Việc chứng minh report/ảnh tồn tại sau khi đóng/mở app cần Android runtime và được ghi nhận trong Task 7.

### Task 7 — Kiểm chứng MVP Android và persistence sau mở lại

**Mục tiêu:** có bằng chứng đầu-cuối cho Ngày 4 và kiểm tra lỗi quan trọng.

**Trạng thái:** Hoàn thành theo quyết định của chủ dự án với ngoại lệ được chấp nhận (2026-09-29). Đây là quyết định đóng task, không phải xác nhận mọi tiêu chí kiểm chứng đều đạt; nghiệm thu đầy đủ Ngày 4 vẫn còn thiếu.

**Kết quả kiểm chứng Task 7 (2026-09-29):** format check 26 file Dart/0 file cần đổi; flutter analyze sạch; flutter test --reporter compact 99/99; test/local_report_repository_test.dart 10/10 bằng SQLite FFI host; APK debug build thành công (version 0.1.0/code 1, SHA-256 6E84D74E20027B08CE7A04B0E93626A00AB872D8064B89D62E97D2DBD9A59804). APK cài đặt trùng hash build. Trên PKG110 Android 16/API 36, một request Gemini tổng hợp tạo draft text-only; người dùng chỉnh sửa/review, xác nhận priority null, lưu, mở đúng report ở History/detail; sau force-stop/relaunch cùng marker vẫn có ở History/detail. Logcat giới hạn: 1.956 dòng, không có match fatal exception hoặc nhóm lỗi SQLite/plugin đã lọc. Model thực tế của request không được ghi nhận; service hiện cấu hình gemini-3.8-flash primary và gemini-3.5-flash-lite fallback.

**Còn thiếu:** fixture ảnh do phiên test tạo không xuất hiện trong Android Photo Picker nên chưa tạo/lưu/reopen report có ảnh; offline save/read chưa chạy vì thiết bị chỉ có ADB Wireless transports và ngắt Wi-Fi làm mất kênh điều khiển. Thử issue rỗng trên thiết bị mới xác nhận editor có field rỗng; chưa thử nút lưu trong trạng thái mọi field khác đã review. Widget/repository tests bao phủ validation/lỗi tương ứng. Bảng trạng thái từng case nằm ở docs/testcase_task7_persistence_day4.txt. Một báo cáo tổng hợp được giữ trong app; fixture ảnh/screenshot tạm chưa dọn được sau khi automatic approval review chặn lệnh xóa qua nhiều shell/filesystem. Không có lệnh xóa chạy.

**Quyết định đóng:** chủ dự án yêu cầu đánh dấu Task 7 hoàn thành và publish dù còn các ngoại lệ trên. Vì vậy task được đóng theo chấp thuận của chủ dự án; các case ảnh/offline vẫn giữ BLOCKED/NOT RUN, không được ghi thành PASS. Việc xác minh ảnh/offline được giữ làm follow-up; điều này không đồng nghĩa nghiệm thu đầy đủ Ngày 4.

**Tiến độ theo tiêu chí:**

1. [x] Format check, flutter analyze, full flutter test và test repository FFI: 26 file/0 đổi, analyzer sạch, 99/99 và 10/10.
2. [x] Debug APK build; app Android chạy qua ADB Wireless, APK cài đặt khớp hash APK vừa build. Không gỡ cài/xóa dữ liệu.
3. [x] Với input tổng hợp, AI tạo draft text-only → sửa/review → xác nhận cuối → save → History → detail.
4. [~] Text-only và priority null đã kiểm tra; issue rỗng được nhìn thấy trong editor nhưng chưa xác minh nút lưu khi các field khác đã review; summary được xác nhận sau review nhưng chưa thử invalidation sau khi summary đã được xác nhận. Có ảnh bị BLOCKED do fixture không xuất hiện trong Photo Picker.
5. [~] Text-only report còn trong History/detail sau force-stop/relaunch; ảnh chưa kiểm chứng.
6. [ ] Chưa chạy offline thật. Chỉ có ADB Wireless transports, nên chưa ngắt Wi-Fi.
7. [x] Test host SQLite FFI 10/10 bao gồm lỗi write, ảnh mất, path không an toàn và JSON hỏng; không cố tình phá dữ liệu Android.
8. [x] Bảng test thủ công có trạng thái từng case tại docs/testcase_task7_persistence_day4.txt.

**Lệnh dùng khi kiểm tra Task 7 (kết quả phiên này ghi ở trên và trong phiếu test):**

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter devices
flutter run -d <android-device-id>
```

Nếu thêm `integration_test`, ghi lệnh/target cụ thể sau khi chọn ở Task 1. Web build chỉ kiểm tra tương thích preview nếu vẫn hỗ trợ, không chứng minh SQLite Android hoạt động.

**File:** test liên quan; docs/testcase_task7_persistence_day4.txt; README.md; docs/CONTEXT_SUMMARY.md; docs/WALKTHROUGH.md; docs/AI_WORKLOG.md.

**Tránh:** gọi AI nhiều lần để kiểm tra các thao tác chỉ cần database; dùng ảnh có sẵn không rõ nguồn; coi build thành công là đã chạy được app; ghi kết quả khi môi trường thiếu công cụ.

**Kiểm thử/tiêu chí hoàn thành:** kiểm tra tự động đạt; Android tạo/sửa/xác nhận/lưu/mở lại có bằng chứng, ảnh không phụ thuộc cache nguồn; lỗi giữ editor, không duplicate. Nếu bị chặn, đánh dấu tiêu chí còn thiếu thay vì hoàn tất ngày bằng fixture.

### Task 8 — Rà tài liệu và bàn giao Ngày 4

**Mục tiêu:** README/context/walkthrough phản ánh đúng persistence và bằng chứng vừa có.

**Trạng thái:** Hoàn tất cập nhật tài liệu và bàn giao theo quyết định đóng Task 7 với ngoại lệ được chấp nhận. Phiếu test và README/context/walkthrough/worklog giữ rõ ảnh/offline chưa được kiểm chứng; Day 4 chưa nghiệm thu đầy đủ.

**Cần làm:**

1. Cập nhật README về kiến trúc repository/SQLite/ảnh, luồng review, cách chạy, nền tảng hỗ trợ và giới hạn offline/gỡ app.
2. Cập nhật `CONTEXT_SUMMARY.md`, `WALKTHROUGH.md` và trạng thái từng task/checklist của kế hoạch này; không giữ câu “chưa có lưu trữ” như trạng thái hiện tại nếu đã kiểm chứng xong.
3. Ghi công cụ AI, prompt triển khai quan trọng, lỗi/đề xuất sai thực sự gặp, cách sửa và lệnh/kết quả trong worklog. Ghi entry mới theo phiên, không bịa nhật ký hồi cứu.
4. Sửa phân bổ test sai và làm rõ các mục cũ Ngày 3 là lịch sử; cập nhật test thủ công quota/confirmation khi có yêu cầu regression liên quan, không xóa bằng chứng cũ.
5. Rà diff/status cuối phiên, liệt kê tệp modified/untracked/deleted và dependency mới; chỉ stage/commit/push khi chủ dự án yêu cầu rõ ràng; giữ nguyên artifacts cần thiết.

**File dự kiến:** `README.md`, `docs/CONTEXT_SUMMARY.md`, `docs/WALKTHROUGH.md`, `docs/AI_WORKLOG.md`, kế hoạch/test case liên quan.

**Tránh:** tuyên bố offline AI, production App Check, release signing hoặc Web persistence hoàn tất khi chỉ kiểm chứng Android debug; coi quota lịch sử là quota hiện thời.

**Kiểm thử/tiêu chí hoàn thành:** mọi tuyên bố khớp code và bằng chứng Task 7; ghi rõ test/build vừa chạy so với lịch sử, blocker còn lại và ưu tiên Ngày 5. Docs-only không cần chạy lại test nếu không đổi mã.

## 5. Nghiệm thu Ngày 4

- [ ] Có thể chỉnh sửa sáu field của draft và đối chiếu đầu vào gốc.
- [ ] Nội dung AI, field cần review và nội dung người dùng xác nhận được phân biệt rõ.
- [~] Issue rỗng đã thấy trong editor, priority null đã xác nhận chưa có; chưa thử nút save khi các field khác đã review hết.
- [~] Các field được review trong luồng test; chưa kiểm tra trên thiết bị rằng chỉnh field sau khi đã xác nhận sẽ yêu cầu review lại.
- [~] Summary được xác nhận sau khi review field; chưa kiểm tra invalidation sau khi summary đã xác nhận. Widget test có coverage.
- [~] Lưu sau xác nhận cuối chạy được; double-tap/retry được test tự động, chưa stress-test trên Android.
- [~] SQLite Android đã giữ report text-only sau force-stop/relaunch; ảnh chưa được chọn/lưu vì Photo Picker không thấy fixture.
- [~] Repository/widget tests bao phủ lỗi write/read/retry; không cố tình tạo lỗi hoặc phá dữ liệu trên Android.
- [x] Lịch sử có loading/rỗng/dữ liệu/lỗi và cập nhật sau lưu.
- [~] Chi tiết mở đúng report theo ID sau restart; fallback ảnh có widget coverage nhưng chưa kiểm tra ảnh Android.
- [~] Report text-only còn sau force-stop/relaunch; persistence ảnh chưa xác minh.
- [x] Format/analyzer/tests/repository FFI/APK debug đều đạt; Android MVP đã kiểm chứng một phần.
- [~] Bảng từng case đã cập nhật; ảnh/offline còn BLOCKED/NOT RUN.
- [x] Tài liệu và bàn giao Task 8 đã đồng bộ; các ngoại lệ ảnh/offline vẫn được nêu rõ.
- [ ] Không thêm secret, dữ liệu nhạy cảm, đăng nhập/cloud/voice/GPS hoặc thay đổi billing.

## 6. Thứ tự ưu tiên và điều kiện dừng

1. Task 1: hợp đồng review/model/storage và phương án kiểm chứng.
2. Task 2–3: validation và persistence thực.
3. Task 4: sửa/xác nhận/lưu từ draft.
4. Task 5–6: lịch sử và chi tiết từ database.
5. Task 7 đã đóng theo quyết định chủ dự án; giữ follow-up kiểm chứng ảnh và offline khi có thiết bị/đường điều khiển phù hợp.
6. Task 8: hoàn tất cập nhật tài liệu/bàn giao và publish; giữ nguyên trạng thái ngoại lệ Task 7.

Triển khai từng task thành lát nhỏ, chạy kiểm tra liên quan sau khi đổi mã; không dựng toàn bộ ngày trong một lượt nếu yêu cầu chỉ một task. Ưu tiên hoàn thiện luồng text-only trước rồi xác minh ảnh bền vững, nhưng không coi Ngày 4 hoàn tất khi còn thiếu lưu ảnh.

Nếu database/ảnh chưa lưu bền vững hoặc điều kiện xác nhận chưa đúng, dừng việc mở rộng UX/tính năng phụ và sửa phần đó trước. Nếu thiếu tooling/thiết bị hoặc AI quota/App Check chặn, tiếp tục phần model/repository/UI có thể kiểm chứng độc lập, ghi rõ phần E2E còn thiếu; không bịa kết quả hoặc bật billing để vượt giới hạn.

Kết thúc Ngày 4 ở MVP tạo → AI → sửa/xác nhận → lưu → lịch sử/chi tiết → mở lại. App Check production, release signing và demo cuối thuộc bước đóng gói; voice/GPS chỉ cân nhắc sau khi MVP ổn định.
