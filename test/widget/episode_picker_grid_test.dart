import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/domain/entities/episode.dart';
import 'package:shortigo/shared/widgets/episode_picker_grid.dart';

void main() {
  testWidgets('episode picker shows ranges and selects current range',
      (tester) async {
    final episodes = List.generate(
      65,
      (index) => Episode(
        id: 'ep${index + 1}',
        seriesId: 's1',
        order: index + 1,
        videoUrl: '',
        thumbnailUrl: '',
        durationSec: 60,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EpisodePickerGrid(
              episodes: episodes,
              currentIndex: 43,
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('1–30'), findsOneWidget);
    expect(find.text('31–60'), findsOneWidget);
    expect(find.text('61–65'), findsOneWidget);
    expect(find.text('44'), findsOneWidget);

    await tester.tap(find.text('1–30'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('31'), findsNothing);
  });

  testWidgets('locked and unavailable episodes do not call onSelect',
      (tester) async {
    var selected = 0;
    final episodes = [
      Episode(
        id: 'locked',
        seriesId: 's1',
        order: 1,
        videoUrl: '',
        thumbnailUrl: '',
        durationSec: 60,
        sourceLocked: true,
      ),
      Episode(
        id: 'unavailable',
        seriesId: 's1',
        order: 2,
        videoUrl: '',
        thumbnailUrl: '',
        durationSec: 60,
        sourceAvailable: false,
      ),
      Episode(
        id: 'open',
        seriesId: 's1',
        order: 3,
        videoUrl: '',
        thumbnailUrl: '',
        durationSec: 60,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EpisodePickerGrid(
            episodes: episodes,
            currentIndex: -1,
            onSelect: (_) => selected += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));

    expect(selected, 1);
  });
}
