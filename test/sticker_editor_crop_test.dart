import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agendario/screens/sticker_editor_screen.dart';

void main() {
  testWidgets('CropOverlayWidget renders correctly and triggers callbacks on drag',
      (WidgetTester tester) async {
    Rect? updatedRect;

    // Pump the CropOverlayWidget inside a fixed-size container
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CropOverlayWidget(
                initialRect: const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
                onRectChanged: (rect) {
                  updatedRect = rect;
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Verify CustomPaint is rendered
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));

    // Verify gesture hitboxes are present
    expect(find.byType(GestureDetector), findsAtLeastNWidgets(8));

    // Drag the top-left handle (which is positioned at 0, 0 relative to the 200x200 box)
    // The top-left Positioned has left = screenRect.left - halfHandle, top = screenRect.top - halfHandle
    // We can drag the top-left gesture detector by starting at (100, 100) on screen if center is offset,
    // but finding it by offset or coordinate is easiest.
    // The top-left handle's center is at local (0, 0), which on screen is at (300, 200) since Center is at (400, 300).
    // Let's drag it inwards to the right and down.
    final topLeftFinder = find.byType(GestureDetector).first;
    await tester.drag(topLeftFinder, const Offset(20, 20));
    await tester.pump();

    // Verify callback was fired and rect shrunk
    expect(updatedRect, isNotNull);
    expect(updatedRect!.left, greaterThan(0.0));
    expect(updatedRect!.top, greaterThan(0.0));
    expect(updatedRect!.right, equals(1.0));
    expect(updatedRect!.bottom, equals(1.0));
  });
}
