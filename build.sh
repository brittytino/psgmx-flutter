#!/bin/bash
set -e

echo "🚀 Starting Flutter Web build process..."

# Install Flutter if not already installed
if ! command -v flutter &> /dev/null; then
    echo "📦 Flutter not found. Installing Flutter..."
    
    # Set Flutter home
    export FLUTTER_HOME=/tmp/flutter
    export PATH="$PATH:$FLUTTER_HOME/bin"
    export PUB_CACHE="$FLUTTER_HOME/.pub-cache"
    
    # Clone Flutter stable with shallow clone
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FLUTTER_HOME
    
    # Allow running as root (Vercel requirement)
    export FLUTTER_ROOT=$FLUTTER_HOME
    
    # Disable analytics and crash reporting
    flutter config --no-analytics 2>/dev/null || true
    flutter config --suppress-analytics 2>/dev/null || true
    
    # Pre-download web artifacts only
    flutter precache --web --no-android --no-ios --no-linux --no-windows --no-macos --no-fuchsia
    
    echo "✅ Flutter installed successfully"
else
    echo "✅ Flutter already installed"
fi

# Verify Flutter installation
flutter --version

# Get dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🏗️  Building Flutter Web..."
flutter build web \
  --release \
  --web-renderer canvaskit \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

echo "✅ Build completed successfully!"
