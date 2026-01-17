import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../profile/user_profile_screen.dart';

/// Màn hình tìm kiếm người dùng và bài viết
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = false;

  List<UserModel> _filteredUsers = [];
  List<PostModel> _filteredPosts = [];
  Map<String, UserModel> _postAuthors = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Xử lý khi nội dung search thay đổi
  void _onSearchChanged() {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _isSearching = false;
        _filteredUsers = [];
        _filteredPosts = [];
      });
    } else if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _isSearching = true;
      });
      _performSearch(query);
    }
  }

  // Thực hiện tìm kiếm người dùng và bài viết
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Tìm kiếm song song
      final results = await Future.wait([
        _firestoreService.searchUsers(query),
        _firestoreService.searchPosts(query),
      ]);

      final users = results[0] as List<UserModel>;
      final posts = results[1] as List<PostModel>;

      // Load tác giả của các bài viết
      for (final post in posts) {
        if (!_postAuthors.containsKey(post.userId)) {
          final author = await _firestoreService.getUser(post.userId);
          if (author != null) {
            _postAuthors[post.userId] = author;
          }
        }
      }

      if (mounted && _searchQuery == query) {
        setState(() {
          _filteredUsers = users;
          _filteredPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Điều hướng đến profile người dùng
  void _navigateToProfile(String userId) {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đây là trang cá nhân của bạn')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 600 ? 24.0 : 12.0;

    return CustomScrollView(
      slivers: [
        // Ô tìm kiếm
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 16),
            child: _buildSearchBar(),
          ),
        ),

        // Loading
        if (_isLoading) _buildLoading(),

        // Gợi ý tìm kiếm (khi chưa search)
        if (!_isSearching) _buildSuggestions(horizontalPadding),

        // Kết quả người dùng
        if (_isSearching && !_isLoading && _filteredUsers.isNotEmpty)
          _buildUsersSection(horizontalPadding),

        // Kết quả bài viết
        if (_isSearching && !_isLoading && _filteredPosts.isNotEmpty)
          _buildPostsSection(horizontalPadding),

        // Không có kết quả
        if (_isSearching && !_isLoading && _filteredUsers.isEmpty && _filteredPosts.isEmpty)
          _buildNoResults(),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // Ô tìm kiếm
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm người dùng, bài viết...',
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.black54),
                onPressed: () => _searchCtrl.clear(),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }

  // Loading indicator
  Widget _buildLoading() {
    return const SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  // Gợi ý tìm kiếm
  Widget _buildSuggestions(double padding) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gợi ý tìm kiếm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSearchChip('Flutter'),
                _buildSearchChip('Dart'),
                _buildSearchChip('UI Design'),
                _buildSearchChip('Social Media'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Chip gợi ý
  Widget _buildSearchChip(String label) {
    return ChoiceChip(
      label: Text(label),
      onSelected: (_) => _searchCtrl.text = label,
      selected: false,
      backgroundColor: Colors.grey[200],
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }

  // Section kết quả người dùng
  Widget _buildUsersSection(double padding) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Người dùng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._filteredUsers.map((user) => _buildUserCard(user)),
          ],
        ),
      ),
    );
  }

  // Card người dùng
  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _navigateToProfile(user.uid),
        leading: _buildAvatar(user.photoURL),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('@${user.username}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // Section kết quả bài viết
  Widget _buildPostsSection(double padding) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Bài viết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._filteredPosts.map((post) => _buildPostCard(post)),
          ],
        ),
      ),
    );
  }

  // Card bài viết
  Widget _buildPostCard(PostModel post) {
    final author = _postAuthors[post.userId];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (author != null) _navigateToProfile(post.userId);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với avatar và tên tác giả
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: _buildAvatar(author?.photoURL, size: 20),
              title: Text(
                author?.displayName ?? 'Người dùng',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('@${author?.username ?? ''}'),
            ),

            // Ảnh bài viết
            if (post.imageUrls.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                ),
              ),

            // Caption
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Avatar
  Widget _buildAvatar(String? photoURL, {double size = 24}) {
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;
    return CircleAvatar(
      backgroundColor: Colors.grey[300],
      backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoURL) : null,
      child: !hasPhoto ? Icon(Icons.person, color: Colors.white, size: size) : null,
    );
  }

  // Không có kết quả
  Widget _buildNoResults() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử từ khóa khác',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}