# 🧠 Escáner Inteligente con Machine Learning (Flutter + TFLite)

Una aplicación móvil desarrollada en Flutter que utiliza la cámara del dispositivo para clasificar imágenes en tiempo real. Integra un modelo de Machine Learning (MobileNet V1) ejecutado localmente gracias a TensorFlow Lite.

## ✨ Características
* **Inferencia Local:** Clasificación de imágenes rápida y sin necesidad de conexión a internet.
* **Interfaz Adaptativa:** Diseño moderno que soporta rotación de pantalla (Portrait / Landscape).
* **Modo Oscuro/Claro:** Botón integrado para cambiar el tema de la aplicación al instante.
* **Uso de Cámara y Galería:** Permite tomar fotos en el momento o seleccionar imágenes guardadas.

## 🚀 Cómo ejecutar este proyecto

Este repositorio contiene únicamente el "corazón" de la aplicación (código Dart, dependencias y el modelo de IA) para mantenerlo ligero. Sigue estos pasos para probarlo en tu máquina:

### 1. Clonar el repositorio
```bash
git clone [https://github.com/luisFerHerna/Aplicacion_con_Modelo-ML.git](https://github.com/luisFerHerna/Aplicacion_con_Modelo-ML.git)
cd Aplicacion_con_Modelo-ML
```
2. Regenerar las carpetas nativas y descargar dependencias
Como es un repositorio limpio, necesitas que Flutter construya las carpetas de Android/iOS:

```bash
flutter create .
flutter pub get
```
3. Configurar permisos (Android)
Para que la cámara funcione correctamente, debes agregar el permiso en el manifiesto de Android.
Abre el archivo android/app/src/main/AndroidManifest.xml y agrega esta línea justo antes de la etiqueta <application>:

```XML
<uses-permission android:name="android.permission.CAMERA" />
```
4. ¡A compilar!
Conecta tu dispositivo físico o inicia un emulador y ejecuta:

```bash
flutter run
```
🛠️ Tecnologías utilizadas
  - Flutter - Framework de UI

  - tflite_flutter - Motor de inferencia

  - image_picker - Acceso a cámara y galería
