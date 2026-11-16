import Foundation
import SwiftUI
#if LINPHONE

/// SIP connection to the doorbell (Linphone SDK). Experimental: the dial format and the
/// unlock command are still being confirmed, so everything is logged for the Connection test screen.
@MainActor
final class SIPService: ObservableObject {
    static let shared = SIPService()

    @Published var registration = "Not started"
    @Published var registered = false
    @Published var callStatus = "Idle"
    @Published var calling = false
    @Published var callActive = false
    @Published var incoming = false
    @Published var log: [String] = []

    private var core: Core?
    private var delegate: CoreDelegateStub?
    private var logDelegate: LoggingServiceDelegateStub?
    private var incomingCall: Call?
    private weak var videoView: UIView?

    var transport: String {
        get { UserDefaults.standard.string(forKey: "sipTransport") ?? "udp" }
        set { UserDefaults.standard.set(newValue, forKey: "sipTransport") }
    }

    var dialTemplate: String {
        get { UserDefaults.standard.string(forKey: "dialTemplate") ?? "{home}" }
        set { UserDefaults.standard.set(newValue, forKey: "dialTemplate") }
    }

    var dtmfMode: String {
        get { UserDefaults.standard.string(forKey: "dtmfMode") ?? "both" }
        set { UserDefaults.standard.set(newValue, forKey: "dtmfMode") }
    }

    func addLog(_ text: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        log.append("\(f.string(from: Date())) \(text)")
        if log.count > 300 { log.removeFirst(100) }
    }

    // MARK: Setup

    private func ensureCore() throws -> Core {
        if let core { return core }
        let ls = LoggingService.Instance
        ls.logLevel = LogLevel.Message
        logDelegate = LoggingServiceDelegateStub(onLogMessageWritten: { [weak self] (_: LoggingService, _: String, _: LogLevel, message: String) in
            let lines = message.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            let sip = lines.filter { $0.hasPrefix("SIP/2.0") || ($0.contains(" SIP/2.0") && !$0.hasPrefix("Via")) }
            guard !sip.isEmpty else { return }
            Task { @MainActor in for l in sip { self?.addLog("SIP: " + String(l.prefix(110))) } }
        })
        ls.addDelegate(delegate: logDelegate!)
        let core = try Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
        // Same ports as the official app: SIP 5068, audio 7200-7299, video 9200-9299
        core.setAudioPortRange(minPort: 7200, maxPort: 7299)
        core.setVideoPortRange(minPort: 9200, maxPort: 9299)
        if let t = core.transports {
            t.udpPort = 5068
            t.tcpPort = 5068
            core.transports = t
        }
        core.videoCaptureEnabled = false
        core.videoDisplayEnabled = true
        core.keepAliveEnabled = true
        // Same as the official app: H.264 on, H.265 off
        for payload in core.videoPayloadTypes { _ = payload.enable(enabled: payload.mimeType == "H264") }
        delegate = CoreDelegateStub(
            onCallStateChanged: { [weak self] (_: Core, call: Call, state: Call.State, message: String) in
                Task { @MainActor in self?.callChanged(call, state, message) }
            },
            onAccountRegistrationStateChanged: { [weak self] (_: Core, _: Account, state: RegistrationState, message: String) in
                Task { @MainActor in self?.registrationChanged(state, message) }
            })
        core.addDelegate(delegate: delegate!)
        self.core = core
        attachVideo()
        addLog("Linphone core created")
        return core
    }

    func register(_ bell: Doorbell) {
        let password = KeychainStore.password(for: bell.id)
        do {
            let core = try ensureCore()
            core.clearAccounts()
            core.clearAllAuthInfo()
            let factory = Factory.Instance
            let params = try core.createAccountParams()
            let host = bell.domain.isEmpty ? bell.host : bell.domain
            try params.setIdentityaddress(newValue: try factory.createAddress(addr: "sip:\(bell.username)@\(host)"))
            try params.setServeraddress(newValue: try factory.createAddress(
                addr: "sip:\(bell.host):\(bell.port);transport=\(transport)"))
            params.registerEnabled = true
            core.addAuthInfo(info: try factory.createAuthInfo(
                username: bell.username, userid: "", passwd: password, ha1: "", realm: "", domain: ""))
            let account = try core.createAccount(params: params)
            try core.addAccount(account: account)
            core.defaultAccount = account
            if core.globalState != GlobalState.On { try core.start() }
            registration = "Registering"
            addLog("Registering \(bell.username)@\(host) via \(transport.uppercased()) port \(bell.port)")
        } catch {
            registration = "Error"
            addLog("Register error: \(error)")
        }
    }

    private func registrationChanged(_ state: RegistrationState, _ message: String) {
        switch state {
        case .Ok: registration = "Registered"; registered = true
        case .Progress: registration = "Registering"; registered = false
        case .Failed: registration = "Failed: \(message)"; registered = false
        case .Cleared, .None: registration = "Not registered"; registered = false
        default: registration = "\(state)"
        }
        addLog("Registration \(state): \(message)")
    }

    // MARK: Calls

    func target(for station: DoorbellStation, bell: Doorbell) -> String {
        dialTemplate
            .replacingOccurrences(of: "{home}", with: bell.homeID)
            .replacingOccurrences(of: "{index}", with: String(station.index))
            .replacingOccurrences(of: "{hex}", with: station.code.replacingOccurrences(of: "0x", with: ""))
            .replacingOccurrences(of: "{user}", with: bell.username)
    }

    func startLive(station: DoorbellStation, bell: Doorbell) {
        dial(target: target(for: station, bell: bell), bell: bell)
    }

