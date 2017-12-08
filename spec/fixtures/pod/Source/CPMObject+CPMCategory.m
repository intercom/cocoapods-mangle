#import "CPMObject+CPMCategory.h"

@implementation CPMObject (CPMCategory)
- (void)cpm_dontMangleDoSomethingWithoutParams {}
- (void)cpm_dontMangleDoSomethingWithParam:(NSInteger)firstParam andParam:(NSInteger)otherParam {}
@end
