# Test fixtures

## `private/` (git-ignored)

Real exports from customers, unzipped: the folder of CSVs that
**Settings → Export Data** produces. They're the only real-world data we
have, and they catch problems synthetic data doesn't (for example, #88's
status histories written in the wrong order by older imports).

They are **personal data**:

- Never commit them, paste their contents into issues or PRs, or copy names
  out of them. `/test/fixtures/private/` is in `.gitignore`.
- Name the folder generically (`customer_2026-06-03`), not after the person.
- Keep them only as long as they're useful, and only with the customer's
  agreement.

Tests that use one load it with `test/helpers/export_fixture.dart` and skip
when it's missing, so they pass for everyone else and in CI:

    flutter test test/real_data
