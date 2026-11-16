"""Writes project-sip.yml: project.yml plus the Linphone package. Usage: enable-sip.py VERSION"""
import sys
v = sys.argv[1]
s = open("project.yml").read()
s = s.replace("\ntargets:\n", f"""
packages:
  linphonesw:
    url: https://gitlab.linphone.org/BC/public/linphone-sdk-swift-ios.git
    exactVersion: {v}

targets:
""", 1)
s = s.replace("      - target: DoorWatch\n", "      - target: DoorWatch\n      - package: linphonesw\n", 1)
open("project-sip.yml", "w").write(s)
