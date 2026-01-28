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

## 5. Resultados de Validación Experimental

Se realizó una prueba manual exhaustiva utilizando el simulador de iOS (iPhone 14 Pro), dibujando 30 figuras a mano alzada (10 de cada clase) para validar la robustez del algoritmo Shape Signature implementado en C++.

### Matriz de Confusión

| Clase Real \ Predicción | Triángulo | Círculo | Cuadrado | **Total Muestras** |
| :--- | :---: | :---: | :---: | :---: |
| **Triángulo** | **10** | 0 | 0 | 10 |
| **Círculo** | 0 | **10** | 0 | 10 |
| **Cuadrado** | 0 | 1 | **9** | 10 |

### Análisis de Desempeño

*   **Precisión Global**: **96.67%** (29/30 aciertos).
*   **Triángulos y Círculos**: El sistema mostró una robustez perfecta (100%) en estas categorías, discriminando correctamente incluso triángulos isósceles y escalenos.
*   **Cuadrados**: Se detectó 1 error de clasificación.

### Análisis de Errores (Casos de Confusión)

El único fallo registrado ocurrió al dibujar un cuadrado con **esquinas excesivamente redondeadas** y trazos rápidos.

- **Causa**: Al suavizar las esquinas, la firma de la forma (fft) pierde los componentes de alta frecuencia que distinguen los ángulos rectos, haciendo que el descriptor se asemeje más al de un círculo (cuyo primer armónico domina la señal).
- **Solución Propuesta**: Aumentar ligeramente el peso de los armónicos superiores en la distancia Euclidiana o mejorar el preprocesamiento para "detectar vértices" antes de la FFT.

> **Conclusión**: La implementación nativa en C++ con descriptores de Fourier complejos demostró ser altamente efectiva para reconocimiento en tiempo real en dispositivos móviles.
