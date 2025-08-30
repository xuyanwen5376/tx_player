import 'package:flutter/material.dart';
import 'package:super_player/super_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TX Player Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VideoPlayerPage(),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final TXVodPlayerController _controller = TXVodPlayerController();
  double _aspectRatio = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  String _currentUrl = '';
  String _playerStatus = '准备就绪';
  
  // 示例视频URL - 包含腾讯云和公开测试视频
  final List<String> _videoUrls = [
    "http://1400329073.vod2.myqcloud.com/d62d88a7vodtranscq1400329073/59c68fe75285890800381567412/adp.10.m3u8",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    // 添加一个测试用的公开 m3u8 文件
    "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
  ];

  @override
  void initState() {
    super.initState();
    _configurePlayerLicense();
    _initPlayer();
  }

  void _configurePlayerLicense() {
    try {
      // 根据官方文档配置 License
      String licenceURL = "https://license.vod2.myqcloud.com/license/v2/1367213550_1/v_cube.license";
      String licenceKey = "da71de3f743a4a523e9d6469d805fb73";
      
      // 设置全局 License
      SuperPlayerPlugin.setGlobalLicense(licenceURL, licenceKey);
      print("腾讯云播放器 License 配置成功");
    } catch (e) {
      print("腾讯云播放器 License 配置失败: $e");
    }
  }

  void _initPlayer() {
    // 监听播放事件
    _controller.onPlayerEventBroadcast.listen((event) {
      final int code = event["event"];
      print("播放事件: $code - 事件详情: $event");
      
      if (code == TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN) {
        print("开始播放");
        setState(() {
          _isPlaying = true;
          _isLoading = false;
          _playerStatus = '正在播放';
        });
      } else if (code == TXVodPlayEvent.PLAY_EVT_PLAY_END) {
        print("播放结束");
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _playerStatus = '播放结束';
        });
      } else if (code == TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION) {
        int? videoWidth = event[TXVodPlayEvent.EVT_PARAM1];
        int? videoHeight = event[TXVodPlayEvent.EVT_PARAM2];
        print("分辨率变化: ${videoWidth}x${videoHeight}");
        if (videoWidth != null && videoHeight != null) {
          setState(() {
            _aspectRatio = videoWidth / videoHeight;
          });
        }
      } else if (code == TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS) {
        // 播放进度事件
        int progress = event[TXVodPlayEvent.EVT_PLAY_PROGRESS] ?? 0;
        int duration = event[TXVodPlayEvent.EVT_PLAY_DURATION] ?? 0;
        print("播放进度: $progress/$duration 秒");
      } else if (code == TXVodPlayEvent.PLAY_ERR_NET_DISCONNECT) {
        print("网络断开错误");
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _playerStatus = '网络错误';
        });
      } else if (code == TXVodPlayEvent.PLAY_ERR_GET_PLAYINFO_FAIL) {
        print("获取播放信息失败");
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _playerStatus = '获取播放信息失败';
        });
      } else if (code == -5) { // PLAY_ERR_LICENCE_CHECK_FAIL
        print("License 检查失败");
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _playerStatus = 'License 验证失败';
        });
      } else if (code == -6) { // PLAY_ERR_VOD_LOAD_FAIL
        print("VOD 加载失败");
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _playerStatus = '视频加载失败';
        });
      } else if (code == -7) { // PLAY_ERR_FILE_NOT_FOUND
        print("文件未找到");
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _playerStatus = '文件未找到';
        });
      }
    });

    // 监听播放状态
    _controller.onPlayerState.listen((state) {
      print("播放状态变化: $state");
      if (state == TXPlayerState.failed) {
        setState(() {
          _isPlaying = false;
          _isLoading = false;
          _playerStatus = '播放失败';
        });
      } else if (state == TXPlayerState.buffering) {
        setState(() {
          _isLoading = true;
          _playerStatus = '缓冲中...';
        });
      }
    });
  }

  void _playVideo(String url) async {
    print("开始播放视频: $url");
    setState(() {
      _currentUrl = url;
      _isPlaying = false;
      _isLoading = true;
      _playerStatus = '准备播放...';
    });
    
    try {
      // 先停止之前的播放
      await _controller.stop();
      
      // 开始播放视频
      await _controller.startVodPlay(url);
      print("播放命令已发送");
      
    } catch (e) {
      print('播放视频失败: $e');
      setState(() {
        _isPlaying = false;
        _isLoading = false;
        _playerStatus = '播放失败: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  void _pausePlay() {
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.resume();
    }
  }

  void _stopPlay() {
    _controller.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TX Player 腾讯云播放器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 视频播放器区域
          Container(
            height: 250,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _aspectRatio > 0
                  ? AspectRatio(
                      aspectRatio: _aspectRatio,
                      child: TXPlayerVideo(
                        androidRenderType: FTXAndroidRenderViewType.TEXTURE_VIEW,
                        onRenderViewCreatedListener: (viewId) {
                          _controller.setPlayerView(viewId);
                        },
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            else
                              const Icon(Icons.video_library, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              _playerStatus,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          
          // 播放器状态显示
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isPlaying ? Icons.play_circle : Icons.pause_circle,
                  color: _isPlaying ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '状态: $_playerStatus',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 控制按钮区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pausePlay,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? '暂停' : '播放'),
                ),
                ElevatedButton.icon(
                  onPressed: _stopPlay,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 视频列表
          Expanded(
            child: ListView.builder(
              itemCount: _videoUrls.length,
              itemBuilder: (context, index) {
                final url = _videoUrls[index];
                final isCurrentVideo = url == _currentUrl;
                
                return ListTile(
                  leading: Icon(
                    Icons.video_library,
                    color: isCurrentVideo ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    '视频 ${index + 1}',
                    style: TextStyle(
                      fontWeight: isCurrentVideo ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _playVideo(url),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentVideo ? Colors.blue : null,
                      foregroundColor: isCurrentVideo ? Colors.white : null,
                    ),
                    child: Text(isCurrentVideo ? '播放中' : '播放'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
