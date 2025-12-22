# 🌐 Mini Social Network - Flutter Web App

Ứng dụng mạng xã hội mini được xây dựng bằng Flutter với Firebase backend và ImgBB image storage.

## ✨ Tính Năng

- 🔐 **Authentication:** Đăng ký, đăng nhập, quên mật khẩu (Firebase Auth)
- 📝 **Posts:** Tạo bài viết kèm ảnh
- 📷 **Image Upload:** Upload ảnh lên ImgBB
- 💾 **Real-time Feed:** Hiển thị bài viết real-time từ Firestore
- 👤 **User Profiles:** Quản lý thông tin cá nhân

## 🛠️ Tech Stack

- **Frontend:** Flutter (Web)
- **Backend:** Firebase (Authentication, Firestore Database)
- **Image Storage:** ImgBB
- **State Management:** Provider

---

## 📋 Prerequisites

### 1. Cài Đặt Flutter

- **Flutter SDK:** >= 3.0.0
- **Dart SDK:** >= 3.0.0

**Download:** https://flutter.dev/docs/get-started/install

**Verify:**
```bash
flutter --version
dart --version
```

### 2. IDE (Tuỳ chọn)

- VS Code + Flutter extension
- Android Studio + Flutter plugin

### 3. Browser

- Chrome (khuyến nghị cho web development)

---

## 🚀 Setup Instructions

### Bước 1: Clone Repository

```bash
git clone https://github.com/Adai-itqnu/Flutter_SocialNetworkMini.git
cd Flutter_SocialNetworkMini
```

### Bước 2: Install Dependencies

```bash
flutter pub get
```

### Bước 3: Tạo File `.env`

**Tạo file `.env` trong root folder:**

```bash
# Windows
type nul > .env

# Mac/Linux
touch .env
```

**Thêm vào file `.env`:**

```env
# ImgBB API Key
IMGBB_API_KEY=your_imgbb_api_key_here
```

**Lấy ImgBB API Key:**
1. Vào: https://api.imgbb.com/
2. Đăng ký/Đăng nhập
3. Copy API key
4. Paste vào `.env`

⚠️ **QUAN TRỌNG:** File `.env` đã được add vào `.gitignore`. KHÔNG commit file này!

### Bước 4: Firebase Configuration (Đã Setup)

Firebase configuration đã có sẵn trong `lib/config/firebase_options.dart`.

**Project:** `MiniSocialNetwork`

**Services Enabled:**
- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore Database
- ✅ Firebase Hosting

---

## ▶️ Run App

### Chạy trên Chrome (Web)

```bash
flutter run -d chrome
```

### Chạy trên Edge

```bash
flutter run -d edge
```

### Build Production

```bash
flutter build web --release
```

Output: `build/web/`

---

## 👥 Team Development

### Làm Việc Với Firebase

**Tất cả team members:**
- ✅ Dùng chung Firebase project
- ✅ Dùng chung `firebase_options.dart`
- ✅ Thấy data real-time

**Mỗi member cần:**
- Tạo `.env` riêng với ImgBB API key của mình
- Không commit `.env`

### Git Workflow

```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/your-feature-name

# 3. Make changes

# 4. Commit
git add .
git commit -m "feat: your feature description"

# 5. Push
git push origin feature/your-feature-name

# 6. Create Pull Request on GitHub
```

---

## 🧪 Test App

### 1. Đăng Ký Account

```
Username: testuser
Email: test@example.com
Password: 123456
```

→ Sau đăng ký → Tự động logout → Quay về Login

### 2. Đăng Nhập

→ Vào Home screen

### 3. Tạo Post

- Click nút **+** (bottom center)
- Click "Thư viện" → Chọn ảnh
- Nhập caption
- Click "Đăng"

→ Post hiển thị trong feed

---

## 📁 Project Structure

```
lib/
├── config/
│   └── firebase_options.dart    # Firebase configuration
├── models/
│   ├── user_model.dart          # User data model
│   ├── post_model.dart          # Post data model
│   └── comment_model.dart       # Comment data model
├── providers/
│   ├── auth_provider.dart       # Auth state management
│   ├── post_provider.dart       # Post state management
│   └── user_provider.dart       # User state management
├── services/
│   ├── auth_service.dart        # Firebase Auth operations
│   ├── firestore_service.dart   # Firestore CRUD operations
│   └── imgbb_service.dart       # ImgBB image upload
├── screens/
│   ├── auth/                    # Login, Register, Forgot Password
│   ├── home/                    # Home feed, Create post
│   ├── profile/                 # User profile
│   └── comments/                # Comments screen
└── main.dart                    # App entry point
```

---

## 🔧 Troubleshooting

### Lỗi: "ImgBB API key không được tìm thấy"

**Fix:**
- Check file `.env` có tồn tại
- Check `IMGBB_API_KEY` có đúng format
- Restart app (Hot restart: `R`)

### Lỗi: "Failed to compile application"

**Fix:**
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Lỗi: "Unsupported operation: _Namespace"

**Fix:**
- Đảm bảo đang dùng `XFile` thay vì `dart:io File`
- Code đã fix sẵn, pull latest changes

### Lỗi: "Permission denied" khi tạo post

**Fix:**
- Check Firebase Security Rules đã được setup
- Check user đã login chưa

---

## 🔐 Security Notes

### Firebase Config

- ✅ `firebase_options.dart` - AN TOÀN để commit
- 🛡️ Bảo vệ bởi Firebase Security Rules

### Environment Variables

- ❌ `.env` - KHÔNG commit (đã có trong `.gitignore`)
- 🔑 Chứa ImgBB API key (sensitive)

### Security Rules

Firebase Security Rules đã được setup để:
- Public read posts
- Authenticated write only
- Owner-only update/delete

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [ImgBB API Documentation](https://api.imgbb.com/)
- [Provider Package](https://pub.dev/packages/provider)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

---

## 📝 License

This project is for educational purposes.

---

## 👨‍💻 Team

**Repository:** https://github.com/Adai-itqnu/Flutter_SocialNetworkMini

**Firebase Project:** MiniSocialNetwork

---

## 📞 Need Help?

- Check existing issues on GitHub
- Contact team members
- Review documentation artifacts in `.gemini/` folder

---

**Last Updated:** December 2024
