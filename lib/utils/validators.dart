String? requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Thông tin bắt buộc';
  }
  return null;
}

