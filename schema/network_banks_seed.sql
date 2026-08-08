-- Fills out `network` with Vietnamese/foreign banks operating in Vietnam, as `category = 'company'`.
-- Banks have no city bias (city stays NULL), matching how the other nationwide companies are seeded.
-- Idempotent: relies on the network_name_city_key unique index (name, city).
--
-- Note: the state-owned "big 4" + most major private JSC banks (Vietcombank, VietinBank, BIDV,
-- Agribank, Techcombank, VPBank, MB, ACB, Sacombank, HDBank, TPBank, VIB, SHB, Eximbank, MSB,
-- LienVietPostBank, OCB, SeABank, Nam A Bank, Bac A Bank, PG Bank, KienlongBank, VietCapital Bank)
-- plus CIMB and HSBC were already present. This adds the remaining private JSC banks, the two
-- policy banks, the interbank co-op bank, and additional foreign/joint-venture banks.

INSERT INTO public.network (name, category, city) VALUES
    ('Ngân hàng TMCP Đông Á (DongA Bank)', 'company', NULL),
    ('Ngân hàng TMCP An Bình (ABBank)', 'company', NULL),
    ('Ngân hàng TMCP Việt Á (VietABank)', 'company', NULL),
    ('Ngân hàng TMCP Đại Chúng Việt Nam (PVcomBank)', 'company', NULL),
    ('Ngân hàng TMCP Bảo Việt (BaoVietBank)', 'company', NULL),
    ('Ngân hàng Phát triển Việt Nam (VDB)', 'company', NULL),
    ('Ngân hàng Chính sách Xã hội Việt Nam (VBSP)', 'company', NULL),
    ('Ngân hàng Hợp tác xã Việt Nam (Co-opBank)', 'company', NULL),
    ('Ngân hàng Shinhan Việt Nam', 'company', NULL),
    ('Ngân hàng ANZ Việt Nam', 'company', NULL),
    ('Ngân hàng Standard Chartered Việt Nam', 'company', NULL),
    ('Ngân hàng UOB Việt Nam', 'company', NULL),
    ('Ngân hàng Public Bank Việt Nam (PBVN)', 'company', NULL),
    ('Ngân hàng Woori Việt Nam', 'company', NULL),
    ('Ngân hàng Indovina (IVB)', 'company', NULL),
    ('Ngân hàng Liên doanh Việt - Nga (VRB)', 'company', NULL),
    ('Ngân hàng Deutsche Bank Việt Nam', 'company', NULL),
    ('Ngân hàng Mizuho Việt Nam', 'company', NULL)
ON CONFLICT (name, city) DO NOTHING;
