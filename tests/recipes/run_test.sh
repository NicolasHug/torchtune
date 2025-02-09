#!/bin/bash
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# Script to run recipe test locally
# Shorter Test using test checkpoint: ./run_test.sh
# Longer Test using llama 7b checkpoint: ./run_test.sh --large-scale

LOCAL_DIR="/tmp/test-artifacts"
S3_URLS=(
    "s3://pytorch-multimodal/llama2-7b/tokenizer.model"
    "s3://pytorch-multimodal/small-ckpt-01242024"
    "s3://pytorch-multimodal/small-ckpt-tune-03082024.pt"
    "s3://pytorch-multimodal/small-ckpt-meta-03082024.pt"
    "s3://pytorch-multimodal/small-ckpt-hf-03082024.pt"
)
PYTEST_COMMAND="pytest tests/recipes -s"

if [[ $# -gt 0 ]]; then
    if [ "$1" = "--large-scale" ]; then
        S3_URLS+=("s3://pytorch-multimodal/llama2-7b-01242024")
        PYTEST_COMMAND+=" --large-scale True"
    fi
fi

mkdir -p $LOCAL_DIR
for S3_URL in "${S3_URLS[@]}"; do
    FILE_NAME=$(basename "$S3_URL")

    # Check if file already exists locally
    if [ -e "$LOCAL_DIR/$FILE_NAME" ]; then
        echo "File already exists locally: $LOCAL_DIR/$FILE_NAME"
    else
        # Download file from S3
        aws s3 cp "$S3_URL" "$LOCAL_DIR"

        # Check if download was successful
        if [ $? -eq 0 ]; then
            echo "File downloaded successfully: $LOCAL_DIR/$FILE_NAME"
        else
            echo "Failed to download file from S3: $S3_URL"
            exit 1  # Failure exit code
        fi
    fi
done

$PYTEST_COMMAND

# Check pytest exit status
if [ $? -eq 0 ]; then
    echo "Pytest passed successfully"
    exit 0  # Success exit code
else
    echo "Pytest failed"
    exit 1  # Failure exit code
fi
