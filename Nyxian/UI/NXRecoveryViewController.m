/*
 SPDX-License-Identifier: AGPL-3.0-or-later

 Copyright (C) 2025 - 2026 emexlab

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <UI/NXRecoveryViewController.h>
#import <UI/NXVolumeButtonMonitor.h>

const CGFloat NXRecoveryFontSize = 13.0;
static const CGFloat NXRecoveryMargin = 0.0;
static const CGFloat NXRecoveryMenuFooterGap = 8.0;

@implementation NXRecoveryItem

- (instancetype)initWithTitle:(NSString *)title
                       action:(NXRecoveryAction)action
{
    self = [super init];
    if(self)
    {
        _title = [title copy];
        _action = [action copy];
    }
    return self;
}

+ (instancetype)itemWithTitle:(NSString *)title
{
    return [[self alloc] initWithTitle:title action:nil];
}

+ (instancetype)itemWithTitle:(NSString *)title
                       action:(NXRecoveryAction)action
{
    return [[self alloc] initWithTitle:title action:action];
}

@end

@interface NXRecoveryRow : NSObject

@property (nonatomic, strong) UIView *bar;
@property (nonatomic, strong) UILabel *label;

@end

@implementation NXRecoveryRow
@end

@interface NXRecoveryLogLine : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic) NXRecoveryLogLevel level;

+ (instancetype)lineWithText:(NSString *)text level:(NXRecoveryLogLevel)level;

@end

@implementation NXRecoveryLogLine

+ (instancetype)lineWithText:(NSString *)text
                       level:(NXRecoveryLogLevel)level
{
    NXRecoveryLogLine *line = [self new];
    line.text = text;
    line.level = level;
    return line;
}

@end

@interface NXRecoveryEntry : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy, nullable) NSString *linkDestination;
@property (nonatomic) BOOL isSymlink;
@property (nonatomic) BOOL isDirectory;
@property (nonatomic) BOOL isBroken;
@property (nonatomic, readonly) NSString *displayTitle;

@end

@implementation NXRecoveryEntry

- (NSString *)displayTitle
{
    NSString *base = self.isDirectory ? [self.name stringByAppendingString:@"/"] : self.name;
    if(!self.isSymlink)
    {
        return base;
    }
    
    NSString *dest = self.linkDestination ?: @"?";
    
    return self.isBroken ? [NSString stringWithFormat:@"%@ -> %@ (broken)", self.name, dest] : [NSString stringWithFormat:@"%@ -> %@", base, dest];
}

@end

@interface NXRecoveryViewController ()

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *instructionsLabel;
@property (nonatomic, strong) UIStackView *menuStack;
@property (nonatomic, strong) UIStackView *footerStack;

@property (nonatomic, strong) NSMutableArray<NXRecoveryRow*> *rows;
@property (nonatomic, strong) NSMutableArray<UIView*> *decor;
@property (nonatomic, strong) NSMutableArray<NXRecoveryItem*> *mutableItems;
@property (nonatomic, strong) UIFont *itemFont;
@property (nonatomic, strong) UIFont *itemFontBold;

@property (nonatomic) NSInteger menuOffset;
@property (nonatomic) NSInteger visibleWindow;
@property (nonatomic) NSInteger menuWindow;

@property (nonatomic, strong) NSMutableArray<NXRecoveryLogLine*> *logLines;
@property (nonatomic, strong) NSMutableArray<UILabel*> *logRows;
@property (nonatomic, strong) UIFont *logFont;

@property (nonatomic, readwrite, getter=isRecoveryActive) BOOL recoveryActive;
@property (nonatomic, copy, nullable) NXRecoveryIndexHandler onSelect;
@property (nonatomic, copy, nullable) NXRecoveryIndexHandler onMove;

@property (nonatomic, copy, nullable) NSString *browserRoot;
@property (nonatomic, copy, nullable) NSString *browserHeader;
@property (nonatomic, copy, nullable) NSString *browserPath;
@property (nonatomic, copy, nullable) NXRecoveryAction browserOnBack;
@property (nonatomic, copy, nullable) NXRecoveryFileHandler browserOnFile;

@end

@implementation NXRecoveryViewController

+ (UIColor *)rgbR:(CGFloat)r
                g:(CGFloat)g
                b:(CGFloat)b
{
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

+ (UIColor *)recoveryBackgroundColor
{
    return [self rgbR:0.0 g:0.0 b:0.0];
}

+ (UIColor *)recoveryHeaderColor
{
    return [self rgbR:249/255.0 g:194/255.0 b:0.0];
}

+ (UIColor *)recoveryInfoColor
{
    return [self rgbR:249/255.0 g:194/255.0 b:0.0];
}

+ (UIColor *)recoveryItemColor
{
    return [self rgbR:0.0 g:0.66 b:1.0];
}

+ (UIColor *)recoveryHighlightColor
{
    return [self rgbR:0.0 g:0.66 b:1.0];
}

+ (UIColor *)recoveryHighlightTextColor
{
    return [self rgbR:1.0 g:1.0 b:1.0];
}

+ (UIColor *)recoveryFooterColor
{
    return [self rgbR:0.5 g:0.5 b:0.5];
}

+ (UIColor *)recoveryLogInfoColor
{
    return [self rgbR:196/255.0 g:196/255.0 b:196/255.0];
}

+ (UIColor *)recoveryLogErrorColor
{
    return [self rgbR:1.0 g:0.27 b:0.27];
}

- (instancetype)initWithNibName:(NSString *)nib
                         bundle:(NSBundle *)bundle
{
    self = [super initWithNibName:nib bundle:bundle];
    if(self)
    {
        _rows = [NSMutableArray array];
        _decor = [NSMutableArray array];
        _mutableItems = [NSMutableArray array];
        _logLines = [NSMutableArray array];
        _logRows = [NSMutableArray array];
        _recoveryIndex = 0;
        _recoveryLogMax = 8;
        _recoveryActive = NO;
        _menuOffset = 0;
        _visibleWindow = 0;
        _menuWindow = 0;
    }
    return self;
}

- (void)createRecoveryView
{
    [self loadViewIfNeeded];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [self.class recoveryBackgroundColor];
    self.view.hidden = YES;
    
    UIColor *clear = [UIColor clearColor];
    UIFont *infoFont = [UIFont monospacedSystemFontOfSize:NXRecoveryFontSize weight:UIFontWeightMedium];
    
    UILabel *header = [UILabel new];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.numberOfLines = 0;
    header.textAlignment = NSTextAlignmentLeft;
    header.backgroundColor = clear;
    header.textColor = [self.class recoveryInfoColor];
    header.text = @"Nyxian Recovery";
    header.font = infoFont;
    [self.view addSubview:header];
    self.headerLabel = header;
    
    UILabel *instructions = [UILabel new];
    instructions.translatesAutoresizingMaskIntoConstraints = NO;
    instructions.numberOfLines = 0;
    instructions.textAlignment = NSTextAlignmentLeft;
    instructions.backgroundColor = clear;
    instructions.textColor = [self.class recoveryInfoColor];
    instructions.text = @"Use volume up/down and hold both volume keys.";
    instructions.font = infoFont;
    [self.view addSubview:instructions];
    self.instructionsLabel = instructions;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionFill;
    stack.spacing = 2;
    [self.view addSubview:stack];
    self.menuStack = stack;
    
    UIStackView *footer = [UIStackView new];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.axis = UILayoutConstraintAxisVertical;
    footer.alignment = UIStackViewAlignmentFill;
    footer.distribution = UIStackViewDistributionFill;
    footer.spacing = 0;
    [self.view addSubview:footer];
    self.footerStack = footer;
    
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12],
        [header.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:NXRecoveryMargin],
        [header.trailingAnchor constraintLessThanOrEqualToAnchor:guide.trailingAnchor constant:-8],
        
        [instructions.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:0],
        [instructions.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:NXRecoveryMargin],
        [instructions.trailingAnchor constraintLessThanOrEqualToAnchor:guide.trailingAnchor constant:-8],
        
        [stack.topAnchor constraintEqualToAnchor:instructions.bottomAnchor constant:4],
        [stack.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:NXRecoveryMargin],
        [stack.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:0],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:footer.topAnchor constant:-NXRecoveryMenuFooterGap],
        
        [footer.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-12],
        [footer.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:NXRecoveryMargin],
        [footer.trailingAnchor constraintLessThanOrEqualToAnchor:guide.trailingAnchor constant:-8],
    ]];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if(self.mutableItems.count == 0)
    {
        return;
    }
    if([self effectiveMenuWindow] != self.visibleWindow)
    {
        [self rebuildMenuRows];
    }
}

- (void)attachToViewController:(UIViewController *)parent
{
    if(parent == nil)
    {
        return;
    }
    
    [parent addChildViewController:self];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    [parent.view addSubview:self.view];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.view.topAnchor constraintEqualToAnchor:parent.view.topAnchor],
        [self.view.bottomAnchor constraintEqualToAnchor:parent.view.bottomAnchor],
        [self.view.leadingAnchor constraintEqualToAnchor:parent.view.leadingAnchor],
        [self.view.trailingAnchor constraintEqualToAnchor:parent.view.trailingAnchor],
    ]];
    
    [self didMoveToParentViewController:parent];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIFont *)itemFont
{
    if (_itemFont == nil) {
        _itemFont = [UIFont monospacedSystemFontOfSize:NXRecoveryFontSize
                                                weight:UIFontWeightRegular];
    }
    return _itemFont;
}

- (UIFont *)itemFontBold
{
    if (_itemFontBold == nil) {
        _itemFontBold = [UIFont monospacedSystemFontOfSize:NXRecoveryFontSize
                                                    weight:UIFontWeightBold];
    }
    return _itemFontBold;
}

- (UIFont *)logFont
{
    if(_logFont == nil)
    {
        _logFont = [UIFont monospacedSystemFontOfSize:NXRecoveryFontSize weight:UIFontWeightRegular];
    }
    return _logFont;
}

- (void)setRecoveryHeader:(NSString *)text
{
    [self createRecoveryView];
    self.headerLabel.text = text ?: @"";
}

- (void)setRecoveryInstructions:(NSString *)text
{
    [self createRecoveryView];
    self.instructionsLabel.text = text ?: @"";
}

- (void)setRecoveryFooter:(NSString *)text
{
    [self createRecoveryView];
    [self.logLines removeAllObjects];
    if(text.length > 0)
    {
        [self.logLines addObject:[NXRecoveryLogLine lineWithText:text level:NXRecoveryLogLevelInfo]];
    }
    [self paintRecoveryLog];
}

- (UIView *)makeRecoveryLine
{
    UIView *v = [UIView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [self.class recoveryItemColor];
    [v.heightAnchor constraintEqualToConstant:1.0].active = YES;
    return v;
}

- (NSArray<NXRecoveryItem *> *)recoveryItems
{
    return [self.mutableItems copy];
}

- (void)setRecoveryItems:(NSArray<NXRecoveryItem *> *)items
{
    [self createRecoveryView];
    
    [self.mutableItems setArray:(items ?: @[])];
    
    _recoveryIndex = 0;
    _menuOffset = 0;
    
    [self rebuildMenuRows];
}

- (NSInteger)autoMenuWindow
{
    CGFloat rowHeight = MAX(self.itemFont.lineHeight, self.itemFontBold.lineHeight);
    rowHeight = ceil(rowHeight) + 2.0;
    CGFloat gap = self.menuStack.spacing;
    
    CGFloat top = CGRectGetMinY(self.menuStack.frame);
    CGFloat bottom = CGRectGetMinY(self.footerStack.frame) - NXRecoveryMenuFooterGap;
    
    if(bottom <= top)
    {
        top = 0.0;
        bottom = CGRectGetHeight(self.view.bounds);
        if(bottom <= 0.0)
        {
            return 1;
        }
    }
    
    CGFloat available = (bottom - top) - 2.0 * (1.0 + gap);
    if(available < rowHeight)
    {
        return 1;
    }
    return MAX(1, (NSInteger)floor((available + gap) / (rowHeight + gap)));
}

- (NSInteger)effectiveMenuWindow
{
    NSInteger count = (NSInteger)self.mutableItems.count;
    if(count == 0)
    {
        return 0;
    }
    
    NSInteger window = (self.menuWindow > 0) ? self.menuWindow : [self autoMenuWindow];
    return MIN(MAX(window, 1), count);
}

- (void)setMenuWindow:(NSInteger)menuWindow
{
    _menuWindow = MAX(0, menuWindow);
    [self rebuildMenuRows];
}

- (void)clampMenuOffset
{
    NSInteger count = (NSInteger)self.mutableItems.count;
    NSInteger window = self.visibleWindow;
    if(count == 0 || window <= 0 || window >= count)
    {
        _menuOffset = 0;
        return;
    }
    
    NSInteger offset = _menuOffset;
    if(_recoveryIndex < offset)
    {
        offset = _recoveryIndex;
    }
    else if(_recoveryIndex >= offset + window)
    {
        offset = _recoveryIndex - window + 1;
    }
    
    _menuOffset = MIN(MAX(offset, 0), count - window);
}

- (void)styleRow:(NXRecoveryRow *)row
     highlighted:(BOOL)highlighted
{
    row.bar.backgroundColor = highlighted ? [self.class recoveryHighlightColor] : [UIColor clearColor];
    row.label.textColor = highlighted ? [self.class recoveryHighlightTextColor] : [self.class recoveryItemColor];
    row.label.font = highlighted ? self.itemFontBold : self.itemFont;
}

- (void)applyMenuWindow
{
    [self clampMenuOffset];
    
    NSInteger count = (NSInteger)self.mutableItems.count;
    for(NSInteger slot = 0; slot < (NSInteger)self.rows.count; slot++)
    {
        NSInteger index = self.menuOffset + slot;
        NXRecoveryRow *row = self.rows[slot];
        
        if(index < 0 || index >= count)
        {
            row.label.text = @"";
            [self styleRow:row highlighted:NO];
            continue;
        }
        
        row.label.text = self.mutableItems[index].title;
        [self styleRow:row highlighted:(index == _recoveryIndex)];
    }
}

- (void)rebuildMenuRows
{
    [self createRecoveryView];
    
    UIColor *clear = [UIColor clearColor];
    for(NXRecoveryRow *row in self.rows)
    {
        [row.bar removeFromSuperview];
    }
    [self.rows removeAllObjects];
    
    for(UIView *d in self.decor)
    {
        [d removeFromSuperview];
    }
    [self.decor removeAllObjects];
    
    NSInteger window = [self effectiveMenuWindow];
    self.visibleWindow = window;
    if(window == 0)
    {
        return;
    }
    
    UIView *topLine = [self makeRecoveryLine];
    [self.menuStack addArrangedSubview:topLine];
    [self.decor addObject:topLine];
    
    for(NSInteger slot = 0; slot < window; slot++)
    {
        UIView *bar = [UIView new];
        bar.translatesAutoresizingMaskIntoConstraints = NO;
        bar.backgroundColor = clear;
        
        UILabel *label = [UILabel new];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 1;
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = clear;
        label.textColor = [self.class recoveryItemColor];
        label.font = self.itemFont;
        
        [bar addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.topAnchor constraintEqualToAnchor:bar.topAnchor constant:1],
            [label.bottomAnchor constraintEqualToAnchor:bar.bottomAnchor constant:-1],
            [label.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:0],
            [label.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-8],
        ]];
        
        [self.menuStack addArrangedSubview:bar];
        
        NXRecoveryRow *row = [NXRecoveryRow new];
        row.bar = bar;
        row.label = label;
        [self.rows addObject:row];
    }
    
    UIView *bottomLine = [self makeRecoveryLine];
    [self.menuStack addArrangedSubview:bottomLine];
    [self.decor addObject:bottomLine];
    
    [self applyMenuWindow];
}

- (void)setRecoveryIndex:(NSInteger)index
{
    NSInteger count = (NSInteger)self.mutableItems.count;
    if(count == 0)
    {
        _recoveryIndex = 0;
        _menuOffset = 0;
        return;
    }
    
    index = ((index % count) + count) % count;
    if(index == _recoveryIndex)
    {
        return;
    }
    
    _recoveryIndex = index;
    [self applyMenuWindow];
}

- (NXRecoveryItem *)currentRecoveryItem
{
    if(_recoveryIndex < 0 || _recoveryIndex >= (NSInteger)self.mutableItems.count)
    {
        return nil;
    }
    return self.mutableItems[_recoveryIndex];
}

- (void)showRecovery:(BOOL)visible
{
    [self createRecoveryView];
    [self.view.superview bringSubviewToFront:self.view];
    self.view.hidden = !visible;
}

- (void)enterRecoveryWithHeader:(NSString *)header
                   instructions:(NSString *)instructions
                         footer:(NSString *)footer
                          items:(NSArray<NXRecoveryItem *> *)items
                       onSelect:(NXRecoveryIndexHandler)onSelect
                         onMove:(NXRecoveryIndexHandler)onMove
{
    [self createRecoveryView];
    
    if(header != nil)
    {
        [self setRecoveryHeader:header];
    }
    [self setRecoveryItems:(items ?: @[])];
    if(footer != nil)
    {
        [self setRecoveryFooter:footer];
    }
    if(instructions != nil)
    {
        [self setRecoveryInstructions:instructions];
    }
    
    self.onSelect = onSelect;
    self.onMove = onMove;
    
    self.recoveryActive = YES;
    [self showRecovery:YES];
    
    [self armVolumeInput];
}

- (void)exitRecovery
{
    self.recoveryActive = NO;
    [self disarmVolumeInput];
    [self showRecovery:NO];
}

- (void)armVolumeInput
{
    __weak typeof(self) weakSelf = self;
    [NXVolumeButtonMonitor armWithHandler:^(NSInteger button, NSString *kind) {
        [weakSelf handleButton:button kindString:kind];
    }];
}

- (void)disarmVolumeInput
{
    [NXVolumeButtonMonitor disarm];
}

- (void)handleButton:(NSInteger)button
          kindString:(NSString*)kind
{
    NXRecoveryEventKind k = [kind isEqualToString:@"select"] ? NXRecoveryEventKindSelect : NXRecoveryEventKindTap;
    [self handleButton:(NXRecoveryButton)button kind:k];
}

- (void)handleButton:(NXRecoveryButton)button
                kind:(NXRecoveryEventKind)kind
{
    if(!self.recoveryActive)
    {
        return;
    }
    
    if(kind == NXRecoveryEventKindSelect)
    {
        [self performRecoverySelect];
    }
    else
    {
        [self moveRecoveryBy:(button == NXRecoveryButtonVolumeUp) ? -1 : 1];
    }
}

- (void)moveRecoveryBy:(NSInteger)delta
{
    self.recoveryIndex = self.recoveryIndex + delta;
    if(self.onMove != nil)
    {
        self.onMove(self, self.recoveryIndex, self.currentRecoveryItem);
    }
}

- (void)performRecoverySelect
{
    NXRecoveryItem *item = self.currentRecoveryItem;
    if(item == nil)
    {
        return;
    }
    
    if(item.action != nil)
    {
        item.action(self);
    }
    
    if(self.recoveryActive && self.onSelect != nil)
    {
        self.onSelect(self, self.recoveryIndex, item);
    }
}

- (void)setRecoveryLogMax:(NSInteger)recoveryLogMax
{
    _recoveryLogMax = MAX(1, recoveryLogMax);
    [self trimRecoveryLog];
    [self paintRecoveryLog];
}

- (void)trimRecoveryLog
{
    NSInteger over = (NSInteger)self.logLines.count - self.recoveryLogMax;
    if(over > 0)
    {
        [self.logLines removeObjectsInRange:NSMakeRange(0, (NSUInteger)over)];
    }
}

- (UIColor *)logColorForLevel:(NXRecoveryLogLevel)level
{
    return (level == NXRecoveryLogLevelError) ? [self.class recoveryLogErrorColor] : [self.class recoveryLogInfoColor];
}

- (void)paintRecoveryLog
{
    [self createRecoveryView];
    
    UIColor *clear = [UIColor clearColor];
    
    for(UILabel *row in self.logRows)
    {
        [row removeFromSuperview];
    }
    [self.logRows removeAllObjects];
    
    for(NXRecoveryLogLine *line in self.logLines)
    {
        UILabel *lbl = [UILabel new];
        lbl.translatesAutoresizingMaskIntoConstraints = NO;
        lbl.numberOfLines = 0;
        lbl.textAlignment = NSTextAlignmentLeft;
        lbl.backgroundColor = clear;
        lbl.textColor = [self logColorForLevel:line.level];
        lbl.text = line.text;
        lbl.font = self.logFont;
        
        [self.footerStack addArrangedSubview:lbl];
        [self.logRows addObject:lbl];
    }
}

- (void)recoveryLog:(NSString *)line
{
    [self recoveryLog:line level:NXRecoveryLogLevelInfo];
}

- (void)recoveryLog:(NSString *)line
              level:(NXRecoveryLogLevel)level
{
    [self createRecoveryView];
    
    for(NSString *part in [(line ?: @"") componentsSeparatedByString:@"\n"])
    {
        [self.logLines addObject:[NXRecoveryLogLine lineWithText:part level:level]];
    }
    
    [self trimRecoveryLog];
    [self paintRecoveryLog];
}

- (void)recoveryLogError:(NSString *)line
{
    [self recoveryLog:line level:NXRecoveryLogLevelError];
}

- (void)clearRecoveryLog
{
    [self.logLines removeAllObjects];
    [self paintRecoveryLog];
}

- (NSFileManager *)fm
{
    return [NSFileManager defaultManager];
}

- (BOOL)fmIsDirectoryAtPath:(NSString *)path
{
    NSDictionary *attrs = [self.fm attributesOfItemAtPath:path error:NULL];
    return attrs != nil && [attrs[NSFileType] isEqualToString:NSFileTypeDirectory];
}

- (NSString *)fmJoin:(NSString *)dir
                name:(NSString *)name
{
    return [dir isEqualToString:@"/"] ? [@"/" stringByAppendingString:name] : [NSString stringWithFormat:@"%@/%@", dir, name];
}

- (NSString *)fmParentOfPath:(NSString *)p
{
    if([p isEqualToString:@"/"])
    {
        return @"/";
    }
    
    NSString *q = p;
    while(q.length > 1 && [q hasSuffix:@"/"])
    {
        q = [q substringToIndex:q.length - 1];
    }

    NSRange slash = [q rangeOfString:@"/" options:NSBackwardsSearch];
    if(slash.location == NSNotFound || slash.location == 0)
    {
        return @"/";
    }
    return [q substringToIndex:slash.location];
}

- (NXRecoveryEntry*)entryForName:(NSString*)name
                     inDirectory:(NSString*)dir
{
    NXRecoveryEntry *e = [NXRecoveryEntry new];
    e.name = name;
    e.path = [self fmJoin:dir name:name];
    
    NSDictionary *attrs = [self.fm attributesOfItemAtPath:e.path error:NULL];
    NSString *type = attrs[NSFileType];
    
    if([type isEqualToString:NSFileTypeSymbolicLink])
    {
        e.isSymlink = YES;
        e.linkDestination = [self.fm destinationOfSymbolicLinkAtPath:e.path error:NULL];
        
        BOOL targetIsDir = NO;
        BOOL targetExists = [self.fm fileExistsAtPath:e.path isDirectory:&targetIsDir];
        
        e.isBroken = !targetExists;
        e.isDirectory = targetExists && targetIsDir;
    }
    else
    {
        e.isDirectory = [type isEqualToString:NSFileTypeDirectory];
    }
    
    return e;
}

- (void)browsePath:(NSString *)path
{
    [self browsePath:path root:self.browserRoot header:self.browserHeader onBack:self.browserOnBack onFile:self.browserOnFile];
}

- (void)browsePath:(NSString *)path
              root:(NSString *)root
            header:(NSString *)header
            onBack:(NXRecoveryAction)onBack
            onFile:(NXRecoveryFileHandler)onFile
{
    NSArray<NSString *> *names = [self.fm contentsOfDirectoryAtPath:path error:NULL];
    if(names == nil)
    {
        [self recoveryLogError:[@"open failed: " stringByAppendingString:path]];
        names = @[];
    }
    names = [names sortedArrayUsingSelector:@selector(localizedCompare:)];
    
    NSMutableArray<NXRecoveryEntry*> *dirs = [NSMutableArray array];
    NSMutableArray<NXRecoveryEntry*> *files = [NSMutableArray array];
    for(NSString *name in names)
    {
        NXRecoveryEntry *e = [self entryForName:name inDirectory:path];
        [(e.isDirectory ? dirs : files) addObject:e];
    }
    
    self.browserRoot = root ?: @"/";
    self.browserHeader = header;
    self.browserPath = path;
    self.browserOnBack = onBack;
    self.browserOnFile = onFile;
    
    NSMutableArray<NXRecoveryItem *> *items = [NSMutableArray array];
    NSString *here = [path copy];
    [items addObject:[NXRecoveryItem itemWithTitle:@"<< Back" action:^(NXRecoveryViewController *c){
        if(![here isEqualToString:c.browserRoot])
        {
            [c browsePath:[c fmParentOfPath:here]];
        }
        else if(c.browserOnBack != nil)
        {
            c.browserOnBack(c);
        }
        else
        {
            [c exitRecovery];
        }
    }]];
    
    for(NXRecoveryEntry *e in dirs)
    {
        NSString *full = e.path;
        [items addObject:[NXRecoveryItem itemWithTitle:e.displayTitle action:^(NXRecoveryViewController *c) {
            [c browsePath:full];
        }]];
    }
    
    for(NXRecoveryEntry *e in files)
    {
        NSString *full = e.path;
        NSString *name = e.name;
        BOOL broken = e.isBroken;
        
        [items addObject:[NXRecoveryItem itemWithTitle:e.displayTitle action:^(NXRecoveryViewController *c) {
            if(broken)
            {
                [c recoveryLogError:[@"dangling symlink: " stringByAppendingString:name]];
                return;
            }
            if(c.browserOnFile != nil)
            {
                c.browserOnFile(full, name, c);
            }
        }]];
    }
    
    [self setRecoveryHeader:[NSString stringWithFormat:@"%@\n%@", (header ?: @"Files"), path]];
    [self setRecoveryItems:items];
}

- (void)enterFileBrowserAtPath:(NSString *)path
                          root:(NSString *)root
                        header:(NSString *)header
                        onBack:(NXRecoveryAction)onBack
                        onFile:(NXRecoveryFileHandler)onFile
{
    [self enterRecoveryWithHeader:(header ?: @"Files") instructions:nil footer:nil items:@[] onSelect:nil onMove:nil];
    [self browsePath:path root:root header:header onBack:onBack onFile:onFile];
}

@end
