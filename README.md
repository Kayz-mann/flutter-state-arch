# custom_redux

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Testing

```bash
flutter test                      # unit + widget tests
flutter test integration_test     # end-to-end test (needs a device/emulator)
```

- `test/widget_test.dart` — drives the labelled buttons and checks the counter.
- `test/reducer_test.dart`, `test/store_test.dart` — reducer + store unit tests.
- `integration_test/app_test.dart` — end-to-end flow in a real engine.

## CI/CD & screenshots

CI runs on GitHub Actions ([.github/workflows/ci.yml](.github/workflows/ci.yml))
on every push / PR to `main`, in three jobs:

1. **analyze-test** — `flutter analyze` + `flutter test --coverage`.
2. **web-screenshots** — builds the app into a Docker image, runs it, captures
   the app starting inside the container, and screenshots it across a device
   matrix. Screenshots upload as the `web-screenshots` artifact.
3. **android-screenshot** — launches the app on real Android API 30 & 34
   emulators and screenshots each (uploaded per API level).

### Run the dockerized screenshots locally

```bash
docker compose up --build --abort-on-container-exit --exit-code-from shots
# -> screenshots + summary.json land in ./artifacts
```

See [docs/ci-cd.md](docs/ci-cd.md) for the device/OS coverage table, how the
"is it broken?" check works, and the design tradeoffs.
