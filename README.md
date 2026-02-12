# SOKA

Aplicacion Flutter para descubrir, crear y gestionar eventos. Integra Firebase (Auth, Realtime Database) y una capa de servicios para CRUD de clientes, empresas, eventos y tickets vendidos.

**Resumen rapido**
- App Flutter multiplataforma (Android, iOS, Web, Desktop).
- Firebase Core + Auth + Realtime Database.
- Provider para estado global y cache local.
- Pantallas para login/registro, home, calendario, detalle de evento, gestion de eventos de empresa y notificaciones.
- Validacion de ubicacion con Geoapify Autocomplete al crear/editar eventos y guardado de coordenadas.
- Apertura de Google Maps en el detalle del evento.

**Stack**
- Flutter SDK 3.x
- Firebase: `firebase_core`, `firebase_auth`, `firebase_database`, `cloud_firestore` (listado en `pubspec.yaml`)
- Estado: `provider`
- Calendario: `table_calendar`
- Enlaces externos: `url_launcher`
- HTTP: `http`

**Estructura del proyecto**
- `lib/` codigo fuente principal.
- `lib/main.dart` punto de entrada y rutas.
- `lib/models/` modelos de dominio (cliente, empresa, evento, tickets, etc.).
- `lib/screens/` pantallas de UI.
- `lib/services/` servicios de datos y autenticacion.
- `lib/theme/` tema y colores.
- `lib/widgets/` componentes reutilizables.
- `lib/assets/` imagenes y recursos.
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` plataformas.
- `firebase.json`, `google-services.json`, `lib/firebase_options.dart` configuracion Firebase.
- `lib/json/soka_plantilla_realtime_databases.json` plantilla de estructura para Realtime Database.

**Pantallas principales (`lib/screens/`)**
- `home_screen.dart` home con listado, filtro y busqueda de eventos.
- `event_details_screen.dart` detalle del evento y CTA de compra.
- `event_editor_screen.dart` crear/editar evento (empresa).
- `company_events_screen.dart` gestion de eventos propios.
- `calendar_screen.dart` calendario de eventos.
- `favorites_history_screen.dart` historial y favoritos.
- `notifications_screen.dart` proximos eventos.
- `login_screen.dart`, `signup_screen.dart` autenticacion.
- `settings_screen.dart`, `account_settings_screen.dart` ajustes.

**Modelos (`lib/models/`)**
- `client.dart` datos del usuario cliente.
- `company.dart` datos de empresa organizadora.
- `event.dart` entidad de evento.
- `ticket_type.dart` tipo de entrada y cupo.
- `sold_tickets.dart` entradas vendidas.
- `contact_info.dart`, `super_admin.dart` modelos auxiliares.
- `models.dart` export central.

**Servicios (`lib/services/`)**
- `soka_service.dart` acceso a Firebase Realtime Database, CRUD de clientes/empresas/eventos/tickets y cache local.
- `auth_service.dart` autenticacion con Google Sign-In.
- `auth_gate.dart` flujo de entrada segun estado de auth.
- `geoapify_service.dart` validacion de ubicacion con Geoapify Autocomplete y parseo de coordenadas/direccion.
- `services.dart` export central.

**Ubicacion de eventos**
- En detalle de evento (`event_details_screen.dart`), el campo “Lugar” abre Google Maps con la direccion guardada.
- En crear/editar (`event_editor_screen.dart`), se valida la direccion con Geoapify antes de guardar y se persisten campos extra (lat/lng, ciudad, etc.).
- Configura el token con `--dart-define=GEOAPIFY_API_KEY=TU_TOKEN` o similar en tu build.

**Flujo de datos**
- `SokaService` se instancia en `main.dart` dentro de `MultiProvider`.
- Cada fetch actualiza listas locales y notifica UI con `notifyListeners()`.
- Los eventos se guardan en `/events` en Realtime Database.
- Clientes en `/users/clients`, empresas en `/users/companies`.

**Firebase**
- Inicializacion en `lib/main.dart` con `DefaultFirebaseOptions`.
- Configuracion generada en `lib/firebase_options.dart`.
- Archivo de configuracion Android: `google-services.json`.

**Como ejecutar**
1. Instala dependencias:

```bash
flutter pub get
```

2. Ejecuta en un dispositivo/emulador:

```bash
flutter run
```

**Configurar Cloudinary (subida de imagenes de eventos)**
- Crea un `upload preset` unsigned en Cloudinary.
- Ejecuta la app pasando estas variables:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=tu_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=tu_unsigned_preset
```

- La subida se hace en la carpeta `events/<organizerId>/<eventId_o_timestamp>`.

**Notas importantes**
- Nominatim tiene limites de uso; la validacion se hace al guardar (no en cada pulsacion).
- La compra de entradas esta marcada como “proximamente”.
- Hay un archivo de plantilla para la BD en `lib/json/soka_plantilla_realtime_databases.json`.

**Assets**
- `lib/assets/SOKA.png`
- `lib/assets/SOKA.gif`
- `lib/assets/iconfinder-new-google-favicon-682665.png`
