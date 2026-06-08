# Multi-stage build: compile the Flutter web app, then serve the static output
# with nginx. The final image only contains the built assets + nginx, so it is
# small and has no Flutter toolchain at runtime.

# ---- Stage 1: build the web bundle ------------------------------------------
# Pinned to the same Flutter version used on the dev machine and in CI.
FROM ghcr.io/cirruslabs/flutter:3.38.7 AS build

WORKDIR /app

# Cache dependencies: copy the manifests first so `pub get` is only re-run when
# they change, not on every source edit.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the project and build the release web bundle.
COPY . .
RUN flutter build web --release

# ---- Stage 2: serve with nginx ----------------------------------------------
FROM nginx:1.27-alpine AS serve

# curl is used by the HEALTHCHECK below.
RUN apk add --no-cache curl

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080

# The container is only reported "healthy" once nginx is actually serving the
# app shell. CI (and docker-compose) wait on this signal to prove the app
# started inside the container before screenshots are taken.
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=12 \
  CMD curl -fsS http://localhost:8080/ >/dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
