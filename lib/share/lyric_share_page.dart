import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/providers.dart';

const _kashideAppStoreUrl =
    'https://apps.apple.com/jp/app/kashide/id6444030139';

class LyricShareData {
  const LyricShareData({
    required this.lyrics,
    required this.title,
    required this.artist,
    this.genres = const [],
  });

  final String lyrics;
  final String title;
  final String artist;
  final List<String> genres;
}

class _ShareBackground {
  const _ShareBackground(this.assetPath, this.label, this.genreKeywords)
    : filePath = null;

  const _ShareBackground.file(this.filePath)
    : assetPath = null,
      label = '写真',
      genreKeywords = const [];

  final String? assetPath;
  final String? filePath;
  final String label;
  final List<String> genreKeywords;
}

Future<void> openLyricShare(BuildContext context, LyricShareData data) {
  return Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => LyricSharePage(data: data)));
}

class LyricSharePage extends ConsumerStatefulWidget {
  const LyricSharePage({required this.data, super.key});

  final LyricShareData data;

  @override
  ConsumerState<LyricSharePage> createState() => _LyricSharePageState();
}

class _LyricSharePageState extends ConsumerState<LyricSharePage> {
  static const _taglines = [
    'その歌詞が、好きだ',
    '歌詞重視派のあなたへ',
    '好きな曲には、好きな言葉がある',
    'あの歌詞が、忘れられない',
    '歌詞と音楽を、もっと好きに',
  ];

  static const _backgroundOptions = <_ShareBackground>[
    _ShareBackground('images/card_with_dog.png', '大切な人と', [
      'ペット',
      '家族',
      '親子',
      '人生',
      '恋愛',
      'アイドル',
    ]),
    _ShareBackground('images/card_nostalsic.png', 'ひとりの夕景', [
      '失恋',
      '懐メロ',
      'LGBTQ',
      '女性目線',
      '男性目線',
      'ロック',
    ]),
    _ShareBackground('images/card_river.png', '川辺の夕景', [
      '青春',
      '勇気',
      '元気',
      'JPOP',
      '自作',
      '男性目線',
    ]),
    _ShareBackground('images/card_river2.png', '花咲く川辺', [
      '青春',
      '勇気',
      '元気',
      'JPOP',
      '人生',
      '親子',
    ]),
    _ShareBackground('images/card_room.png', '部屋で聴く音楽', [
      '恋愛',
      '懐メロ',
      '洋楽',
      'JPOP',
      'アイドル',
      'R&B ソウル',
      'ジャニーズ',
    ]),
    _ShareBackground('images/card_countryride.png', 'ふるさとの夕景', [
      '人生',
      '懐メロ',
      '家族',
      '親子',
      '青春',
      'クリスマスソング',
    ]),
    _ShareBackground('images/card_abroad.png', '旅先の夕景', [
      '洋楽',
      '恋愛',
      'クリスマスソング',
      'LGBTQ',
      '勇気',
      'JPOP',
    ]),
    _ShareBackground('images/card_love.jpg', '恋愛', ['恋愛', '女性目線', '男性目線']),
    _ShareBackground('images/card_sad.jpg', '失恋', ['失恋', 'LGBTQ']),
    _ShareBackground('images/card_youth.jpg', '青春', [
      '青春',
      '勇気',
      '元気',
      '人生',
      '自作',
    ]),
    _ShareBackground('images/card_jpop.jpg', 'J-POP', [
      'JPOP',
      'アイドル',
      'ジャニーズ',
    ]),
    _ShareBackground('images/card_western.jpg', '洋楽', ['洋楽', 'R&B ソウル']),
    _ShareBackground('images/card_retro.jpg', '懐メロ', ['懐メロ', '失恋', '恋愛', '人生']),
    _ShareBackground('images/card_life.jpg', '人生', ['人生', '家族', '親子']),
    _ShareBackground('images/card_pet.jpg', 'ペット', ['ペット']),
    _ShareBackground('images/card_rock.jpg', 'ロック', ['ロック']),
    _ShareBackground('images/card_rnb.jpg', 'R&B', ['R&B']),
  ];