    func dial(target: String, bell: Doorbell) {
        guard let core else { addLog("Not started yet"); return }
        do {
            let host = bell.domain.isEmpty ? bell.host : bell.domain
            let address = try Factory.Instance.createAddress(addr: "sip:\(target)@\(host)")
            let params = try core.createCallParams(call: nil)
            params.videoEnabled = true
            params.videoDirection = MediaDirection.RecvOnly
            params.audioDirection = MediaDirection.RecvOnly
            addLog("INVITE sip:\(target)@\(host)")
            calling = true
            if core.inviteAddressWithParams(addr: address, params: params) == nil {
                calling = false
                addLog("INVITE could not start")
            }
        } catch {
            calling = false
            addLog("Dial error: \(error)")
        }
    }


    /// Tries several number formats for one station, a few seconds each, and logs what the server says.
    func probe(station: DoorbellStation, bell: Doorbell) async {
        let i = station.index
        let h = station.code.replacingOccurrences(of: "0x", with: "")
        let pad = String(format: "%02d", i)
        let dec = Int(h, radix: 16).map(String.init) ?? h
        let candidates = [h, String(i), dec, "0099" + "0000" + pad, "00990000" + pad,
                          bell.homeID + String(i), bell.homeID + h, String(bell.homeID.prefix(10)) + pad, "DS\(i)"]
        addLog("Probe: trying \(candidates.count) formats for \(station.name)")
        for target in candidates {
            hangUp()
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            dial(target: target, bell: bell)
            for _ in 0..<12 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if callActive { addLog("Probe: \(target) CONNECTED. Use this format."); return }
            }
            addLog("Probe: \(target) no luck")
        }
        hangUp()
        addLog("Probe: finished, nothing connected")
    }

    func hangUp() {
        guard let core else { return }
        try? core.currentCall?.terminate()
        calling = false
    }

    func answer() {
        try? incomingCall?.accept()
        incoming = false
    }

    func decline() {
        try? incomingCall?.decline(reason: Reason.Declined)
        incoming = false
    }

    func sendDTMF(_ digits: String) {
        guard let core, let call = core.currentCall else { addLog("No active call for DTMF"); return }
        core.useInfoForDtmf = (dtmfMode != "rfc2833")
        core.useRfc2833ForDtmf = (dtmfMode != "info")
        do {
            try call.sendDtmfs(dtmfs: digits)
            addLog("DTMF sent: \(digits)")
        } catch {
            addLog("DTMF error: \(error)")
        }
    }

    private func callChanged(_ call: Call, _ state: Call.State, _ message: String) {
        addLog("Call \(state): \(message)")
        if state == .Error || state == .End, let info = call.errorInfo, info.protocolCode != 0 {
            addLog("Reason: \(info.protocolCode) \(info.phrase ?? "")")
        }
        switch state {
        case .IncomingReceived:
            incomingCall = call
            incoming = true
            callStatus = "Incoming"
            NotificationManager.shared.postRing(station: "Door")
        case .OutgoingInit, .OutgoingProgress, .OutgoingRinging:
            calling = true
            callStatus = "Calling"
        case .OutgoingEarlyMedia, .Connected, .StreamsRunning:
            calling = false
            callActive = true
            incoming = false
            callStatus = "Live"
        case .End, .Error, .Released:
            calling = false
            callActive = false
            incoming = false
            callStatus = state == .Error ? "Error: \(message)" : "Idle"
        default:
            break
        }
    }

    // MARK: Video

    func setVideoView(_ view: UIView) {
        videoView = view
        attachVideo()
    }

    private func attachVideo() {
        guard let core, let view = videoView else { return }
        core.nativeVideoWindowId = UnsafeMutableRawPointer(Unmanaged.passUnretained(view).toOpaque())
    }
}

struct SIPVideoView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        SIPService.shared.setVideoView(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#else
/// Stub used when this build was made without the Linphone SDK.
@MainActor
final class SIPService: ObservableObject {
    static let shared = SIPService()
    @Published var registration = "SIP library not included in this build"
    @Published var registered = false
    @Published var callStatus = "Unavailable"
    @Published var calling = false
    @Published var callActive = false
    @Published var incoming = false
    @Published var log: [String] = ["SIP library not included in this build"]
    var transport: String {
        get { UserDefaults.standard.string(forKey: "sipTransport") ?? "udp" }
        set { UserDefaults.standard.set(newValue, forKey: "sipTransport") }
    }
    var dialTemplate: String {
        get { UserDefaults.standard.string(forKey: "dialTemplate") ?? "{home}" }
        set { UserDefaults.standard.set(newValue, forKey: "dialTemplate") }
    }
    var dtmfMode: String {
        get { UserDefaults.standard.string(forKey: "dtmfMode") ?? "both" }
        set { UserDefaults.standard.set(newValue, forKey: "dtmfMode") }
    }

    func addLog(_ text: String) { log.append(text) }
    func register(_ bell: Doorbell) { addLog("SIP library not included in this build") }
    func target(for station: DoorbellStation, bell: Doorbell) -> String { "" }
    func startLive(station: DoorbellStation, bell: Doorbell) { addLog("SIP library not included in this build") }
    func dial(target: String, bell: Doorbell) { addLog("SIP library not included in this build") }
    func probe(station: DoorbellStation, bell: Doorbell) async {}
    func hangUp() {}
    func answer() {}
    func decline() {}
    func sendDTMF(_ digits: String) {}
    func setVideoView(_ view: UIView) {}
}

struct SIPVideoView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif
