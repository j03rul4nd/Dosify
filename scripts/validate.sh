#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/DosifyDerivedData}"
LOG_PATH="${LOG_PATH:-/tmp/dosify-validate.log}"

echo "Using derived data path: $DERIVED_DATA_PATH"
echo "Writing build log to: $LOG_PATH"
echo "Building Dosify for generic iOS device without code signing..."

set +e
xcodebuild \
  -scheme Dosify \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build | tee "$LOG_PATH"
BUILD_EXIT_CODE=$?
set -e

if [ $BUILD_EXIT_CODE -eq 0 ]; then
  echo "Build succeeded."
  exit 0
fi

echo ""
echo "Build failed."

if grep -q "swift-plugin-server.*malformed response\|PersistentModelMacro\|AttributePropertyMacro" "$LOG_PATH"; then
  echo "Detected SwiftData macro/plugin failure in the local Xcode environment."
  echo "This usually means the toolchain or plugin host is failing before Swift type-checking completes."
fi

if grep -q "CoreSimulatorService\|simdiskimaged\|Unable to discover any Simulator runtimes\|actool" "$LOG_PATH"; then
  echo "Detected simulator or asset catalog tooling failure."
  echo "This environment is blocking full Xcode validation independently of app logic."
fi

if grep -q "cannot convert value of type '\\[Any\\]' to expected argument type 'any PersistentModel.Type'" "$LOG_PATH"; then
  echo "Detected a SwiftData type-inference error around model container/schema declarations."
  echo 'Recheck preview `.modelContainer(for:)` and app `Schema([...])` declarations in Xcode.'
fi

echo "If the failure mentions CoreSimulator, actool or swift-plugin-server,"
echo "rerun validation from Xcode on a machine with working simulator runtimes and SwiftData macros."
echo "Full log: $LOG_PATH"

exit $BUILD_EXIT_CODE
