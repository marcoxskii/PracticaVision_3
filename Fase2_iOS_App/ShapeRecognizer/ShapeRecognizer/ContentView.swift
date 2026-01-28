//
//  ContentView.swift
//  ShapeRecognizer
//
//  Created by Marco Cajamarca C on 1/25/26.
//

import SwiftUI

struct ContentView: View {
    @State private var currentDrawing = Drawing()
    @State private var drawings: [Drawing] = []
    @State private var classificationResult = "Dibuja una forma"
    @State private var isLoaded = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Shape Recognizer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Canvas para dibujar
            Canvas { context, size in
                // Dibujar líneas previas
                for drawing in drawings {
                    var path = Path()
                    if let firstPoint = drawing.points.first {
                        path.move(to: firstPoint)
                        for point in drawing.points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    context.stroke(path, with: .color(.black), lineWidth: 3)
                }
                
                // Dibujar línea actual
                var currentPath = Path()
                if let firstPoint = currentDrawing.points.first {
                    currentPath.move(to: firstPoint)
                    for point in currentDrawing.points.dropFirst() {
                        currentPath.addLine(to: point)
                    }
                }
                context.stroke(currentPath, with: .color(.blue), lineWidth: 3)
            }
            .frame(width: 300, height: 300)
            .background(Color.white)
            .border(Color.gray, width: 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentDrawing.points.append(value.location)
                    }
                    .onEnded { _ in
                        drawings.append(currentDrawing)
                        currentDrawing = Drawing()
                    }
            )
            
            // Resultado de clasificación
            Text(classificationResult)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(classificationResult.contains("Error") || classificationResult.contains("fallida") ? .red : .green)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            HStack(spacing: 20) {
                // Botón clasificar
                Button("Clasificar") {
                    classifyDrawing()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(drawings.isEmpty)
                
                // Botón limpiar
                Button("Limpiar") {
                    drawings.removeAll()
                    currentDrawing = Drawing()
                    classificationResult = "Dibuja una forma"
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Text(isLoaded ? "Modelo cargado" : "! Cargando modelo...")
                .foregroundColor(isLoaded ? .green : .orange)
        }
        .padding()
        .onAppear {
            loadTrainingData()
        }
    }
    
    private func loadTrainingData() {
        guard let path = Bundle.main.path(forResource: "ios_training_data_corrected", ofType: "json") else {
            classificationResult = "Error: Archivo JSON no encontrado"
            return
        }
        
        let success = OpenCVWrapper.loadTrainingData(path)
        isLoaded = success
        
        if !success {
            classificationResult = "Error cargando modelo"
        }
    }
    
    private func classifyDrawing() {
        // Renderizamos la vista del dibujo a una imagen
        let renderer = ImageRenderer(content: drawingView)
        renderer.scale = 2.0 // Escala para mejor resolución
        
        if let uiImage = renderer.uiImage {
            // Llamada al wrapper de OpenCV
            let result = OpenCVWrapper.classifyShape(uiImage)
            classificationResult = result ?? "No se pudo clasificar"
        } else {
            classificationResult = "Error convirtiendo imagen"
        }
    }
    
    // Vista auxiliar solo para renderizar la imagen limpia (sin bordes ni cursores)
    private var drawingView: some View {
        Canvas { context, size in
            for drawing in drawings {
                var path = Path()
                if let firstPoint = drawing.points.first {
                    path.move(to: firstPoint)
                    for point in drawing.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                // Usamos un trazo más grueso para que OpenCV lo detecte mejor
                context.stroke(path, with: .color(.black), lineWidth: 8)
            }
        }
        .frame(width: 300, height: 300)
        .background(Color.white)
    }
}

struct Drawing {
    var points: [CGPoint] = []
}

#Preview {
    ContentView()
}
