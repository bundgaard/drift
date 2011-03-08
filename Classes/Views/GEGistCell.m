//
//  GEGistCell.m
//  Driftpad
//
//  Created by Devin Chalmers on 3/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GEGistCell.h"

@implementation GEGistCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
{
	if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
		return nil;
	
	self.selectedBackgroundView = [[[UIView alloc] initWithFrame:self.frame] autorelease];
	self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.19 alpha:1.0];
	
	self.backgroundView = [[[UIView alloc] initWithFrame:self.frame] autorelease];
	self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
	
	self.textLabel.textColor = [UIColor colorWithWhite:0.19 alpha:1.0];
	self.textLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
	
	self.detailTextLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
	
	return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
{
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}




@end
