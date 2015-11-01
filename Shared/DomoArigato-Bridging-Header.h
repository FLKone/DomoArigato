//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#define NSLog(__FORMAT__, ...) NSLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#import "Crittercism.h"