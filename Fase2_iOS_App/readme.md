# Fase 2: Aplicación iOS de Reconocimiento de Formas

Esta carpeta contiene el código fuente de la aplicación móvil desarrollada en SwiftUI que implementa el motor de inferencia utilizando OpenCV y C++.

## 1. Arquitectura de la Solución
La aplicación utiliza un patrón híbrido para combinar la interfaz moderna de Apple con la potencia de OpenCV:

- **Interfaz de Usuario (SwiftUI)**:
  - `ContentView.swift`: Proporciona un **Canvas de dibujo** donde el usuario traza la figura y muestra el resultado de la clasificación en tiempo real.
  - `ShapeRecognizerApp.swift`: Punto de entrada de la aplicación.
  
- **Capa Intermedia (Objective-C++)**:
  - `OpenCVWrapper.h/mm`: Actúa como puente entre Swift y C++. Implementa la lógica nativa de visión computacional.

- **Motor de Visión (C++)**:
  - Implementación del algoritmo **Shape Signature** con coordenadas complejas:
    1. **Preprocessing**: Binarización y corrección morfológica del trazo (negro sobre blanco o viceversa).
    2. **Contorno**: Extracción y remuestreo a 64 puntos equidistantes.
    3. **DFT**: Cálculo de la Transformada Discreta de Fourier usando `cv::dft` de OpenCV.
    4. **Clasificación**: Algoritmo k-NN (k=5) utilizando distancia Euclidiana contra el corpus cargado.

## 2. Configuración del Proyecto

### Requisitos
- **Xcode 14.0+**
- **iOS 15.0+**
- **OpenCV Framework (iOS Pack)**: Debe estar presente en `ShapeRecognizer/opencv2.framework`.

### Instalación de OpenCV
1. Descargar el framework iOS desde [opencv.org](https://opencv.org/releases/).
2. Colocar `opencv2.framework` en `Fase2_iOS_App/ShapeRecognizer/`.
3. Verificar en Xcode: "Build Phases" -> "Link Binary With Libraries".

## 3. Modelo de Datos
La app carga al iniciar el archivo `ios_training_data_corrected.json` que contiene los vectores característicos (Fourier Descriptors) generados en la Fase 1.

## 4. Estructura de Archivos
```
ShapeRecognizer/
├── OpenCVWrapper.mm       # Lógica C++ (cv::dft, k-NN)
├── ContentView.swift      # Canvas de dibujo
├── ios_training_data_corrected.json  # Corpus
└── ...
```

## 5. Procedimiento de Prueba y Validación (Manual)

Para cumplir con el requerimiento de validar la precisión del sistema ("Determinar el nivel de precisión... al menos 30 imágenes"), siga estos pasos:

1. **Ejecutar la App** en un Simulador o Dispositivo real (iPhone/iPad).
2. **Dibujar** una figura geométrica en el área blanca.
3. Presionar **"Clasificar"**.
4. Registrar el resultado ("Acierto" o "Fallo") en una hoja de cálculo.
5. Presionar **"Limpiar"** y repetir.

### Protocolo de Prueba Experimental
Se debe realizar una prueba con **30 iteraciones** (10 triángulos, 10 círculos, 10 cuadrados) distribuidas de la siguiente forma:

| Iteración | Figura Dibujada | Predicción App | ¿Correcto? |
|-----------|-----------------|----------------|------------|
| 1         | Triángulo       | Triángulo      | ✅         |
| 2         | Círculo         | Círculo        | ✅         |
| 3         | Cuadrado        | Triángulo      | ❌         |
| ...       | ...             | ...            | ...        |
| 30        | ...             | ...            | ...        |

**Cálculo de Precisión:**
$$ \text{Precisión} = \frac{\text{Total Aciertos}}{30} \times 100\% $$

La **Matriz de Confusión** resultante debe incluirse en el reporte final, indicando qué figuras se confunden con mayor frecuencia (ej. Cuadrados redondeados confundidos con Círculos).
