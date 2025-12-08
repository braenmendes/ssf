#!/bin/bash


if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

if [ -f .env ]; then
  echo "Loading .env file..."
  export $(grep -v '^#' .env | xargs)
fi

echo "Cleaning dist directory..."
rm -rf dist/*


echo "Building package..."
python3 -m build


if [ $? -ne 0 ]; then
  echo "Build failed. Exiting."
  exit 1
fi

echo "Uploading to PyPI..."
twine upload dist/*
