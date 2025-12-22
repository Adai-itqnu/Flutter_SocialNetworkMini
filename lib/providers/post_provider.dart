import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class PostProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<PostModel> _posts = [];
  Map<String, UserModel> _postAuthors = {}; // Cache user data for posts
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PostModel> get posts => _posts;
  Map<String, UserModel> get postAuthors => _postAuthors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize post stream
  void initializePostStream() {
    _firestoreService.getPosts().listen(
      (List<PostModel> loadedPosts) async {
        _posts = loadedPosts;
        
        // Load author data for each post
        for (var post in _posts) {
          if (!_postAuthors.containsKey(post.userId)) {
            try {
              UserModel? author = await _firestoreService.getUser(post.userId);
              if (author != null) {
                _postAuthors[post.userId] = author;
              }
            } catch (e) {
              print('Error loading author data: $e');
            }
          }
        }
        
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Create post
  Future<bool> createPost({
    required String userId,
    required String caption,
    required List<String> imageUrls,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.createPost(
        userId: userId,
        caption: caption,
        imageUrls: imageUrls,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete post
  Future<bool> deletePost(String postId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deletePost(postId, userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestoreService.likePost(postId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestoreService.unlikePost(postId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check if user liked post
  Future<bool> hasLikedPost(String postId, String userId) async {
    return await _firestoreService.hasLikedPost(postId, userId);
  }

  // Get author for a post
  UserModel? getPostAuthor(String userId) {
    return _postAuthors[userId];
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
