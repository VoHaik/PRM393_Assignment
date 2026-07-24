import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/lucide_icons.dart';

/// Helper to parse YouTube video ID from various YouTube URL formats.
String? getYoutubeVideoId(String source) {
  try {
    final cleanSource = source.trim();
    if (cleanSource.isEmpty) return null;

    final id = YoutubePlayerController.convertUrlToId(cleanSource);
    if (id != null && id.isNotEmpty) return id;

    final uri = Uri.parse(cleanSource);
    final host = uri.host.toLowerCase().replaceAll('www.', '');

    if (host == 'youtube.com' || host == 'm.youtube.com') {
      if (uri.path == '/watch') return uri.queryParameters['v'];
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'shorts') {
        return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      }
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'embed') {
        return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      }
    } else if (host == 'youtu.be') {
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
    }
  } catch (_) {}
  return null;
}

class InAppVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final VoidCallback? onClose;
  final bool autoPlay;

  const InAppVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.onClose,
    this.autoPlay = true,
  });

  @override
  State<InAppVideoPlayer> createState() => _InAppVideoPlayerState();
}

class _InAppVideoPlayerState extends State<InAppVideoPlayer> {
  // YouTube player fields
  YoutubePlayerController? _youtubeController;

  // Direct MP4 / Cloud video player fields
  VideoPlayerController? _videoPlayerController;

  bool _isInit = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final youtubeId = getYoutubeVideoId(widget.videoUrl);
    if (youtubeId != null && youtubeId.isNotEmpty) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: youtubeId,
        autoPlay: widget.autoPlay,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          enableJavaScript: true,
          playsInline: true,
        ),
      );
      if (mounted) {
        setState(() {
          _isInit = true;
        });
      }
    } else {
      // Direct Cloud / MP4 Video Player using pure video_player
      try {
        final uri = Uri.parse(widget.videoUrl.trim());
        _videoPlayerController = VideoPlayerController.networkUrl(uri);
        await _videoPlayerController!.initialize();

        _videoPlayerController!.addListener(() {
          if (mounted) setState(() {});
        });

        if (widget.autoPlay) {
          _videoPlayerController!.play();
        }

        if (mounted) {
          setState(() {
            _isInit = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = e.toString();
            _isInit = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.tryParse(widget.videoUrl.trim());
    if (uri == null) return;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorCard(_errorMessage);
    }

    // For YouTube URLs, render YoutubeExternalPlayer matching Mobile React 100%
    final youtubeId = getYoutubeVideoId(widget.videoUrl);
    if (youtubeId != null && youtubeId.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0000).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Video YouTube này không cho phát nhúng trong ứng dụng. Hãy mở bằng YouTube, sau đó quay lại để tiếp tục xem nhân vật liên quan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openExternalBrowser,
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: const Text('Mở trên YouTube', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
            if (widget.onClose != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onClose,
                child: const Text('Tiếp tục xem chi tiết', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ],
        ),
      );
    }

    // Direct Cloud MP4 Player View
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      final controller = _videoPlayerController!;
      final value = controller.value;

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          child: AspectRatio(
            aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(controller),

                // Controls overlay
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                value.isPlaying ? LucideIcons.pause : LucideIcons.play,
                                color: Colors.amber,
                              ),
                              onPressed: () {
                                setState(() {
                                  value.isPlaying ? controller.pause() : controller.play();
                                });
                              },
                            ),
                            Text(
                              '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                value.volume == 0 ? LucideIcons.volumeX : LucideIcons.volume2,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  controller.setVolume(value.volume == 0 ? 1.0 : 0.0);
                                });
                              },
                            ),
                          ],
                        ),
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.amber,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildErrorCard('Không thể khởi tạo trình phát video.');
  }

  Widget _buildErrorCard(String errorMsg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.film, size: 42, color: Colors.amber),
          const SizedBox(height: 12),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const Text(
            'Không thể xem trực tiếp hoặc video yêu cầu mở bằng ứng dụng ngoài.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openExternalBrowser,
            icon: Icon(LucideIcons.externalLink, size: 16),
            label: const Text('Mở nguồn Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal Fullscreen Video Player for Context Detail screen
class FullscreenVideoModal extends StatelessWidget {
  final String videoUrl;
  final String title;

  const FullscreenVideoModal({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: InAppVideoPlayer(
              videoUrl: videoUrl,
              title: title,
              autoPlay: true,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}
