#!/usr/bin/env python3
"""Демо SOAP-клиент к demo_sign (stdlib, без зависимостей)."""

from __future__ import annotations

import sys
import urllib.error
import urllib.request


def soap_post(url: str, envelope: str, soap_action: str, timeout: float = 15.0) -> tuple[int, str]:
    req = urllib.request.Request(
        url,
        data=envelope.encode("utf-8"),
        method="POST",
        headers={
            "Content-Type": "text/xml; charset=utf-8",
            "SOAPAction": soap_action,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")


def main() -> None:
    base = (sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8080").rstrip("/")
    soap_url = f"{base}/services/demo_sign"

    health_envelope = """<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:p="http://demo.sign/axis2">
  <soapenv:Body>
    <p:getHealth/>
  </soapenv:Body>
</soapenv:Envelope>"""

    sign_envelope = """<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:p="http://demo.sign/axis2">
  <soapenv:Body>
    <p:signDocument>
      <key_id>demo-key-1</key_id>
      <document>hello world</document>
    </p:signDocument>
  </soapenv:Body>
</soapenv:Envelope>"""

    for label, env, action in (
        ("getHealth", health_envelope, "getHealth"),
        ("signDocument", sign_envelope, "signDocument"),
    ):
        status, body = soap_post(soap_url, env, action)
        print(f"{label} status:", status)
        print(f"{label} body:\n", body)


if __name__ == "__main__":
    main()
