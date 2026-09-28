import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfly/models/pdf_tool.dart';
import 'package:pdfly/screens/file_picker_screen.dart';

void main() {
  testWidgets('Continue button stays above the system navigation bar inset',
      (tester) async {
    const navBarInset = 135.0;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.padding = const FakeViewPadding(bottom: navBarInset);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBarInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: FilePickerScreen(tool: PdfTool.compress)),
    );

    final continueBottom =
        tester.getBottomLeft(find.widgetWithText(FilledButton, 'Continue')).dy;
    expect(continueBottom, lessThanOrEqualTo(800 - navBarInset));
  });
}
