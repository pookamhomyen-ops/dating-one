import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class CreatePostSheet extends StatefulWidget {
  final VoidCallback onPosted;
  const CreatePostSheet({super.key, required this.onPosted});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _supabase = Supabase.instance.client;
  final _ctrl = TextEditingController();
  XFile? _pickedImage;
  bool _isPosting = false;
  static const int _maxChars = 250;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    int quality = 85;
    File? result;
    while (quality >= 20) {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path, targetPath,
        quality: quality, format: CompressFormat.jpeg,
      );
      if (compressed == null) break;
      result = File(compressed.path);
      if (await result.length() <= 300 * 1024) break;
      quality -= 15;
    }
    return result ?? file;
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isPosting) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isPosting = true);
    try {
      final postRes = await _supabase.from('posts').insert({
        'author_id': userId,
        'content': text,
        'is_published': true,
      }).select('id').single();
      final postId = postRes['id'] as String;

      if (_pickedImage != null) {
        final file = File(_pickedImage!.path);
        final compressed = await _compressImage(file);
        final storagePath = '$userId/$postId.jpg';
        await _supabase.storage.from('post-media').upload(
          storagePath, compressed,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        final publicUrl = _supabase.storage.from('post-media').getPublicUrl(storagePath);
        await _supabase.from('post_media').insert({
          'post_id': postId,
          'storage_path': storagePath,
          'public_url': publicUrl,
          'media_type': 'image',
          'sort_order': 0,
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPosted();
      }
    } catch (e) {
      debugPrint('Post Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โพสไม่สำเร็จ: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxChars - _ctrl.text.length;
    final isOverLimit = remaining < 0;
    final canPost = _ctrl.text.trim().isNotEmpty && !isOverLimit && !_isPosting;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  const Text('✍️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text('เขียนโพสใหม่', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: canPost ? _submit : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: canPost ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFEC4899)]) : null,
                        color: canPost ? null : AppColors.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isPosting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('โพส 🚀', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: canPost ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'วันนี้เป็นยังไงบ้าง...?',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_pickedImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_pickedImage!.path), width: double.infinity, fit: BoxFit.contain, height: 200),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _pickedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                        children: [
                          Icon(Icons.image_rounded, size: 18, color: Color(0xFF7C4DFF)),
                          SizedBox(width: 6),
                          Text('รูปภาพ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF7C4DFF))),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isOverLimit ? AppColors.destructive : remaining <= 30 ? const Color(0xFFF97316) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
