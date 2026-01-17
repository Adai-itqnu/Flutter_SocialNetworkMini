import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'user_firestore_service.dart';
import 'post_firestore_service.dart';
import 'comment_firestore_service.dart';
import 'follow_firestore_service.dart';

/// FirestoreService - Facade class để giữ backward compatibility
/// Delegate tới các service chuyên biệt (clean architecture)
class FirestoreService {
  final UserFirestoreService _userService = UserFirestoreService();
  final PostFirestoreService _postService = PostFirestoreService();
  final CommentFirestoreService _commentService = CommentFirestoreService();
  final FollowFirestoreService _followService = FollowFirestoreService();

  // User operations
  Future<UserModel?> getUser(String uid) => _userService.getUser(uid);
  Future<void> updateUser(String uid, Map<String, dynamic> data) => _userService.updateUser(uid, data);
  Future<void> updateUserRole(String uid, String role) => _userService.updateUserRole(uid, role);
  Future<List<UserModel>> getAllUsers({int limit = 50}) => _userService.getAllUsers(limit: limit);
  Future<List<UserModel>> searchUsers(String query) => _userService.searchUsers(query);

  // Post operations
  Future<String> createPost({required String userId, required String caption, required List<String> imageUrls, PostVisibility visibility = PostVisibility.public}) => 
      _postService.createPost(userId: userId, caption: caption, imageUrls: imageUrls, visibility: visibility);
  Stream<List<PostModel>> getPosts() => _postService.getPosts();
  Stream<List<PostModel>> getUserPosts(String userId) => _postService.getUserPosts(userId);
  Future<PostModel?> getPost(String postId) => _postService.getPost(postId);
  Stream<PostModel?> getPostStream(String postId) => _postService.getPostStream(postId);
  Future<void> updatePost(String postId, Map<String, dynamic> data) => _postService.updatePost(postId, data);
  Future<void> deletePost(String postId, String userId) => _postService.deletePost(postId, userId);
  Future<List<PostModel>> searchPosts(String query) => _postService.searchPosts(query);

  // Like operations
  Future<void> likePost(String postId, String userId) => _postService.likePost(postId, userId);
  Future<void> unlikePost(String postId, String userId) => _postService.unlikePost(postId, userId);
  Future<bool> hasLikedPost(String postId, String userId) => _postService.hasLikedPost(postId, userId);

  // Share post operations
  Future<String> sharePost({required String userId, required String caption, required String sharedPostId, required String sharedUserId}) =>
      _postService.sharePost(userId: userId, caption: caption, sharedPostId: sharedPostId, sharedUserId: sharedUserId);

  // Saved posts operations
  Future<void> savePost(String userId, String postId) => _postService.savePost(userId, postId);
  Future<void> unsavePost(String userId, String postId) => _postService.unsavePost(userId, postId);
  Future<bool> hasSavedPost(String userId, String postId) => _postService.hasSavedPost(userId, postId);
  Future<List<PostModel>> getSavedPosts(String userId) => _postService.getSavedPosts(userId);
  Future<Set<String>> getSavedPostIds(String userId) => _postService.getSavedPostIds(userId);

  // Comment operations
  Future<String> addComment({required String postId, required String userId, required String text, String? parentCommentId}) =>
      _commentService.addComment(postId: postId, userId: userId, text: text, parentCommentId: parentCommentId);
  Stream<List<CommentModel>> getComments(String postId) => _commentService.getComments(postId);
  Future<void> deleteComment(String commentId, String postId) => _commentService.deleteComment(commentId, postId);

  // Comment like operations
  Future<void> likeComment(String commentId, String userId) => _commentService.likeComment(commentId, userId);
  Future<void> unlikeComment(String commentId, String userId) => _commentService.unlikeComment(commentId, userId);
  Future<bool> hasLikedComment(String commentId, String userId) => _commentService.hasLikedComment(commentId, userId);
  Stream<List<CommentModel>> getReplies(String parentCommentId) => _commentService.getReplies(parentCommentId);

  // Follow operations
  Future<void> followUser(String followerId, String followingId) => _followService.followUser(followerId, followingId);
  Future<void> unfollowUser(String followerId, String followingId) => _followService.unfollowUser(followerId, followingId);
  Future<bool> isFollowing(String followerId, String followingId) => _followService.isFollowing(followerId, followingId);
  Future<List<String>> getFollowers(String userId) => _followService.getFollowers(userId);
  Future<List<String>> getFollowing(String userId) => _followService.getFollowing(userId);
}
