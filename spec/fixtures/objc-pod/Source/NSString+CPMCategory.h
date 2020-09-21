#import <Foundation/Foundation.h>

@interface NSString (CPMCategory)
- (void)cpm_doSomethingWithoutParams;
- (void)cpm_doSomethingWithParam:(NSInteger)firstParam andParam:(NSInteger)otherParam;
@end
