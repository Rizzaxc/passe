import 'package:flutter_test/flutter_test.dart';
import 'package:passe/manage_tab/lobby_section/invite_link/redeem_code_sheet.dart';

void main() {
  group('parseInviteCode', () {
    test('takes a bare code', () {
      expect(parseInviteCode('AbC123xy'), 'AbC123xy');
      expect(parseInviteCode('  AbC-1_23  '), 'AbC-1_23');
    });

    test('pulls the code out of a pasted link', () {
      expect(parseInviteCode('https://passe.vn/invite/AbC123xy'), 'AbC123xy');
      expect(parseInviteCode('passe.vn/invite/AbC123xy/'), 'AbC123xy');
      expect(
        parseInviteCode('https://www.passe.vn/invite/AbC123xy?utm=x'),
        'AbC123xy',
      );
      expect(
        parseInviteCode('Vào lobby nhé: https://passe.vn/invite/AbC123xy'),
        'AbC123xy',
      );
    });

    test('rejects things that are not an invite', () {
      expect(parseInviteCode(''), isNull);
      expect(parseInviteCode('   '), isNull);
      expect(parseInviteCode('https://example.com/foo'), isNull);
      expect(parseInviteCode('abc'), isNull);
      expect(parseInviteCode('passe.vn/invite/'), isNull);
      expect(parseInviteCode('hello world'), isNull);
    });
  });
}
