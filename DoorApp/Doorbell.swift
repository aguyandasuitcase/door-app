import SwiftUI
import Security

/// One saved video doorbell (SIP account). The password lives in the Keychain.
struct Doorbell: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var host: String
    var port: Int = 5068
    var username: String
    var domain: String = ""
    var homeID: String = ""
    var callCode: String = ""
    var stations: [DoorbellStation] = []
}

struct DoorbellStation: Codable, Hashable, Identifiable {
    var id: Int { index }
    var index: Int
    var name: String
    var code: String
}

enum KeychainStore {
    static func setPassword(_ password: String, for id: UUID, slot: String = "main") {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "door.sip",
            kSecAttrAccount as String: id.uuidString + "." + slot
        ]
        SecItemDelete(base as CFDictionary)
        guard !password.isEmpty else { return }
        var item = base
        item[kSecValueData as String] = Data(password.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }

    static func password(for id: UUID, slot: String = "main") -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "door.sip",
            kSecAttrAccount as String: id.uuidString + "." + slot,
            kSecReturnData as String: true
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
}

@MainActor
final class DoorbellStore: ObservableObject {
    @Published private(set) var doorbells: [Doorbell] = []
    @Published var activeID: UUID? {
        didSet { UserDefaults.standard.set(activeID?.uuidString, forKey: "activeDoorbell") }
    }

    private let key = "doorbells"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([Doorbell].self, from: data) {
            doorbells = list
        }
        if let s = UserDefaults.standard.string(forKey: "activeDoorbell") {
            activeID = UUID(uuidString: s)
        }
        if activeID == nil { activeID = doorbells.first?.id }
    }

    var active: Doorbell? { doorbells.first { $0.id == activeID } ?? doorbells.first }

    func add(_ doorbell: Doorbell, password: String, password2: String = "") {
        doorbells.append(doorbell)
        KeychainStore.setPassword(password, for: doorbell.id)
        KeychainStore.setPassword(password2, for: doorbell.id, slot: "second")
        if activeID == nil { activeID = doorbell.id }
        save()
    }

    func update(_ doorbell: Doorbell, password: String, password2: String = "") {
        guard let i = doorbells.firstIndex(where: { $0.id == doorbell.id }) else { return }
        doorbells[i] = doorbell
        KeychainStore.setPassword(password, for: doorbell.id)
        KeychainStore.setPassword(password2, for: doorbell.id, slot: "second")
        save()
    }

    func remove(at offsets: IndexSet) {
        for i in offsets {
            KeychainStore.setPassword("", for: doorbells[i].id)
            KeychainStore.setPassword("", for: doorbells[i].id, slot: "second")
        }
        doorbells.remove(atOffsets: offsets)
        if !doorbells.contains(where: { $0.id == activeID }) { activeID = doorbells.first?.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(doorbells) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

/// Reads a doorbell QR payload. The real VDPConnect format is not confirmed yet,
/// so this accepts JSON, URLs, sip: addresses and key=value text, and falls back
/// to showing the raw text so the form can be completed by hand.
enum QRParser {
    struct Result {
        var host = ""
        var port = 5068
        var username = ""
        var password = ""
        var domain = ""
        var name = ""
        var password2 = ""
        var homeID = ""
        var callCode = ""
        var stations: [DoorbellStation] = []
    }

    /// Format used by the indoor monitor: <USER>..</USER><PSW>..</PSW><DOMAIN>host:port</DOMAIN>
    /// <HOME ID>..</HOME ID><PSW2>..</PSW2><CALL CODE>..</CALL CODE> and a list of
    /// <item>index,name,homeid,type,hexcode</item> door stations.
    private static func parseMonitor(_ text: String) -> Result? {
        guard text.contains("<USER>"), text.contains("<DOMAIN>") else { return nil }
        func tag(_ name: String) -> String {
            guard let a = text.range(of: "<\(name)>"), let b = text.range(of: "</\(name)>", range: a.upperBound..<text.endIndex)
            else { return "" }
            return String(text[a.upperBound..<b.lowerBound])
        }
        var r = Result()
        r.username = tag("USER")
        r.password = tag("PSW")
        r.password2 = tag("PSW2")
        r.homeID = tag("HOME ID")
        r.callCode = tag("CALL CODE")
        let domain = tag("DOMAIN")
        let parts = domain.split(separator: ":", maxSplits: 1).map(String.init)
        r.host = parts.first ?? ""
        if parts.count == 2, let p = Int(parts[1]) { r.port = p }
        var rest = Substring(text)
        while let a = rest.range(of: "<item>"), let b = rest.range(of: "</item>", range: a.upperBound..<rest.endIndex) {
            let f = rest[a.upperBound..<b.lowerBound].split(separator: ",").map(String.init)
            if f.count >= 2, let i = Int(f[0]) {
                r.stations.append(DoorbellStation(index: i, name: f[1], code: f.last ?? ""))
            }
            rest = rest[b.upperBound...]
        }
        return r
    }

    static func parse(_ text: String) -> Result {
        if let r = parseMonitor(text) { return r }
        var fields: [String: String] = [:]
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = trimmed.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for (k, v) in obj { fields[k.lowercased()] = "\(v)" }
        } else if let url = URL(string: trimmed), url.scheme != nil,
                  let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            for item in comps.queryItems ?? [] { fields[item.name.lowercased()] = item.value ?? "" }
            if let h = comps.host { fields["host"] = fields["host"] ?? h }
            if let p = comps.port { fields["port"] = fields["port"] ?? String(p) }
            if let u = comps.user { fields["user"] = fields["user"] ?? u }
            if let pw = comps.password { fields["password"] = fields["password"] ?? pw }
        } else {
            let parts = trimmed.components(separatedBy: CharacterSet(charactersIn: "\n;,&|"))
            for part in parts {
                let kv = part.split(separator: "=", maxSplits: 1).map(String.init)
                let kv2 = kv.count == 2 ? kv : part.split(separator: ":", maxSplits: 1).map(String.init)
                if kv2.count == 2 {
                    fields[kv2[0].trimmingCharacters(in: .whitespaces).lowercased()] =
                        kv2[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }

        func pick(_ keys: [String]) -> String {
            for k in keys { if let v = fields[k], !v.isEmpty { return v } }
            return ""
        }

        var r = Result()
        r.host = pick(["host", "server", "sip", "sipserver", "ip", "address", "proxy"])
        r.port = Int(pick(["port", "sipport"])) ?? 5068
        r.username = pick(["user", "username", "account", "id", "name", "extension"])
        r.password = pick(["password", "pass", "pwd", "secret"])
        r.domain = pick(["domain", "realm"])
        r.name = pick(["label", "title", "alias"])
        return r
    }
}
