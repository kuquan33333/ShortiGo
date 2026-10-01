import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/features/shorts/presentation/shorts_video_progress_bar.dart';

void main() {
  test('Shorts seek target uses the real duration', () {
    expect(shortsSeekTargetMilliseconds(.25, 100000), 25000);
  });

  testWidgets('Shorts timeline exposes a seekable touch target',
      (tester) async {
    double? selected;
    double? ended;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShortsVideoProgressBar(
            progress: .25,
            durationMs: 100000,
            onSeekStart: (value) => selected = value,
            onSeekChanged: (value) => selected = value,
            onSeekEnd: (value) => ended = value,
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNotNull);
    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pump();

    expect(selected, isNotNull);
    expect(ended, isNotNull);
    expect(ended, inInclusiveRange(0, 1));
  });
}
