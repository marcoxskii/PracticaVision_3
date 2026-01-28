// OpenCVWrapper.h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

// Dejamos los métodos pero no harán nada por ahora
+ (NSString*)classifyShape:(UIImage*)image;
+ (BOOL)loadTrainingData:(NSString*)jsonPath;
+ (NSString*)testOpenCV;

@end
