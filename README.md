# gPOS - Terminal de Punto de Venta (POS)

Sistema moderno y personalizable de **Punto de Venta (TPV / POS)** desarrollado con **Flutter** y **Riverpod**.

---

##  Características Principales

-  **Terminal TPV Rápido:** Selección por categorías, buscador instantáneo por nombre/SKU y cuadrícula interactiva.
-  **Ventas Personalizadas:** Modificación de precios al vuelo, especificaciones y notas personalizadas por producto.
-  **Cobro Multidivisa y Métodos:** Efectivo (con desglose y cálculo de cambio), tarjeta de crédito y Bizum/transferencia.
-  **Arqueo y Registro de Ventas:** Resumen de ingresos diarios, recuento de tickets e historial de transacciones.
-  **Control de Inventario:** Gestión de existencias, ajuste rápido de stock y alta de nuevos productos.
-  **Soporte Multiplataforma & Modo Oscuro:** Optimizado para Android, iOS, Windows y Web con interfaz adaptable (Móvil / Tablet / Desktop).

---

##  Arquitectura del Proyecto

El proyecto sigue el patrón **Feature-First + Clean Architecture**:

```
lib/
├── main.dart                                # Punto de entrada principal
└── src/
    ├── core/
    │   ├── router/                          # GoRouter
    │   ├── theme/                           # AppTheme, Paleta de colores POS
    │   └── utils/                           # Formateadores de moneda y fecha
    └── features/
        ├── home/                            # Navegación principal (Shell/Rail)
        └── pos/
            ├── data/                        # Mock data y repositorios
            ├── domain/models/               # Product, Category, CartItem, Sale
            └── presentation/
                ├── controllers/             # Notifiers & Providers de Riverpod
                ├── screens/                 # TPV, Historial, Inventario, Ajustes
                └── widgets/                 # ProductCard, CartSheet, PaymentModal...
```

---

##  Requisitos y Ejecución

### 1. Requisitos
- **Flutter SDK** (versión `>= 3.19.0`)
- **Dart SDK** (versión `>= 3.0.0`)

> Si aún no tienes Flutter instalado en tu equipo, puedes instalarlo rápidamente mediante `winget`:
> ```powershell
> winget install Google.Flutter
> ```
> O descargándolo desde [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile).

### 2. Obtener dependencias
```bash
flutter pub get
```

### 3. Ejecutar la aplicación
- **En Android / iOS (Emulador o dispositivo físico):**
  ```bash
  flutter run
  ```
- **En Windows Desktop:**
  ```bash
  flutter run -d windows
  ```
- **En Web (Chrome):**
  ```bash
  flutter run -d chrome
  ```

---

## 🛠️ Tecnologías Utilizadas

- **[Flutter](https://flutter.dev/)**
- **[Flutter Riverpod](https://riverpod.dev/)** - Gestión de estado reactiva
- **[GoRouter](https://pub.dev/packages/go_router)** - Enrutamiento declarativo
- **[Google Fonts](https://pub.dev/packages/google_fonts)** - Tipografía Inter
- **[Intl](https://pub.dev/packages/intl)** - Internacionalización y formatos de moneda (€)
