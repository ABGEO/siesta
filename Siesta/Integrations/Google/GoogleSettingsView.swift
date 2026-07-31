import SwiftUI

struct GoogleSettingsView: View {
    @Bindable var integration: GoogleIntegration

    private enum CalendarLoadState {
        case idle
        case loading
        case loaded([GoogleCalendarClient.CalendarListEntry])
        case failed(String)
    }

    @State private var loadState: CalendarLoadState = .idle

    var body: some View {
        @Bindable var config = integration.googleConfig

        Form {
            Section("Connection") {
                IntegrationConnectionRow(integration: integration)
            }

            Section("Calendar event when away") {
                TextField("Event title", text: $config.eventTitle)
                calendarRow(selection: $config.calendarID)
                Picker("Show me as", selection: $config.showAs) {
                    ForEach(ShowAs.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .disabled(!integration.connectionState.isConnected)
        }
        .formStyle(.grouped)
        .task(id: integration.connectionState) {
            await loadCalendars()
        }
    }

    @ViewBuilder
    private func calendarRow(selection: Binding<String>) -> some View {
        switch loadState {
        case .idle, .loading:
            HStack {
                Text("Calendar")
                Spacer()
                if case .loading = loadState {
                    ProgressView().controlSize(.small)
                } else {
                    Picker("", selection: selection) {
                        Text("Primary Calendar").tag("primary")
                    }
                    .labelsHidden()
                    .disabled(true)
                }
            }
        case let .failed(message):
            HStack {
                Text(message)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Retry") { Task { await loadCalendars() } }
            }
        case let .loaded(calendars):
            Picker("Calendar", selection: selection) {
                Text("Primary Calendar").tag("primary")
                ForEach(calendars.filter { !($0.primary ?? false) }, id: \.id) { calendar in
                    Text(calendar.summary).tag(calendar.id)
                }
            }
        }
    }

    private func loadCalendars() async {
        guard integration.connectionState.isConnected else {
            loadState = .idle
            return
        }

        loadState = .loading
        do {
            let calendars = try await integration.fetchWritableCalendars()
            loadState = .loaded(calendars)
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
