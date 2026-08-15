import SwiftUI

struct CollectionDetailView: View {
    @ObservedObject var store: PlexStore

    var body: some View {
        Group {
            if store.selectedCollection == nil {
                emptyState("Selecciona una colección", "rectangle.stack")
            } else if store.isLoadingItems {
                ProgressView("Cargando elementos y metadatos…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.itemsError {
                emptyState(error, "exclamationmark.triangle")
            } else {
                VStack(spacing: 0) {
                    Table(store.items) {
                        TableColumn("Título", value: \.title)
                        TableColumn("Año") { item in
                            Text(item.year.map(String.init) ?? "—")
                        }.width(60)
                        TableColumn("Duración") { item in
                            Text(item.durationFormatted)
                        }.width(80)
                        TableColumn("Valoración") { item in
                            Text(item.rating.map { String(format: "%.1f", $0) } ?? "—")
                        }.width(80)
                        TableColumn("Géneros") { item in
                            Text(item.genresJoined).lineLimit(1)
                        }
                        TableColumn("Reparto") { item in
                            Text(item.actorsJoined).lineLimit(1)
                        }
                    }

                    Divider()

                    HStack {
                        Text("\(store.items.count) elementos")
                            .foregroundStyle(.secondary)

                        if let exportError = store.exportError {
                            Text(exportError).font(.caption).foregroundStyle(.red)
                        } else if let url = store.lastExportedURL {
                            Text("Exportado: \(url.lastPathComponent)")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        Button {
                            store.exportCurrentCollection()
                        } label: {
                            Label("Exportar a CSV", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.items.isEmpty)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(store.selectedCollection?.title ?? "Detalle")
    }

    @ViewBuilder
    private func emptyState(_ text: String, _ icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(.secondary)
            Text(text).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
