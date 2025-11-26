import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';
import '../home/create_post_screen.dart'; // chỉnh path nếu khác

class UserProfile {
  const UserProfile({
    required this.name,
    required this.username,
    required this.bio,
    required this.pronouns,
    required this.tagline,
    required this.link,
    required this.posts,
    required this.followers,
    required this.following,
    required this.gender,
    required this.showThreadsBadge,
  });

  final String name;
  final String username;
  final String bio;
  final String pronouns;
  final String tagline;
  final String link;
  final int posts;
  final int followers;
  final int following;
  final String gender;
  final bool showThreadsBadge;

  UserProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? pronouns,
    String? tagline,
    String? link,
    int? posts,
    int? followers,
    int? following,
    String? gender,
    bool? showThreadsBadge,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      pronouns: pronouns ?? this.pronouns,
      tagline: tagline ?? this.tagline,
      link: link ?? this.link,
      posts: posts ?? this.posts,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      gender: gender ?? this.gender,
      showThreadsBadge: showThreadsBadge ?? this.showThreadsBadge,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile = const UserProfile(
    name: 'Tran Anh Dai',
    username: '_adaidf',
    bio: '',
    pronouns: '',
    tagline: 'Changes',
    link: '',
    posts: 0,
    followers: 12,
    following: 17,
    gender: 'Nam',
    showThreadsBadge: false,
  );

  // 0: home, 1: search, 2: add, 3: friends, 4: profile
  int _selectedIndex = 4; // đang ở tab profile
  bool _isAddPressed = false;

  Future<void> _onNavTapped(int index) async {
    if (index != 4 && index != 2) {
      // Về các tab khác: pop với index để home sync
      Navigator.pop(context, index);
      return;
    }

    if (index == 2) {
      // nút tạo: đi thẳng tới CreatePostScreen
      setState(() => _isAddPressed = true);
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );
      if (!mounted) return;
      setState(() => _isAddPressed = false);
      return;
    }

    // index 4: không làm gì
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              Text(
                _profile.username,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 18),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.black),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.menu, color: Colors.black)),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _ProfileHeader(profile: _profile, onEdit: _openEditProfile),
                  const SizedBox(height: 12),
                  _ProfessionalToolsCard(theme: theme),
                  const SizedBox(height: 12),
                  _ProfileActions(onEdit: _openEditProfile),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileTabBarDelegate(
                const TabBar(
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on, size: 20, color: Colors.black)),
                    Tab(icon: Icon(Icons.video_collection_outlined, size: 22, color: Colors.black)),
                    Tab(icon: Icon(Icons.person_pin_outlined, size: 22, color: Colors.black)),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _EmptyPostsSection(profile: _profile),
              _EmptyPostsSection(
                profile: _profile,
                description: 'Video sẽ hiển thị tại đây sau khi bạn đăng.',
              ),
              _EmptyPostsSection(
                profile: _profile,
                description: 'Ảnh và video được gắn thẻ sẽ hiển thị tại đây.',
                showCreateButton: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile)),
    );

    if (updated != null) {
      setState(() => _profile = updated);
    }
  }
}

// ================== CÁC PHẦN CÒN LẠI GIỮ NGUYÊN ==================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Avatar(),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      count: profile.posts.toString(),
                      label: 'bài viết',
                    ),
                    _StatItem(
                      count: profile.followers.toString(),
                      label: 'người theo dõi',
                    ),
                    _StatItem(
                      count: profile.following.toString(),
                      label: 'đang theo dõi',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(profile.name, style: textTheme.titleMedium),
          if (profile.tagline.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.tagline,
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(profile.bio, style: textTheme.bodyMedium),
          ],
          if (profile.link.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    profile.link,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.pink, Colors.purple],
            ),
          ),
        ),
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        const CircleAvatar(
          radius: 34,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person_outline, size: 32, color: Colors.white),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ProfessionalToolsCard extends StatelessWidget {
  const _ProfessionalToolsCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Công cụ chuyên nghiệp',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(
              'Công cụ và nguồn lực dành riêng cho người sáng tạo nội dung.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              child: const Text('Chỉnh sửa trang cá nhân'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Chia sẻ trang cá nhân'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmptyPostsSection extends StatelessWidget {
  const _EmptyPostsSection({
    required this.profile,
    this.description =
        'Biến không gian này thành của riêng bạn bằng cách chia sẻ.',
    this.showCreateButton = true,
  });

  final UserProfile profile;
  final String description;
  final bool showCreateButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 96,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Tạo bài viết đầu tiên',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text('Tạo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  _ProfileTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_ProfileTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}