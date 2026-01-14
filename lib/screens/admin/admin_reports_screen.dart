import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/admin_service.dart';
import '../../services/firestore_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _adminService = AdminService();
  final _firestoreService = FirestoreService();
  String _status = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: StreamBuilder<List<ReportModel>>(
        stream: _adminService.getReportsStream(status: _status),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) return const _EmptyView();

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (_, i) => _ReportCard(
              report: reports[i],
              firestore: _firestoreService,
              adminService: _adminService,
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Báo cáo vi phạm'),
      backgroundColor: const Color(0xFF006CFF),
      foregroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildFilters(),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            _filterChip('Chờ xử lý', 'pending'),
            _filterChip('Đã xử lý', 'resolved'),
            _filterChip('Đã bỏ qua', 'dismissed'),
            _filterChip('Tất cả', 'all'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF006CFF),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
        onSelected: (_) => setState(() => _status = value),
      ),
    );
  }
}

/* ================= REPORT CARD ================= */

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final FirestoreService firestore;
  final AdminService adminService;

  const _ReportCard({
    required this.report,
    required this.firestore,
    required this.adminService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReportData>(
      future: _loadData(),
      builder: (_, snap) {
        if (!snap.hasData) return const _LoadingCard();
        final d = snap.data!;
        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(report),
              _Info(d.reporter, d.owner),
              _Reason(report.reason),
              _PostPreview(report, d.post),
              if (report.status == 'pending') _Actions(report, adminService),
            ],
          ),
        );
      },
    );
  }

  Future<_ReportData> _loadData() async {
    final reporter = await firestore.getUser(report.reportedBy);
    final owner = await firestore.getUser(report.postOwnerId);
    final post = await firestore.getPost(report.postId);
    return _ReportData(reporter, owner, post);
  }
}

/* ================= UI BLOCKS ================= */

class _Header extends StatelessWidget {
  final ReportModel r;
  const _Header(this.r);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(r.status);
    return Container(
      padding: const EdgeInsets.all(12),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Icon(_statusIcon(r.status), color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusText(r.status),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            timeago.format(r.createdAt, locale: 'vi'),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final UserModel? reporter;
  final UserModel? owner;
  const _Info(this.reporter, this.owner);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Người báo cáo: ${reporter?.displayName ?? "Unknown"}'),
          Text('Chủ bài viết: ${owner?.displayName ?? "Unknown"}'),
        ],
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  final String text;
  const _Reason(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade100,
        child: Text(text),
      ),
    );
  }
}

class _PostPreview extends StatelessWidget {
  final ReportModel r;
  final PostModel? post;

  const _PostPreview(this.r, this.post);

  @override
  Widget build(BuildContext context) {
    final caption = post?.caption ?? r.postCaption ?? '';
    String? image;
    if (post != null && post!.imageUrls.isNotEmpty) {
      image = post!.imageUrls.first;
    } else if (r.postImageUrls != null && r.postImageUrls!.isNotEmpty) {
      image = r.postImageUrls!.first;
    }

    if (caption.isEmpty && image == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bài viết bị báo cáo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (caption.isNotEmpty)
            Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (image != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.network(
                image,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final ReportModel report;
  final AdminService service;

  const _Actions(this.report, this.service);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Xóa bài viết',
                style: TextStyle(color: Colors.red),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                elevation: 0,
              ),
              onPressed: () => service.resolveReportAndDeletePost(
                report.reportId,
                report.postId,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Bỏ qua'),
              onPressed: () => service.dismissReport(report.reportId),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= HELPERS ================= */

class _ReportData {
  final UserModel? reporter;
  final UserModel? owner;
  final PostModel? post;
  _ReportData(this.reporter, this.owner, this.post);
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 12),
          Text('Không có báo cáo nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/* ================= STATUS HELPERS ================= */

Color _statusColor(String s) {
  switch (s) {
    case 'pending':
      return Colors.orange;
    case 'resolved':
      return Colors.green;
    case 'dismissed':
      return Colors.grey;
    default:
      return Colors.blue;
  }
}

IconData _statusIcon(String s) {
  switch (s) {
    case 'pending':
      return Icons.pending;
    case 'resolved':
      return Icons.check_circle;
    case 'dismissed':
      return Icons.cancel;
    default:
      return Icons.flag;
  }
}

String _statusText(String s) {
  switch (s) {
    case 'pending':
      return 'Chờ xử lý';
    case 'resolved':
      return 'Đã xử lý';
    case 'dismissed':
      return 'Đã bỏ qua';
    default:
      return s;
  }
}
