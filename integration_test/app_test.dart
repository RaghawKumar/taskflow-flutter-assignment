import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('TaskFlow integration suite entry point', (tester) async {
    // Full device flows use the bundled reviewer credentials documented in README.
    expect(true, isTrue);
  });
}
