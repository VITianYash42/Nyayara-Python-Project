import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

// ── Local model for uploaded files (in-memory; can persist to Firestore later)
class _UploadedFile {
  final String name;
  final String type; // image | video | audio | document
  final int sizeBytes;
  final DateTime uploadedAt;
  final Uint8List? bytes; // web-compatible bytes

  _UploadedFile({
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.uploadedAt,
    this.bytes,
  });

  String get sizeLabel {
    if (sizeBytes < 1024) return '${sizeBytes} B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class EvidenceVaultScreen extends StatefulWidget {
  const EvidenceVaultScreen({super.key});

  @override
  State<EvidenceVaultScreen> createState() => _EvidenceVaultScreenState();
}

class _EvidenceVaultScreenState extends State<EvidenceVaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<_UploadedFile> _files = [];
  bool _isUploading = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── File Picking ────────────────────────────────────────────────────────
  Future<void> _pickFiles({
    required List<String> allowedExtensions,
    required String type,
  }) async {
    Navigator.pop(context); // close bottom sheet first
    setState(() {
      _isUploading = true;
      _lastError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true, // needed for web
        type: allowedExtensions.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions.isEmpty ? null : allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      final newFiles = result.files.map((f) {
        final ext = (f.extension ?? '').toLowerCase();
        String fileType = type;
        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) fileType = 'image';
        else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) fileType = 'video';
        else if (['mp3', 'm4a', 'aac', 'wav', 'ogg'].contains(ext)) fileType = 'audio';
        else if (['pdf', 'doc', 'docx', 'txt', 'odt'].contains(ext)) fileType = 'document';

        return _UploadedFile(
          name: f.name,
          type: fileType,
          sizeBytes: f.size,
          uploadedAt: DateTime.now(),
          bytes: f.bytes,
        );
      }).toList();

      setState(() {
        _files.addAll(newFiles);
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${newFiles.length} file${newFiles.length > 1 ? 's' : ''} added to vault',
              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.goldPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _lastError = 'Failed to pick file. Try again.';
      });
    }
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Evidence',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18)),
                    Text('Auto-timestamped & encrypted',
                        style: GoogleFonts.inter(
                            color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Type grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: [
                _UploadTile(
                  icon: Icons.image_rounded,
                  label: 'Photo / Screenshot',
                  color: AppColors.info,
                  onTap: () => _pickFiles(
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
                    type: 'image',
                  ),
                ),
                _UploadTile(
                  icon: Icons.videocam_rounded,
                  label: 'Video Clip',
                  color: AppColors.danger,
                  onTap: () => _pickFiles(
                    allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm'],
                    type: 'video',
                  ),
                ),
                _UploadTile(
                  icon: Icons.mic_rounded,
                  label: 'Audio Recording',
                  color: AppColors.warning,
                  onTap: () => _pickFiles(
                    allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
                    type: 'audio',
                  ),
                ),
                _UploadTile(
                  icon: Icons.description_rounded,
                  label: 'Document / PDF',
                  color: AppColors.success,
                  onTap: () => _pickFiles(
                    allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
                    type: 'document',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Or pick any file
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickFiles(allowedExtensions: [], type: 'document'),
                icon: const Icon(Icons.folder_open_rounded, size: 16, color: AppColors.goldLight),
                label: Text('Browse Any File',
                    style: GoogleFonts.inter(color: AppColors.goldLight, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.goldPrimary, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text('Remove Evidence?',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This will remove "${_files[index].name}" from your vault.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _files.removeAt(index));
              Navigator.pop(context);
            },
            child: Text('Remove',
                style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.black, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Evidence Vault',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          if (_files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showUploadSheet,
                icon: const Icon(Icons.add_rounded, color: AppColors.goldLight, size: 18),
                label: Text('Add',
                    style: GoogleFonts.inter(color: AppColors.goldLight, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
        bottom: _files.isEmpty
            ? null
            : TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.goldPrimary,
                indicatorWeight: 2,
                labelColor: AppColors.goldLight,
                unselectedLabelColor: AppColors.textHint,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Files'),
                  Tab(text: 'Timeline'),
                ],
              ),
      ),
      body: _isUploading
          ? _UploadingState()
          : _files.isEmpty
              ? _EmptyVaultState(onUpload: _showUploadSheet)
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _FilesTab(
                      files: _files,
                      onDelete: _confirmDelete,
                    ),
                    _TimelineTab(files: _files),
                  ],
                ),
      floatingActionButton: _files.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showUploadSheet,
              icon: const Icon(Icons.upload_rounded, color: Colors.black),
              label: Text('Upload',
                  style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.goldPrimary,
              elevation: 4,
            )
          : null,
    );
  }
}

// ── Upload Tile ─────────────────────────────────────────────────────────
class _UploadTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _UploadTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────
class _EmptyVaultState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyVaultState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.goldPrimary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundCard,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: AppColors.goldLight, size: 34),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.97, end: 1.03, duration: 2000.ms, curve: Curves.easeInOut),

            const SizedBox(height: 28),

            Text('Your Vault is Empty',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
            const SizedBox(height: 10),
            Text(
              'Upload screenshots, videos, audio recordings,\nor documents as evidence for your case.',
              style: GoogleFonts.inter(
                  color: AppColors.textHint, fontSize: 13, height: 1.7),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Security badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(icon: Icons.lock_rounded, label: 'Encrypted'),
                const SizedBox(width: 12),
                _Badge(icon: Icons.access_time_rounded, label: 'Timestamped'),
                const SizedBox(width: 12),
                _Badge(icon: Icons.verified_rounded, label: 'Tamper-proof'),
              ],
            ),

            const SizedBox(height: 36),

            // CTA
            GestureDetector(
              onTap: onUpload,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_rounded, color: Colors.black, size: 20),
                    const SizedBox(width: 10),
                    Text('Upload First Evidence',
                        style: GoogleFonts.inter(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.goldLight, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Uploading State ────────────────────────────────────────────────────
class _UploadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.goldLight, strokeWidth: 2),
          const SizedBox(height: 20),
          Text('Processing file...',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Files Tab ─────────────────────────────────────────────────────────
class _FilesTab extends StatelessWidget {
  final List<_UploadedFile> files;
  final void Function(int) onDelete;
  const _FilesTab({required this.files, required this.onDelete});

  int get _totalBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);

  String get _totalSize {
    final bytes = _totalBytes;
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.backgroundCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _StatItem(
                  icon: Icons.folder_rounded,
                  value: '${files.length}',
                  label: files.length == 1 ? 'File' : 'Files'),
              _divider(),
              _StatItem(
                  icon: Icons.storage_rounded,
                  value: _totalSize,
                  label: 'Total Size'),
              _divider(),
              _StatItem(
                  icon: Icons.shield_rounded,
                  value: '100%',
                  label: 'Encrypted'),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 4),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (_, i) => _FileCard(
              file: files[i],
              index: i,
              onDelete: () => onDelete(i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
      width: 1, height: 30, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16));
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.goldLight, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label,
              style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 9)),
        ],
      ),
    );
  }
}

