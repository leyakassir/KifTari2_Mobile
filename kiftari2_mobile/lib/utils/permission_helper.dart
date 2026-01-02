import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotos() async {
    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted) return true;

    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }
}
