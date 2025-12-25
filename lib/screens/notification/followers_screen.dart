import 'package:flutter/material.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<Map<String, dynamic>> followers = [
    {
      'id': 1,
      'userName': 'thuong12_pp',
      'fullName': 'Phan Phạm Hu...',
      'isFollowingBack': true,
      'avatar': null,
    },
    {
      'id': 2,
      'userName': 'bllllllys',
      'fullName': 'Phan Bao Ly',
      'isFollowingBack': true,
      'avatar': 'https://i.pravatar.cc/150?img=2',
    },
    {
      'id': 3,
      'userName': 'phanthanhtri...',
      'fullName': 'Phan Thanh Tri...',
      'isFollowingBack': true,
      'avatar': null,
    },
    {
      'id': 4,
      'userName': '_tine07_',
      'fullName': 'Tuyết Trinh',
      'isFollowingBack': true,
      'avatar': 'https://i.pravatar.cc/150?img=4',
    },
    {
      'id': 5,
      'userName': 'bloomie_flow...',
      'fullName': 'Bloomie.Flower',
      'isFollowingBack': true,
      'avatar': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'id': 6,
      'userName': 'phanthidiem...',
      'fullName': 'Phan Thị Diễm...',
      'isFollowingBack': true,
      'avatar': 'https://i.pravatar.cc/150?img=6',
    },
    {
      'id': 7,
      'userName': 'haovann_02',
      'fullName': 'Van Hao',
      'isFollowingBack': true,
      'avatar': 'https://i.pravatar.cc/150?img=7',
    },
    {
      'id': 8,
      'userName': 'trkien.29',
      'fullName': 'Trần Kiên',
      'isFollowingBack': false,
      'avatar': null,
    },
    {
      'id': 9,
      'userName': 'myx_iu179',
      'fullName': 'Đào Thị Mỹ',
      'isFollowingBack': true,
      'avatar': null,
    },
    {
      'id': 10,
      'userName': 'thanhnhi.2509',
      'fullName': 'Thanh Nhi',
      'isFollowingBack': false,
      'avatar': 'https://i.pravatar.cc/150?img=10',
    },
  ];

  void _toggleFollowBack(int id) {
    setState(() {
      final index = followers.indexWhere((follower) => follower['id'] == id);
      if (index != -1) {
        followers[index]['isFollowingBack'] = !followers[index]['isFollowingBack'];

        final userName = followers[index]['userName'];
        final isFollowing = followers[index]['isFollowingBack'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isFollowing
                    ? 'Đã theo dõi lại $userName'
                    : 'Đã bỏ theo dõi $userName'
            ),
            backgroundColor: isFollowing ? Colors.blue : Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _removeFollower(int id, String userName) {
    setState(() {
      followers.removeWhere((follower) => follower['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa $userName khỏi danh sách người theo dõi'),
        backgroundColor: Colors.grey[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveDialog(int id, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa người theo dõi'),
          content: Text('Bạn có chắc muốn xóa $userName khỏi danh sách người theo dõi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFollower(id, userName);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tất cả người theo dõi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: followers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'Chưa có người theo dõi nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: followers.length,
        itemBuilder: (context, index) {
          final follower = followers[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 28,
                  backgroundImage: follower['avatar'] != null
                      ? NetworkImage(follower['avatar'])
                      : null,
                  child: follower['avatar'] == null
                      ? Text(
                    follower['userName']![0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        follower['userName'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        follower['fullName'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action button
                SizedBox(
                  width: 120,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _toggleFollowBack(follower['id'] as int),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: follower['isFollowingBack']
                          ? Colors.grey[200]
                          : Colors.blue,
                      foregroundColor: follower['isFollowingBack']
                          ? Colors.black
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: Text(
                      follower['isFollowingBack'] ? 'Theo dõi lại' : 'Nhắn tin',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Remove button
                GestureDetector(
                  onTap: () => _showRemoveDialog(
                    follower['id'] as int,
                    follower['userName'] as String,
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}