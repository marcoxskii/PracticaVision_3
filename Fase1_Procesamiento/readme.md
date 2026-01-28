# Fase 1: Investigación y Generación del Modelo

Este directorio contiene el entorno de experimentación en Python donde se analizaron diferentes técnicas de visión artificial para clasificar formas geométricas.

## 1. Introducción
El objetivo de esta fase es encontrar un descriptor de características robusto que pueda identificar círculos, cuadrados y triángulos incluso bajo condiciones adversas (ruido, rotación, cambios de escala), para posteriormente implementarlo en una aplicación móvil.

Se utiliza el **UPS Writing Skills Dataset**, que contiene trazos reales dibujados a mano.

## 2. Dependencias Principales
El análisis se realiza en el notebook `Practica3.1-3.2.ipynb` utilizando las siguientes librerías:
- **OpenCV (`cv2`)**: Procesamiento de imágenes y contornos.
- **Scikit-learn**: Algoritmos de clasificación (SVM, KNN) y métricas.
- **Mahotas / Skimage**: Extracción de momentos de Zernike y Hu.
- **NumPy / Matplotlib**: Manipulación de matrices y visualización.

## 3. Metodología
El flujo de trabajo implementado es el siguiente:

### A. Preprocesamiento
Todas las imágenes se normalizan a **128x128 píxeles** en escala de grises y se escalan al rango `[0, 1]`.

### B. Extracción de Características
Se evaluaron tres algoritmos diferentes para describir las formas:
1.  **Momentos de Hu**: 7 momentos invariantes (Escala, Traslación, Rotación).
2.  **Momentos de Zernike**: Polinomios ortogonales complejos (Grado 8).
3.  **Shape Signature + FFT**: Conversión del contorno a una señal 1D (distancia al centroide) y análisis de sus descriptores de Fourier.

### C. Evaluación de Robustez
Se sometió a los modelos a pruebas de estrés con:
- Ruido Gaussiano
- Ruido Sal y Pimienta
- Rotación aleatoria (0-360°)

## 4. Resultados y Conclusión
| Método | Precisión (Original) | Precisión (Rotación) | Observaciones |
| :--- | :---: | :---: | :--- |
| **Momentos de Hu** | 43% | 36% | Muy sensible al ruido y deformaciones. No apto. |
| **Momentos de Zernike** | **94%** | **88%** | El más robusto matemáticamente. |
| **Shape Signature** | 82% | 60% | Buen balance entre precisión y facilidad de implementación. |

**Decisión Final:**
Se seleccionó una variación de **Shape Signature / Descriptores de Fourier** para la aplicación final (Fase 2) debido a que su implementación en C++ (usando `std::vector` y `cv::dft`) es más directa y eficiente para dispositivos móviles que la implementación de polinomios de Zernike.

## 5. Salida
El notebook genera un archivo JSON (`ios_training_data_corrected.json`) que contiene los vectores de características "ideales" (promedios o centroides de las clases) que la app de iOS cargará para realizar la clasificación por distancia mínima.

