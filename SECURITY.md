# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x.x   | ✅ Current |

## Reporting a Vulnerability

**DO NOT open a public GitHub issue for security vulnerabilities.**

Email security reports to: **security@envault.dev** (or your contact)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We commit to:
- Acknowledge receipt within 48 hours
- Provide a status update within 7 days
- Credit researchers in our release notes (unless anonymity is requested)

## Security Design Principles

### What envault protects against
- Passive binary analysis (`strings libapp.so`) — AES-256-GCM ciphertext is opaque
- Accidental secret logging — `SecureString.toString()` always returns `[REDACTED]`
- Accidental git commits — build blocked if `.env` is not gitignored
- Weak secrets — entropy validation at build time

### What envault does NOT protect against
- **Active runtime instrumentation (Frida)** — if an attacker can hook `dart:ffi` on a rooted/jailbroken device, any in-memory secret can be read. This is a fundamental limitation of all client-side secret management.
- **Compromise of the `VAULT_MASTER_KEY`** — if your CI master key is leaked, rotate it immediately and rebuild all targets.
- **Fully compromised OS** — if the operating system itself is compromised, all bets are off.

### Threat Model
For a complete threat model, see [THREAT_MODEL.md](./THREAT_MODEL.md).

### Compliance
For PCI-DSS v4.0 and OWASP MASVS v2 alignment, see [COMPLIANCE.md](./COMPLIANCE.md).

## Cryptographic Algorithms Used
- **Key derivation:** PBKDF2-HMAC-SHA256 (310,000 iterations — NIST SP 800-132 compliant)
- **Encryption:** AES-256-GCM (NIST FIPS 197, NIST SP 800-38D)
- **IV generation:** OS CSPRNG via `dart:math Random.secure()` — 96-bit (12 bytes)
- **Authentication tag:** GCM 128-bit tag (16 bytes)
- **Runtime crypto:** `package:cryptography` — no dependency on PointyCastle

## Responsible Disclosure Timeline
- **Day 0:** Vulnerability reported
- **Day 2:** Acknowledgement sent
- **Day 7:** Severity assessment and fix timeline communicated
- **Day 30:** Fix released (critical), **Day 90:** Fix released (medium/low)
- **Day 90/120:** Public disclosure (CVE requested if applicable)
