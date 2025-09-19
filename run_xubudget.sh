#!/bin/bash
# Script to run Xubudget Flutter app with 2GB memory optimization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Xubudget Flutter App Runner ===${NC}"
echo -e "${YELLOW}Optimized for 2GB memory devices${NC}"

# Set Flutter path
export PATH="$PATH:/opt/flutter/bin"

# Navigate to mobile app directory
cd "$(dirname "$0")/mobile_app"

echo -e "${YELLOW}Current directory:${NC} $(pwd)"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter not found. Trying to use cached version...${NC}"
    export PATH="$PATH:/opt/flutter/bin"
fi

# Function to check if Android emulator is running
check_emulator() {
    if command -v adb &> /dev/null; then
        if adb devices | grep -q "emulator"; then
            echo -e "${GREEN}Android emulator detected${NC}"
            return 0
        fi
    fi
    return 1
}

# Function to start Android emulator with 2GB memory
start_emulator() {
    echo -e "${YELLOW}Starting Android emulator with 2GB memory...${NC}"
    if command -v emulator &> /dev/null; then
        # Start emulator with memory optimization
        emulator -avd Xubudget_2GB -memory 2048 -vmheap 256 -no-audio -no-boot-anim &
        
        # Wait for emulator to boot
        echo -e "${YELLOW}Waiting for emulator to boot...${NC}"
        timeout 300 adb wait-for-device
        echo -e "${GREEN}Emulator ready!${NC}"
    else
        echo -e "${RED}Android emulator not found. Please install Android Studio.${NC}"
        return 1
    fi
}

# Function to run the app
run_app() {
    echo -e "${YELLOW}Building and running Xubudget app...${NC}"
    
    # Try to get dependencies first
    echo -e "${YELLOW}Getting Flutter dependencies...${NC}"
    flutter pub get || {
        echo -e "${RED}Failed to get dependencies. Continuing anyway...${NC}"
    }
    
    # Try to run the app
    echo -e "${YELLOW}Running app with memory optimization...${NC}"
    flutter run --debug --shrink || {
        echo -e "${RED}Flutter run failed. Trying alternative approach...${NC}"
        return 1
    }
}

# Main execution
echo -e "${YELLOW}Checking for running emulator...${NC}"
if ! check_emulator; then
    echo -e "${YELLOW}No emulator running. Attempting to start one...${NC}"
    start_emulator
fi

echo -e "${YELLOW}Running the app...${NC}"
run_app

echo -e "${GREEN}Done!${NC}"