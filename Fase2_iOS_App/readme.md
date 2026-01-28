# Fase 2: Aplicación iOS de Reconocimiento de Formas

Esta carpeta contiene el código fuente de la aplicación móvil desarrollada en SwiftUI que implementa el motor de inferencia utilizando OpenCV y C++.

## 1. Arquitectura de la Solución
La aplicación utiliza un patrón híbrido para combinar la interfaz moderna de Apple con la potencia de OpenCV:

- **Interfaz de Usuario (SwiftUI)**:
  - `ContentView.swift`: Maneja la selección de imágenes (Cámara/Galería) y muestra los resultados.
  - `ShapeRecognizerApp.swift`: Punto de entrada de la aplicación.
  
- **Capa Intermedia (Objective-C++)**:
  - `OpenCVWrapper.h/mm`: Actúa como puente (Bridging Header) entre el código Swift y el motor C++. Convierte los objetos `UIImage` de Apple a matrices `cv::Mat` de OpenCV.

- **Motor de Visión (C++ Standard)**:
  - Implementación directa dentro del wrapper (por simplicidad) que replica el algoritmo `Shape Signature` validado en la Fase 1:
    1. Binarización y extracción de contornos.
    2. Muestreo del contorno a N puntos equidistantes.
    3. Cálculo de la transformada de Fourier (FFT) del contorno (Coordenadas complejas).
    4. Comparación de descriptores con el modelo JSON cargado.

## 2. Configuración del Proyecto

### Requisitos
- **Xcode 14.0+**
- **iOS 15.0+**
- **OpenCV Framework (iOS Pack)**: Debe estar presente en `ShapeRecognizer/opencv2.framework`. (No incluido en el repo por peso).

### Instalación de OpenCV
1. Descarga el framework desde [opencv.org](https://opencv.org/releases/).
2. Coloca la carpeta `opencv2.framework` dentro de `Fase2_iOS_App/ShapeRecognizer/`.
3. Asegúrate de que en los ajustes del proyecto ("Build Phases" -> "Link Binary With Libraries") aparezca enlazado.

## 3. Modelo de Datos
La app no realiza entrenamiento "on-device". En su lugar, carga al iniciar el archivo:
- `ios_training_data_corrected.json`

Este archivo contiene los vectores de características pre-calculados en la Fase 1. La clasificación se realiza calculando la **Distancia Euclidiana** entre la firma de la nueva imagen y los vectores promedios del JSON.

## 4. Estructura de Archivos
```
ShapeRecognizer/
├── OpenCVWrapper.mm       # Lógica principal de Visión (C++)
├── OpenCVWrapper.h        # Cabecera pública para Swift
├── ShapeRecognizer-Bridging-Header.h
├── ContentView.swift      # UI principal
├── ios_training_data_corrected.json  # Modelo
└── Assets.xcassets/       # Iconos y recursos
```

## 5. Solución de Problemas Comunes
- **"opencv2/opencv.hpp not found"**: Verifica que el framework esté en la ruta correcta y que en "Framework Search Paths" en Xcode esté configurado `$(PROJECT_DIR)/ShapeRecognizer`.
- **Errores de Linker**: Asegúrate de importar los frameworks del sistema necesarios: `libc++.tbd`, `AVFoundation`, `CoreMedia`.
