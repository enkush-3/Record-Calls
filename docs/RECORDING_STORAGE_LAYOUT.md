# Local recording storage layout

Recordings stay on the device. The app creates the following directories under the
configured recording root, then writes new recordings into them:

```text
Record Call/
├── Audio/
│   ├── Viber/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.m4a
│   ├── Telegram/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.m4a
│   ├── WhatsApp/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.m4a
│   ├── Messenger/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.m4a
│   ├── WeChat/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.m4a
│   ├── Phone/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.m4a
│   └── Manual/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.m4a
└── Video/
    └── <source>/<sanitized phone number>/<yyyyMMdd_HHmmss_SSS>.mp4
```

Examples:

```text
Record Call/Audio/Viber/+97699112233/20261112_153045_123.m4a
Record Call/Video/Telegram/+97699112233/20261112_153045_123.mp4
Record Call/Audio/Phone/Unknown_Caller/20261112_153045_123.m4a
```

Filenames include milliseconds. If a filename already exists, the app adds a
numeric suffix before the extension to avoid replacing that file.

To reduce file sizes, audio recording uses 22.05 kHz AAC at 64 kbit/s. Screen
recordings are capped at a 1280-pixel longest edge, 24 frames per second, and
1.2 Mbit/s video with 22.05 kHz / 64 kbit/s AAC audio. Actual size depends on
screen content and recording duration.

The source name is normalized for known apps (for example, `watsapp` becomes
`WhatsApp`, and cellular/phone/call becomes `Phone`). Other source names have
non-ASCII letters and punctuation removed. Phone-number folder names replace
characters outside letters, digits, `+`, `_`, `.`, and `-` with `_`; missing or
unknown caller IDs use `Unknown_Caller`.

## Default root and Android storage access

On Android 10–15, the default is the app-specific external Documents directory:

```text
<external app files>/Documents/Record Call
```

If Android does not provide app-specific external storage, the app uses its
internal files directory under `Documents/Record Call`. These locations are
writable without broad storage permissions and are private to the app. The first
location may be removed by Android when the app is uninstalled.

This is not the device-wide public `Documents/Record Call` directory. Android's
scoped-storage rules do not allow the app to write there through a raw filesystem
path. Choosing the public Documents location requires a Storage Access Framework
folder grant (or a MediaStore implementation); the current raw-path preference
does not persist such a grant. A user-selected writable path is kept as the root
and uses the same `Audio`/`Video` hierarchy below it. Invalid or unwritable paths
fall back to the app-specific default.

Changing the root affects new recordings only. Existing recordings and their
stored file paths are left in place; no files are moved or renamed.
