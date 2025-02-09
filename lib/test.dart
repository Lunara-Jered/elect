import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     
      home: VideoPlayerWidget(),
    );
  }
}


class VideoPlayerWidget extends statefulwidget{
  const VideoPlayerWidget({Key? key}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
  }

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>{

  late VideoPlayerController _videoPlayerController;

  @override
  void initState(){
    super.initState();
    _videoPlayerController = VideoPlayerController.asset(
      'assets/vid.mp4')..initialize().then((_){
      _videoPlayerController.play();
      setState(() {
        
      });
    });
      
  }
  @override
  widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff1D1E22),
        title: const Text('Video Player'),
        centerTitle: true,
      ),
      body: Center(
        child: _videoPlayerController.value.IsInitialized ? 
        VideoPlayer(_videoPlayerController) : Container(),
      ),
    );
  }
}
