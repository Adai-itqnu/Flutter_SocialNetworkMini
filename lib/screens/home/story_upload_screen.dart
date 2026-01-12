import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StoryUploadScreen extends StatefulWidget {
  const StoryUploadScreen({super.key});

  @override
  State<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _textController = TextEditingController();
  Offset _textPosition = const Offset(50, 100);
  double _textScale = 1.0;
  Color _textColor = Colors.white;
  bool _isEditingText = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<Size> _getImageSize(String path) async {
    final Completer<Size> completer = Completer<Size>();
    final ImageStream stream = FileImage(File(path)).resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
        stream.removeListener(listener!);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.completeError(exception, stackTrace);
        stream.removeListener(listener!);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => const Size(400, 800));
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
      maxHeight: 1920,
    );
    if (image != null && mounted) {
      final size = await _getImageSize(image.path).catchError((_) => const Size(400, 800));
      setState(() {
        _image = image;
        _textPosition = Offset(
          (size.width / 2) - 100,
          (size.height / 2) - 50,
        );
      });
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _submitStory() {
    if (_image == null || _textController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ảnh và nhập nội dung'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    // TODO: Upload logic here (e.g., save to Firebase, etc.)
    if (mounted) Navigator.pop(context, {
      'image': _image!.path,
      'text': _textController.text,
      'position': _textPosition,
      'scale': _textScale,
      'color': _textColor,
    });
  }

  void _showTextOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Tùy chỉnh văn bản',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Slider(
              value: _textScale,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
              onChanged: (value) => setState(() => _textScale = value),
            ),
            const Text('Kích thước', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _textColor = Colors.white),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _textColor = Colors.yellow),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _textColor = Colors.pink),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Tạo tin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: _submitStory,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Đăng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _image == null
          ? _buildEmptyState(size)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  // Image with zoom and pan
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      child: Image.file(
                        File(_image!.path),
                        fit: BoxFit.contain,
                        width: size.width,
                        height: size.height,
                      ),
                    ),
                  ),
                  // Draggable Text Overlay
                  Positioned(
                    left: _textPosition.dx,
                    top: _textPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _textPosition += details.delta;
                          // Boundary constraints
                          _textPosition = Offset(
                            _textPosition.dx.clamp(0.0, size.width - 200),
                            _textPosition.dy.clamp(0.0, size.height - 100),
                          );
                        });
                      },
                      onTap: _showTextOptions,
                      child: Transform.scale(
                        scale: _textScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _textController.text.isEmpty
                                ? 'Nhập văn bản...'
                                : _textController.text,
                            style: TextStyle(
                              fontSize: 24 * _textScale,
                              color: _textColor,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Text Input Bar
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _textController,
                          onChanged: (_) => _onTextChanged(),
                          onTap: () => setState(() => _isEditingText = true),
                          onSubmitted: (_) => setState(() => _isEditingText = false),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Thêm chú thích...',
                            hintStyle: TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            suffixIcon: _textController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white60),
                                    onPressed: () {
                                      _textController.clear();
                                      _onTextChanged();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: Colors.white60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn ảnh để tạo tin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Từ thư viện'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}