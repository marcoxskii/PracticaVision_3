//
//  OpenCVWrapper.mm
//  ShapeRecognizer
//
//  Created by Marco Cajamarca C on 1/25/26.
//

#include <vector>
#include <complex>
#include <cmath>
#include <string>
#include <map>
#include <algorithm>

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>

#import "OpenCVWrapper.h"

// Variables estáticas
static std::vector<std::vector<std::vector<double>>> trainingFeatures;
static std::vector<std::string> trainingLabels;
// Ajuste: Usamos normalizationFactors simple para coincidir con tu JSON
static std::vector<double> normalizationFactors;

@implementation OpenCVWrapper

+ (BOOL)loadTrainingData:(NSString *)jsonPath {
    NSLog(@"Loading training data from: %@", jsonPath);
    
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    if (!jsonData) {
        NSLog(@"Failed to load JSON file");
        return NO;
    }
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                       options:0
                                                         error:&error];
    if (error) {
        NSLog(@"JSON parsing error: %@", error.localizedDescription);
        return NO;
    }
    
    // Limpiar datos anteriores
    trainingFeatures.clear();
    trainingLabels.clear();
    normalizationFactors.clear();
    
    // 1. CARGAR NORMALIZACIÓN (Formato: normalization_factors)
    NSArray *normFactors = json[@"normalization_factors"];
    if (normFactors) {
        for (NSNumber *n in normFactors) {
            normalizationFactors.push_back([n doubleValue]);
        }
    } else {
        NSLog(@"Warning: 'normalization_factors' not found in JSON.");
    }

    // 2. CARGAR MUESTRAS (Formato: training_samples con 'label' de texto)
    NSArray *samples = json[@"training_samples"];
    if (!samples) {
        NSLog(@"Error: 'training_samples' not found.");
        return NO;
    }

    for (NSDictionary *sample in samples) {
        NSArray *featuresArray = sample[@"features"]; // Array de arrays [[...]]
        NSString *label = sample[@"label"];           // String directo "triangle"
        
        if (!featuresArray) continue;

        std::vector<std::vector<double>> sampleFeatures;
        
        // Iterar sobre los sets de características (usualmente solo hay 1 por muestra)
        for (NSArray *featureSet in featuresArray) {
            std::vector<double> features;
            for (NSNumber *val in featureSet) {
                features.push_back([val doubleValue]);
            }
            sampleFeatures.push_back(features);
        }
        
        trainingFeatures.push_back(sampleFeatures);
        
        // Guardar la etiqueta tal cual viene en el JSON
        if (label) {
            trainingLabels.push_back([label UTF8String]);
        } else {
            trainingLabels.push_back("unknown");
        }
    }
    
    NSLog(@"SUCCESS: Loaded %lu samples. Normalization factors: %lu",
          trainingFeatures.size(), normalizationFactors.size());
    return YES;
}

+ (NSString *)classifyShape:(UIImage *)image {
    if (trainingFeatures.empty()) {
        return @"No training data loaded";
    }
    
    try {
        cv::Mat cvImage = [self matFromUIImage:image];
        
        // Preprocesamiento (Optimizado para dibujos de iPhone)
        cv::Mat processedImage = [self optimizeForMobileDrawing:cvImage];
        
        std::vector<std::vector<double>> signature = [self extractShapeSignature:processedImage];
        if (signature.empty()) {
            return @"Could not extract shape";
        }
        
        // --- NORMALIZACIÓN AJUSTADA AL JSON ---
        // Tu JSON usa factores simples (división), no StandardScaler.
        if (!normalizationFactors.empty() && !signature.empty() && !signature[0].empty()) {
            std::vector<double>& features = signature[0];
            for (size_t i = 0; i < features.size(); i++) {
                if (i < normalizationFactors.size()) {
                    double factor = normalizationFactors[i];
                    if (factor != 0) {
                        features[i] /= factor; // Solo dividir
                    }
                }
            }
        }
        
        // Clasificación k-NN (k=5 para estabilidad)
        std::string result = [self classifyUsingKNN:signature k:5];
        return [NSString stringWithUTF8String:result.c_str()];
        
    } catch (const cv::Exception& e) {
        NSLog(@"OpenCV Error: %s", e.what());
        return @"Classification error";
    } catch (...) {
        return @"Unknown error";
    }
}

+ (NSString*)testOpenCV {
    return @"OpenCV Ready";
}

+ (cv::Mat)matFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    cvMat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    cv::Mat grayImage;
    cv::cvtColor(cvMat, grayImage, cv::COLOR_RGBA2GRAY);
    
    return grayImage;
}

// Optimización de imagen (Mantenida)
+ (cv::Mat)optimizeForMobileDrawing:(cv::Mat)image {
    cv::Mat optimized;
    cv::Size targetSize(200, 200);
    cv::resize(image, optimized, targetSize, 0, 0, cv::INTER_AREA);
    cv::GaussianBlur(optimized, optimized, cv::Size(3, 3), 1.0);
    
    cv::Mat binary;
    cv::adaptiveThreshold(optimized, binary, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY_INV, 15, 5);
    
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3));
    cv::morphologyEx(binary, binary, cv::MORPH_CLOSE, kernel);
    cv::morphologyEx(binary, binary, cv::MORPH_OPEN, kernel);
    
    cv::Mat kernel2 = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(2, 2));
    cv::dilate(binary, binary, kernel2, cv::Point(-1, -1), 1);
    
    return binary;
}

