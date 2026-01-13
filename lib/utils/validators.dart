// Validator cơ bản - kiểm tra không để trống
String? requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Thông tin bắt buộc';
  }
  return null;
}

// Validator cho email - kiểm tra format hợp lệ
String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Thông tin bắt buộc';
  }
  
  // Regex để kiểm tra format email
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Email không hợp lệ';
  }
  
  return null;
}

// Validator cho password mạnh (dùng cho register)
String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Thông tin bắt buộc';
  }
  
  if (value.length < 8) {
    return 'Mật khẩu phải ít nhất 8 ký tự';
  }
  
  // Kiểm tra có ít nhất 1 chữ hoa
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ hoa';
  }
  
  // Kiểm tra có ít nhất 1 chữ thường
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ thường';
  }
  
  // Kiểm tra có ít nhất 1 số
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Mật khẩu phải chứa ít nhất 1 số';
  }
  
  // Kiểm tra có ít nhất 1 ký tự đặc biệt
  if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
    return r'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (@$!%*?&)';
  }
  
  return null;
}

// Validator cho username
String? usernameValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Thông tin bắt buộc';
  }
  
  final trimmed = value.trim();
  
  if (trimmed.length < 3 || trimmed.length > 30) {
    return 'Username phải từ 3-30 ký tự';
  }
  
  // Không được bắt đầu bằng số
  if (RegExp(r'^[0-9]').hasMatch(trimmed)) {
    return 'Username không được bắt đầu bằng số';
  }
  
  // Chỉ chứa chữ cái, số và dấu gạch dưới
  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
    return 'Username chỉ chứa chữ, số và dấu gạch dưới';
  }
  
  return null;
}

// Validator cho display name (họ tên)
String? displayNameValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Thông tin bắt buộc';
  }
  
  final trimmed = value.trim();
  
  if (trimmed.length < 2 || trimmed.length > 50) {
    return 'Tên hiển thị phải từ 2-50 ký tự';
  }
  
  return null;
}

// Validator để confirm password - nhận password gốc làm tham số
String? confirmPasswordValidator(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Thông tin bắt buộc';
  }
  
  if (value != password) {
    return 'Mật khẩu không khớp';
  }
  
  return null;
}
