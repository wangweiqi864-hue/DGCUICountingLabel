#import <QuartzCore/QuartzCore.h>

#import "DGCUICountingLabel.h"

#if !__has_feature(objc_arc)
#error DGCUICountingLabel is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#pragma mark - UILabelCounter

#ifndef kUILabelCounterRate
#define kUILabelCounterRate 3.0
#endif

@protocol UILabelCounter<NSObject>

-(CGFloat)update:(CGFloat)t;

@end

@interface DGCUILabelCounterLinear : NSObject<UILabelCounter>

@end

@interface DGCUILabelCounterEaseIn : NSObject<UILabelCounter>

@end

@interface DGCUILabelCounterEaseOut : NSObject<UILabelCounter>

@end

@interface DGCUILabelCounterEaseInOut : NSObject<UILabelCounter>

@end

@interface DGCUILabelCounterEaseInBounce : NSObject<UILabelCounter>

@end

@interface DGCUILabelCounterEaseOutBounce : NSObject<UILabelCounter>

@end

@implementation DGCUILabelCounterLinear

-(CGFloat)update:(CGFloat)t
{
    return t;
}

@end

@implementation DGCUILabelCounterEaseIn

-(CGFloat)update:(CGFloat)t
{
    return powf(t, kUILabelCounterRate);
}

@end

@implementation DGCUILabelCounterEaseOut

-(CGFloat)update:(CGFloat)t{
    return 1.0-powf((1.0-t), kUILabelCounterRate);
}

@end

@implementation DGCUILabelCounterEaseInOut

-(CGFloat) update: (CGFloat) t
{
    t *= 2;
    if (t < 1)
        return 0.5f * powf (t, kUILabelCounterRate);
    else
        return 0.5f * (2.0f - powf(2.0 - t, kUILabelCounterRate));
}

@end

@implementation DGCUILabelCounterEaseInBounce

-(CGFloat) update: (CGFloat) t {
    
    if (t < 4.0 / 11.0) {
        return 1.0 - (powf(11.0 / 4.0, 2) * powf(t, 2)) - t;
    }
    
    if (t < 8.0 / 11.0) {
        return 1.0 - (3.0 / 4.0 + powf(11.0 / 4.0, 2) * powf(t - 6.0 / 11.0, 2)) - t;
    }
    
    if (t < 10.0 / 11.0) {
        return 1.0 - (15.0 /16.0 + powf(11.0 / 4.0, 2) * powf(t - 9.0 / 11.0, 2)) - t;
    }
    
    return 1.0 - (63.0 / 64.0 + powf(11.0 / 4.0, 2) * powf(t - 21.0 / 22.0, 2)) - t;
    
}

@end

@implementation DGCUILabelCounterEaseOutBounce

-(CGFloat) update: (CGFloat) t {
    
    if (t < 4.0 / 11.0) {
        return powf(11.0 / 4.0, 2) * powf(t, 2);
    }
    
    if (t < 8.0 / 11.0) {
        return 3.0 / 4.0 + powf(11.0 / 4.0, 2) * powf(t - 6.0 / 11.0, 2);
    }
    
    if (t < 10.0 / 11.0) {
        return 15.0 /16.0 + powf(11.0 / 4.0, 2) * powf(t - 9.0 / 11.0, 2);
    }
    
    return 63.0 / 64.0 + powf(11.0 / 4.0, 2) * powf(t - 21.0 / 22.0, 2);
    
}

@end

#pragma mark - DGCUICountingLabel

@interface DGCUICountingLabel ()

@property CGFloat startingValue;
@property CGFloat destinationValue;
@property NSTimeInterval progress;
@property NSTimeInterval lastUpdate;
@property NSTimeInterval totalTime;
@property CGFloat easingRate;

@property (nonatomic, strong) CADisplayLink *timer;
@property (nonatomic, strong) id<UILabelCounter> counter;

@end

@implementation DGCUICountingLabel

-(void)countFrom:(CGFloat)value to:(CGFloat)endValue {
    
    if (self.animationDuration == 0.0f) {
        self.animationDuration = 2.0f;
    }
    
    [self countFrom:value to:endValue withDuration:self.animationDuration];
}

