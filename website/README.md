# Passe website

Astro 7 marketing site and lobby-invite fallback for `https://passe.vn`.

## Local development

```sh
npm install
npm run dev
npm run build
npm run preview
```

The project uses Astro's official Cloudflare adapter because `/invite/[code]` must render for arbitrary invite codes. Deploy it as a Cloudflare Worker; current Astro Cloudflare adapters no longer target Cloudflare Pages.

Optional store buttons are controlled at build time:

```text
PUBLIC_APP_STORE_URL=https://apps.apple.com/...
PUBLIC_PLAY_STORE_URL=https://play.google.com/store/apps/details?id=passe.vn.passe
```

## Verified links

- Android: `/.well-known/assetlinks.json`
- iOS: `/.well-known/apple-app-site-association`
- Shared URL: `https://passe.vn/invite/<CODE>`

`assetlinks.json` currently contains the SHA-256 certificate used by this repository's current Android build: release is still configured to use the debug signing key. Before publishing through Google Play, replace or append the fingerprint from **Play Console → App integrity → App signing key certificate**. The upload-key fingerprint is not sufficient for Play-installed builds.

The AASA app ID is `5G4R29Y63U.passe.vn.passe`. Confirm that `5G4R29Y63U` is the production Apple Team ID, enable Associated Domains for the App ID, and regenerate provisioning profiles before the iOS release.

Both association endpoints must return HTTP 200 directly, without redirects, with `Content-Type: application/json`.
