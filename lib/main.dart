import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChannelListScreen(),
    );
  }
}

class Channel {
  final String name;
  final String url;

  Channel(this.name, this.url);
}

Future<List<Channel>> loadM3UFile(String path) async {
  final String fileContent = await rootBundle.loadString(path);
  final List<String> lines = fileContent.split('\n');
  final List<Channel> channels = [];

  String? currentName;

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    if (line.startsWith('#EXTINF')) {
      currentName = line.split(',')[1].trim();
    } else if (currentName != null) {
      channels.add(Channel(currentName, line.trim()));
      currentName = null;
    }
  }

  return channels;
}

class ChannelListScreen extends StatefulWidget {
  @override
  _ChannelListScreenState createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  late Future<List<Channel>> _channelListFuture;

  @override
  void initState() {
    super.initState();
    _channelListFuture = loadM3UFile('assets/mal.m3u');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Channel List'),
      ),
      body: FutureBuilder<List<Channel>>(
        future: _channelListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading channels'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No channels available'));
          }

          final List<Channel> channels = snapshot.data!;

          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(channels[index].name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        videoUrl: channels[index].url,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  VideoPlayerScreen({required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _videoPlayerController.initialize();
    _videoPlayerController.play();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: Center(
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error initializing video player');
            } else {
              return AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController),
              );
            }
          },
        ),
      ),
    );
  }
}
