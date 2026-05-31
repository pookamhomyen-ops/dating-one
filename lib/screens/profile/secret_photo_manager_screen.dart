import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../theme/app_colors.dart';

class SecretPhotoManagerScreen extends StatefulWidget {
  final String userId;

  const SecretPhotoManagerScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SecretPhotoManagerScreen> createState() => _SecretPhotoManagerScreenState();
}

class _SecretPhotoManagerScreenState extends State<SecretPhotoManagerScreen> {
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
          .from('secret_photos')
          .select()
          .eq('profile_id', widget.userId)
          .order('sort_order');
      
      if (mounted) {
        setState(() {
          _existingPhotos = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading private photos: $e');
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
    final int canAddCount = 10 - currentTotal;

    if (canAddCount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณสามารถอัปโหลดได้สูงสุด 10 รูป')),
        );
      }
      return;
    }

    final List<XFile> toProcess = pickedFiles.take(canAddCount).toList();

    int oversizedCount = 0;
    final List<XFile> validFiles = [];

    for (var x in toProcess) {
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
    final targetPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed_secret.jpg');
    
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;
    
    File compressedFile = File(result.path);
    
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
              .from('secret-photos')
              .remove([photo['storage_path']]);
        } catch (e) {
          debugPrint('Storage remove error (ignoring): $e');
        }

        await Supabase.instance.client
            .from('secret_photos')
            .delete()
            .eq('id', photo['id']);
      }

      // 2. Process additions
      final List<Map<String, dynamic>> finalPhotos = [];
      for (var p in _existingPhotos) {
        finalPhotos.add(p);
      }

      for (int i = 0; i < _pendingAdd.length; i++) {
        final xfile = _pendingAdd[i];
        File fileToUpload = File(xfile.path);

        final compressed = await _compressImage(fileToUpload);
        if (compressed != null) {
          fileToUpload = compressed;
        }

        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_private_$i.jpg';
        final String path = '${widget.userId}/$fileName';

        await Supabase.instance.client.storage
            .from('secret-photos')
            .upload(path, fileToUpload);

        final String publicUrl = Supabase.instance.client.storage
            .from('secret-photos')
            .getPublicUrl(path);

        final res = await Supabase.instance.client.from('secret_photos').insert({
          'profile_id': widget.userId,
          'storage_path': path,
          'public_url': publicUrl,
          'sort_order': 1000 + i,
        }).select().single();

        finalPhotos.add(res);
      }

      // 3. Create ordered list
      if (finalPhotos.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      if (_primaryIndex >= finalPhotos.length) _primaryIndex = 0;
      final primaryPhoto = finalPhotos[_primaryIndex];
      final otherPhotos = finalPhotos.where((p) => p['id'] != primaryPhoto['id']).toList();
      final orderedPhotos = [primaryPhoto, ...otherPhotos];

      // 4. Update all in database
      for (int i = 0; i < orderedPhotos.length; i++) {
        await Supabase.instance.client
            .from('secret_photos')
            .update({
              'sort_order': -(i + 1),
            })
            .eq('id', orderedPhotos[i]['id']);
      }

      for (int i = 0; i < orderedPhotos.length; i++) {
        await Supabase.instance.client
            .from('secret_photos')
            .update({
              'sort_order': i,
            })
            .eq('id', orderedPhotos[i]['id']);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving private photos: $e');
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('413')) {
          errorMsg = 'ไฟล์มีขนาดใหญ่เกินไป แม้จะบีบอัดแล้ว กรุณาเลือกรูปอื่น';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $errorMsg'), backgroundColor: Colors.red),
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
        title: const Text('จัดการรูปส่วนตัว'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAll,
            child: const Text(
              'บันทึก',
              style: TextStyle(
                color: AppColors.brandPink,
                fontWeight: FontWeight.w700,
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
              'เลือกรูปภาพที่ต้องการให้เป็นรูปหลักของรูปส่วนตัว',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                    itemCount: totalCount + (totalCount < 10 ? 1 : 0),
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
                                      ? Border.all(color: Colors.green, width: 3)
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
                                  top: 8,
                                  left: 8,
                                  child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _deletePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 18),
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
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 40, color: Colors.grey[500]),
                                const SizedBox(height: 8),
                                Text(
                                  'เพิ่มรูปส่วนตัว',
                                  style: TextStyle(
                                    color: Colors.grey[500],
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
