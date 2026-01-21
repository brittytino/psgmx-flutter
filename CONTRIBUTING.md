# Contributing to PSG MCA Placement Prep App

Thank you for your interest in contributing! This guide will help you get started.

## Getting Started

1. **Fork the Repository**
   ```bash
   git clone https://github.com/yourusername/psgmx-flutter.git
   cd psgmx-flutter
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow the existing code style
   - Write clean, well-commented code
   - Test thoroughly

## Development Setup

```bash
# Install dependencies
flutter pub get

# Run analyzer
dart analyze

# Run tests
flutter test

# Format code
dart format lib/
```

## Commit Guidelines

- Write clear commit messages
- Reference issues when applicable: `Fixes #123`
- Keep commits focused and atomic

## Pull Request Process

1. Update documentation if needed
2. Add/update tests for new features
3. Ensure `dart analyze` passes with no errors
4. Create a descriptive PR with context
5. Link related issues

## Code Style

- Follow [Flutter style guidelines](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Maximum line length: 80 characters for comments, 120 for code
- Use `final` by default, `const` when appropriate

## Testing

- Write tests for new features
- Ensure existing tests pass
- Aim for >80% code coverage

## Reporting Bugs

Include:
- Device/OS details
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs if applicable

## Feature Requests

- Describe the use case
- Explain the proposed solution
- Consider backwards compatibility

## License

By contributing, you agree your code will be licensed under MIT License.

---

Questions? Open a discussion or issue!