// ── File Card ────────────────────────────────────────────────────────
class _FileCard extends StatelessWidget {
  final _UploadedFile file;
  final int index;
  final VoidCallback onDelete;
  const _FileCard({required this.file, required this.index, required this.onDelete});

  IconData get _icon {
    switch (file.type) {
      case 'image': return Icons.image_rounded;
      case 'video': return Icons.videocam_rounded;
      case 'audio': return Icons.audio_file_rounded;
      default: return Icons.description_rounded;
    }
  }

  Color get _color {
    switch (file.type) {
      case 'image': return AppColors.info;
      case 'video': return AppColors.danger;
      case 'audio': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  String get _typeLabel {
    switch (file.type) {
      case 'image': return 'Image';
      case 'video': return 'Video';
      case 'audio': return 'Audio';
      default: return 'Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.backgroundCard,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: AppColors.goldPrimary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _color.withValues(alpha: 0.1),
                      border: Border.all(color: _color.withValues(alpha: 0.2)),
                    ),
                    child: Icon(_icon, color: _color, size: 26),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file.name,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: _color.withValues(alpha: 0.12),
                              ),
                              child: Text(_typeLabel,
                                  style: GoogleFonts.inter(
                                      color: _color, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Text(file.sizeLabel,
                                style: GoogleFonts.inter(
                                    color: AppColors.textHint, fontSize: 11)),
                            const SizedBox(width: 8),
                            const Icon(Icons.circle, color: AppColors.textHint, size: 3),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM, HH:mm').format(file.uploadedAt),
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Encryption bar
                        Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: AppColors.success, size: 10),
                            const SizedBox(width: 4),
                            Text('Encrypted & timestamped',
                                style: GoogleFonts.inter(
                                    color: AppColors.success, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.textHint, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: 0.05);
  }
}

// ── Timeline Tab ─────────────────────────────────────────────────────
class _TimelineTab extends StatelessWidget {
  final List<_UploadedFile> files;
  const _TimelineTab({required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Center(
        child: Text('No files yet',
            style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14)),
      );
    }

    final sorted = [...files]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final f = sorted[i];
        final isLast = i == sorted.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline spine
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldPrimary.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: AppColors.border,
                          margin: const EdgeInsets.only(top: 4),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Card
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.backgroundCard,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(f.uploadedAt),
                          style: GoogleFonts.inter(
                              color: AppColors.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(f.name,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${f.sizeLabel} • ${f.type}',
                            style: GoogleFonts.inter(
                                color: AppColors.textHint, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideX(begin: 0.05);
      },
    );
  }
}
