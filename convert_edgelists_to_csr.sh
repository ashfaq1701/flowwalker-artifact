#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <input_dir> <output_dir> [num_labels]"
  exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
NUM_LABELS="${3:-32}"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: input directory '$INPUT_DIR' does not exist."
  exit 1
fi

if ! [[ "$NUM_LABELS" =~ ^[0-9]+$ ]] || [[ "$NUM_LABELS" -lt 1 ]]; then
  echo "Error: num_labels must be an integer >= 1 (got '$NUM_LABELS')."
  exit 1
fi

if [[ ! -f "data/EdgeListToCSR.cpp" ]]; then
  echo "Error: expected source file at data/EdgeListToCSR.cpp."
  echo "Run this script from the repository base directory."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Compiling data/EdgeListToCSR.cpp ..."
g++ -O3 -std=c++17 -o data/EdgeListToCSR data/EdgeListToCSR.cpp

echo "Converting *.edgelist from '$INPUT_DIR' to CSR outputs in '$OUTPUT_DIR' ..."

shopt -s nullglob
edgelist_files=("$INPUT_DIR"/*.edgelist)
shopt -u nullglob

if [[ ${#edgelist_files[@]} -eq 0 ]]; then
  echo "No .edgelist files found in '$INPUT_DIR'."
  exit 0
fi

for file in "${edgelist_files[@]}"; do
  name="$(basename "$file")"
  stem="${name%.edgelist}"

  start_time=$(date +%s)
  ./data/EdgeListToCSR "$file" "$OUTPUT_DIR/$stem" "$NUM_LABELS"
  end_time=$(date +%s)

  elapsed=$((end_time - start_time))
  echo "*** Time to convert ${name} to CSR - ${elapsed} seconds ***"
done
