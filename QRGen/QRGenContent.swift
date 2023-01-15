//
//  QRGenContent.swift
//  QRGen
//
//  Created by Max-Joseph on 15.01.23.
//

import Foundation

struct QRGenContent {
	enum WifiEncryption: String, ArgumentEnum {
		case wep
		case wpa
		//case wpa2eap(eapMethod: String?, anonymousIdentity: String?, identity: String?, phase2Method: String?)
	}
	static func wifi(ssid: String, password: String?, encryption: WifiEncryption?, hidden: Bool = false) {
		var content = "WIFI:"
		func addParameter(_ parameter: String, value: String) {
			var escapedValue = value
			for special in ["\\", ";", ",", "\"", ":"] {
				escapedValue = escapedValue.replacingOccurrences(of: special, with: "\\"+special)
			}
			content += "\(parameter):\(escapedValue);"
		}
		
		addParameter("S", value: ssid)
		switch (encryption, password) {
				
			case (.wep, .some(let password)):
				addParameter("T", value: "WEP")
				addParameter("P", value: password)
			case (.wpa, .some(let password)):
				addParameter("T", value: "WPA")
				addParameter("P", value: password)
//			case (.wpa2eap(let eapMethod, let anonymousIdentity, let identity, let phase2Method), let password):
//				addParameter("T", value: "WPA2-EAP")
//				for (parameter, value) in [("P", password), ("E", eapMethod), ("A", anonymousIdentity), ("I", identity), ("PH2", value: phase2Method)] {
//					guard let value else { continue }
//					addParameter(parameter, value: value)
//				}
			case (.none, _): fallthrough
			case (_, .none):
				//addParameter("T", value: "nopass")
				break
		}
		if hidden {
			addParameter("H", value: "true")
		}
		content += ";"
		
		stdout(content, terminator: "")
	}
}
