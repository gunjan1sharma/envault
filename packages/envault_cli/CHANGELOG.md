## 0.1.0

* Initial release of envault_cli.
* Fast, standalone CLI generator (no `build_runner` required).
* Extracts .env, checks entropy/placeholders via `envault validate`.
* Emits securely encrypted `vault.g.dart` using AES-256-GCM.
