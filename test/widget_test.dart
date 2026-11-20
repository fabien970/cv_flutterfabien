import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cv_flutter_fabien/main.dart';

void main() {
  testWidgets('L\'application s\'ouvre sur la page de connexion', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(const CvFabienApp());
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
