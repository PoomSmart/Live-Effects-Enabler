#import "../PS.h"

%group preiOS9

%hook NSUserDefaults

- (BOOL)boolForKey: (NSString *)defaultName
{
    return [defaultName isEqualToString:@"PLDebugLiveEffects"] ? YES : %orig;
}

%end

%end

%hook CAMBottomBar

%group iOS8

%new
- (void)_setupVerticalFilterButtonConstraints
{
    CAMFilterButton *filterButton = [self.filterButton retain];
    [self retain];
    UIScreen *mainScreen = [[UIScreen mainScreen] retain];
    CGFloat scale = mainScreen.scale;
    CGFloat topMargin = 32*scale;
    NSNumber *topMarginNum = [[NSNumber numberWithDouble:topMargin] retain];
    NSDictionary *marginDict = [@{@"topMargin" : topMarginNum} retain];
    [topMarginNum release];
    [mainScreen release];
    NSDictionary *views = [_NSDictionaryOfVariableBindings(@"filterButton", filterButton) retain];
    NSMutableArray *constraint = [[NSMutableArray array] retain];
    NSLayoutConstraint *constraint1 = [[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeCenterX relatedBy:nil toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f] retain];
    NSArray *constraint2 = [[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(topMargin)-[filterButton]" options:0 metrics:marginDict views:views] retain];
    [constraint addObject:constraint1];
    [constraint addObjectsFromArray:constraint2];
    [filterButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self cam_addConstraints:constraint forKey:@"CAMFilterButton"];
    [self release];
    [constraint2 release];
    [constraint1 release];
    [constraint release];
    [views release];
    [marginDict release];
    [filterButton release];
}

- (void)_setupVerticalConstraints {
    %orig;
    if (![self cam_hasConstraintForKey:@"CAMFilterButton"]) {
        CAMFilterButton *filterButton = [self.filterButton retain];
        [filterButton release];
        if (filterButton != nil)
            [self _setupVerticalFilterButtonConstraints];
    }
}

%end

%group iOS9

- (void)_layoutFilterButtonForTraitCollection: (UITraitCollection *)trait
{
    %orig;
    if ([[self class] wantsVerticalBarForTraitCollection:trait]) {
        CAMFilterButton *filterButton = [self.filterButton retain];
        CGSize buttonSize = [filterButton intrinsicContentSize];
        filterButton.bounds = CGRectMake(0, 0, buttonSize.width, buttonSize.height);
        CGRect barRect = self.bounds;
        filterButton.center = CGPointMake(barRect.size.width / 2, barRect.size.height / 2 - buttonSize.height - 40);
        [filterButton release];
    }
}

%end

%end

%group iOS10Up

@interface CAMBottomBar (Addition)
@property(retain, nonatomic) CAMFilterButton *_filterButton;
- (void)_layoutFilterButtonForLayoutStyle:(NSInteger)layoutStyle;
@end

%hook CAMBottomBar

%property(retain, nonatomic) CAMFilterButton *_filterButton;

%new
- (void)setFilterButton: (CAMFilterButton *)button {
    if ([button retain] != self._filterButton) {
        [self._filterButton removeFromSuperview];
        CAMFilterButton *retainBtn = [button retain];
        self._filterButton = retainBtn;
        // tappableEdgeInsets
        [self cam_ensureSubview:retainBtn];
    }
    [button release];
}

%new
- (void)_layoutFilterButtonForLayoutStyle: (NSInteger)layoutStyle
{
    if ([[self class] wantsVerticalBarForLayoutStyle:layoutStyle]) {
        CAMFilterButton *filterButton = [self._filterButton retain];
        CGSize buttonSize = [filterButton intrinsicContentSize];
        filterButton.bounds = CGRectMake(0, 0, buttonSize.width, buttonSize.height);
        CGRect barRect = self.bounds;
        filterButton.center = CGPointMake(barRect.size.width / 2, buttonSize.height - 10);
        [filterButton release];
    }
}

- (void)layoutSubviews {
    [self _layoutFilterButtonForLayoutStyle:self.layoutStyle];
    %orig;
}

%end

%hook CAMViewfinderViewController

- (void)_embedFilterButtonWithLayoutStyle: (NSInteger)style {
    CAMBottomBar *bottomBar = [self._bottomBar retain];
    CAMFilterButton *filterButton = [self._filterButton retain];
    if (style != 2 && ![self isEmulatingImagePicker] && [NSClassFromString(@"CAMBottomBar") wantsVerticalBarForLayoutStyle:style])
        [bottomBar setFilterButton:filterButton];
    [filterButton release];
    [bottomBar release];
}

%end

@interface CAMFilterButton (Addition)
@property(retain, nonatomic) UIImageView *_padBackgroundView;
@end

%hook CAMFilterButton

%property(retain, nonatomic) UIImageView *_padBackgroundView;

- (void)_commonCAMFilterButtonInitialization {
    %orig;
    UIImage *padImage = [[UIImage imageNamed:@"CAMButtonBackgroundPad" inBundle:[NSBundle bundleForClass:[self class]]] retain];
    UIImageView *padView = [[UIImageView alloc] initWithImage:padImage];
    [self insertSubview:padView atIndex:0];
    self._padBackgroundView = padView;
    [self._padBackgroundView release];
    [padImage release];
}

- (void)layoutSubviews {
    %orig;
    if (self._padBackgroundView) {
        self._padBackgroundView.frame = [self alignmentRectForFrame:self._padBackgroundView.bounds];
        [self sendSubviewToBack:self._padBackgroundView];
    }
}

- (CGSize)intrinsicContentSize {
    return self._padBackgroundView.image.size;
}

%end

%end

extern "C" BOOL MGGetBoolAnswer(CFStringRef);
%hookf(BOOL, MGGetBoolAnswer, CFStringRef key){
    if (CFEqual(key, CFSTR("CameraLiveEffectsCapability")))
        return YES;
    return %orig;
}

%ctor
{
    %init;
    if (isiOS9Up) {
        if (isiOS10Up) {
            %init(iOS10Up);
        } else {
            %init(iOS9);
        }
    } else {
        if (isiOS8) {
            %init(iOS8);
        }
        %init(preiOS9);
    }
}
