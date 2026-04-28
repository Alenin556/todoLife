# Store Publishing Checklist (Google Play / App Store)

This checklist helps you publish **todoLife** legally and safely with respect to user data.

## 1) Required links

- **Privacy Policy URL** (publicly accessible HTTPS)
- **Support / contact email**
- (Recommended) **Terms of Use / EULA URL**

## 2) In-app privacy section (recommended)

Make sure the app has a visible place where users can:

- read Privacy Policy and Terms
- export their data (user-initiated)
- reset/delete all local data
- control optional data sharing (analytics / crash reports / ads), if any

## 3) Google Play (Data safety)

In Play Console → **App content** → **Data safety**:

- Declare which data types are **collected** and which are **shared**
- For each data type, state:
  - purpose(s) (app functionality, analytics, fraud prevention, etc.)
  - whether data is processed **ephemerally** or stored
  - whether collection is **required** or **optional**
- If you don’t collect/share data, declare that clearly.

Also check:

- Permissions are justified (notifications, etc.)
- No unnecessary permissions (contacts, location, storage) without a clear need

## 4) Apple App Store (App Privacy)

In App Store Connect → **App Privacy**:

- Fill “Data Used to Track You” (usually **No** unless you use advertising/tracking SDKs)
- Fill “Data Linked to You” and “Data Not Linked to You”
- Describe purposes and whether data is used for tracking

If tracking is used:

- Implement **App Tracking Transparency (ATT)** prompt and respect user choice

## 5) Third-party SDK inventory

Keep a written list of SDKs and what they do (analytics, crashes, ads, etc.), including links to their privacy policies.

If you add any SDK that sends data off-device:

- update Privacy Policy
- add an in-app consent screen (if required)
- update Play Data safety and Apple App Privacy answers

## 6) Security baseline checklist

- Sensitive user content stored securely on-device (keystore/keychain where applicable)
- No sensitive content in logs (tasks text, notes, financial values)
- Clear “Reset all data” behavior (removes local storage)
- Export is **user-initiated** and never auto-sent

