//
//  ImageCacheTestViewController.m
//  ImageCacheTest
//
//  Created by Johan Kool on 19/8/2011.
//  Copyright 2011 Koolistov. All rights reserved.
//

#import "ImageCacheTestViewController.h"

#import "KVImageCache.h"
#import "UIImageView+URL.h"

@implementation ImageCacheTestViewController
@synthesize imageURL;
@synthesize imageView;
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [self setImageURL:nil];
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)emptyCache:(id)sender {
    [[KVImageCache defaultCache] flush];
}

- (IBAction)loadImage:(id)sender {
    [self.imageURL resignFirstResponder];
    NSURL *URL = [NSURL URLWithString:self.imageURL.text];
    [self.imageView kv_setImageAtURL:URL];
}

- (void)dealloc {
    [imageURL release];
    [imageView release];
    [super dealloc];
}

@end