+ (std::vector<std::vector<double>>)extractShapeSignature:(cv::Mat)image {
    std::vector<std::vector<double>> signature;
    
    try {
        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(image, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
        
        if (contours.empty()) return signature;
        
        int maxAreaIdx = -1;
        double maxArea = 0;
        for (size_t i = 0; i < contours.size(); i++) {
            double area = cv::contourArea(contours[i]);
            if (area > maxArea && area > 500) {
                maxArea = area;
                maxAreaIdx = i;
            }
        }
        
        if (maxAreaIdx == -1) return signature;
        
        std::vector<cv::Point> contour = contours[maxAreaIdx];
        if (contour.size() < 10) return signature;
        
        // SIN SUAVIZADO EXTRA (smoothContour removido para detectar esquinas)
        cv::Moments m = cv::moments(contour);
        if (m.m00 == 0) return signature;
        
        double cx = m.m10 / m.m00;
        double cy = m.m01 / m.m00;
        
        const int numPoints = 64;
        std::vector<cv::Point2d> resampledContour = [self resampleContour:contour numPoints:numPoints];
        
        std::vector<std::complex<double>> complexContour;
        for (const cv::Point2d& pt : resampledContour) {
            std::complex<double> z(pt.x - cx, pt.y - cy);
            complexContour.push_back(z);
        }
        
        std::vector<std::complex<double>> fourierDescriptors = [self computeDFT:complexContour];
        
        const int numDescriptors = 8;
        std::vector<double> features;
        
        if (fourierDescriptors.size() > 1) {
            double normFactor = abs(fourierDescriptors[1]);
            
            if (normFactor > 1e-10) {
                for (int i = 2; i < std::min((int)fourierDescriptors.size(), numDescriptors + 2); i++) {
                    double magnitude = abs(fourierDescriptors[i]) / normFactor;
                    features.push_back(magnitude);
                }
            }
        }
        
        while (features.size() < numDescriptors) {
            features.push_back(0.0);
        }
        
        signature.push_back(features);
        
    } catch (const cv::Exception& e) {
        NSLog(@"Error in extractShapeSignature: %s", e.what());
    }
    
    return signature;
}

+ (std::vector<cv::Point2d>)resampleContour:(std::vector<cv::Point>)contour numPoints:(int)numPoints {
    std::vector<cv::Point2d> resampled;
    if (contour.size() < 2) return resampled;
    
    double totalLength = 0;
    for (size_t i = 0; i < contour.size(); i++) {
        cv::Point p1 = contour[i];
        cv::Point p2 = contour[(i + 1) % contour.size()];
        totalLength += cv::norm(p1 - p2);
    }
    
    if (totalLength == 0) return resampled;
    
    double stepSize = totalLength / numPoints;
    resampled.push_back(cv::Point2d(contour[0].x, contour[0].y));
    
    double currentLength = 0;
    double targetLength = stepSize;
    
    for (size_t i = 0; i < contour.size() && resampled.size() < numPoints; i++) {
        cv::Point p1 = contour[i];
        cv::Point p2 = contour[(i + 1) % contour.size()];
        double segmentLength = cv::norm(p1 - p2);
        
        while (currentLength + segmentLength >= targetLength && resampled.size() < numPoints) {
            double ratio = (targetLength - currentLength) / segmentLength;
            cv::Point2d interpolated(
                p1.x + ratio * (p2.x - p1.x),
                p1.y + ratio * (p2.y - p1.y)
            );
            resampled.push_back(interpolated);
            targetLength += stepSize;
        }
        
        currentLength += segmentLength;
    }
    return resampled;
}

+ (std::vector<std::complex<double>>)computeDFT:(std::vector<std::complex<double>>)signal {
    int N = (int)signal.size();
    std::vector<std::complex<double>> result(N);
    for (int k = 0; k < N; k++) {
        std::complex<double> sum(0, 0);
        for (int n = 0; n < N; n++) {
            double angle = -2.0 * M_PI * k * n / N;
            std::complex<double> twiddle(cos(angle), sin(angle));
            sum += signal[n] * twiddle;
        }
        result[k] = sum;
    }
    return result;
}

+ (std::string)classifyUsingKNN:(std::vector<std::vector<double>>)querySignature k:(int)k {
    if (trainingFeatures.empty() || querySignature.empty()) {
        return "No data";
    }
    
    std::vector<std::pair<double, std::string>> distances;
    
    for (size_t i = 0; i < trainingFeatures.size(); i++) {
        double distance = [self calculateDistance:querySignature sample2:trainingFeatures[i]];
        distances.push_back(std::make_pair(distance, trainingLabels[i]));
    }
    
    std::sort(distances.begin(), distances.end());
    
    // Votación ponderada
    std::map<std::string, double> weightedVotes;
    for (int i = 0; i < std::min(k, (int)distances.size()); i++) {
        double distance = distances[i].first;
        std::string className = distances[i].second;
        double weight = (distance >= 0) ? 1.0 / (1.0 + distance) : 1.0;
        weightedVotes[className] += weight;
    }
    
    std::string bestClass;
    double maxWeight = 0;
    for (const auto& vote : weightedVotes) {
        if (vote.second > maxWeight) {
            maxWeight = vote.second;
            bestClass = vote.first;
        }
    }
    
    NSLog(@"Classification result: %s (confidence: %.3f)", bestClass.c_str(), maxWeight);
    return bestClass;
}

+ (double)calculateDistance:(std::vector<std::vector<double>>)sample1 sample2:(std::vector<std::vector<double>>)sample2 {
    if (sample1.empty() || sample2.empty()) return INFINITY;
    
    const std::vector<double>& features1 = sample1[0];
    const std::vector<double>& features2 = sample2[0];
    
    if (features1.size() != features2.size()) return INFINITY;
    
    double sum = 0;
    for (size_t i = 0; i < features1.size(); i++) {
        double diff = features1[i] - features2[i];
        sum += diff * diff;
    }
    
    return sqrt(sum);
}

@end
