import 'package:flutter/material.dart';

/// Delegate cho TabBar trong profile (pinned header)
class ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  ProfileTabBarDelegate(this.tabBar);

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
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(ProfileTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
