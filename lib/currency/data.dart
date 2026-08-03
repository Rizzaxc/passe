import 'model.dart';

// The đá currency ledger is not in the DB yet (see lib/currency/controller.dart
// and root CLAUDE.md). Until a real server-side ledger + payment provider land,
// there is no transaction history to show — these lists are intentionally empty
// rather than fabricated, so the wallet never presents fake purchases/spends as
// if they were real. The history screens render an honest empty state instead.
const sampleDaPurchases = <DaPurchase>[];

const sampleDaSpending = <DaSpending>[];

const daPackages = <DaPackage>[
  DaPackage(id: 'pkg50', da: 50, price: 50000, bonus: 0),
  DaPackage(id: 'pkg100', da: 100, price: 100000, bonus: 0),
  DaPackage(id: 'pkg200', da: 200, price: 200000, bonus: 0),
  DaPackage(id: 'pkg500', da: 500, price: 500000, bonus: 25, tag: 'Phổ Biến'),
  DaPackage(
    id: 'pkg1k',
    da: 1000,
    price: 1000000,
    bonus: 100,
    tag: 'Tiết Kiệm 10%',
  ),
  DaPackage(
    id: 'pkg5k',
    da: 5000,
    price: 5000000,
    bonus: 750,
    tag: 'Tốt Nhất',
  ),
];

const daPurchasablePayMethods = <DaPayMethod>[
  DaPayMethod.momo,
  DaPayMethod.zalopay,
  DaPayMethod.vietqr,
  DaPayMethod.apple,
];

// Local, non-functional balance (no server ledger yet). Starts at zero so the
// wallet never shows đá the user never actually acquired; the test-only top-up
// screen can still credit it locally.
const defaultDaBalance = 0;
