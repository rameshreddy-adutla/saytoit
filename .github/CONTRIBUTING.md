# Contributing to SayToIt

Thanks for your interest in contributing! Here's how to get started.

## Development Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/rameshreddy-adutla/saytoit.git
   cd saytoit
   ```

2. **Build**
   ```bash
   make build
   ```

3. **Run tests**
   ```bash
   make test
   ```

4. **Run the app**
   ```bash
   make run
   ```

## Making Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes with clear, atomic commits
4. Add/update tests for your changes
5. Ensure all tests pass: `make test`
6. Push and open a Pull Request

## Code Guidelines

- Swift 5.9+, SwiftUI for UI
- Follow existing code patterns and naming conventions
- Use protocols for services (enables testing via dependency injection)
- Never store secrets in plaintext — use Keychain via `SecureStorage`
- Add unit tests for new functionality

## Reporting Bugs

Use the [bug report template](https://github.com/rameshreddy-adutla/saytoit/issues/new?template=bug_report.md).

## Requesting Features

Use the [feature request template](https://github.com/rameshreddy-adutla/saytoit/issues/new?template=feature_request.md).

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](../LICENSE).
