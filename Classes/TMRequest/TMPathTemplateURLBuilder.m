//
//  TMPathTemplateURLBuilder.m
//  TMTumblrSDK
//
//  Created by Nick DiStefano on 12/14/17.
//

#import "TMPathTemplateURLBuilder.h"

@implementation TMPathTemplateURLBuilder

-(NSURL*)urlWithRoot:(NSString*)root path:(NSString*)path pathParameters:(NSDictionary*)parameters {
    // Construct the url components
    NSURLComponents *components = [NSURLComponents componentsWithString:root];

    // Set the path so it's encoded using the normal URL encoding in iOS (e.g. space ' ' is encoded as %20, note that + etc won't be touched
    // See https://tools.ietf.org/html/rfc3986#section-2.2 for details on valid characters
    components.path = [components.path stringByAppendingString:path];

    // Replace the parameters in the path
    if (parameters.count > 0) {
        components.percentEncodedPath = [self replaceValuesInPath:components.percentEncodedPath withParameters:parameters];
    }

    return components.URL;
}

- (NSString*)replaceValuesInPath:(NSString*)path withParameters:(NSDictionary*) parameters {
    // Per https://tools.ietf.org/html/rfc3986#section-2.2 certain characters are valid URL character, however user data should be considered
    // outside of this set, and certain characters have meaning within the context of a URL, so they must be replaced by their percent encoded counterpart
    NSMutableCharacterSet *charset = NSCharacterSet.URLPathAllowedCharacterSet.mutableCopy;
    [charset removeCharactersInRange:NSMakeRange('+', 1)]; // + should be encoded as a literal + (%2B) not a space
    [charset removeCharactersInRange:NSMakeRange('/', 1)]; // / should be encoded as it's the path separator
    [charset removeCharactersInRange:NSMakeRange('?', 1)]; // / should be encoded as it's the query separator
    [charset removeCharactersInRange:NSMakeRange('#', 1)]; // / should be encoded as it's the fragment separator

    NSMutableDictionary *encodedParameters = parameters.mutableCopy;

    // Percent encode the paramters
    for (NSString *name in parameters) {
        NSString *value = parameters[name];
        encodedParameters[name] = [value stringByAddingPercentEncodingWithAllowedCharacters:charset];
    }

    return [self replaceValuesInTemplateString:path withParameters:encodedParameters];
}

- (NSString*)replaceValuesInTemplateString:(NSString*) inputString withParameters:(NSDictionary*) parameters {
    NSError *error = nil;

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@":([a-zA-Z0-9_]+)(/|\\?|#|$)" options:0 error:&error];

    // make a copy of the input string. we are going to edit this one as we iterate
    NSMutableString *output = [NSMutableString stringWithString:inputString];

    // keep track of how many additional characters we've added to ensure range offset is correct
    __block NSUInteger count = 0;

    // Enumerate the template matches and attempt to replace them with their percent encoded values
    [regex enumerateMatchesInString:inputString
                            options:0
                              range:NSMakeRange(0, inputString.length)
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){

                             NSString *key = [inputString substringWithRange:[match rangeAtIndex:1]];
                             NSString *value = parameters[key];

                             if (value == nil) {
                                 // Fail here somehow if a token is encountered that there's no param value, exception?
                                 return;
                             }

                             NSRange replaceRange = NSMakeRange(match.range.location + count, match.range.length);
                             [output replaceCharactersInRange:replaceRange withString:value];

                             count += value.length - match.range.length;
                         }];

    return [output copy];
}

@end
