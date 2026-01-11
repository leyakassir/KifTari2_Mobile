import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kiftari2/features/reports/success/report_success_screen.dart';
import 'package:kiftari2/core/services/ai_service.dart';
import 'package:kiftari2/core/services/report_service.dart';
import 'package:kiftari2/core/services/token_service.dart';
import 'package:kiftari2/utils/permission_helper.dart';
import 'location_picker_screen.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool locationCaptured = false;
  bool imageAdded = false;
  bool loading = false;
  bool _aiLoading = false;

  double? latitude;
  double? longitude;
  File? imageFile;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    ReportService.syncQueuedReports();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ================= LOCATION =================
  Future<void> _captureLocation() async {
    final granted = await PermissionHelper.requestLocation();
    if (!granted) {
      _toast("Location permission denied");
      return;
    }

    if (!mounted) return; // FIX: guard context after async
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: latitude,
          initialLongitude: longitude,
        ),
      ),
    );

    if (result is Map) {
      setState(() {
        latitude = result["latitude"] as double?;
        longitude = result["longitude"] as double?;
        locationCaptured = latitude != null && longitude != null;
      });
    }
  }

  // ================= IMAGE =================
  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;

    final granted = source == ImageSource.camera
        ? await PermissionHelper.requestCamera()
        : await PermissionHelper.requestPhotos();
    if (!granted) {
      _toast(source == ImageSource.camera
          ? "Camera permission denied"
          : "Gallery permission denied");
      return;
    }

    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1280,
    );

    if (image == null) return;

    setState(() {
      imageFile = File(image.path);
      imageAdded = true;
    });
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

  // ================= AI HELP =================
  Future<void> _improveDescriptionWithAi() async {
    if (_aiLoading) return;

    final input = descriptionController.text.trim();
    if (input.isEmpty) {
      _toast("Please write a description first.");
      return;
    }

    setState(() => _aiLoading = true);

    try {
      final improved = await AiService.sendMessage(
        message: input,
        context: "create_report",
      );

      if (!mounted) return;

      final apply = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI suggestion",
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "AI suggestions only. Review before applying.",
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      improved,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Use this text"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (apply == true) {
        descriptionController.text = improved;
      }
    } catch (_) {
      if (mounted) {
        _toast("AI service is temporarily unavailable.");
      }
    } finally {
      if (mounted) {
        setState(() => _aiLoading = false);
      }
    }
  }

  // ================= SUBMIT =================
  Future<void> _submitReport() async {
    if (loading) return;

    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        latitude == null ||
        longitude == null) {
      _toast("Please fill all required fields");
      return;
    }

    setState(() => loading = true);

    final result = await ReportService.createReport(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      latitude: latitude!,
      longitude: longitude!,
      imageFile: imageFile,
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (result["success"] == true) {
      await _syncCachedPoints(result);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ReportSuccessScreen(),
        ),
      );
    } else {
      await _offerOfflineSave(result["message"]?.toString());
    }
  }

  Future<void> _offerOfflineSave(String? message) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submission failed"),
          content: Text(
            message?.isNotEmpty == true
                ? "$message\n\nSave this report and retry later?"
                : "Save this report and retry later?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Discard"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      _toast(message ?? "Submission failed");
      return;
    }

    await ReportService.queueReport(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      imageFile: imageFile,
    );
    if (!mounted) return;
    _toast("Saved offline. We'll retry automatically.");
  }

  void _toast(String msg) {
    if (!mounted) return; // FIX: guard context after async
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _syncCachedPoints(Map<String, dynamic> result) async {
    final data = result["data"];
    if (data is Map && data["user"] is Map) {
      final user = data["user"] as Map;
      final totalPoints = int.tryParse(user["points"].toString());
      if (totalPoints != null) {
        await TokenService.savePoints(totalPoints);
        return;
      }
    }

    var shouldAward = true;
    var awarded = 0;

    if (data is Map) {
      final pointsAdded = data["pointsAdded"];
      if (pointsAdded is bool && pointsAdded == false) {
        shouldAward = false;
      }

      final quality = data["descriptionQuality"];
      if (quality is Map && quality["block"] == true) {
        shouldAward = false;
      }

      final awardedRaw = data["pointsAwarded"];
      if (awardedRaw is int) {
        awarded = awardedRaw;
      } else if (awardedRaw is String) {
        awarded = int.tryParse(awardedRaw) ?? 0;
      }
    }

    if (!shouldAward) return;

    if (awarded <= 0) {
      awarded = 10;
    }

    final current = await TokenService.getPoints();
    await TokenService.savePoints(current + awarded);
  }

  // ================= UI (UNCHANGED) =================
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _form()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.traffic, size: 46, color: scheme.onPrimary),
          const SizedBox(height: 10),
          Text(
            "Create Report",
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Help improve road safety in your area",
            style: TextStyle(color: scheme.onPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Report Title"),
          _inputField(titleController, "e.g. Broken road"),

          const SizedBox(height: 22),

          _label("Description"),
          _inputField(descriptionController, "Describe the issue",
              maxLines: 4),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  "AI suggestions only.",
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _aiLoading ? null : _improveDescriptionWithAi,
                child: _aiLoading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      )
                    : const Text("Improve description with AI"),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _statusAction(
            icon: Icons.location_on,
            text: "Location",
            active: locationCaptured,
            onTap: _captureLocation,
          ),

          const SizedBox(height: 14),

          _statusAction(
            icon: Icons.camera_alt,
            text: "Photo (Optional)",
            active: imageAdded,
            onTap: _pickImage,
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? CircularProgressIndicator(color: scheme.onPrimary)
                  : Text(
                      "Submit Report",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _statusAction({
    required IconData icon,
    required String text,
    required bool active,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.tertiary : scheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                active ? "$text added" : "Add $text",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Opacity(
              opacity: active ? 1 : 0,
              child: Icon(Icons.check_circle, color: scheme.tertiary),
            ),
          ],
        ),
      ),
    );
  }
}
