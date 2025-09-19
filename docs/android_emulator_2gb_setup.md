# Android Emulator Setup for 2GB Memory Testing

## Creating Android Virtual Device (AVD) with 2GB RAM

### Using Android Studio:

1. **Open Android Studio**
2. **Go to Tools > AVD Manager**
3. **Click "Create Virtual Device"**
4. **Select Device:**
   - Choose a device with lower resolution for better memory usage
   - Recommended: Pixel 4 or Pixel 5 (smaller screen = less memory)

5. **Select System Image:**
   - Choose latest API level (34 recommended)
   - Select x86_64 architecture for better performance
   - Download if not already available

6. **Configure AVD:**
   - **RAM:** Set to **2048 MB (2GB)**
   - **VM heap:** Set to **256 MB**
   - **Internal Storage:** 8 GB (minimum)
   - **SD Card:** Optional, 2GB max

### Using Command Line:

```bash
# List available system images
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager list

# Create AVD with 2GB RAM
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  -n "Xubudget_2GB" \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_4"

# Configure memory in AVD config file
echo "hw.ramSize=2048" >> ~/.android/avd/Xubudget_2GB.avd/config.ini
echo "vm.heapSize=256" >> ~/.android/avd/Xubudget_2GB.avd/config.ini
```

### Running the Emulator:

```bash
# Start emulator with memory optimization
$ANDROID_HOME/emulator/emulator -avd Xubudget_2GB \
  -memory 2048 \
  -vmheap 256 \
  -partition-size 2048 \
  -no-audio \
  -no-boot-anim
```

### Testing App on 2GB Device:

```bash
# Build debug APK optimized for memory
cd mobile_app
flutter build apk --debug --shrink

# Install and run
flutter install
flutter run -d <device-id>
```

### Memory Optimization Tips:

1. **App Build:**
   - Use `flutter build apk --shrink` to reduce APK size
   - Enable ProGuard/R8 for release builds
   - Limit resource configurations to only needed languages

2. **Runtime Optimization:**
   - Close background apps on emulator
   - Monitor memory usage with `flutter logs` and DevTools
   - Test with different memory pressure scenarios

3. **Emulator Performance:**
   - Enable hardware acceleration (HAXM/WHPX)
   - Use x86_64 system images
   - Disable unnecessary emulator features (animations, audio)

### Memory Monitoring:

```bash
# Monitor app memory usage
adb shell dumpsys meminfo com.example.mobile_app

# Monitor device memory
adb shell cat /proc/meminfo
```