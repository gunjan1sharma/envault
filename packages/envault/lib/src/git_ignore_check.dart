/// How strict the generator should be about .gitignore hygiene.
enum GitIgnoreCheck {
  /// Do not check (not recommended).
  skip,
  
  /// Print a warning if .env is not gitignored, but continue generation.
  warn,
  
  /// Block generation entirely if .env is not gitignored. Default.
  failBuild,
}
