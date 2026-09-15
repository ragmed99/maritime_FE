import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

void main() {
  testWidgets('French uses left-to-right layout', (tester) async {
    await tester.pumpWidget(const _LocalizedHarness(locale: Locale('fr')));
    expect(find.text('TAR FISHING'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('TAR FISHING'))),
      TextDirection.ltr,
    );
  });

  testWidgets('Arabic uses right-to-left layout', (tester) async {
    await tester.pumpWidget(const _LocalizedHarness(locale: Locale('ar')));
    expect(find.text('TAR FISHING'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('TAR FISHING'))),
      TextDirection.rtl,
    );
  });
}

class _LocalizedHarness extends StatelessWidget {
  const _LocalizedHarness({required this.locale});
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) =>
            Scaffold(body: Text(AppLocalizations.of(context).appName)),
      ),
    );
  }
}
