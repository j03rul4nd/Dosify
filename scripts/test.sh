#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/DosifyDerivedData}"
LOG_PATH="${LOG_PATH:-/tmp/dosify-test.log}"
TEST_DESTINATION="${TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 16}"

echo "Using derived data path: $DERIVED_DATA_PATH"
echo "Writing test log to: $LOG_PATH"
echo "Using test destination: $TEST_DESTINATION"
echo "Running Dosify tests without code signing..."

set +e
xcodebuild \
  -scheme Dosify \
  -destination "$TEST_DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  test | tee "$LOG_PATH"
TEST_EXIT_CODE=$?
set -e

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "Tests succeeded."
  exit 0
fi

echo ""
echo "Tests failed."

if grep -q "swift-plugin-server.*malformed response\|PersistentModelMacro\|AttributePropertyMacro" "$LOG_PATH"; then
  echo "Detected SwiftData macro/plugin failure in the local Xcode environment."
  echo "This usually means the toolchain or plugin host is failing before Swift type-checking or test execution completes."
fi

if grep -q "CoreSimulatorService\|simdiskimaged\|Unable to discover any Simulator runtimes\|actool\|Failed to initialize simulator device set" "$LOG_PATH"; then
  echo "Detected simulator or asset catalog tooling failure."
  echo "This environment is blocking full Xcode test execution independently of app logic."
fi

if grep -q "Tests must be run on a concrete device" "$LOG_PATH"; then
  echo "Detected an invalid generic destination for test execution."
  echo "This scheme requires a concrete simulator or device destination to run tests."
fi

if grep -q "cannot convert value of type '\\[Any\\]' to expected argument type 'any PersistentModel.Type'" "$LOG_PATH"; then
  echo "Detected a SwiftData type-inference error around model container/schema declarations."
  echo 'Recheck preview `.modelContainer(for:)` and app `Schema([...])` declarations in Xcode.'
fi

if grep -q "Testing failed:\|Test session results, code coverage, and logs:" "$LOG_PATH"; then
  echo "Xcode reached the test phase but one or more tests failed."
  echo "Inspect the detailed log for the specific failing test cases."
fi

echo "If the failure mentions CoreSimulator, actool or swift-plugin-server,"
echo "rerun tests from Xcode on a machine with working simulator runtimes and SwiftData macros."
echo "Full log: $LOG_PATH"

exit $TEST_EXIT_CODE
