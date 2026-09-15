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

#import <UI/UIInit/NXUISwitch.h>
#import <Nyxian-Swift.h>

@implementation NXUISwitch

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if(self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleRethemeNotification:) name:@"uiColorChangeNotif" object:nil];
    [self applyTheme];
    __weak __typeof(self) weakSelf = self;
    [self registerForTraitChanges:@[UITraitUserInterfaceStyle.class] withHandler:^(id<UITraitEnvironment> traitEnvironment, UITraitCollection *previousCollection) {
        [weakSelf applyTheme];
    }];
}

- (void)handleRethemeNotification:(NSNotification*)notification
{
    [self applyTheme];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self applyTheme];
}

- (void)applyTheme
{
    self.onTintColor = LDETheme.currentTheme.appLabel;
    self.thumbTintColor = LDETheme.currentTheme.appTableCell;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
