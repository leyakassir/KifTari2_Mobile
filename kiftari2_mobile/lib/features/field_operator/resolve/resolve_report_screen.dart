import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/report_service.dart';
import '../../../core/services/offline_upload_service.dart';
import '../../../utils/permission_helper.dart';

class ResolveReportScreen extends StatefulWidget {
  final String reportId;
  final bool isResolved;

  const ResolveReportScreen({
    super.key,
    required this.reportId,
    this.isResolved = false,
  });

  @override
  State<ResolveReportScreen> createState() => _ResolveReportScreenState();
}

class _ResolveReportScreenState extends State<ResolveReportScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _loading = false;
  bool _retrying = false;
  int _pendingCount = 0;

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;

    final granted = source == ImageSource.camera
        ? await PermissionHelper.requestCamera()
        : await PermissionHelper.requestPhotos();
    if (!granted) {
      _showMessage(
        source == ImageSource.camera
            ? "Camera permission denied"
            : "Gallery permission denied",
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );

    if (image == null) return;

    setState(() {
      _imageFile = File(image.path);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final count = await OfflineUploadService.pendingCount();
    if (!mounted) return;
    setState(() => _pendingCount = count);
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text("Camera"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resolve() async {
    if (_loading) return;

    if (widget.isResolved) {
      _showMessage("This report is already resolved.");
      return;
    }

    if (_imageFile == null) {
      _showMessage("Please attach a proof image before resolving.");
      return;
    }

    // NEW FEATURE: confirm resolve action
    final confirmed = await _confirmResolve();
    if (!confirmed) return;

    setState(() => _loading = true);

    final resolveResult = await ReportService.resolveReport(widget.reportId);
    if (resolveResult["success"] != true) {
      _showMessage(resolveResult["message"] ?? "Failed to resolve report");
      setState(() => _loading = false);
      return;
    }

    final uploadResult = await ReportService.attachStreetImage(
      reportId: widget.reportId,
      imageFile: _imageFile!,
    );

    setState(() => _loading = false);

    if (uploadResult["success"] == true) {
      if (!mounted) return;
      await _showResolveSuccess();
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    await OfflineUploadService.enqueue(
      widget.reportId,
      _imageFile!.path,
    );
    await _loadPendingCount();
    _showMessage(
      "${uploadResult["message"] ?? "Upload failed"} (queued for retry)",
    );
  }

  Future<void> _retryPendingUploads() async {
    if (_retrying) return;
    setState(() => _retrying = true);

    final uploads = await OfflineUploadService.loadQueue();
    for (var i = uploads.length - 1; i >= 0; i--) {
      final item = uploads[i];
      final file = File(item.filePath);
      if (!file.existsSync()) {
        await OfflineUploadService.removeAt(i);
        continue;
      }

      final result = await ReportService.attachStreetImage(
        reportId: item.reportId,
        imageFile: file,
      );
      if (result["success"] == true) {
        await OfflineUploadService.removeAt(i);
      }
    }

    await _loadPendingCount();
    if (!mounted) return;
    setState(() => _retrying = false);
  }

  // NEW FEATURE: confirm dialog before resolve
  Future<bool> _confirmResolve() async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Resolution"),
          content: const Text(
            "Are you sure you want to mark this report as resolved?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: TextStyle(color: scheme.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
              ),
              child: Text(
                "Confirm",
                style: TextStyle(color: scheme.onPrimary),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // NEW FEATURE: success feedback
  Future<void> _showResolveSuccess() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Report Resolved"),
          content: const Text(
            "Report resolved successfully. The citizen has been notified.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resolve Report"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Confirm Resolution",
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  "Please upload a proof photo before marking this report as resolved.",
                  style: textTheme.bodyMedium,
                ),
                if (widget.isResolved) ...[
                  const SizedBox(height: 10),
                  // NEW FEATURE: read-only notice
                  Text(
                    "This report is already resolved and locked.",
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Proof Image", style: textTheme.titleSmall),
                const SizedBox(height: 12),
                _imageFile == null
                    ? Text(
                        "No image selected",
                        style: textTheme.bodyMedium,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    // NEW FEATURE: read-only mode for resolved reports
                    onPressed: widget.isResolved ? null : _pickImage,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: scheme.primary),
                    ),
                    child: Text(
                      widget.isResolved ? "Photo Locked" : "Add Photo",
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pending Uploads", style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  _pendingCount == 0
                      ? "No pending uploads"
                      : "Pending uploads: $_pendingCount",
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _pendingCount == 0 ? null : _retryPendingUploads,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: scheme.primary),
                    ),
                    child: _retrying
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : Text(
                            "Retry Pending Uploads",
                            style: textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _resolve,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
              ),
              child: _loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text(
                      "Resolve Report",
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
