#import "CPMObject.h"

@interface CPMObject (CPMCategory)
- (void)cpm_dontMangleDoSomethingWithoutParams;
- (void)cpm_dontMangleDoSomethingWithParam:(NSInteger)firstParam andParam:(NSInteger)otherParam;
@end
