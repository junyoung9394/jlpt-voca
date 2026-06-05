import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:flutter/material.dart' hide Ink;
import 'package:flutter/services.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

import 'practice_answer_utils.dart';

class HandwritingPracticeScreen extends StatefulWidget {
  final String target;
  final String? reading;
  final String hint;
  final List<String> acceptedAnswers;
  final Color color;

  const HandwritingPracticeScreen({
    super.key,
    required this.target,
    required this.hint,
    required this.acceptedAnswers,
    required this.color,
    this.reading,
  });

  @override
  State<HandwritingPracticeScreen> createState() =>
      _HandwritingPracticeScreenState();
}

class _HandwritingPracticeScreenState extends State<HandwritingPracticeScreen> {
  static const _model = 'ja';
  static const _stylusInputChannel =
      EventChannel('com.junyoung.jlptvoca/stylus_input');
  final _ink = Ink();
  final _modelManager = DigitalInkRecognizerModelManager();
  final _recognizer = DigitalInkRecognizer(languageCode: _model);
  final _canvasKey = GlobalKey();
  final _inkRepaint = ValueNotifier<int>(0);
  final _nativeStylusDevices = <int>{};
  StreamSubscription<dynamic>? _stylusSubscription;
  Stroke? _currentStroke;
  int? _activePointer;
  bool _nativeStrokeActive = false;
  bool? _previousResamplingEnabled;
  bool _checking = false;
  String? _recognized;
  bool? _correct;
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  bool get _usesNativeStylus => defaultTargetPlatform == TargetPlatform.android;

  bool _supportsWriting(PointerDeviceKind kind) {
    if (kind == PointerDeviceKind.touch) return true;
    if (_usesNativeStylus) return false;
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus ||
        kind == PointerDeviceKind.unknown;
  }

  @override
  void initState() {
    super.initState();
    _previousResamplingEnabled = GestureBinding.instance.resamplingEnabled;
    GestureBinding.instance.resamplingEnabled = true;
    if (_usesNativeStylus) {
      _stylusSubscription =
          _stylusInputChannel.receiveBroadcastStream().listen(_onStylusEvent);
    }
    _bannerAd = AdService.createBannerAd(
      onLoaded: () { if (mounted) setState(() => _bannerReady = true); },
      onFailed: () { _bannerAd = null; },
    );
    _bannerAd?.load();
  }

  void _startStroke(PointerDownEvent event) {
    if (_activePointer != null ||
        _nativeStylusDevices.contains(event.device) ||
        !_supportsWriting(event.kind)) {
      return;
    }
    _activePointer = event.pointer;
    _beginStroke(event.localPosition, event.timeStamp.inMilliseconds);
  }

  void _beginStroke(Offset point, int timestamp) {
    _currentStroke = Stroke()
      ..points.add(StrokePoint(
        x: point.dx,
        y: point.dy,
        t: timestamp,
      ));
    _ink.strokes.add(_currentStroke!);
    if (_recognized != null) {
      setState(() {
        _recognized = null;
        _correct = null;
      });
    }
    _inkRepaint.value++;
  }

  void _addPoint(PointerMoveEvent event) {
    if (event.pointer != _activePointer ||
        _nativeStylusDevices.contains(event.device)) {
      return;
    }
    _appendPoint(event.localPosition, event.timeStamp.inMilliseconds);
  }

  void _appendPoint(Offset point, int endTime) {
    final stroke = _currentStroke;
    if (stroke == null) return;
    final previous = stroke.points.last;
    final previousOffset = Offset(previous.x, previous.y);
    final distance = (point - previousOffset).distance;
    if (distance < 0.1) return;
    const maxSpacing = 3.0;
    final steps = (distance / maxSpacing).ceil().clamp(1, 40);
    final lastTime = math.max(previous.t + 1, endTime);
    final elapsed = lastTime - previous.t;

    for (var step = 1; step <= steps; step++) {
      final fraction = step / steps;
      final sampled = Offset.lerp(previousOffset, point, fraction)!;
      stroke.points.add(StrokePoint(
        x: sampled.dx,
        y: sampled.dy,
        t: previous.t + (elapsed * fraction).round(),
      ));
    }
    _inkRepaint.value++;
  }

  void _onStylusEvent(dynamic rawEvent) {
    if (!mounted || rawEvent is! Map) return;
    final type = rawEvent['type'] as String?;
    final device = (rawEvent['device'] as num?)?.toInt();
    final points = rawEvent['points'];
    if (type == null || points is! List || points.isEmpty) return;
    if (device != null) _nativeStylusDevices.add(device);

    if (type == 'down') {
      final first = _toCanvasPoint(points.first);
      if (first == null || !_isInsideCanvas(first.$1)) return;
      _nativeStrokeActive = true;
      _beginStroke(first.$1, first.$2);
      for (final point in points.skip(1)) {
        final sample = _toCanvasPoint(point);
        if (sample != null) _appendPoint(sample.$1, sample.$2);
      }
      return;
    }
    if (!_nativeStrokeActive) return;
    for (final point in points) {
      final sample = _toCanvasPoint(point);
      if (sample != null) _appendPoint(sample.$1, sample.$2);
    }
    if (type == 'up' || type == 'cancel') {
      _nativeStrokeActive = false;
      _currentStroke = null;
    }
  }

