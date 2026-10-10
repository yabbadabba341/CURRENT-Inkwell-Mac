# INGENIUM  |  Copyright (c) 2026 Yannie D. Forest. All rights reserved.
# NO LICENCE IS GRANTED. No copying, adaptation, redistribution, reverse
# engineering or commercial use without the author's written permission.
# See LICENCE.txt. Every distributed copy carries a build marker.
# -*- mode: python ; coding: utf-8 -*-
#
# Ingenium — standalone macOS app.
#
#   Built by "Build Mac App.command". You do not run this file yourself.
#
# Uses only PyInstaller arguments that exist in both 5 and 6: PyInstaller 6.0
# removed `cipher`, `win_no_prefer_redirects`, `win_private_assemblies` and the
# zipped_data/zipfiles arguments, and `pip install pyinstaller` installs 6.

import json
import os
import re
import sys

from PyInstaller.utils.hooks import collect_all

# R65: who the app is comes from app.json (Ingenium's builder writes a new one
# for each new app): the name under the icon, the bundle id, the file names.
try:
    with open(os.path.join(SPECPATH, 'app.json'), encoding='utf-8') as _fh:
        _cfg = json.load(_fh)
except Exception:
    _cfg = {}
APP_NAME = re.sub(r'\s+', ' ', re.sub(r'[^A-Za-z0-9 ._-]', '', str(_cfg.get('name') or ''))).strip() or 'Ingenium'
APP_FILE = re.sub(r'[^A-Za-z0-9._-]', '', str(_cfg.get('file_name') or '')) or 'Ingenium'
APP_ID = str(_cfg.get('app_id') or 'com.yannieforest.ingenium')
if not re.match(r'^[A-Za-z][A-Za-z0-9]*(\.[A-Za-z][A-Za-z0-9]*)+$', APP_ID):
    raise SystemExit('app.json: app_id %r is not a valid id (letters and digits, dots between)' % APP_ID)
APP_VERSION = os.environ.get('INGENIUM_VERSION', '3.2')
_own = [('ingenium.html', '.')]
# R75: the seal is the icon when it is there; a build without it still
# finishes, with the plain icon
for _f in ('ingenium.icns', 'ingenium.png'):
    if os.path.isfile(os.path.join(SPECPATH, _f)):
        _own.append((_f, '.'))
ICON = 'ingenium.icns' if os.path.isfile(os.path.join(SPECPATH, 'ingenium.icns')) else None
for _f in ('app.json', 'THIRD_PARTY_NOTICES.txt', 'LICENCE.txt'):
    if os.path.isfile(os.path.join(SPECPATH, _f)):
        _own.append((_f, '.'))

extra_datas = []
extra_binaries = []
extra_hidden = []

# pywebview loads its own JavaScript from disk while a window opens, so those
# files must travel inside the bundle. collect_all takes a package's modules,
# data and binaries together, and a package that is absent is simply skipped.
# certifi travels too: its cacert.pem is a DATA file (hidden imports alone do
# not bring it), and the relay verifies https calls against it.
for _pkg in ('webview', 'proxy_tools', 'objc', 'Foundation', 'WebKit', 'certifi'):
    try:
        _d, _b, _h = collect_all(_pkg)
        extra_datas += _d
        extra_binaries += _b
        extra_hidden += _h
    except Exception as _e:
        print('ingenium: nothing collected for %s (%s)' % (_pkg, _e))

a = Analysis(
    ['ingenium_app.py'],
    pathex=[],
    binaries=extra_binaries,
    # the app itself travels inside the bundle
    datas=extra_datas + _own,
    # Named outright because PyInstaller cannot see them: pywebview chooses its
    # backend while running, so nothing in the source imports these by name.
    # Left out, the app builds cleanly and then cannot draw a window. Any that
    # are not installed are merely reported, which does not stop the build.
    hiddenimports=[
        'webview.platforms.cocoa',
        'objc',
        'Foundation',
        'AppKit',
        'WebKit',
        # R53/R57: the relay and the loopback server need this whole chain.
        # R57 also imports them statically at the top of ingenium_app.py, but
        # naming them here is belt and braces: with noarchive=True these land
        # as loose files on sys.path, where any import finds them.
        'urllib.request',
        'urllib.error',
        'urllib.parse',
        'http.client',
        'http.server',
        'socketserver',
        'ssl',
        '_ssl',
        'certifi',
        'email',
        'email.message',
        'email.parser',
        'email.feedparser',
        'email.header',
        'email.charset',
        'email.utils',
        'quopri',
        'uu',
        'mimetypes',
        'socket',
        'selectors',
        'tempfile',
        'json',
        'pathlib',
        'datetime',
        'shutil',
        'subprocess',
        'threading',
        'functools',
        'base64',
        'hmac',
        'hashlib',
    ] + extra_hidden,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=True,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name=APP_FILE,
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=True,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=ICON,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name=APP_FILE,
)

if sys.platform == 'darwin':
    app = BUNDLE(
        coll,
        name=APP_FILE + '.app',
        icon=ICON,
        bundle_identifier=APP_ID,
        info_plist={
            'CFBundleName': APP_NAME,
            'CFBundleDisplayName': APP_NAME,
            'CFBundleShortVersionString': APP_VERSION,
            'CFBundleVersion': APP_VERSION,
            'NSHighResolutionCapable': True,
            'LSMinimumSystemVersion': '11.0',
            # R74: the one permission Ingenium can ask for. macOS 15 asks before
            # an app reaches other devices on the home network; this is what it
            # shows. Ingenium does so only to use, or lend, models between the
            # person's own computers, and only after they set that up. It never
            # asks for the microphone, the camera, or anything else.
            'NSLocalNetworkUsageDescription': 'Ingenium uses the home network only to lend models to your other devices, or to use the models of your other computer, when you set that up in Settings.',
        },
    )
