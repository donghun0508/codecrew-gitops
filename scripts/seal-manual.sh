#!/usr/bin/env bash
set -euo pipefail

# 사용법: ./scripts/seal-manual.sh <입력파일경로> <출력파일경로> <타겟네임스페이스> <타겟시크릿이름>
# 예시: ./scripts/seal-manual.sh services/old/secret.yaml services/new/sealedsecret.yaml my-ns my-secret

INPUT_FILE="${1:-}"
OUTPUT_FILE="${2:-}"
NAMESPACE="${3:-}"
SECRET_NAME="${4:-}"

if [[ -z "${INPUT_FILE}" || -z "${OUTPUT_FILE}" || -z "${NAMESPACE}" || -z "${SECRET_NAME}" ]]; then
  echo "Usage: $0 <input-secret-path> <output-sealed-path> <target-namespace> <target-secret-name>" >&2
  echo "Example: $0 services/world-service/envs/prod/secret.yaml services/world-master-service/envs/prod/sealedsecret-world-server.yaml world-master-service-prod world-server-secret" >&2
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CERT_PATH="${SEALED_SECRETS_CERT:-${BASE_DIR}/../.secrets/pub-sealed-secrets.pem}"

# Cert 파일 위치가 다를 수 있으므로 확인 (기존 seal.sh 참고)
# 기존 seal.sh에서는 .secrets/sealed-secrets/sealed-secrets.pem 일 수도 있고 .secrets/pub-sealed-secrets.pem 일 수도 있음
# 유저가 이전에 pub-sealed-secrets.pem을 언급했으므로 우선순위 확인

if [[ ! -f "${CERT_PATH}" ]]; then
  # Fallback to other common location
  CERT_PATH="${BASE_DIR}/../.secrets/sealed-secrets/sealed-secrets.pem"
fi

if [[ ! -f "${CERT_PATH}" ]]; then
  echo "Error: Certificate not found at ${CERT_PATH}" >&2
  exit 1
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
  echo "Error: Input secret file not found: ${INPUT_FILE}" >&2
  exit 1
fi

# Ensure output directory exists (출력 폴더가 없으면 생성)
mkdir -p "$(dirname "${OUTPUT_FILE}")"

echo "=================================================="
echo "Sealing Secret Configuration"
echo "Input:      ${INPUT_FILE}"
echo "Output:     ${OUTPUT_FILE}"
echo "Namespace:  ${NAMESPACE}"
echo "SecretName: ${SECRET_NAME}"
echo "=================================================="

kubeseal \
  --format yaml \
  --cert "${CERT_PATH}" \
  --namespace "${NAMESPACE}" \
  --name "${SECRET_NAME}" \
  < "${INPUT_FILE}" \
  > "${OUTPUT_FILE}"

echo "✅ Success! Sealed secret created at: ${OUTPUT_FILE}"
