//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>

#ifdef DEBUG

@class NIOverviewerPageView;

@interface NIOverviewerView : UIView {
@private
  UIImage*  _backgroundImage;
  
  // State
  BOOL            _translucent;
  NSMutableArray* _pageViews;

  // Views
  UIScrollView* _pagingScrollView;
}

/**
 * Whether the view has a translucent background or not.
 */
@property (nonatomic, readwrite, assign) BOOL translucent;

/**
 * Adds a new page to the overviewer.
 */
- (void)addPageView:(NIOverviewerPageView *)page;

/**
 * Update all of the views.
 */
- (void)updatePages;

- (void)flashScrollIndicators;

@end

#endif