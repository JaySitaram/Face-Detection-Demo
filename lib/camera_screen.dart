import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_face_detect/detector_view.dart';
import 'package:flutter_application_face_detect/face_detector_painter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late Offset _greenAreaPosition;
  late FaceDetector _faceDetector;
  List<Face> _faces = [];
   bool _canProcess = true;
  bool _isBusy = false;
   CustomPaint? _customPaint;
    String? _text;
  var _cameraLensDirection = CameraLensDirection.front;  

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
    _greenAreaPosition = Offset(0, 0);
    final options = FaceDetectorOptions();
    _faceDetector = FaceDetector(options: options);
  }

  void _detectFaces() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    // final image = FirebaseVisionImage.fromBytes(
    //   (await _controller.takePicture()).buffer.asUint8List(),
    // );

    ///final faces = await _faceDetector.processImage(image);

    setState(() {
      // _faces = faces;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: DetectorView(
                    title: 'Face Detector',
                    customPaint: _customPaint,
                    text: _text,
                    onImage: _processImage,
                    initialCameraLensDirection: _cameraLensDirection,
                    onCameraLensDirectionChanged: (value) =>
                        _cameraLensDirection = value,
                  ),
                ),
                // ElevatedButton(
                //   onPressed: _captureImage,
                //   child: Text('Capture Image'),
                // ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _captureImage() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    final path = (await _controller.takePicture()).path;
    // _detectFacesFromImage(path);
    print('Image captured at: $path');
  }

 Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if(faces.length>1){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Oops Multiple Faces Showing')));
    }
    else{
      if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
    }
  }

  Widget _buildFaceWidgets() {
    return Stack(
      children: _faces.map((face) {
        final faceRect = face.boundingBox;
        return Positioned(
          left: faceRect.left,
          top: faceRect.top,
          width: faceRect.width,
          height: faceRect.height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 2.0,
              ),
            ),
            child: Center(
              child: Text(
                '😊',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30.0,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}