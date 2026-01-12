import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  int _selectedIndex = 3; // Đang ở tab bạn bè (index 3)
  bool _isAddPressed = false; // trạng thái nhấn nút +

  List<Map<String, dynamic>> friendRequests = [
    {
      'id': 1,
      'userName': 'Đỗ Văn F',
      'mutualFriends': 12,
      'time': '1 tuần trước',
    },
    {
      'id': 2,
      'userName': 'Vũ Thị G',
      'mutualFriends': 5,
      'time': '2 tuần trước',
    },
    {
      'id': 3,
      'userName': 'Bùi Văn H',
      'mutualFriends': 8,
      'time': '3 tuần trước',
    },
    {
      'id': 4,
      'userName': 'Mai Thị I',
      'mutualFriends': 20,
      'time': '1 tháng trước',
    },
  ];

  Future<void> _onNavTapped(int index) async {
    // 0: home, 1: search, 2: add, 3: friends, 4: profile
    if (index != 3 && index != 2) {
      // Về các tab khác: pop với index để home sync
      Navigator.pop(context, index);
      return;
    }

    if (index == 2) {
      // nút tạo: đi thẳng tới CreatePostScreen (hoặc options)
      setState(() => _isAddPressed = true);
      await Navigator.of(context).pushNamed('/create-post'); // Hoặc push MaterialPageRoute
      if (!mounted) return;
      setState(() => _isAddPressed = false);
      return;
    }

    // index 3: không làm gì (đang ở đây)
  }

  void _acceptRequest(int id, String userName) {
    setState(() {
      friendRequests.removeWhere((request) => request['id'] == id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chấp nhận lời mời từ $userName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _rejectRequest(int id, String userName) {
    setState(() {
      friendRequests.removeWhere((request) => request['id'] == id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối lời mời từ $userName'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Lời mời kết bạn',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: friendRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_disabled_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có lời mời kết bạn nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: friendRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final request = friendRequests[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.pink[100],
                              child: Text(
                                (request['userName'] as String)[0],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['userName'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${request['mutualFriends']} bạn chung',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    request['time'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _acceptRequest(
                                  request['id'] as int,
                                  request['userName'] as String,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[500],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Chấp nhận',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _rejectRequest(
                                  request['id'] as int,
                                  request['userName'] as String,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: const Text(
                                  'Từ chối',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}