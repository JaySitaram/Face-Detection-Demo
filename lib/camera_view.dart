import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CameraView extends StatefulWidget {
  CameraView(
      {Key? key,
      required this.customPaint,
      required this.onImage,
      this.onCameraFeedReady,
      this.onDetectorViewModeChanged,
      this.onCameraLensDirectionChanged,
      this.initialCameraLensDirection = CameraLensDirection.back})
      : super(key: key);

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  String? imagePath;
  bool _changingCameraLens = false;
  List<String> options = ['Option 1', 'Option 2'];

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _liveFeedBody();
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: FractionalOffset.center,
    
        children: <Widget>[
          
          Positioned.fill(
            child: Transform.scale(
      scale:  1 / (_controller!.value.aspectRatio *  MediaQuery.of(context).size.aspectRatio),
      alignment: Alignment.topCenter,
      child: Center(
                child: imagePath != null && imagePath!.isNotEmpty
                    ? Image.file(File(imagePath!))
                    : CameraPreview(
                        _controller!,
                        child: widget.customPaint,
                      ),
              ),
            ),
          ),
           Align(
            alignment: Alignment.topLeft,
             child: Container(
                    color: Colors.black,
                    height: 40,
                    margin: EdgeInsets.only(top: 30,bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         IconButton(onPressed: (){}, icon: Icon(Icons.close,color: Colors.white,)),
                         IconButton(onPressed: (){}, icon: Icon(Icons.menu,color: Colors.white,)) 
                      ],
                    ),
                  ),
           ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 220.0,
              padding: EdgeInsets.all(20.0),
              color: Color.fromRGBO(00, 00, 00, 0.7),
              child: imagePath != null
                  ? Stack(
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.arrow_back, color: Colors.white),
                                ),
                                Text(
                                  'Options',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                  itemCount: options.length,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  // padding: EdgeInsets.symmetric(horizontal: 20),
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      child: Container(
                                          color: Colors.grey[200],
                                          padding:
                                              EdgeInsets.symmetric(horizontal: 10),
                                          margin:
                                              EdgeInsets.symmetric(horizontal: 10),
                                          child:
                                              Center(child: Text(options[index]))),
                                    );
                                  }),
                            ),
                           
                          ],
                        ),
                     Align(
                          alignment: Alignment.bottomCenter,
                          child: MaterialButton(
                            onPressed: () {},
                            color: Colors.blue,
                            minWidth: MediaQuery.of(context).size.width,
                            child: Text('Save'),
                          ),
                        ),
                    ],
                  )
                  : Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 10, bottom: 20),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50.0)),
                              onTap: () {
                                _captureImage();
                              },
                              child: Container(
                                padding: EdgeInsets.all(4.0),
                                child: Image.asset(
                                  'assets/images/ic_shutter_1.png',
                                  width: 72.0,
                                  height: 72.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey[200],
                                    size: 42.0,
                                  ),
                                )),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50.0)),
                                onTap: () {
                                  // if (!_toggleCamera) {
                                  //   onCameraSelected(widget.cameras[1]);
                                  //   setState(() {
                                  //     _toggleCamera = true;
                                  //   });
                                  // } else {
                                  //   onCameraSelected(widget.cameras[0]);
                                  //   setState(() {
                                  //     _toggleCamera = false;
                                  //   });
                                  // }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4.0),
                                  child: Image.asset(
                                    'assets/images/ic_switch_camera_3.png',
                                    color: Colors.grey[200],
                                    width: 42.0,
                                    height: 42.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
      
          // _switchLiveCameraToggle(),
          // _detectionViewModeToggle(),
        ],
      ),
    );
  }

  Widget _detectionViewModeToggle() => Positioned(
        bottom: 8,
        left: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: widget.onDetectorViewModeChanged,
            backgroundColor: Colors.black54,
            child: Icon(
              Icons.photo_library_outlined,
              size: 25,
            ),
          ),
        ),
      );

  Widget _switchLiveCameraToggle() => Positioned(
        bottom: 8,
        right: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: _switchLiveCamera,
            backgroundColor: Colors.black54,
            child: Icon(
              Platform.isIOS
                  ? Icons.flip_camera_ios_outlined
                  : Icons.flip_camera_android_outlined,
              size: 25,
            ),
          ),
        ),
      );

  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        _currentZoomLevel = value;
        _minAvailableZoom = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });
      _currentExposureOffset = 0.0;
      _controller?.getMinExposureOffset().then((value) {
        _minAvailableExposureOffset = value;
      });
      _controller?.getMaxExposureOffset().then((value) {
        _maxAvailableExposureOffset = value;
      });
      // _controller?.startImageStream(_processCameraImage).then((value) {
      //   if (widget.onCameraFeedReady != null) {
      //     widget.onCameraFeedReady!();
      //   }
      //   if (widget.onCameraLensDirectionChanged != null) {
      //     widget.onCameraLensDirectionChanged!(camera.lensDirection);
      //   }
      // });
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  void _captureImage() {
    takePicture().then((String? filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          print('this is >> $imagePath');
        });
        // if (filePath != null) {
        // showMessage('Picture saved to $filePath');
        //  Navigator.pop(context,imagePath);
        //}
      }
    });
  }

  Future<String?> takePicture() async {
    if (!_controller!.value.isInitialized) {
      ///showMessage('Error: select a camera first.');
      return null;
    }

    if (_controller!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await _controller!.takePicture();

      return file.path;
    } on CameraException catch (e) {
      // showException(e);
      return null;
    }
    // return filePath;
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    // print(
    //     'lensDirection: ${camera.lensDirection}, sensorOrientation: $sensorOrientation, ${_controller?.value.deviceOrientation} ${_controller?.value.lockedCaptureOrientation} ${_controller?.value.isCaptureOrientationLocked}');
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;
    // print('final rotation: $rotation');

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}
