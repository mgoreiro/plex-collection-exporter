import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: PlexStore

    var body: some View {
        List(selection: Binding<PlexLibrary?>(
            get: { store.selectedLibrary },
            set: { newValue in
                if let library = newValue {
                    Task { await store.selectLibrary(library) }
                }
            }
        )) {
            Section("Conexión") {
                if store.isConnected {
                    Label {
                        Text(store.serverURL).lineLimit(1).truncationMode(.middle)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                    Button("Desconectar", role: .destructive) {
                        store.disconnect()
                    }
                } else {
                    TextField("http://192.168.1.10:32400", text: $store.serverURL)
                        .textFieldStyle(.roundedBorder)
                    SecureField("X-Plex-Token", text: $store.token)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await store.connect() }
                    } label: {
                        HStack {
                            if store.isConnecting {
                                ProgressView().controlSize(.small)
                            }
                            Text(store.isConnecting ? "Conectando…" : "Conectar")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(store.serverURL.isEmpty || store.token.isEmpty || store.isConnecting)
                    .buttonStyle(.borderedProminent)

                    if let error = store.connectionError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            if store.isConnected {
                Section("Librerías") {
                    if store.libraries.isEmpty {
                        Text("No se encontraron librerías de películas o series.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.libraries) { library in
                            Label(library.title, systemImage: library.type == "movie" ? "film" : "tv")
                                .tag(library)
                        }
                    }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 230, ideal: 270)
    }
}
