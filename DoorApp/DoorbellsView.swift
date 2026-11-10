import SwiftUI
import PhotosUI
import Vision

struct DoorbellsView: View {
    @EnvironmentObject private var doorbells: DoorbellStore
    @State private var showAdd = false
    @State private var editing: Doorbell?

    var body: some View {
        List {
            Section {
                ForEach(doorbells.doorbells) { bell in
                    Button {
                        doorbells.activeID = bell.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bell.name).font(.headline).foregroundStyle(.primary)
                                Text("\(bell.host):\(bell.port)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if bell.id == doorbells.active?.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.mint)
                            }
                            Button { editing = bell } label: { Image(systemName: "pencil") }
                                .buttonStyle(.borderless)
                        }
                    }
                }
                .onDelete { doorbells.remove(at: $0) }
            } footer: {
                if doorbells.doorbells.isEmpty {
                    Text("No doorbells yet. Scan the QR code from your indoor monitor or VDP Connect account screen.")
                }
            }
        }
        .navigationTitle("Doorbells")
        .toolbar {
            Button { showAdd = true } label: { Label("Add", systemImage: "plus") }
        }
        .sheet(isPresented: $showAdd) { AddDoorbellView(existing: nil) }
        .sheet(item: $editing) { AddDoorbellView(existing: $0) }
    }
}

struct AddDoorbellView: View {
    let existing: Doorbell?
    @EnvironmentObject private var doorbells: DoorbellStore
    @Environment(\.dismiss) private var dismiss

    @State private var scanning = false
    @State private var name = ""
    @State private var host = ""
    @State private var port = "5068"
    @State private var username = ""
    @State private var password = ""
    @State private var domain = ""
    @State private var raw = ""
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var note: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { scanning = true } label: {
                        Label("Scan QR code", systemImage: "qrcode.viewfinder")
                    }
                    PhotosPicker(selection: $pickedPhoto, matching: .images) {
                        Label("Choose a screenshot of the QR", systemImage: "photo")
                    }
                    Button { if let s = UIPasteboard.general.string { apply(s) } } label: {
                        Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                    }
                } footer: {
                    if let note { Text(note) }
                }
                Section("Doorbell") {
                    TextField("Name (for example Home)", text: $name)
                    TextField("SIP server", text: $host)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Port", text: $port).keyboardType(.numberPad)
                    TextField("Account", text: $username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Password", text: $password)
                    TextField("Domain (optional)", text: $domain)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
            }
            .navigationTitle(existing == nil ? "Add doorbell" : "Edit doorbell")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(host.isEmpty || username.isEmpty)
                }
            }
            .fullScreenCover(isPresented: $scanning) {
                ZStack(alignment: .topTrailing) {
                    QRScannerView { code in
                        scanning = false
                        apply(code)
                    }
                    .ignoresSafeArea()
                    Button { scanning = false } label: {
                        Image(systemName: "xmark.circle.fill").font(.largeTitle)
                            .foregroundStyle(.white).padding()
                    }
                }
            }
            .onChange(of: pickedPhoto) { _, item in
                guard let item else { return }
                Task { await decode(item) }
            }
            .onAppear {
                guard let e = existing else { return }
                name = e.name; host = e.host; port = String(e.port)
                username = e.username; domain = e.domain; raw = e.rawPayload
                password = KeychainStore.password(for: e.id)
            }
        }
    }

    private func apply(_ text: String) {
        raw = text
        let r = QRParser.parse(text)
        if !r.host.isEmpty { host = r.host }
        port = String(r.port)
        if !r.username.isEmpty { username = r.username }
        if !r.password.isEmpty { password = r.password }
        if !r.domain.isEmpty { domain = r.domain }
        if name.isEmpty { name = r.name.isEmpty ? "Doorbell" : r.name }
        note = (r.host.isEmpty || r.username.isEmpty)
            ? "The code was read, but some fields were not recognised. Please complete them by hand."
            : "Code read. Check the details and save."
    }

    private func decode(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)?.cgImage else { return }
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try? VNImageRequestHandler(cgImage: image).perform([request])
        if let text = request.results?.first?.payloadStringValue {
            apply(text)
        } else {
            note = "No QR code found in that image."
        }
    }

    private func save() {
        var bell = existing ?? Doorbell(name: "", host: "", username: "")
        bell.name = name.isEmpty ? "Doorbell" : name
        bell.host = host
        bell.port = Int(port) ?? 5068
        bell.username = username
        bell.domain = domain
        bell.rawPayload = raw
        if existing == nil { doorbells.add(bell, password: password) }
        else { doorbells.update(bell, password: password) }
        dismiss()
    }
}
