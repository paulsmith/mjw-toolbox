% YubiKey Neo (and Neo-n) / OS X 10.11

This directory contains a collection of things useful for YubiKey setup on OS X.

The configured features, when finished, include:

* [u2f](https://www.google.com/search?q=u2f&oq=u2f&aqs=chrome..69i57j69i60j69i61.401j0j7&sourceid=chrome&es_sm=91&ie=UTF-8)
* PIV/PKCS11 for ssh authentication
* OpenPGP interface for GPG key storage

Prerequisites:

* yubikey-neo-manager [yubico](https://developers.yubico.com/yubikey-neo-manager/)
* yubico-piv-tool (homebrew)
* opensc (homebrew)
* GPG Suite [gpgtools](https://gpgtools.org/)

Notes:

* If you manage to trigger the PIN retry block, you will need to use 
  `gpg --change-pin` and choose the `unblock PIN` option along with 
  the PUK/Admin code you set up when configuring the card.
    * If you try to use the `unblock` option of the `gpg --card-edit` tool
      you will likely meet with failure.

* The gpg-agent (and scdaemon spawned by gpg-agent) won't be able to access the
  YubiKey initially due to Apple's buggy PCSC. First, shutdown gpg-agent
  `killall gpg-agent` and then disable Apple's ifdreader (this forces gpg-agent
  and scdaemon to use the CCID lib instead): `sudo launchctl unload -w
  /System/Library/LaunchDaemons/com.apple.ifdreader.plist`. When you next try a
  GPG command that accesses the YubiKey, like `gpg2 --card-status`, gpg-agent and
  scdaemon will start back up, and should work at this point. [1][1] [2][2]

[1]: http://lifecs.likai.org/2015/02/yubikey-neo-n.html
[2]: https://gpgtools.tenderapp.com/discussions/problems/28634-gpg-agent-stops-working-after-osx-upgrade-to-yosemite#comment_35808149
