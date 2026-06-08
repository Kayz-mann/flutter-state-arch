# Screenshot harness image. The Playwright base image already bundles Chromium
# and all its system libraries, so no `playwright install` is needed at runtime.
FROM mcr.microsoft.com/playwright:v1.50.0-jammy

WORKDIR /harness

# Install JS deps first for layer caching. --omit=dev keeps the image lean; the
# harness only needs the runtime dependencies declared in package.json.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY capture.mjs ./

# APP_URL and ARTIFACTS_DIR are provided by docker-compose / CI.
ENV ARTIFACTS_DIR=/artifacts
CMD ["node", "capture.mjs"]
