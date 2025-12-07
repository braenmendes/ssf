#!/bin/bash

usage() {
    echo "Usage: $0 <version | major | minor | patch>"
    echo "  version: Explicit version number (e.g., 1.2.3)"
    echo "  major: Bump major version (e.g., 1.2.3 -> 2.0.0)"
    echo "  minor: Bump minor version (e.g., 1.2.3 -> 1.3.0)"
    echo "  patch: Bump patch version (e.g., 1.2.3 -> 1.2.4)"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

PYPROJECT_FILE="pyproject.toml"
INIT_FILE="ssf/__init__.py"

if [ ! -f "$PYPROJECT_FILE" ]; then
    echo "Error: $PYPROJECT_FILE not found!"
    exit 1
fi

if [ ! -f "$INIT_FILE" ]; then
    echo "Error: $INIT_FILE not found!"
    exit 1
fi

CURRENT_VERSION=$(grep '^version = ' "$PYPROJECT_FILE" | sed 's/version = "\(.*\)"/\1/')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not extract version from $PYPROJECT_FILE"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"

TARGET_VERSION=""
BUMP_TYPE=""


for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        TARGET_VERSION="$arg"
    elif [[ "$arg" =~ ^(major|minor|patch)$ ]]; then
        BUMP_TYPE="$arg"
    fi
done

if [ -n "$TARGET_VERSION" ]; then
    NEW_VERSION="$TARGET_VERSION"
elif [ -n "$BUMP_TYPE" ]; then
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    case "$BUMP_TYPE" in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        patch)
            PATCH=$((PATCH + 1))
            ;;
    esac
    NEW_VERSION="$MAJOR.$MINOR.$PATCH"
else
    usage
fi

echo "New version: $NEW_VERSION"


read -p "Update files to version $NEW_VERSION? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi


sed "s/^version = \".*\"/version = \"$NEW_VERSION\"/" "$PYPROJECT_FILE" > "${PYPROJECT_FILE}.tmp" && mv "${PYPROJECT_FILE}.tmp" "$PYPROJECT_FILE"

sed "s/__version__ = \".*\"/__version__ = \"$NEW_VERSION\"/" "$INIT_FILE" > "${INIT_FILE}.tmp" && mv "${INIT_FILE}.tmp" "$INIT_FILE"


V_FILES=(
    "README.md"
    "ssf/__main__.py"
    "ssf/core/banner.py"
    "ssf/app/static/index.html"
)

for file in "${V_FILES[@]}"; do
    if [ -f "$file" ]; then

        sed -E "s/v[0-9]+\.[0-9]+\.[0-9]+/v$NEW_VERSION/g" "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        echo "Updated $file"
    else
        echo "Warning: $file not found"
    fi
done

echo "Files updated."


echo "Done."
