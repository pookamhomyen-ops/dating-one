import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../theme/app_colors.dart';

class PhotoManagerScreen extends StatefulWidget {
  final String userId;

  const PhotoManagerScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  List<Map<String, dynamic>> _existingPhotos = [];
  List<XFile> _pendingAdd = [];
  List<Map<String, dynamic>> _pendingDelete = [];
  bool _isLoading = true;
  bool _isSaving = false;
  int _primaryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final data = await Supabase.instance.client
          .from('profile_photos')
          .select()
          .eq('profile_id', widget.userId)
          .order('sort_order');
      
      if (mounted) {
        final List<Map<String, dynamic>> photos = List<Map<String, dynamic>>.from(data);
        int pIndex = 0;
        for (int i = 0; i < photos.length; i++) {
          if (photos[i]['is_primary'] == true) {
            pIndex = i;
            break;
          }
        }

        setState(() {
          _existingPhotos = photos;
          _primaryIndex = pIndex;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading photos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickPhotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    final int currentTotal = _existingPhotos.length + _pendingAdd.length;
    final int canAddCount = 5 - currentTotal;

    if (canAddCount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณสามารถอัปโหลดได้สูงสุด 5 รูป')),
        );
      }
      return;
    }

    // Take only what's allowed
    final List<XFile> toProcess = pickedFiles.take(canAddCount).toList();
    
    int oversizedCount = 0;
    final List<XFile> validFiles = [];

    for (var x in toProcess) {
      // Allow up to 10MB in UI, but we'll compress them later
      if (File(x.path).lengthSync() > 10 * 1024 * 1024) {
        oversizedCount++;
      } else {
        validFiles.add(x);
      }
    }

    if (oversizedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('พบ $oversizedCount รูป มีขนาดเกิน 10 MB จึงถูกข้ามไป')),
      );
    }

    if (validFiles.isNotEmpty) {
      setState(() {
        _pendingAdd.addAll(validFiles);
      });
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      if (index < _existingPhotos.length) {
        _pendingDelete.add(_existingPhotos[index]);
        _existingPhotos.removeAt(index);
      } else {
        final pendingIndex = index - _existingPhotos.length;
        _pendingAdd.removeAt(pendingIndex);
      }
      
      if (_primaryIndex >= (_existingPhotos.length + _pendingAdd.length)) {
        _primaryIndex = (_existingPhotos.length + _pendingAdd.length) - 1;
        if (_primaryIndex < 0) _primaryIndex = 0;
      }
    });
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');
    
    // Initial compression at 80% quality
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;
    
    File compressedFile = File(result.path);
    
    // If still > 5MB, try harder
    if (compressedFile.lengthSync() > 5 * 1024 * 1024) {
      result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      if (result != null) compressedFile = File(result.path);
    }

    return compressedFile;
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      // 1. Process deletions
      for (var photo in _pendingDelete) {
        try {
          await Supabase.instance.client.storage
              .from('profile-photos')
              .remove([photo['storage_path']]);
        } catch (e) {
          debugPrint('Storage remove error (ignoring): $e');
        }

        await Supabase.instance.client
            .from('profile_photos')
            .delete()
            .eq('id', photo['id']);
      }

      // 2. Process additions & Collect all final photo IDs
      final List<Map<String, dynamic>> finalPhotos = [];
      
      // Existing ones that remain
      for (var p in _existingPhotos) {
        finalPhotos.add(p);
      }

      // New ones
      for (int i = 0; i < _pendingAdd.length; i++) {
        final xfile = _pendingAdd[i];
        File fileToUpload = File(xfile.path);
        
        // Compress if needed or always to be safe with 5MB Supabase limit
        final compressed = await _compressImage(fileToUpload);
        if (compressed != null) {
          fileToUpload = compressed;
        }

        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_new_$i.jpg';
        final String path = '${widget.userId}/$fileName';

        await Supabase.instance.client.storage
            .from('profile-photos')
            .upload(path, fileToUpload);

        final String publicUrl = Supabase.instance.client.storage
            .from('profile-photos')
            .getPublicUrl(path);

        // To avoid unique constraint (profile_id, sort_order) error, 
        // use a very high temporary sort_order that won't conflict.
        // We use 1000 + i to be safe.
        final res = await Supabase.instance.client.from('profile_photos').insert({
          'profile_id': widget.userId,
          'storage_path': path,
          'public_url': publicUrl,
          'sort_order': 1000 + i, 
          'is_primary': false,
        }).select().single();
        
        finalPhotos.add(res);
      }

      // 3. Create ordered list: Primary first, then others
      if (finalPhotos.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      if (_primaryIndex >= finalPhotos.length) _primaryIndex = 0;
      final primaryPhoto = finalPhotos[_primaryIndex];
      final otherPhotos = finalPhotos.where((p) => p['id'] != primaryPhoto['id']).toList();
      final orderedPhotos = [primaryPhoto, ...otherPhotos];

      // 4. Update sort_order + is_primary ทีละรูป (ไม่มี unique constraint แล้ว)
      for (int i = 0; i < orderedPhotos.length; i++) {
        debugPrint('Updating photo id: ${orderedPhotos[i]['id']}, sort_order: $i, is_primary: ${i == 0}');
        await Supabase.instance.client
            .from('profile_photos')
            .update({
              'sort_order': i,
              'is_primary': i == 0,
            })
            .eq('id', orderedPhotos[i]['id']);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving photos: $e');
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('413')) {
          errorMsg = 'ไฟล์มีขนาดใหญ่เกินไป แม้จะบีบอัดแล้ว กรุณาเลือกรูปอื่น';
        } else if (errorMsg.contains('23505')) {
          errorMsg = 'เกิดข้อผิดพลาดของลำดับรูปภาพ กรุณาลองใหม่อีกครั้ง';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $errorMsg'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _existingPhotos.length + _pendingAdd.length;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('จัดการรูปภาพ'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAll,
            child: const Text(
              'บันทึก',
              style: TextStyle(
                color: AppColors.brandPink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSaving) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'กดที่รูปภาพเพื่อเลือกเป็นรูปโปรไฟล์หลัก',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: totalCount + (totalCount < 5 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < totalCount) {
                        final bool isExisting = index < _existingPhotos.length;
                        final String? url = isExisting ? _existingPhotos[index]['public_url'] : null;
                        final File? file = isExisting ? null : File(_pendingAdd[index - _existingPhotos.length].path);
                        final bool isPrimary = _primaryIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => _primaryIndex = index),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: isPrimary 
                                      ? Border.all(color: AppColors.primary, width: 3)
                                      : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(isPrimary ? 9 : 12),
                                    child: isExisting 
                                      ? Image.network(url!, fit: BoxFit.cover)
                                      : Image.file(file!, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                              if (isPrimary)
                                const Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _deletePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.textPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: AppColors.background, size: 18),
                                  ),
                                ),
                              ),
                              if (!isExisting)
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPink,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ใหม่',
                                      style: TextStyle(color: AppColors.background, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      } else {
                        return GestureDetector(
                          onTap: _isSaving ? null : _pickPhotos,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text(
                                  'เพิ่มรูป',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
