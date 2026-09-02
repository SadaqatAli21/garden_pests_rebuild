import 'dart:io';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

import '../../core/services/permission_service.dart';
import '../core/app_constrants.dart';
import '../core/services/analytics_services.dart';
import '../providers/subscribtionprovider.dart';
import '../widgets/no_internet_dialog.dart';
import 'premium_screen.dart';
import '../../core/app_theme.dart';
import '../../core/app_logger.dart';
import '../providers/scan_provider.dart';
import '../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import 'loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ai_disclosure_dialog.dart';
import '../widgets/app_dialogs.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final String analysisType; // 'identify', 'diagnose', or 'pest'
  const ScanScreen({super.key, this.analysisType = 'pest'});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  CameraMacOSController? _macosController;
  List<CameraDescription>? cameras;
  List<CameraMacOSDevice>? macosCameras;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isMacOS) {
      _macosController?.destroy();
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera when app resumes
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      AppLogger.info("Initializing camera...", "ScanScreen");

      // Check for camera permission first (Mobile only)
      if (!Platform.isMacOS) {
        final granted = await PermissionService.requestCameraPermission(context);
        if (!granted) {
          AppLogger.warning("Camera permission denied", "ScanScreen");
          if (mounted) {
            Navigator.pop(context);
          }
          return;
        }
      }

      if (Platform.isMacOS) {
        // Skip camera initialization on macOS as per user request (Picker-first approach)
        AppLogger.info("Skipping camera initialization on macOS (Picker-first)", "ScanScreen");
        if (mounted) {
          setState(() {
            _isCameraInitialized = true; // Set to true to bypass "black screen" check in build
          });
        }
        return;
      }

      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        // Initialize with selected camera
        _onNewCameraSelected(cameras![_selectedCameraIndex]);
      } else {
        AppLogger.warning("No cameras found", "ScanScreen");
      }
    } catch (e, stack) {
      AppLogger.error("Camera init error", e, stack, "ScanScreen");
    }
  }

  Future<void> _onNewMacOSCameraSelected(CameraMacOSDevice device) async {
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _macosController = null;
      });
    }

    // Initialization is handled by CameraMacOSView in the build method
    // or we can initialize it here if we want more control.
    // For camera_macos, it's often easiest to let the view handle it
    // but we can set _isCameraInitialized to true once we have a device.
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    // Controller is already disposed/nulled in _toggleCamera, but handle init case
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
    );

    // If there was a controller (e.g. initial init or error recovery), dispose it
    if (_controller != null) {
      await _controller!.dispose();
    }

    if (mounted) {
      setState(() {
        _controller = cameraController;
      });
    }

    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      // Reset zoom to 1.0 to avoid "zoomed-in" default behavior on some devices
      await cameraController.setZoomLevel(1.0);
      // Explicitly set flash mode to off after initialization
      await cameraController.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isFlashOn = false; // Reset flash on switch
        });
      }
    } on CameraException catch (e) {
      AppLogger.error("Camera Exception", e, null, "ScanScreen");
    }
  }

  void _toggleCamera() async {
    if (Platform.isMacOS) {
      if (macosCameras == null || macosCameras!.length < 2) return;
      if (mounted) {
        setState(() {
          _macosController = null;
          _isCameraInitialized = false;
          _selectedCameraIndex = (_selectedCameraIndex + 1) % macosCameras!.length;
        });
      }
      _onNewMacOSCameraSelected(macosCameras![_selectedCameraIndex]);
      return;
    }

    if (cameras == null || cameras!.length < 2) return;

    final CameraController? oldController = _controller;

    // 1. Detach controller from UI IMMEDIATELY
    if (mounted) {
      setState(() {
        _controller = null; // Important: Clear the reference the UI uses
        _isCameraInitialized = false;
        _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras!.length;
      });
    }

    // 2. Dispose old controller safely AFTER UI update is scheduled
    if (oldController != null) {
      await oldController.dispose();
    }

    // 3. Initialize new camera
    _onNewCameraSelected(cameras![_selectedCameraIndex]);
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;

    if (Platform.isMacOS) {
      if (_macosController == null) return;
      try {
        setState(() => _isProcessing = true);
        await HapticFeedback.mediumImpact();
        AppLogger.info("Taking picture on macOS...", "ScanScreen");
        if (_macosController == null) {
          AppLogger.warning("macOS Controller is null", "ScanScreen");
          return;
        }
        final CameraMacOSFile? result = await _macosController!.takePicture();
        if (result != null && result.bytes != null && mounted) {
          AppLogger.info("Picture taken on macOS, size: ${result.bytes!.length}", "ScanScreen");
          // Since camera_macos might not provide a path for photos, we save bytes to a temp file
          final tempDir = await getTemporaryDirectory();
          final String path = '${tempDir.path}/macos_capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File imageFile = File(path);
          if (!await imageFile.parent.exists()) {
            await imageFile.parent.create(recursive: true);
          }
          await imageFile.writeAsBytes(result.bytes!);

          final croppedFile = await _cropToViewfinder(imageFile);
          await _analyzeImage(imageFile, croppedFile ?? imageFile);
        } else {
          AppLogger.warning("Picture capture returned null result or empty bytes on macOS", "ScanScreen");
        }
      } catch (e, stack) {
        AppLogger.error("Error taking picture on macOS", e, stack, "ScanScreen");
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      setState(() => _isProcessing = true);
      await HapticFeedback.mediumImpact();

      // Ensure flash mode is consistent with UI state before capture
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.torch);
      } else {
        await _controller!.setFlashMode(FlashMode.off);
      }

      AppLogger.info("Taking picture...", "ScanScreen");
      // Optional: Pause animation or haptic feedback
      final XFile image = await _controller!.takePicture();

      // Turn off torch immediately after capture if it was on
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
        if (mounted) setState(() => _isFlashOn = false);
      }

      if (mounted) {
        AppLogger.info("Picture taken, starting crop...", "ScanScreen");
        // Crop image to viewfinder before analysis
        final croppedFile = await _cropToViewfinder(File(image.path));
        AppLogger.info("Crop finished: ${croppedFile?.path ?? 'failed'}", "ScanScreen");

        // Pass original for context and cropped for AI analysis
        // CRITICAL: DON'T AWAIT _analyzeImage HERE.
        // We want the _takePicture finally block to run and reset _isProcessing = false immediately.
        _analyzeImage(File(image.path), croppedFile ?? File(image.path));
      }
    } catch (e, stack) {
      AppLogger.error("Error taking picture", e, stack, "ScanScreen");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToProcessImage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<File?> _cropToViewfinder(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Offload heavy image processing to a background isolate to prevent UI hang (ANR)
      final bool success = await compute(_cropImageIsolate, {
        'inputPath': imageFile.path,
        'outputPath': outputPath,
      });

      return success ? File(outputPath) : null;
    } catch (e) {
      AppLogger.error("Error initiating image crop", e, null, "ScanScreen");
      return null;
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final croppedFile = await _cropToViewfinder(File(image.path));
      _analyzeImage(File(image.path), croppedFile ?? File(image.path));
    }
  }

  Future<void> _analyzeImage(File originalFile, File croppedFile) async {
    AppLogger.info("Starting _analyzeImage flow...", "ScanScreen");
    try {
      // 1. Check Internet Connectivity
      try {
        AppLogger.info("Checking connectivity...", "ScanScreen");
        final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
        AppLogger.info("Connectivity result: $connectivityResult", "ScanScreen");

        if (connectivityResult.contains(ConnectivityResult.none)) {
          if (mounted) {
            AppDialogs.showNoInternetDialog(context);
          }
          return;
        }
      } catch (e) {
        AppLogger.error("Connectivity check failed: $e", "ScanScreen");
        // Fallback or just continue, but usually we want to show dialog if we can't confirm connectivity
        if (mounted) {
          AppDialogs.showNoInternetDialog(context);
        }
        return;
      }

      if (mounted) {
        // AI Consent Check
        AppLogger.info("Checking AI consent...", "ScanScreen");
        final prefs = await SharedPreferences.getInstance();
        final bool consentGiven = prefs.getBool(AppConstants.aiConsentGivenKey) ?? false;
        AppLogger.info("AI consent given: $consentGiven", "ScanScreen");

        if (!consentGiven) {
          AppLogger.info("Showing AIDisclosureDialog...", "ScanScreen");
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AIDisclosureDialog(),
          );
          AppLogger.info("AIDisclosureDialog result: $result", "ScanScreen");

          if (result != true) {
            AppLogger.info("AI consent declined by user", "ScanScreen");
            return;
          }

          await prefs.setBool(AppConstants.aiConsentGivenKey, true);
        }

        // Check Premium & Scan Limit
        final scanState = ref.read(scanProvider);
        final subProvider = ref.read(subscriptionProvider);

        if (!subProvider.isPremium && scanState.totalCount >= 2) {
          AppLogger.info("Scan limit reached (Total: ${scanState.totalCount}), showing PremiumScreen", "ScanScreen");
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
          return;
        }

        // Pause camera to save resources
        _controller?.pausePreview();

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingScreen(
              imageFile: originalFile,
              croppedFile: croppedFile,
              onAnalyze: () async {
                // Perform compression INSIDE the loading screen to transition faster
                final bytes = await _compressImage(croppedFile);
                if (bytes == null) throw Exception("Failed to compress image");

                final base64Image = base64Encode(bytes);

                // Get current language name
                final languageName = ref.read(localeProvider.notifier).getLanguageName();

                await ref.read(scanProvider.notifier).analyzeImage(
                  base64Image,
                  languageName,
                  analysisType: widget.analysisType,
                );
              },
            ),
          ),
        );

        // Resume when back
        _controller?.resumePreview();
      }
    } catch (e, stack) {
      AppLogger.error("Error preparing image", e, stack, "ScanScreen");
    }
  }

  Future<List<int>?> _compressImage(File file) async {
    try {
      var result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
      );
      if (result != null && result.length > 1024 * 1024) {
        result = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
        );
      }
      return result;
    } catch (e) {
      return null;
    }
  }

  void _toggleFlash() {
    if (Platform.isMacOS) {
      // camera_macos flash support is limited/different, skipping for now
      return;
    }
    if (_controller != null) {
      setState(() {
        _isFlashOn = !_isFlashOn;
        _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
      });
    }
  }

  void _showScanTipsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScanTipsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Determine if we are on front camera for Flash visibility
    final isFrontCamera = cameras != null && cameras!.isNotEmpty
        ? cameras![_selectedCameraIndex].lensDirection == CameraLensDirection.front
        : false;

    // Camera Preview Widget logic
    Widget cameraPreviewWidget;
    if (Platform.isMacOS) {
      // macOS Picker-First UI
      cameraPreviewWidget = Container(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: _pickFromGallery,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor, size: 64),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.macLibrary,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.macLibraryDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(l10n.chooseImage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_controller == null || !_controller!.value.isInitialized) {
      cameraPreviewWidget = Container(color: Colors.black);
    } else {
      final size = MediaQuery.of(context).size;
      // Precise scale calculation to fill screen without excessive zoom/cropping
      var scale = size.aspectRatio * _controller!.value.aspectRatio;
      if (scale < 1) scale = 1 / scale;

      cameraPreviewWidget = Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(_controller!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Natural Scale Camera Preview
          cameraPreviewWidget,

          // 3. Scan Frame (White Border ONLY) - Hidden on macOS
          if (!Platform.isMacOS)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
                    child: Stack(
                      children: [
                        // Corners
                        Positioned(top: 0, left: 0, child: _buildCorner(0)),
                        Positioned(top: 0, right: 0, child: _buildCorner(1)),
                        Positioned(bottom: 0, right: 0, child: _buildCorner(2)),
                        Positioned(bottom: 0, left: 0, child: _buildCorner(3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.alignPlant,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          // 4. Top Controls (SafeArea)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () {
                          AnalyticsService.instance.logEvent('scan_screen_onPressed_tapped');
                          return Navigator.pop(context);
                        },
                      ),
                    ),
                    // Center label with info icon - Hidden on macOS
                    if (!Platform.isMacOS)
                      GestureDetector(
                        onTap: _showScanTipsSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.energy_savings_leaf, color: AppTheme.primaryColor, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                l10n.aiScanner,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 10),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40), // Spacer to maintain layout balance
                    // Right: Flash only (eye icon replaced by info chip on label)
                    if (!Platform.isMacOS && !isFrontCamera)
                      CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn ? Colors.yellow : Colors.white,
                            size: 22,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      )
                    else if (!Platform.isMacOS)
                      const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Controls - Hidden on macOS
          if (!Platform.isMacOS)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gallery
                        InkWell(
                          onTap: _pickFromGallery,
                          borderRadius: BorderRadius.circular(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                                child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.gallery,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Shutter Button
                        SizedBox(
                          height: 96, // Enlarged from 84 for better accessibility
                          width: 96,
                          child: InkResponse(
                            onTap: _isProcessing ? null : _takePicture,
                            containedInkWell: false,
                            splashColor: Colors.white24,
                            highlightColor: Colors.white10,
                            radius: 48,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: _isProcessing ? 68 : 80, // Enlarged from 60/72
                                width: _isProcessing ? 68 : 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isProcessing ? Colors.white54 : Colors.white,
                                    width: 4, // Slightly thicker border
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(6), // Adjusted margin
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isProcessing ? Colors.white.withOpacity(0.5) : Colors.white,
                                  ),
                                  child: _isProcessing
                                      ? const Center(
                                    child: SizedBox(
                                      height: 32, // Larger spinner
                                      width: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 4,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                      ),
                                    ),
                                  )
                                      : const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 32), // Larger icon
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Flip Camera
                        InkWell(
                          onTap: _toggleCamera,
                          borderRadius: BorderRadius.circular(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                                child: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 22),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.flip,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(int quarter) {
    return Transform.rotate(
      angle: quarter * 1.5708, // 90 degrees in radians
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          border: Border(
            top: BorderSide(color: Colors.white, width: 4),
            left: BorderSide(color: Colors.white, width: 4),
          ),
        ),
      ),
    );
  }
}

/// Isolate top-level function for background image processing to prevent ANR
Future<bool> _cropImageIsolate(Map<String, dynamic> params) async {
  try {
    final String inputPath = params['inputPath'];
    final String outputPath = params['outputPath'];

    final File imageFile = File(inputPath);
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return false;

    // Fix orientation issues common with mobile cameras
    image = img.bakeOrientation(image);

    final int width = image.width;
    final int height = image.height;

    // We want a square crop from the center
    final int side = width < height ? width : height;
    final int x = (width - side) ~/ 2;
    final int y = (height - side) ~/ 2;

    final img.Image croppedImage = img.copyCrop(image, x: x, y: y, width: side, height: side);

    final File croppedFile = File(outputPath);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

    return true;
  } catch (e) {
    debugPrint("Background crop error: $e");
    return false;
  }
}

// ─── Scan Tips Bottom Sheet ───────────────────────────────────────────────────
class _ScanTipsSheet extends StatelessWidget {
  const _ScanTipsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tips = [
      _TipData(
        icon: Icons.wb_sunny_outlined,
        color: Colors.orange,
        title: l10n.scanTipLightTitle,
        subtitle: l10n.scanTipLightDesc,
      ),
      _TipData(icon: Icons.blur_off, color: Colors.red, title: l10n.scanTipBlurTitle, subtitle: l10n.scanTipBlurDesc),
      _TipData(
        icon: Icons.eco_outlined,
        color: Colors.green,
        title: l10n.scanTipPlantTitle,
        subtitle: l10n.scanTipPlantDesc,
      ),
      _TipData(
        icon: Icons.straighten_outlined,
        color: Colors.blue,
        title: l10n.scanTipDistTitle,
        subtitle: l10n.scanTipDistDesc,
      ),
      _TipData(
        icon: Icons.rotate_90_degrees_ccw_outlined,
        color: Colors.purple,
        title: l10n.scanTipAngleTitle,
        subtitle: l10n.scanTipAngleDesc,
      ),
      _TipData(
        icon: Icons.crop_square_outlined,
        color: Colors.teal,
        title: l10n.scanTipBgTitle,
        subtitle: l10n.scanTipBgDesc,
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
              ),
              // Header
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.primaryColor.withOpacity(0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.scanTipsTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.scanTipsSubtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tips list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: tips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _TipCard(data: tips[i]),
                ),
              ),
              // Got It button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        AnalyticsService.instance.logEvent('scan_screen_onPressed_tapped');
                        return Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(l10n.scanTipGotIt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TipData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _TipData({required this.icon, required this.color, required this.title, required this.subtitle});
}

class _TipCard extends StatelessWidget {
  final _TipData data;
  const _TipCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: data.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(data.subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
