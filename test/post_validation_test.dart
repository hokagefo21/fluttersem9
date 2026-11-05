import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/presentation/state/posts_controller.dart';

void main() {
  group('Post form validation', () {
    test(
      'Empty title rejected',
      () => expect(PostValidation.title('  '), isNotNull),
    );
    test(
      'Short title rejected',
      () => expect(PostValidation.title('abcd'), isNotNull),
    );
    test(
      'Valid title accepted',
      () => expect(PostValidation.title('My new post'), isNull),
    );
    test(
      'Long title rejected',
      () => expect(PostValidation.title('x' * 101), isNotNull),
    );
    test(
      'Short body rejected',
      () => expect(PostValidation.body('Too short'), isNotNull),
    );
    test(
      'Valid body accepted',
      () => expect(PostValidation.body('A complete post body.'), isNull),
    );
    test(
      'Long body rejected',
      () => expect(PostValidation.body('x' * 1001), isNotNull),
    );
  });
}
