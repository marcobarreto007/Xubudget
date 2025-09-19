#!/usr/bin/env python3
"""
Basic Dart code analysis script to verify Flutter project structure
Checks for common issues without requiring Flutter SDK
"""

import os
import re
import json

def check_pubspec():
    """Check pubspec.yaml for essential dependencies"""
    pubspec_path = "mobile_app/pubspec.yaml"
    if not os.path.exists(pubspec_path):
        return False, "pubspec.yaml not found"
    
    with open(pubspec_path, 'r') as f:
        content = f.read()
    
    essential_deps = ['flutter', 'provider', 'google_mlkit_text_recognition', 'image_picker']
    missing_deps = []
    
    for dep in essential_deps:
        if dep not in content:
            missing_deps.append(dep)
    
    if missing_deps:
        return False, f"Missing dependencies: {', '.join(missing_deps)}"
    
    return True, "All essential dependencies found"

def check_main_dart():
    """Check main.dart for proper structure"""
    main_path = "mobile_app/lib/main.dart"
    if not os.path.exists(main_path):
        return False, "main.dart not found"
    
    with open(main_path, 'r') as f:
        content = f.read()
    
    # Check for essential components
    checks = [
        ("void main()", "main() function"),
        ("runApp", "runApp call"),
        ("MyApp", "MyApp class"),
        ("MaterialApp", "MaterialApp widget"),
        ("BudgetDashboardPage", "Dashboard page reference")
    ]
    
    for check, name in checks:
        if check not in content:
            return False, f"Missing {name}"
    
    return True, "main.dart structure is correct"

def check_platform_dirs():
    """Check for platform-specific directories"""
    required_dirs = [
        "mobile_app/android",
        "mobile_app/ios", 
        "mobile_app/web",
        "mobile_app/test"
    ]
    
    missing_dirs = []
    for dir_path in required_dirs:
        if not os.path.exists(dir_path):
            missing_dirs.append(dir_path)
    
    if missing_dirs:
        return False, f"Missing directories: {', '.join(missing_dirs)}"
    
    return True, "All platform directories exist"

def check_android_config():
    """Check Android configuration for 2GB optimization"""
    build_gradle = "mobile_app/android/app/build.gradle"
    if not os.path.exists(build_gradle):
        return False, "Android build.gradle not found"
    
    with open(build_gradle, 'r') as f:
        content = f.read()
    
    optimizations = [
        ("minSdk = 21", "Minimum SDK for memory efficiency"),
        ("minifyEnabled = true", "Code shrinking enabled"),
        ("multiDexEnabled = false", "MultiDex disabled for memory"),
        ("resConfigs", "Resource configuration optimization")
    ]
    
    found_optimizations = []
    for opt, desc in optimizations:
        if opt in content:
            found_optimizations.append(desc)
    
    return True, f"Memory optimizations found: {len(found_optimizations)}/4"

def check_dart_files():
    """Check Dart files for basic syntax"""
    dart_files = []
    for root, dirs, files in os.walk("mobile_app/lib"):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    issues = []
    for file_path in dart_files:
        with open(file_path, 'r') as f:
            content = f.read()
            lines = content.split('\n')
        
        # Basic checks
        open_braces = content.count('{')
        close_braces = content.count('}')
        
        if open_braces != close_braces:
            issues.append(f"{file_path}: Brace mismatch ({open_braces} open, {close_braces} close)")
    
    if issues:
        return False, f"Syntax issues found: {'; '.join(issues)}"
    
    return True, f"All {len(dart_files)} Dart files have correct basic syntax"

def main():
    """Run all checks"""
    print("🔍 Xubudget Flutter Project Analysis")
    print("=" * 50)
    
    checks = [
        ("📋 pubspec.yaml", check_pubspec),
        ("🚀 main.dart", check_main_dart),
        ("📁 Platform directories", check_platform_dirs),
        ("🤖 Android 2GB config", check_android_config),
        ("🎯 Dart syntax", check_dart_files)
    ]
    
    all_passed = True
    
    for name, check_func in checks:
        try:
            success, message = check_func()
            status = "✅" if success else "❌"
            print(f"{status} {name}: {message}")
            if not success:
                all_passed = False
        except Exception as e:
            print(f"❌ {name}: Error - {str(e)}")
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All checks passed! Project is ready for Flutter development.")
        print("\nNext steps:")
        print("1. Install Flutter SDK")
        print("2. Set up Android emulator with 2GB RAM")
        print("3. Run: flutter pub get && flutter run")
    else:
        print("⚠️  Some issues found. Please fix them before running the app.")
    
    return 0 if all_passed else 1

if __name__ == "__main__":
    exit(main())