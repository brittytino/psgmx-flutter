# 🔐 GitHub Secrets Setup for Android Signing

## Required Secrets

To build signed Android APKs, you need to add these secrets to your GitHub repository:

### 1. **KEYSTORE_BASE64**
The base64-encoded keystore file.

**Value:** Copy the contents from `android/keystore.base64.txt`

### 2. **KEYSTORE_PASSWORD**
**Value:** `psgmx2026`

### 3. **KEY_PASSWORD**
**Value:** `psgmx2026`

### 4. **KEY_ALIAS**
**Value:** `psgmx`

### 5. **SUPABASE_URL** (Already exists)
**Value:** `https://dsucqgrwyimtuhebvmpx.supabase.co`

### 6. **SUPABASE_ANON_KEY** (Already exists)
**Value:** `sb_publishable_0Xf74Qb5kGsF9qvOHL4nAA_m31d69DK`

---

## How to Add Secrets to GitHub

1. Go to your repository: https://github.com/brittytino/psgmx-flutter
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with its name and value

---

## 📱 How to Create a Release

### Option 1: Manual Workflow Trigger
1. Go to **Actions** tab
2. Click **Build and Release** workflow
3. Click **Run workflow** → **Run workflow**
4. Wait for build to complete
5. Download signed APK from the release

### Option 2: Push a Version Tag
```bash
# Update version in pubspec.yaml first (e.g., version: 2.1.0)
git add pubspec.yaml
git commit -m "Bump version to 2.1.0"
git tag -a v2.1.0 -m "Release v2.1.0"
git push origin main
git push origin v2.1.0
```

---

## ✅ After Setup

Once all secrets are added:
- GitHub Actions will automatically sign your APKs
- Users can install directly without any warnings
- APKs will be attached to GitHub releases

---

## 🔒 Security Notes

- **NEVER** commit the keystore file to Git
- **NEVER** commit key.properties to Git
- Keep keystore passwords secure
- The `.gitignore` is already configured to protect these files

---

## 📁 Files Created

- `android/app/upload-keystore.jks` - Your signing keystore (KEEP SAFE!)
- `android/keystore.base64.txt` - Base64 encoded keystore (for GitHub secret)
- `android/key.properties.example` - Template for local builds

**Backup the keystore file!** If you lose it, you can't update the app later.
