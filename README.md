# Door (working title)

Custom iOS, iPad, Widgets and Apple Watch client for a SIP video doorbell. Design: "Porcelain Orb". Currently runs on **mock data**. `MockDoorService` in `Shared/Core/DoorStore.swift` is the seam where a real SIP service plugs in.

## Unsigned IPA on GitHub, signed on Windows

1. Public repo, upload this folder (keep `.github`). No secrets are used.
2. Actions, "Build unsigned IPA", Run workflow. Enter a bundle id that fits your profile (the log of the build contains no personal data).
3. Download the `DoorApp-ipa` artifact. Sign it on Windows with zsign, using your p12, its password and the mobileprovision. zsign signs the widgets and Watch app inside the IPA too:
   `zsign -k cert.p12 -p PASSWORD -m profile.mobileprovision -o signed.ipa DoorApp.ipa`
4. Install signed.ipa on the iPhone (the Watch app follows from the iPhone's Watch app).

A wildcard profile is needed so the app, widgets and Watch can share one profile. Check the profile's `application-identifier` in a text editor.

## Build on a Mac instead

`brew install xcodegen && xcodegen generate`, open `DoorApp.xcodeproj`, set your team under Signing, Run.

## Known open items

- Real SIP calling (Linphone SDK or PJSIP), unlock command (SIP INFO or DTMF, unverified), live video.
- Ringing while the app is closed needs a VoIP push source.
- Decode the QR from the indoor monitor to confirm SIP server and unlock details (redact the password).