-(void)countFrom:(CGFloat)startValue to:(CGFloat)endValue withDuration:(NSTimeInterval)duration {
    
    self.startingValue = startValue;
    self.destinationValue = endValue;
    
    // remove any (possible) old timers
    [self.timer invalidate];
    self.timer = nil;
    
    if(self.format == nil) {
        self.format = @"%f";
    }
    if (duration == 0.0) {
        // No animation
        [self setTextValue:endValue];
        [self runCompletionBlock];
        return;
    }

    self.easingRate = 3.0f;
    self.progress = 0;
    self.totalTime = duration;
    self.lastUpdate = CACurrentMediaTime();

    switch(self.method)
    {
        case UILabelCountingMethodLinear:
            self.counter = [[DGCUILabelCounterLinear alloc] init];
            break;
        case UILabelCountingMethodEaseIn:
            self.counter = [[DGCUILabelCounterEaseIn alloc] init];
            break;
        case UILabelCountingMethodEaseOut:
            self.counter = [[DGCUILabelCounterEaseOut alloc] init];
            break;
        case UILabelCountingMethodEaseInOut:
            self.counter = [[DGCUILabelCounterEaseInOut alloc] init];
            break;
        case UILabelCountingMethodEaseOutBounce:
            self.counter = [[DGCUILabelCounterEaseOutBounce alloc] init];
            break;
        case UILabelCountingMethodEaseInBounce:
            self.counter = [[DGCUILabelCounterEaseInBounce alloc] init];
            break;
    }

    CADisplayLink *timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateValue:)];
    timer.frameInterval = 2;
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:UITrackingRunLoopMode];
    self.timer = timer;
}

- (void)countFromCurrentValueTo:(CGFloat)endValue {
    [self countFrom:[self currentValue] to:endValue];
}

- (void)countFromCurrentValueTo:(CGFloat)endValue withDuration:(NSTimeInterval)duration {
    [self countFrom:[self currentValue] to:endValue withDuration:duration];
}

- (void)countFromZeroTo:(CGFloat)endValue {
    [self countFrom:0.0f to:endValue];
}

- (void)countFromZeroTo:(CGFloat)endValue withDuration:(NSTimeInterval)duration {
    [self countFrom:0.0f to:endValue withDuration:duration];
}

- (void)updateValue:(NSTimer *)timer {
    
    // update progress
    NSTimeInterval now = CACurrentMediaTime();
    self.progress += now - self.lastUpdate;
    self.lastUpdate = now;
    
    if (self.progress >= self.totalTime) {
        [self.timer invalidate];
        self.timer = nil;
        self.progress = self.totalTime;
    }
    
    [self setTextValue:[self currentValue]];
    
    if (self.progress == self.totalTime) {
        [self runCompletionBlock];
    }
}

- (void)setTextValue:(CGFloat)value
{
    if (self.attributedFormatBlock != nil) {
        self.attributedText = self.attributedFormatBlock(value);
    }
    else if(self.formatBlock != nil)
    {
        self.text = self.formatBlock(value);
    }
    else
    {
        // check if counting with ints - cast to int
        // regex based on IEEE printf specification: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
        if([self.format rangeOfString:@"%[^fega]*[diouxc]" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch].location != NSNotFound)
        {
            self.text = [NSString stringWithFormat:self.format,(int)value];
        }
        else
        {
            self.text = [NSString stringWithFormat:self.format,value];
        }
    }
}

- (void)setFormat:(NSString *)format {
    _format = format;
    // update label with new format
    [self setTextValue:self.currentValue];
}

- (void)runCompletionBlock {
    
    void (^block)(void) = self.completionBlock;
    if (block) {
        self.completionBlock = nil;
        block();
    }
}

- (CGFloat)currentValue {
    
    if (self.progress >= self.totalTime) {
        return self.destinationValue;
    }
    
    CGFloat percent = self.progress / self.totalTime;
    CGFloat updateVal = [self.counter update:percent];
    return self.startingValue + (updateVal * (self.destinationValue - self.startingValue));
}

@end
