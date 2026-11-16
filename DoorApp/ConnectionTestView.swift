import SwiftUI

/// Shows what the SIP connection is doing, so problems can be found from a screenshot.
struct ConnectionTestView: View {
    @EnvironmentObject private var doorbells: DoorbellStore
    @ObservedObject private var sip = SIPService.shared
    @State private var transport = SIPService.shared.transport
    @State private var template = SIPService.shared.dialTemplate
    @State private var dtmf = "#"
    @State private var dtmfMode = SIPService.shared.dtmfMode
    @State private var manual = ""

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Registration", value: sip.registration)
                LabeledContent("Call", value: sip.callStatus)
                Picker("Transport", selection: $transport) {
                    Text("UDP").tag("udp"); Text("TCP").tag("tcp"); Text("TLS").tag("tls")
                }
                .pickerStyle(.segmented)
                .onChange(of: transport) { _, v in sip.transport = v }
                Button("Register now") {
                    if let bell = doorbells.active { sip.register(bell) }
                }
            }
            Section {
                TextField("Dial template", text: $template)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .onChange(of: template) { _, v in sip.dialTemplate = v }
                if let bell = doorbells.active {
                    ForEach(bell.stations.filter(\.enabled)) { station in
                        Button("Dial \(station.name): \(sip.target(for: station, bell: bell))") {
                            sip.startLive(station: station, bell: bell)
                        }
                    }
                    HStack {
                        TextField("Dial a number", text: $manual)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button("Dial") { sip.dial(target: manual, bell: bell) }
                    }
                }
                if let bell = doorbells.active, let st = bell.stations.first(where: \.enabled) {
                    Button("Try all number formats for \(st.name)") {
                        Task { await sip.probe(station: st, bell: bell) }
                    }
                }
                Button("Hang up", role: .destructive) { sip.hangUp() }
            } header: {
                Text("Test call")
            } footer: {
                Text("Placeholders: {home} {index} {hex} {user}")
            }
            Section("Unlock test") {
                HStack {
                    TextField("DTMF digits", text: $dtmf)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Send") { sip.sendDTMF(dtmf) }
                }
                Picker("Method", selection: $dtmfMode) {
                    Text("Both").tag("both")
                    Text("SIP INFO").tag("info")
                    Text("RFC2833").tag("rfc2833")
                }
                .pickerStyle(.segmented)
                .onChange(of: dtmfMode) { _, v in sip.dtmfMode = v }
                HStack {
                    ForEach(["#", "*", "1", "0", "00"], id: \.self) { d in
                        Button(d) { dtmf = d; sip.sendDTMF(d) }.buttonStyle(.bordered)
                    }
                }
            }
            Section("Log") {
                Button("Copy log") { UIPasteboard.general.string = sip.log.joined(separator: "\n") }
                Text(sip.log.suffix(60).joined(separator: "\n"))
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Connection test")
    }
}
