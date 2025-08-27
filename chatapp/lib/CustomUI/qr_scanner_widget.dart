import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onQRCodeScanned;

  const QRScannerWidget({Key? key, required this.onQRCodeScanned})
    : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget>
    with WidgetsBindingObserver {
  MobileScannerController? cameraController;
  bool hasPermission = false;
  bool isInitialized = false;
  bool isDisposed = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    if (isDisposed) return;

    try {
      print('Initializing QR scanner...');

      // Stop and dispose existing controller if any
      if (cameraController != null) {
        print('Stopping existing controller...');
        await cameraController!.stop();
        cameraController!.dispose();
        cameraController = null;
      }

      await _checkPermission();

      if (hasPermission && !isDisposed) {
        print('Permission granted, creating camera controller...');
        cameraController = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
          torchEnabled: false,
          autoStart: false, // Don't auto start
        );

        print('Starting camera controller...');
        await cameraController!.start();

        if (!isDisposed) {
          setState(() {
            isInitialized = true;
            errorMessage = null;
          });
          print('Camera initialized and started successfully');
        }
      }
    } catch (e) {
      print('Error initializing scanner: $e');
      if (!isDisposed) {
        setState(() {
          errorMessage = 'Failed to initialize camera: $e';
          isInitialized = false;
        });
      }
    }
  }

  Future<void> _checkPermission() async {
    if (isDisposed) return;

    try {
      print('Checking camera permission...');
      final status = await Permission.camera.status;
      print('Current permission status: $status');

      if (status.isGranted) {
        if (!isDisposed) {
          setState(() {
            hasPermission = true;
          });
          print('Camera permission already granted');
        }
      } else {
        print('Requesting camera permission...');
        final result = await Permission.camera.request();
        print('Permission request result: $result');

        if (!isDisposed) {
          setState(() {
            hasPermission = result.isGranted;
          });

          if (!result.isGranted) {
            setState(() {
              errorMessage =
                  'Camera permission denied. Please grant permission in app settings.';
            });
          }
        }
      }
    } catch (e) {
      print('Error checking permission: $e');
      if (!isDisposed) {
        setState(() {
          errorMessage = 'Permission error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error if there's an error message
    if (errorMessage != null) {
      return _buildErrorState(errorMessage!);
    }

    // Show permission request if permission not granted
    if (!hasPermission) {
      return _buildPermissionState();
    }

    // Show loading while initializing
    if (!isInitialized || cameraController == null) {
      return _buildLoadingState();
    }

    // Show camera scanner
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MobileScanner(
          controller: cameraController!,
          onDetect: (capture) {
            try {
              final List<Barcode> barcodes = capture.barcodes;
              print('Detected ${barcodes.length} barcodes');

              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  print('QR Code detected: ${barcode.rawValue}');
                  widget.onQRCodeScanned(barcode.rawValue!);
                  break;
                }
              }
            } catch (e) {
              print('Error processing QR code: $e');
            }
          },
          errorBuilder: (context, error, child) {
            print('Mobile scanner error: $error');
            return _buildErrorState('Camera error: $error');
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Camera Error',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                errorMessage = null;
                isInitialized = false;
              });
              await _initializeScanner();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionState() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Camera Permission Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'This app needs camera access to scan QR codes',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff075E54),
              foregroundColor: Colors.white,
            ),
            child: Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff075E54)),
          ),
          SizedBox(height: 16),
          Text('Initializing Camera...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('Disposing QR scanner widget...');
    WidgetsBinding.instance.removeObserver(this);
    isDisposed = true;

    if (cameraController != null) {
      print('Stopping and disposing camera controller...');
      try {
        cameraController!.stop();
        cameraController!.dispose();
      } catch (e) {
        print('Error disposing camera controller: $e');
      }
      cameraController = null;
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (cameraController == null || !isInitialized) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        print('App paused/hidden, stopping camera...');
        cameraController?.stop();
        break;
      case AppLifecycleState.resumed:
        print('App resumed, starting camera...');
        if (!isDisposed && hasPermission) {
          cameraController?.start();
        }
        break;
      default:
        break;
    }
  }
}
