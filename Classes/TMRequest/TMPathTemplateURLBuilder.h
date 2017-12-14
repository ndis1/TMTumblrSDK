//
//  TMPathTemplateURLBuilder.h
//  TMTumblrSDK
//
//  Created by Nick DiStefano on 12/14/17.
//

#import <Foundation/Foundation.h>

@interface TMPathTemplateURLBuilder : NSObject

-(NSURL*)urlWithRoot:(NSString*)root path:(NSString*)path pathParameters:(NSDictionary*)parameters;

@end
