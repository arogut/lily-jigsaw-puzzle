#!/usr/bin/env bash
set -euo pipefail

# Pin the Cursor CLI lab build. Bump intentionally when upgrading CI.
CURSOR_CLI_VERSION="${CURSOR_CLI_VERSION:-2026.07.01-41b2de7}"

OS="linux"
ARCH="x64"
DOWNLOAD_URL="https://downloads.cursor.com/lab/${CURSOR_CLI_VERSION}/${OS}/${ARCH}/agent-cli-package.tar.gz"
VERSION_DIR="${HOME}/.local/share/cursor-agent/versions/${CURSOR_CLI_VERSION}"
WORK_DIR="${HOME}/.local/share/cursor-agent/versions/.work-${CURSOR_CLI_VERSION}-$$"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "${WORK_DIR}" "${BIN_DIR}"

curl -fSL "${DOWNLOAD_URL}" -o "${WORK_DIR}/agent-cli-package.tar.gz"
tar -xzf "${WORK_DIR}/agent-cli-package.tar.gz" -C "${WORK_DIR}"

PACKAGE_DIR="${WORK_DIR}/dist-package"
if [ ! -x "${PACKAGE_DIR}/cursor-agent" ]; then
  echo "cursor-agent binary not found in extracted package." >&2
  exit 1
fi

rm -rf "${VERSION_DIR}"
mv "${PACKAGE_DIR}" "${VERSION_DIR}"
rm -rf "${WORK_DIR}"

ln -sf "${VERSION_DIR}/cursor-agent" "${BIN_DIR}/agent"
ln -sf "${VERSION_DIR}/cursor-agent" "${BIN_DIR}/cursor-agent"

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "${BIN_DIR}" >> "${GITHUB_PATH}"
fi

echo "Installed Cursor CLI ${CURSOR_CLI_VERSION} to ${VERSION_DIR}"
