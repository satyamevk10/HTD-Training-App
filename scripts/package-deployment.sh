#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
PKG_NAME="upg-platforms-portal-deploy-${STAMP}"
DIST_ROOT="${ROOT}/dist"
OUT_DIR="${DIST_ROOT}/${PKG_NAME}"
ARCHIVE="${DIST_ROOT}/${PKG_NAME}.tar.gz"

mkdir -p "${OUT_DIR}"

echo "Packaging source (excluding node_modules, .next, .git, dist)..."
tar -czf "${OUT_DIR}/source.tar.gz" \
  --exclude=node_modules \
  --exclude=.next \
  --exclude=.git \
  --exclude=dist \
  -C "${ROOT}" .

cp "${ROOT}/deploy/INSTALL.txt" "${OUT_DIR}/"
cp "${ROOT}/deploy/env.example" "${OUT_DIR}/"

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "Building app image..."
    IMAGE_TAG="upg-platforms-portal:${STAMP}"
    docker build -t "${IMAGE_TAG}" "${ROOT}"
    echo "Saving image to ${OUT_DIR}/upg-platforms-portal-image.tar ..."
    docker save "${IMAGE_TAG}" -o "${OUT_DIR}/upg-platforms-portal-image.tar"
    echo "To load on another host: docker load -i upg-platforms-portal-image.tar"
  else
    echo "Docker daemon not reachable; skipping image build (source bundle only). Start Docker and re-run to include the image."
  fi
else
  echo "Docker not found; skipping image build (source bundle only)."
fi

echo "Creating ${ARCHIVE}..."
mkdir -p "${DIST_ROOT}"
tar -czf "${ARCHIVE}" -C "${DIST_ROOT}" "${PKG_NAME}"

echo "Done."
echo "  Bundle: ${ARCHIVE}"
echo "  Extract: tar -xzf ${ARCHIVE}"
echo ""
echo 'Do not commit dist/*.tar.gz to Git (bloats `git clone`). Publish with GitHub Releases, e.g.:'
echo "  gh release create \"deploy-${STAMP}\" \"${ARCHIVE}\" --title \"Deployment ${STAMP}\" --notes \"See INSTALL.txt inside the archive.\""
echo "  (Requires gh auth with repo/releases access.) See deploy/GITHUB_ARTIFACTS.md"
