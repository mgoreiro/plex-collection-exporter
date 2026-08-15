# Plex Collection Exporter

App nativa de macOS (SwiftUI) para conectarse a un servidor Plex, navegar por sus
librerías y exportar colecciones completas (título, año, valoración, géneros,
reparto, director, sinopsis, duración, etc.) a un fichero CSV.

## Requisitos

- macOS 14 (Sonoma) o superior
- Xcode 15+ (o solo las Command Line Tools de Swift, `swift --version` ≥ 5.9)

## Cómo obtener tu X-Plex-Token

1. Abre la web app de Plex (`app.plex.tv`) o `http://TU_SERVIDOR:32400/web`.
2. Reproduce cualquier elemento y pulsa el icono "..." → **Obtener información** →
   **Ver XML** (o **View XML**). En la URL que se abre verás un parámetro
   `X-Plex-Token=xxxxxxxxxxxx`. Ese valor es tu token.
3. Alternativa: en la web de Plex, ve a **Ajustes → Red**, y en el inspector del
   navegador (pestaña Network) busca cualquier petición a tu servidor; el header
   `X-Plex-Token` aparece ahí.

El token se guarda cifrado en el **Keychain de macOS**, no en texto plano.

## Cómo compilar y ejecutar

### Opción A: Xcode (recomendado)

1. Abre Xcode.
2. **File → Open…** y selecciona la carpeta `PlexCollectionExporter` (el fichero
   `Package.swift`). Xcode lo reconoce como un proyecto SwiftUI ejecutable.
3. Selecciona el esquema `PlexCollectionExporter` y el destino "My Mac".
4. Pulsa ▶️ (Cmd+R) para compilar y ejecutar.
5. Si quieres un `.app` distribuible: **Product → Archive**, y desde el
   organizador exporta como app de macOS.

### Opción B: línea de comandos

```bash
cd PlexCollectionExporter
swift run
```

La primera vez tardará un poco en compilar; luego se abrirá la ventana de la app.

## Uso

1. Introduce la URL de tu servidor Plex, por ejemplo `http://192.168.1.10:32400`
   (usa la IP local, no plex.tv, salvo que tengas acceso remoto configurado).
2. Pega tu `X-Plex-Token` y pulsa **Conectar**.
3. En la barra lateral aparecerán tus librerías de tipo película y serie.
4. Al seleccionar una librería, la columna central muestra sus colecciones.
5. Al seleccionar una colección, la columna de la derecha carga cada elemento
   con sus metadatos completos (géneros, reparto, director, guionistas...).
6. Pulsa **Exportar a CSV** y elige dónde guardar el fichero.

## Columnas exportadas

Título, Año, Tipo, Valoración, Clasificación, Estudio, Duración,
Fecha de estreno, Añadido el, Géneros, Directores, Guionistas, Reparto, Sinopsis.

## Notas / limitaciones conocidas

- Solo se listan librerías de tipo `movie` y `show` (no música ni fotos).
- Para colecciones de series, las columnas de reparto/director reflejan los
  metadatos del propio show (Plex no siempre agrega esa info a nivel de serie
  igual que a nivel de película).
- La carga de metadatos completos hace una petición por elemento en paralelo;
  colecciones muy grandes (cientos de elementos) pueden tardar unos segundos.
- No usa sandboxing de App Store, así que no hace falta el permiso especial de
  "Red local" de macOS: al ser una app normal, el acceso a tu IP local funciona
  directamente.
- Este proyecto se ha escrito y revisado cuidadosamente pero no se ha podido
  compilar en este entorno (no hay Xcode/macOS aquí). Si al abrirlo en Xcode
  aparece algún error puntual de sintaxis, dímelo y lo corrijo.

## Estructura del proyecto

```
PlexCollectionExporter/
├── Package.swift
└── Sources/PlexCollectionExporter/
    ├── PlexCollectionExporterApp.swift   # Entry point
    ├── Models/
    │   ├── PlexModels.swift              # Structs Codable de la API de Plex
    │   └── PlexStore.swift               # Estado observable de la app
    ├── Networking/
    │   ├── PlexClient.swift              # Llamadas a la API REST de Plex
    │   └── KeychainHelper.swift          # Guardado seguro del token
    ├── Utilities/
    │   └── CSVExporter.swift             # Generación y guardado del CSV
    └── Views/
        ├── ContentView.swift
        ├── SidebarView.swift
        ├── CollectionListView.swift
        └── CollectionDetailView.swift
```
