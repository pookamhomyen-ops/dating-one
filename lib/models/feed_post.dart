import 'gender.dart';

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorGender,
    required this.authorPhotoUrl,
    required this.content,
    required this.postedAt,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.likedByMe = false,
    this.dislikedByMe = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final Gender authorGender;
  final String authorPhotoUrl;
  final String content;
  final DateTime postedAt;
  final String? imageUrl;
  final int likes;
  final int comments;
  final bool likedByMe;
  final bool dislikedByMe;

  FeedPost copyWith({
    int? likes,
    int? comments,
    bool? likedByMe,
    bool? dislikedByMe,
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorGender: authorGender,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      postedAt: postedAt,
      imageUrl: imageUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedByMe: likedByMe ?? this.likedByMe,
      dislikedByMe: dislikedByMe ?? this.dislikedByMe,
    );
  }
}