  final _previewKey = GlobalKey();
  late final PageController _backgroundController;
  late final Future<String?> _artworkUrlFuture;
  late final String _tagline;
  late double _fontSize;
  late int _selectedBackgroundIndex;
  final List<_ShareBackground> _backgrounds = [..._backgroundOptions];
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _selectedBackgroundIndex = _recommendedBackgroundIndex();
    _backgroundController = PageController(
      initialPage: _selectedBackgroundIndex,
    );
    _artworkUrlFuture = _loadArtworkUrl();
    _tagline = _taglines[math.Random().nextInt(_taglines.length)];
    final lyricLength = widget.data.lyrics.trim().runes.length;
    _fontSize = switch (lyricLength) {
      <= 36 => 21.0,
      <= 60 => 19.0,
      <= 90 => 17.0,
      _ => 15.0,
    };
  }

  int _recommendedBackgroundIndex() {
    final candidates = <int>[];
    for (var index = 0; index < _backgroundOptions.length; index++) {
      final option = _backgroundOptions[index];
      if (widget.data.genres.any(
        (genre) =>
            option.genreKeywords.any((keyword) => genre.contains(keyword)),
      )) {
        candidates.add(index);
      }
    }
    if (candidates.isEmpty) return 0;
    return candidates[math.Random().nextInt(candidates.length)];
  }

  Future<void> _uploadBackground() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (image == null || !mounted) return;
    setState(() {
      _backgrounds.add(_ShareBackground.file(image.path));
      _selectedBackgroundIndex = _backgrounds.length - 1;
    });
    _backgroundController.jumpToPage(_selectedBackgroundIndex);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  Future<String?> _loadArtworkUrl() async {
    try {
      return await ref
          .read(songSearchServiceProvider)
          .lookupArtworkUrl(
            artist: widget.data.artist,
            title: widget.data.title,
          );
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final artworkUrl = await _artworkUrlFuture;
      if (artworkUrl != null && artworkUrl.isNotEmpty && mounted) {
        try {
          await precacheImage(NetworkImage(artworkUrl), context);
        } catch (_) {
          // 通信できない場合も、ジャケット画像なしでシェア画像を作る。
        }
      }
      await WidgetsBinding.instance.endOfFrame;

      final renderObject = _previewKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('シェア画像を作成できませんでした');
      }

      final image = await renderObject.toImage(pixelRatio: 3);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw StateError('画像データを作成できませんでした');
        final bytes = Uint8List.view(
          byteData.buffer,
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        if (!mounted) return;

        final title = widget.data.title.trim();
        final artist = widget.data.artist.trim();
        await SharePlus.instance.share(
          ShareParams(
            title: 'Kashideで見つけた歌詞',
            text: [
              [title, artist].where((value) => value.isNotEmpty).join(' / '),
              _kashideAppStoreUrl,
            ].where((value) => value.isNotEmpty).join('\n'),
            files: [XFile.fromData(bytes, mimeType: 'image/png')],
            fileNameOverrides: const ['kashide_lyric.png'],
          ),
        );
      } finally {
        image.dispose();
      }
    } catch (error, stackTrace) {
      debugPrint('Lyric image share failed: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像を作成・共有できませんでした。もう一度お試しください。')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F7),
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        toolbarHeight: 44,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: PageView.builder(
                      controller: _backgroundController,
                      itemCount: _backgrounds.length,
                      onPageChanged: (index) =>
                          setState(() => _selectedBackgroundIndex = index),
                      itemBuilder: (context, index) => RepaintBoundary(
                        key: index == _selectedBackgroundIndex
                            ? _previewKey
                            : null,
                        child: _LyricShareCard(
                          data: widget.data,
                          artworkUrlFuture: _artworkUrlFuture,
                          background: _backgrounds[index],
                          fontSize: _fontSize,
                          tagline: _tagline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploadBackground,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: const Text('写真を追加'),
                    style: OutlinedButton.styleFrom(foregroundColor: mainColor),
                  ),
                  const SizedBox(width: 6),
                  Text('文字の大きさ', style: const TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12,
                      max: 30,
                      divisions: 18,
                      activeColor: mainColor,
                      semanticFormatterCallback: (value) =>
                          '文字の大きさ ${value.round()}',
                      onChanged: (value) => setState(() => _fontSize = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _backgrounds[_selectedBackgroundIndex].label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF777780)),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < _backgrounds.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: index == _selectedBackgroundIndex ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _selectedBackgroundIndex
                            ? mainColor
                            : const Color(0xFFC8C8CE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _shareImage,
                  icon: _sharing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(_sharing ? '画像を準備しています…' : '画像をシェア'),
                  style: FilledButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LyricShareCard extends StatelessWidget {
  const _LyricShareCard({
    required this.data,
    required this.artworkUrlFuture,
    required this.background,
    required this.fontSize,
    required this.tagline,
  });

  final LyricShareData data;
  final Future<String?> artworkUrlFuture;
  final _ShareBackground background;
  final double fontSize;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: background.filePath == null
                ? Image.asset(background.assetPath!, fit: BoxFit.cover)
                : Image.file(File(background.filePath!), fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x55000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            child: Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  height: constraints.maxHeight * 0.62,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, lyricConstraints) => FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: lyricConstraints.maxWidth,
                                child: Text(
                                  data.lyrics.trim(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'serif',
                                    fontSize: fontSize,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 1,
                          margin: const EdgeInsets.symmetric(vertical: 18),
                          color: Colors.white70,
                        ),
                        Row(
                          children: [
                            _ArtworkThumbnail(
                              artworkUrlFuture: artworkUrlFuture,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    data.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * 0.48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'images/kashide_app_icon.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: mainColor,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Kashide',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tagline,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  const _ArtworkThumbnail({required this.artworkUrlFuture});

  final Future<String?> artworkUrlFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: artworkUrlFuture,
      builder: (context, snapshot) {
        final url = snapshot.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox.square(
            dimension: 56,
            child: url == null || url.isEmpty
                ? Container(
                    color: Colors.white24,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.white24,
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
