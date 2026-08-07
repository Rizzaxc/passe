export const prerender = true;

const body = [
  {
    relation: ['delegate_permission/common.handle_all_urls'],
    target: {
      namespace: 'android_app',
      package_name: 'passe.vn.passe',
      sha256_cert_fingerprints: [
        'E0:95:13:4A:EB:8F:C0:B4:5A:8C:00:D2:E9:E3:55:A4:5F:96:C4:A8:DF:D3:0F:F9:93:0B:D8:CB:FD:91:30:E5',
      ],
    },
  },
];

export function GET() {
  return new Response(JSON.stringify(body), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}
