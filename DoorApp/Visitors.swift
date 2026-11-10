import SwiftUI

struct VisitorsSection: View {
    @EnvironmentObject private var store: DoorStore
    var limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Visitors")
                .font(.title3.bold())
                .padding(.horizontal, 4)
            ForEach(store.visitors.prefix(limit)) { visitor in
                VisitorRow(visitor: visitor)
            }
        }
    }
}

struct VisitorRow: View {
    let visitor: Visitor

    var body: some View {
        HStack(spacing: 12) {
            // Placeholder for the saved snapshot of the visitor.
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.769, green: 0.800, blue: 0.910), Color(red: 0.529, green: 0.576, blue: 0.761)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.95)))
            VStack(alignment: .leading, spacing: 2) {
                Text(visitor.event.title).font(.subheadline.weight(.semibold))
                Text(visitor.date, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(visitor.event.badge)
                .font(.caption.weight(.bold))
                .foregroundStyle(visitor.event.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(visitor.event.tint.opacity(0.16), in: Capsule())
        }
        .padding(8)
        .glassCard(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: DoorStore
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", opened = "Opened", missed = "Missed"
        var id: String { rawValue }
    }

    private var filtered: [Visitor] {
        switch filter {
        case .all: return store.visitors
        case .opened: return store.visitors.filter { $0.event == .opened }
        case .missed: return store.visitors.filter { $0.event == .missed }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 6)
                    ForEach(filtered) { VisitorRow(visitor: $0) }
                }
                .padding(16)
            }
            .background(AppBackground())
            .navigationTitle("History")
        }
    }
}
