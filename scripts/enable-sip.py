"""Writes project-sip.yml: project.yml plus the Linphone frameworks and Swift wrapper
that fetch-linphone.sh put under Vendor/. Usage: enable-sip.py"""
import os, re
s = open("project.yml").read()
fw = sorted(d for d in os.listdir("Vendor/XCFrameworks") if d.endswith(".xcframework") and "tester" not in d)
deps = "".join(f"      - framework: Vendor/XCFrameworks/{d}\n        embed: true\n" for d in fw)
s = s.replace("      - target: DoorWatch\n", "      - target: DoorWatch\n" + deps, 1)
s = s.replace("      - Shared/Intents\n", "      - Shared/Intents\n      - Vendor/LinphoneWrapper.swift\n", 1)
s = s.replace("        TARGETED_DEVICE_FAMILY: \"1,2\"\n", "        TARGETED_DEVICE_FAMILY: \"1,2\"\n        SWIFT_ACTIVE_COMPILATION_CONDITIONS: \"$(inherited) LINPHONE\"\n", 1)
open("project-sip.yml", "w").write(s)
print("frameworks:", len(fw))