  (Offset, int)? _toCanvasPoint(dynamic rawPoint) {
    if (rawPoint is! Map) return null;
    final x = rawPoint['x'];
    final y = rawPoint['y'];
    final time = rawPoint['t'];
    if (x is! num || y is! num || time is! num) return null;
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return (
      renderBox.globalToLocal(Offset(x.toDouble(), y.toDouble())),
      time.toInt(),
    );
  }

  bool _isInsideCanvas(Offset point) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox != null &&
        renderBox.hasSize &&
        (Offset.zero & renderBox.size).contains(point);
  }

  void _endStroke(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _currentStroke = null;
  }

  Size? _canvasSize() {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.hasSize == true ? renderBox!.size : null;
  }

  void _undo() {
    if (_ink.strokes.isEmpty) return;
    setState(() {
      _ink.strokes.removeLast();
      _recognized = null;
      _correct = null;
    });
    _inkRepaint.value++;
  }

  void _clear() {
    setState(() {
      _ink.strokes.clear();
      _recognized = null;
      _correct = null;
    });
    _inkRepaint.value++;
  }

  Future<void> _recognize() async {
    if (_ink.strokes.isEmpty || _checking) return;
    final size = _canvasSize();
    if (size == null || size.isEmpty) return;
    setState(() => _checking = true);
    try {
      final downloaded = await _modelManager.isModelDownloaded(_model);
      if (!downloaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('처음 한 번 일본어 필기 인식 모델을 준비하고 있어요.')),
          );
        }
        await _modelManager.downloadModel(_model, isWifiRequired: false);
      }
      final candidates = await _recognizer.recognize(
        _ink,
        context: DigitalInkRecognitionContext(
          writingArea: WritingArea(width: size.width, height: size.height),
        ),
      );
      final texts = candidates.map((candidate) => candidate.text).toList();
      final correct = texts.any(
        (text) => matchesPracticeAnswer(widget.acceptedAnswers, text),
      );
      if (!mounted) return;
      setState(() {
        _recognized = texts.isEmpty ? '인식 결과 없음' : texts.take(3).join(' / ');
        _correct = correct;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필기 인식을 준비하지 못했습니다. 네트워크를 확인해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    _stylusSubscription?.cancel();
    GestureBinding.instance.resamplingEnabled =
        _previousResamplingEnabled ?? false;
    _inkRepaint.dispose();
    _recognizer.close();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('필기 연습'),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: widget.color.withValues(alpha: isDark ? 0.2 : 0.09),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Text(
                    widget.target,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 52,
                    ),
                  ),
                  if (widget.reading != null) ...[
                    const SizedBox(height: 4),
                    Text(widget.reading!,
                        style: TextStyle(
                            fontSize: 18,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 5),
                  Text(widget.hint,
                      style: TextStyle(
                          color:
                              isDark ? Colors.white60 : Colors.grey.shade600)),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF191B2A) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: widget.color.withValues(alpha: 0.42),
                                width: 2),
                          ),
                          child: Listener(
                            key: _canvasKey,
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: _startStroke,
                            onPointerMove: _addPoint,
                            onPointerUp: _endStroke,
                            onPointerCancel: _endStroke,
                            child: CustomPaint(
                              painter: _WritingPainter(
                                strokes: _ink.strokes,
                                inkColor:
                                    isDark ? Colors.white : Colors.black87,
                                guideColor:
                                    widget.color.withValues(alpha: 0.14),
                                repaint: _inkRepaint,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                      if (_recognized != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _correct == true
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_correct == true ? '정답' : '오답'}  |  인식: $_recognized',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _correct == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _undo,
                              icon: const Icon(Icons.undo),
                              label: const Text('되돌리기'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _clear,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('지우기'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _checking ? null : _recognize,
                              style: FilledButton.styleFrom(
                                  backgroundColor: widget.color),
                              icon: _checking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.search),
                              label: const Text('인식'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_bannerReady && _bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}

class _WritingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color inkColor;
  final Color guideColor;

  const _WritingPainter({
    required this.strokes,
    required this.inkColor,
    required this.guideColor,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = guideColor
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), guide);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), guide);

    final pen = Paint()
      ..color = inkColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path()..moveTo(stroke.points.first.x, stroke.points.first.y);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.x, point.y);
      }
      canvas.drawPath(path, pen);
    }
  }

  @override
  bool shouldRepaint(covariant _WritingPainter oldDelegate) => true;
}
