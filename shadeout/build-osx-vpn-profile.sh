#!/bin/bash

# This doesn't do EAP-TLS yet.

VPN_NAME="<Friendly name to appear in VPN list>"
VPN_ENDPOINT="<hostname>"
CA_CERTIFICATE="<ca certificate path"
CERTIFICATE_FILE="<device certificate path>"

if [ -n "$CA_CERTIFICATE" ]; then
    if [ ! -e "${CA_CERTIFICATE}" ]; then
        echo "CA Certificate ${CA_CERTIFICATE} missing." 1>&2
        exit 1
    fi
fi

mkid() {
	echo "$1"|tr . '\n'|tail -r|tr '\n' '.'|sed -e 's/\.$//'
}

pkcs12() {
	openssl pkcs12 -export -in "$1"
}

# To match what Apple Configurator 2 outputs
base64_indent() {
    base64 -b 52 -i "$1"|sed -e 's/^/			/g'
}

getcn() {
    openssl x509 -in "$1" -subject|sed -n -e '/subject= /s/subject= .*CN=\([^/]*\).*/\1/p'
}

ca_payload() {
    if [ -z "${CA_CERTIFICATE}" ]; then 
        return
    fi
    CA_CERTIFICATE_UUID=$(uuidgen)
cat<<END
		<dict>
			<key>PayloadContent</key>
			<data>
$(base64_indent "${CA_CERTIFICATE}")
			</data>
			<key>PayloadDisplayName</key>
			<string>$(getcn "${CA_CERTIFICATE}") (CA Certificate)</string>
			<key>PayloadIdentifier</key>
			<string>com.apple.security.root.${CA_CERTIFICATE_UUID}</string>
			<key>PayloadType</key>
			<string>com.apple.security.root</string>
			<key>PayloadUUID</key>
			<string>${CA_CERTIFICATE_UUID}</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
		</dict>
END
}

CERTIFICATE_UUID=$(uuidgen|tr A-Z a-z)
LOCAL_IDENTIFIER="$(getcn "${CERTIFICATE_FILE}")"
cat <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
$(ca_payload)
		<dict>
			<key>PayloadContent</key>
			<data>
$(pkcs12 ${CERTIFICATE_FILE} | base64_indent -)
			</data>
			<key>PayloadDisplayName</key>
			<string>$(getcn ${CERTIFICATE_FILE})</string>
			<key>PayloadIdentifier</key>
			<string>com.apple.security.pkcs12.${CERTIFICATE_UUID}</string>
			<key>PayloadType</key>
			<string>com.apple.security.pkcs12</string>
			<key>PayloadUUID</key>
			<string>${CERTIFICATE_UUID}</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
		</dict>
		<dict>
			<key>IKEv2</key>
			<dict>
				<key>AuthenticationMethod</key>
				<string>Certificate</string>
				<key>ChildSecurityAssociationParameters</key>
				<dict>
					<key>DiffieHellmanGroup</key>
					<integer>14</integer>
					<key>EncryptionAlgorithm</key>
					<string>AES-128</string>
					<key>IntegrityAlgorithm</key>
					<string>SHA1-96</string>
				</dict>
				<key>ExtendedAuthEnabled</key>
				<integer>0</integer>
				<key>IKESecurityAssociationParameters</key>
				<dict>
					<key>DiffieHellmanGroup</key>
					<integer>14</integer>
					<key>EncryptionAlgorithm</key>
					<string>AES-128</string>
					<key>IntegrityAlgorithm</key>
					<string>SHA1-96</string>
				</dict>
				<key>LocalIdentifier</key>
				<string>${LOCAL_IDENTIFIER}</string>
				<key>PayloadCertificateUUID</key>
				<string>${CERTIFICATE_UUID}</string>
				<key>RemoteAddress</key>
				<string>${VPN_ENDPOINT}</string>
				<key>RemoteIdentifier</key>
				<string>${VPN_ENDPOINT}</string>
			</dict>
			<key>PayloadDisplayName</key>
			<string>${VPN_ENDPOINT} IKEv2 Config 1</string>
			<key>PayloadIdentifier</key>
			<string>com.apple.vpn.managed.$(uuidgen)</string>
			<key>PayloadType</key>
			<string>com.apple.vpn.managed</string>
			<key>PayloadUUID</key>
			<string>$(uuidgen)</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>UserDefinedName</key>
			<string>${VPN_NAME}</string>
			<key>VPNType</key>
			<string>IKEv2</string>
		</dict>
	</array>
	<key>PayloadDisplayName</key>
	<string>${VPN_ENDPOINT} IKEv2 Profile</string>
	<key>PayloadIdentifier</key>
	<string>$(mkid ${VPN_ENDPOINT})1</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>$(uuidgen)</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
END
