import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../profile/user_profile_screen.dart';

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

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Search users and posts in parallel
      final results = await Future.wait([
        _firestoreService.searchUsers(query),
        _firestoreService.searchPosts(query),
      ]);

      final users = results[0] as List<UserModel>;
      final posts = results[1] as List<PostModel>;

      // Load authors for posts
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
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 16),
            child: TextField(
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
            ),
          ),
        ),

        // Loading indicator
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )),
          ),

        // Suggestions when not searching
        if (!_isSearching)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
          ),

        // Users results
        if (_isSearching && !_isLoading && _filteredUsers.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Người dùng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ..._filteredUsers.map((user) => _buildUserResult(user)),
                ],
              ),
            ),
          ),

        // Posts results
        if (_isSearching && !_isLoading && _filteredPosts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Bài viết',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ..._filteredPosts.map((post) => _buildPostResult(post)),
                ],
              ),
            ),
          ),

        // No results
        if (_isSearching && !_isLoading && _filteredUsers.isEmpty && _filteredPosts.isEmpty)
          SliverFillRemaining(
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
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSearchChip(String label) {
    return ChoiceChip(
      label: Text(label),
      onSelected: (_) => _searchCtrl.text = label,
      selected: false,
      backgroundColor: Colors.grey[200],
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }

  Widget _buildUserResult(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _navigateToProfile(user.uid),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
              ? CachedNetworkImageProvider(user.photoURL!)
              : null,
          child: user.photoURL == null || user.photoURL!.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('@${user.username}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildPostResult(PostModel post) {
    final author = _postAuthors[post.userId];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (author != null) {
            _navigateToProfile(post.userId);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage: author?.photoURL != null && author!.photoURL!.isNotEmpty
                    ? CachedNetworkImageProvider(author.photoURL!)
                    : null,
                child: author?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              title: Text(
                author?.displayName ?? 'Người dùng',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('@${author?.username ?? ''}'),
            ),
            if (post.imageUrls.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                ),
              ),
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
}