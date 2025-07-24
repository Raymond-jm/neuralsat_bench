#!/bin/bash

# ==============================================================================
# ---                           CONFIGURATION                              ---
# ==============================================================================
MAIN_PY_PATH="neuralsat/src/main.py"
ONNX_MODELS=(
    "neuralsat_bench/onnx/NN_rul_full_window_20.onnx"
    "neuralsat_bench/onnx/NN_rul_full_window_40.onnx"
)
RESULTS_FILENAME="Collins_Results.txt"

# ==============================================================================
# ---                         BENCHMARK SCRIPT                             ---
# ==============================================================================
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
RESULTS_FILE="$SCRIPT_DIR/$RESULTS_FILENAME"
> "$RESULTS_FILE"

for model_path_relative in "${ONNX_MODELS[@]}"
do
    model_basename=$(basename "$model_path_relative" .onnx)
    spec_pattern=""

    # Set the spec file pattern based on the model name
    if [[ "$model_basename" == *window_20 ]]; then
        spec_pattern="neuralsat_bench/vnnlib/*w20.vnnlib"
    elif [[ "$model_basename" == *window_40 ]]; then
        spec_pattern="neuralsat_bench/vnnlib/*w40.vnnlib"
    else
        echo "Warning: No spec pattern defined for $model_basename. Skipping." | tee -a "$RESULTS_FILE"
        continue
    fi

    echo "======================================================================" | tee -a "$RESULTS_FILE"
    echo "###   STARTING TESTS FOR MODEL: $model_basename" | tee -a "$RESULTS_FILE"
    echo "======================================================================" | tee -a "$RESULTS_FILE"

    for spec_path_relative in $spec_pattern
    do
        abs_main_py_path="$SCRIPT_DIR/$MAIN_PY_PATH"
        abs_model_path="$SCRIPT_DIR/$model_path_relative"
        abs_spec_path="$SCRIPT_DIR/$spec_path_relative"

        if ! [ -f "$abs_main_py_path" ]; then echo "Error: main.py not found. Exiting." | tee -a "$RESULTS_FILE"; exit 1; fi
        if ! [ -f "$abs_model_path" ]; then echo "Error: Model file not found. Exiting." | tee -a "$RESULTS_FILE"; exit 1; fi
        if ! [ -f "$abs_spec_path" ]; then echo "Warning: Spec file not found. Skipping." | tee -a "$RESULTS_FILE"; continue; fi

        VERIFIER_COMMAND="python3 $abs_main_py_path --net $abs_model_path --spec $abs_spec_path"

        echo "" | tee -a "$RESULTS_FILE"
        echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"
        echo "### Verifying Spec: $(basename "$spec_path_relative")" | tee -a "$RESULTS_FILE"
        echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"
        echo "" >> "$RESULTS_FILE"
        echo "Running command: $VERIFIER_COMMAND"

        ( cd "$SCRIPT_DIR" && /usr/bin/time -v $VERIFIER_COMMAND ) &>> "$RESULTS_FILE"

        echo "" >> "$RESULTS_FILE"
        echo "--> Finished verification for $(basename "$spec_path_relative")."
        echo "" >> "$RESULTS_FILE"
    done
done

echo -e "\n==================================================\nCollins Benchmark complete.\nResults saved to: $RESULTS_FILE\n=================================================="