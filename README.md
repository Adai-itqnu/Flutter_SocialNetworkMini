lib/
 ├─ main.dart
 │
 ├─ config/
 │   ├─ app_colors.dart
 │   ├─ app_styles.dart
 │   └─ firebase_options.dart        // file cấu hình Firebase
 │
 ├─ models/
 │   ├─ user_model.dart              // thông tin người dùng
 │   ├─ post_model.dart              // bài viết
 │   └─ comment_model.dart           // bình luận
 │
 ├─ services/
 │   ├─ auth_service.dart            // đăng nhập, đăng ký
 │   ├─ post_service.dart            // CRUD bài viết
 │   ├─ comment_service.dart         // bình luận
 │   ├─ storage_service.dart         // upload ảnh
 │   └─ notification_service.dart    // gửi/nhận thông báo
 │
 ├─ providers/
 │   ├─ auth_provider.dart           // quản lý trạng thái đăng nhập
 │   ├─ post_provider.dart           // quản lý danh sách bài viết
 │   ├─ comment_provider.dart        // quản lý comment
 │   └─ user_provider.dart           // quản lý thông tin người dùng
 │
 ├─ screens/
 │   ├─ auth/
 │   │   ├─ login_screen.dart
 │   │   └─ register_screen.dart
 │   │
 │   ├─ home/
 │   │   ├─ home_screen.dart
 │   │   └─ create_post_screen.dart
 │   │
 │   ├─ profile/
 │   │   ├─ profile_screen.dart
 │   │   └─ edit_profile_screen.dart
 │   │
 │   └─ comments/
 │       └─ comment_screen.dart
 │
 ├─ widgets/
 │   ├─ post_card.dart               // hiển thị 1 bài viết
 │   ├─ comment_tile.dart            // hiển thị 1 comment
 │   └─ custom_button.dart           // nút dùng chung
 │
 └─ utils/
     ├─ constants.dart
     ├─ validators.dart
     └─ helpers.dart
