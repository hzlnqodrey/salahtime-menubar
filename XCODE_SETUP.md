# 🛠️ Xcode Project Setup Guide

Step-by-step guide to set up the Salah Time Xcode project. This only needs to be done once.

## Prerequisites

- **Xcode 15+** installed from the Mac App Store
- **macOS 14 (Sonoma)** or later

---

## Step 1: Create the Xcode Project

1. Open **Xcode**
2. Click **File → New → Project** (or press `⇧⌘N`)
3. Select **macOS** tab at the top
4. Choose **App** → click **Next**
5. Fill in:
   - **Product Name**: `SalahTime`
   - **Team**: Personal Team (or None)
   - **Organization Identifier**: `com.salahtime`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: None
   - ☐ **Uncheck** "Include Tests"
6. Click **Next**
7. Navigate to this `prayer-reminder/` directory
8. Click **Create**

> Xcode will create `SalahTime.xcodeproj` and a `SalahTime/` folder with default files.  
> Since our `SalahTime/` folder already exists with all the source code, Xcode will merge them.

---

## Step 2: Clean Up Default Files

In the Xcode Project Navigator (left sidebar):

1. **Delete** `ContentView.swift` (right-click → Delete → Move to Trash)
2. **Replace** the content of `SalahTimeApp.swift` with our version:
   - Open `SalahTimeApp.swift` in the editor
   - Select All (⌘A) → Delete
   - Open our `SalahTime/SalahTimeApp.swift` from Finder
   - Copy the entire content and paste it into Xcode

---

## Step 3: Add Source Files to the Project

Our source files are organized in subdirectories. Add them to the project:

1. Right-click on the **SalahTime** group in Project Navigator
2. Select **Add Files to "SalahTime"...**
3. Navigate to `prayer-reminder/SalahTime/`
4. Select ALL folders: `Models/`, `Services/`, `Theme/`, `Views/`
5. Ensure these options are set:
   - ☑ **Copy items if needed**: **Unchecked** (files are already in place)
   - ☑ **Create groups**: **Selected**
   - ☑ **Add to targets**: **SalahTime** checked
6. Click **Add**

---

## Step 4: Add the adhan-swift Package

1. Click **File → Add Package Dependencies...** (or select the project in Navigator → Package Dependencies tab)
2. In the search bar, paste:
   ```
   https://github.com/batoulapps/adhan-swift
   ```
3. Select the **adhan-swift** package
4. Set **Dependency Rule**: "Up to Next Major Version" from `1.0.0`
5. Click **Add Package**
6. Ensure the **Adhan** library is added to the **SalahTime** target
7. Click **Add Package**

---

## Step 5: Configure Project Settings

### 5a. Set Deployment Target

1. Click on the **SalahTime** project (top of Navigator)
2. Select the **SalahTime** target
3. Go to **General** tab
4. Set **Minimum Deployments → macOS**: `14.0`

### 5b. Hide from Dock (Menubar-Only App)

1. Go to the **Info** tab (in target settings)
2. Click the **+** button to add a new key
3. Add: `Application is agent (UIElement)` → set value to **YES**

> This makes the app a "faceless" agent — it only shows in the menubar, not in the Dock or App Switcher.

### 5c. Location Permission

1. Still in the **Info** tab
2. Add key: `Privacy - Location When In Use Usage Description`
3. Set value: `Salah Time needs your location to calculate accurate prayer times for your area.`

---

## Step 6: Add Adhan Audio (Optional)

If you have a royalty-free Adhan audio file:

1. Rename it to `default_adhan.m4a` (or `.mp3`)
2. Drag it into `SalahTime/Resources/` in the Project Navigator
3. Ensure **Add to target: SalahTime** is checked
4. Click **Add**

> Without this file, the app will work fine — it just won't play Adhan audio until you either add a bundled file or import a custom one via Settings.

---

## Step 7: Build and Run

1. Select the **SalahTime** scheme in the toolbar
2. Ensure the target is **My Mac**
3. Press **⌘R** to build and run

The ☪ icon should appear in your menubar!

---

## Troubleshooting

### "Cannot find 'Adhan' in scope"
→ Make sure the adhan-swift package was added correctly (Step 4). Try: File → Packages → Resolve Package Versions.

### "SalahTimeApp has multiple @main"
→ Delete the auto-generated `SalahTimeApp.swift` that Xcode created and keep only our version. Or replace its contents with ours.

### Location permission not showing
→ Ensure the `Privacy - Location When In Use Usage Description` is set in Info tab (Step 5c).

### App appears in Dock
→ Ensure `Application is agent (UIElement)` is set to YES in Info tab (Step 5b).

### Adhan audio not playing
→ Either add a bundled audio file (Step 6) or import a custom one via Settings → Adhan Audio → Choose File.

---

## Building a Release DMG

```bash
chmod +x scripts/build-dmg.sh
./scripts/build-dmg.sh
```

The `.dmg` will be created in `dist/SalahTime.dmg`.
