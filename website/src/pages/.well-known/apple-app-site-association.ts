export const prerender = true;

const body = {
  applinks: {
    apps: [],
    details: [
      {
        appID: '5G4R29Y63U.passe.vn.passe',
        paths: ['/invite/*'],
      },
    ],
  },
};

export function GET() {
  return new Response(JSON.stringify(body), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}
