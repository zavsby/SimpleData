//
//  NSManagedObjectContext+SimpleData.h
//  MagicalRecordAndPods
//
//  Created by Andrew Zhdanov on 05.07.13.
//  Copyright (c) 2013 ITMHouse. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (SimpleData)

+ (void)initializeContexts;
+ (void)closeContexts;

+ (NSManagedObjectContext*)contextForCurrentThread;
- (void)performSave;

@end
