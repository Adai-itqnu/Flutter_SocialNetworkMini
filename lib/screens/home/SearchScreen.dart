import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Dữ liệu mẫu cho kết quả tìm kiếm (users và posts)
  final List<Map<String, String>> _sampleUsers = [
    {'name': 'buitruonggiang', 'username': '@buitruonggiang', 'avatar': 'https://i.pravatar.cc/150?img=1'},
    {'name': 'linguyen', 'username': '@linguyen', 'avatar': 'https://i.pravatar.cc/150?img=2'},
    {'name': 'meokun', 'username': '@meokun', 'avatar': 'https://i.pravatar.cc/150?img=3'},
    {'name': 'travel_love', 'username': '@travel_love', 'avatar': 'https://i.pravatar.cc/150?img=4'},
    {'name': 'photography', 'username': '@photography', 'avatar': 'https://i.pravatar.cc/150?img=5'},
  ];

  final List<Map<String, String>> _samplePosts = List.generate(
    5,
    (i) => {
      'author': 'user$i',
      'avatar': 'https://i.pravatar.cc/150?img=${10 + i}',
      'image': 'https://picsum.photos/seed/search$i/400/400',
      'caption': 'Kết quả tìm kiếm demo số ${i + 1}',
    },
  );

  List<Map<String, String>> _filteredUsers = [];
  List<Map<String, String>> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = List.from(_sampleUsers);
    _filteredPosts = List.from(_samplePosts);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
      if (_isSearching) {
        _filteredUsers = _sampleUsers.where((user) =>
            user['name']!.toLowerCase().contains(_searchQuery) ||
            user['username']!.toLowerCase().contains(_searchQuery)).toList();
        _filteredPosts = _samplePosts.where((post) =>
            post['author']!.toLowerCase().contains(_searchQuery) ||
            post['caption']!.toLowerCase().contains(_searchQuery)).toList();
      } else {
        _filteredUsers = List.from(_sampleUsers);
        _filteredPosts = List.from(_samplePosts);
      }
    });
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng, bài viết...',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black54),
                        onPressed: () => _searchController.clear(),
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
        // Recent searches or suggestions if not searching
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
        if (_isSearching && _filteredUsers.isNotEmpty)
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
        if (_isSearching && _filteredPosts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
        if (_isSearching && _filteredUsers.isEmpty && _filteredPosts.isEmpty)
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
      onSelected: (_) => _searchController.text = label,
      selected: false,
      backgroundColor: Colors.grey[200],
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }

  Widget _buildUserResult(Map<String, String> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(user['avatar']!)),
        title: Text(user['name']!),
        subtitle: Text(user['username']!),
        trailing: ElevatedButton(
          onPressed: () {
            // Navigate to profile
          },
          child: const Text('Theo dõi'),
        ),
      ),
    );
  }

  Widget _buildPostResult(Map<String, String> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundImage: NetworkImage(post['avatar']!)),
            title: Text(post['author']!, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.more_vert),
          ),
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[200],
            child: Image.network(post['image']!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              post['caption']!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}