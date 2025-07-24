#!/bin/bash

# ==============================================================================
# ---                           CONFIGURATION                              ---
# ==============================================================================
# Paths should be relative to the project root directory (where this script is).

# 1. The path to your main.py file.
MAIN_PY_PATH="neuralsat/src/main.py"

# 2. List of ONNX model files for cGAN.
ONNX_MODELS=(
    "neuralsat_bench/onnx/cGAN_imgSz32_nCh_1.onnx"
    "neuralsat_bench/onnx/cGAN_imgSz32_nCh_3.onnx"
    "neuralsat_bench/onnx/cGAN_imgSz64_nCh_1.onnx"
    "neuralsat_bench/onnx/cGAN_imgSz64_nCh_3.onnx"
)

# 3. The name of the output file for the results.
RESULTS_FILENAME="cGAN_Results.txt"

# ==============================================================================
# ---                         BENCHMARK SCRIPT                             ---
# ==============================================================================

# Get the absolute path to the directory where this script is located.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RESULTS_FILE="$SCRIPT_DIR/$RESULTS_FILENAME"

# Clear the old results file.
> "$RESULTS_FILE"

# --- Loop over each ONNX model ---
for model_path_relative in "${ONNX_MODELS[@]}"
do
    # Get the base name of the model to find matching spec files.
    # e.g., "neuralsat_bench/onnx/cGAN_imgSz32_nCh_1.onnx" -> "cGAN_imgSz32_nCh_1"
    model_basename=$(basename "$model_path_relative" .onnx)

    echo "======================================================================" | tee -a "$RESULTS_FILE"
    echo "###   STARTING TESTS FOR MODEL: $model_basename" | tee -a "$RESULTS_FILE"
    echo "======================================================================" | tee -a "$RESULTS_FILE"

    # --- Find and loop over all matching .vnnlib files ---
    # Pattern: neuralsat_bench/vnnlib/cGAN_imgSz32_nCh_1_*.vnnlib
    for spec_path_relative in neuralsat_bench/vnnlib/${model_basename}_*.vnnlib
    do
        # Construct ABSOLUTE paths for all files.
        abs_main_py_path="$SCRIPT_DIR/$MAIN_PY_PATH"
        abs_model_path="$SCRIPT_DIR/$model_path_relative"
        abs_spec_path="$SCRIPT_DIR/$spec_path_relative"

        # Check if files exist.
        if ! [ -f "$abs_main_py_path" ]; then
            echo "Error: main.py not found at '$abs_main_py_path'. Exiting." | tee -a "$RESULTS_FILE"
            exit 1
        fi
        if ! [ -f "$abs_model_path" ]; then
            echo "Error: Model file not found at '$abs_model_path'. Exiting." | tee -a "$RESULTS_FILE"
            exit 1
        fi
        if ! [ -f "$abs_spec_path" ]; then
            echo "Warning: Spec file not found at '$abs_spec_path'. Skipping." | tee -a "$RESULTS_FILE"
            continue
        fi

        # Construct the full command.
        VERIFIER_COMMAND="python3 $abs_main_py_path --net $abs_model_path --spec $abs_spec_path"

        echo "" | tee -a "$RESULTS_FILE"
        echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"
        echo "### Verifying Spec: $(basename "$spec_path_relative")" | tee -a "$RESULTS_FILE"
        echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"
        echo "" >> "$RESULTS_FILE"
        echo "Running command: $VERIFIER_COMMAND"

        # Group the command and run it with /usr/bin/time, appending all output.
        (
            cd "$SCRIPT_DIR" &&
            /usr/bin/time -v $VERIFIER_COMMAND
        ) &>> "$RESULTS_FILE"

        echo "" >> "$RESULTS_FILE"
        echo "--> Finished verification for $(basename "$spec_path_relative")."
        echo "" >> "$RESULTS_FILE"
    done
done

echo ""
echo "=================================================="
echo "cGAN Benchmark complete."
echo "Results saved to: $RESULTS_FILE"
echo "=================================================="