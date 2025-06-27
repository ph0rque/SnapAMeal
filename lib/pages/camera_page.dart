import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:snapameal/pages/preview_page.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:provider/provider.dart';
import '../services/fasting_service.dart';
import '../services/ar_filter_service.dart';
import '../services/rag_service.dart';
import '../services/openai_service.dart';
import '../models/fasting_session.dart';
import '../providers/fasting_state_provider.dart';
import '../design_system/widgets/fasting_timer_widget.dart';
import '../design_system/widgets/ar_filter_selector.dart';
import '../design_system/widgets/fasting_status_indicators.dart';
import '../utils/logger.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.cameras, this.onStoryPosted});

  final List<CameraDescription> cameras;
  final VoidCallback? onStoryPosted;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _noCamerasAvailable = false;
  bool _flashOn = false;
  bool _showFastingTimer = false;
  bool _showARFilters = false;
  FastingSession? _currentFastingSession;
  FastingARFilterType? _selectedARFilter;
  late ARFilterService _arFilterService;
  final List<ARFilterOverlay> _activeAROverlays = [];

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) {
      setState(() {
        _noCamerasAvailable = true;
      });
      return;
    }
    _initializeCamera();
    _initializeARFilterService();
  }

  Future<void> _initializeARFilterService() async {
    final openAIService = OpenAIService();
    await openAIService.initialize();
    final ragService = RAGService(openAIService);
    _arFilterService = ARFilterService(ragService);
  }

  void _initializeCamera() {
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameras[_selectedCameraIndex],
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  void _switchCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    _arFilterService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_noCamerasAvailable) {
      return const Scaffold(body: Center(child: Text("No cameras available.")));
    }
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Consumer<FastingService>(
              builder: (context, fastingService, child) {
                return StreamBuilder<FastingSession?>(
                  stream: fastingService.sessionStream,
                  builder: (context, snapshot) {
                    _currentFastingSession = snapshot.data;

                    return Stack(
                      children: [
                        CameraPreview(_controller),

                        // AR Filter Overlays
                        if (_activeAROverlays.isNotEmpty)
                          ARFilterOverlayWidget(
                            activeOverlays: _activeAROverlays,
                            screenSize: MediaQuery.of(context).size,
                          ),

                        // Top controls
                        Positioned(
                          top: 40,
                          left: 20,
                          right: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Fasting timer toggle
                                  IconButton(
                                    icon: Icon(
                                      _showFastingTimer
                                          ? Icons.timer_off
                                          : Icons.timer,
                                      color: SnapUIColors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showFastingTimer = !_showFastingTimer;
                                      });
                                    },
                                  ),

                                  // AR Filters toggle (only show if fasting)
                                  if (_currentFastingSession?.isActive == true)
                                    IconButton(
                                      icon: Icon(
                                        _showARFilters
                                            ? Icons.auto_awesome_outlined
                                            : Icons.auto_awesome,
                                        color: _showARFilters
                                            ? Colors.yellow
                                            : SnapUIColors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showARFilters = !_showARFilters;
                                          if (!_showARFilters) {
                                            _clearARFilters();
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),

                              // Flash toggle
                              IconButton(
                                icon: Icon(
                                  _flashOn ? EvaIcons.flash : EvaIcons.flashOff,
                                  color: SnapUIColors.white,
                                ),
                                onPressed: _toggleFlash,
                              ),
                            ],
                          ),
                        ),

                        // Fasting timer overlay
                        if (_showFastingTimer)
                          Positioned(
                            top: 100,
                            right: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(8),
                              child: FastingTimerWidget(
                                size: 120,
                                showControls: false,
                              ),
                            ),
                          ),

                        // Fasting status indicator
                        if (_currentFastingSession != null)
                          Positioned(
                            top: 100,
                            left: 20,
                            child: _buildFastingStatusIndicator(
                              _currentFastingSession!,
                            ),
                          ),

                        // Camera switch button
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: IconButton(
                            icon: const Icon(
                              EvaIcons.flip2,
                              color: SnapUIColors.white,
                            ),
                            onPressed: _switchCamera,
                          ),
                        ),

                        // AR Filter Selector
                        if (_showARFilters &&
                            _currentFastingSession?.isActive == true)
                          Positioned(
                            bottom: 140,
                            left: 0,
                            right: 0,
                            child: ARFilterSelector(
                              fastingSession: _currentFastingSession,
                              arFilterService: _arFilterService,
                              onFilterSelected: _onARFilterSelected,
                              selectedFilter: _selectedARFilter,
                              isVisible: _showARFilters,
                            ),
                          ),

                        // Main camera controls
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: SnapUIColors.black.withAlpha(128),
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Fasting snap button (if fasting is active)
                                if (_currentFastingSession?.isActive == true)
                                  _buildFastingSnapButton(fastingService),

                                // Main camera button
                                GestureDetector(
                                  onTap: () => _takePicture(fastingService),
                                  onLongPressStart: (_) =>
                                      _startVideoRecording(),
                                  onLongPressEnd: (_) => _stopVideoRecording(),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isRecording
                                          ? SnapUIColors.accentRed
                                          : SnapUIColors.white,
                                      border:
                                          _currentFastingSession?.isActive ==
                                              true
                                          ? Border.all(
                                              color: Colors.green,
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child:
                                        _currentFastingSession?.isActive == true
                                        ? Icon(
                                            Icons.restaurant_menu,
                                            color: Colors.green,
                                            size: 30,
                                          )
                                        : null,
                                  ),
                                ),

                                // End fasting snap button (if fasting is active)
                                if (_currentFastingSession?.isActive == true)
                                  _buildEndFastingSnapButton(fastingService),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<XFile> _saveFilePermanently(XFile file) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String newPath = p.join(appDir.path, p.basename(file.path));
    Logger.d("Saving file to permanent path: $newPath");
    await file.saveTo(newPath);
    return XFile(newPath);
  }

  Future<void> _takePicture(FastingService fastingService) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      final savedImage = await _saveFilePermanently(image);

      // Record snap engagement if fasting is active
      if (_currentFastingSession?.isActive == true) {
        await fastingService.recordEngagement(snapTaken: true);
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: savedImage,
            isVideo: false,
            onStoryPosted: widget.onStoryPosted,
            fastingSession: _currentFastingSession,
          ),
        ),
      );
    } catch (e) {
      Logger.d("Error taking picture: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    setState(() {
      _isRecording = true;
    });
    try {
      await _controller.startVideoRecording();
    } catch (e) {
      Logger.d("Error starting video recording: $e");
      return;
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return;
    }

    try {
      final file = await _controller.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      if (!mounted) return;

      final savedFile = await _saveFilePermanently(file);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: savedFile,
            isVideo: true,
            onStoryPosted: widget.onStoryPosted,
          ),
        ),
      );
    } catch (e) {
      Logger.d("Error stopping video recording: $e");
      return;
    }
  }

  void _toggleFlash() {
    if (_controller.value.flashMode == FlashMode.off ||
        _controller.value.flashMode == FlashMode.auto) {
      _controller.setFlashMode(FlashMode.torch).then((_) {
        if (mounted) {
          setState(() {
            _flashOn = true;
          });
        }
      });
    } else {
      _controller.setFlashMode(FlashMode.off).then((_) {
        if (mounted) {
          setState(() {
            _flashOn = false;
          });
        }
      });
    }
  }

  /// Build fasting status indicator
  Widget _buildFastingStatusIndicator(FastingSession session) {
    if (session.state != FastingState.active) {
      return SizedBox.shrink();
    }

    return Consumer<FastingService>(
      builder: (context, fastingService, _) {
        final progress = session.progressPercentage;
        final statusColor = FastingStatusIndicators.getStatusColor(progress);

        return FastingColorShift(
          fastingState: Provider.of<FastingStateProvider>(
            context,
            listen: false,
          ),
          applyToBackground: true,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FastingBadge(
                  fastingState: Provider.of<FastingStateProvider>(
                    context,
                    listen: false,
                  ),
                  size: 32,
                  animate: true,
                ),
                SizedBox(height: 4),
                Text(
                  FastingStatusIndicators.getMotivationalText(progress),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build fasting snap button (for motivation/progress snaps)
  Widget _buildFastingSnapButton(FastingService fastingService) {
    return GestureDetector(
      onTap: () async {
        await _takeFastingProgressSnap(fastingService);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.withValues(alpha: 0.8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(Icons.favorite, color: Colors.white, size: 24),
      ),
    );
  }

  /// Build end fasting snap button
  Widget _buildEndFastingSnapButton(FastingService fastingService) {
    return GestureDetector(
      onTap: () async {
        await _showEndFastingDialog(fastingService);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(Icons.stop, color: Colors.white, size: 24),
      ),
    );
  }

  /// Take a progress snap during fasting
  Future<void> _takeFastingProgressSnap(FastingService fastingService) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      final savedImage = await _saveFilePermanently(image);

      // Record engagement and add snap to session
      await fastingService.recordEngagement(snapTaken: true);

      if (!mounted) return;
      // Show quick success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress snap captured! 💪'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: savedImage,
            isVideo: false,
            onStoryPosted: widget.onStoryPosted,
            fastingSession: _currentFastingSession,
            isFastingProgressSnap: true,
          ),
        ),
      );
    } catch (e) {
      Logger.d("Error taking fasting progress snap: $e");
    }
  }

  /// Show dialog to end fasting session with snap
  Future<void> _showEndFastingDialog(FastingService fastingService) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Fasting Session?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Would you like to take a completion snap before ending your fasting session?',
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Capture your achievement!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Just End Session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Take Completion Snap'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _takeCompletionSnap(fastingService);
    } else if (result == false) {
      await fastingService.endFastingSession(FastingEndReason.completed);
    }
  }

  /// Take a completion snap when ending fasting
  Future<void> _takeCompletionSnap(FastingService fastingService) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      final savedImage = await _saveFilePermanently(image);

      // End the fasting session
      await fastingService.endFastingSession(FastingEndReason.completed);

      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fasting completed! Great job! 🎉'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: savedImage,
            isVideo: false,
            onStoryPosted: widget.onStoryPosted,
            fastingSession: _currentFastingSession,
            isFastingCompletionSnap: true,
          ),
        ),
      );
    } catch (e) {
      Logger.d("Error taking completion snap: $e");
      // Fallback: just end the session
      await fastingService.endFastingSession(FastingEndReason.completed);
    }
  }

  /// Handle AR filter selection
  void _onARFilterSelected(FastingARFilterType filterType) async {
    if (_selectedARFilter == filterType) {
      // Deselect the filter
      _clearARFilters();
      return;
    }

    setState(() {
      _selectedARFilter = filterType;
    });

    // Clear existing overlays
    _clearARFilters();

    // Apply new filter
    if (_currentFastingSession != null) {
      final overlay = await _arFilterService.applyFilter(
        filterType,
        _currentFastingSession!,
        this,
      );

      if (overlay != null) {
        setState(() {
          _activeAROverlays.add(overlay);
        });

        // Auto-remove overlay after duration
        if (overlay.duration != Duration.zero) {
          Future.delayed(overlay.duration, () {
            setState(() {
              _activeAROverlays.remove(overlay);
            });
          });
        }
      }
    }
  }

  /// Clear all active AR filters
  void _clearARFilters() {
    setState(() {
      _selectedARFilter = null;
      _activeAROverlays.clear();
    });
    _arFilterService.clearAllOverlays();
  }
}
