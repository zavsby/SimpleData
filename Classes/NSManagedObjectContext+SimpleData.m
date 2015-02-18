//
//  NSManagedObjectContext+SimpleData.m
//  MagicalRecordAndPods
//
//  Created by Andrew Zhdanov on 05.07.13.
//  Copyright (c) 2013 ITMHouse. All rights reserved.
//

#import "NSManagedObjectContext+SimpleData.h"
#import "SimpleDataModel.h"

static NSManagedObjectContext *_mainContext = nil;
static NSManagedObjectContext *_rootSavingContext = nil;

static NSString const *simpleDataThreadKeyForContext = @"SimpleData_NSManagedObjectContextForThreadKey";

@implementation NSManagedObjectContext (SimpleData)

#pragma mark - Initialize

+ (void)initializeContexts
{
    if ((_mainContext == nil) && (_rootSavingContext == nil))
    {
        NSPersistentStoreCoordinator *coordinator = [[SimpleDataModel sharedDataModel]storeCoordinator];
        NSManagedObjectContext *rootContext = [self createContextWithStoreCoordinator:coordinator];
        [self setRootSavingContext:rootContext];
        
        NSManagedObjectContext *defaultContext = [self createNewMainQueueContext];
        [self setDefaultContext:defaultContext];
        
        [defaultContext setParentContext:rootContext];
    }
}

+ (NSManagedObjectContext *) createContextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	NSManagedObjectContext *context = nil;
    if (coordinator != nil)
	{
        context = [self createContextWithoutParent];
        [context performBlockAndWait:^{
            [context setPersistentStoreCoordinator:coordinator];
        }];
    }
    return context;
}

+ (void)setRootSavingContext:(NSManagedObjectContext *)context
{
    if (_rootSavingContext)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_rootSavingContext];
    }
    
    _rootSavingContext = context;
    [context addObtainPermanentIDsBeforeSavingNotificationHandler];
    [_rootSavingContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
}

+ (NSManagedObjectContext *) createNewMainQueueContext;
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    return context;
}

+ (void)setDefaultContext:(NSManagedObjectContext *)context
{
    if (_mainContext)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_mainContext];
    }
    _mainContext = context;
    [context addObtainPermanentIDsBeforeSavingNotificationHandler];
}

#pragma mark - Creating Child Context

+ (NSManagedObjectContext *) createContextWithoutParent
{
    NSManagedObjectContext *context = [[self alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    return context;
}

+ (NSManagedObjectContext *) createContextWithParent:(NSManagedObjectContext *)parentContext;
{
    NSManagedObjectContext *context = [self createContextWithoutParent];
    [context setParentContext:parentContext];
    [context addObtainPermanentIDsBeforeSavingNotificationHandler];
    return context;
}

- (void)addObtainPermanentIDsBeforeSavingNotificationHandler
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                    selector:@selector(contextWillSaveNotificationHandler:) name:NSManagedObjectContextWillSaveNotification
                                               object:self];
}

- (void)contextWillSaveNotificationHandler:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    NSSet *insertedObjects = [context insertedObjects];
    
    if ([insertedObjects count])
    {
        //MRLog(@"Context %@ is about to save. Obtaining permanent IDs for new %lu inserted objects", [context MR_workingName], (unsigned long)[insertedObjects count]);
        NSError *error = nil;
        BOOL success = [context obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
        if (!success)
        {
            //[MagicalRecord handleErrors:error];
        }
    }
}

#pragma mark - Properties setters

+ (NSManagedObjectContext*)contextForCurrentThread
{
    if ([NSThread isMainThread])
	{
		return _mainContext;
	}
	else
	{
		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:simpleDataThreadKeyForContext];
		if (threadContext == nil)
		{
			threadContext = [self createContextWithParent:_mainContext];
			[threadDict setObject:threadContext forKey:simpleDataThreadKeyForContext];
		}
		return threadContext;
	}
    
    //return self.mainContext;
}


- (void)performSave
{
    if (![self hasChanges]) return;
    
    id saveBlock = ^{
        NSError *error = nil;
        BOOL     saved = NO;
        @try
        {
            saved = [self save:&error];
        }
        @catch(NSException *exception)
        {
            NSLog(@"Exeption During Saving!!!%@",error);
        }
        @finally
        {
            if (saved)
            {
                // If we're the default context, save to disk too (the user expects it to persist)
                if (self == _mainContext)
                {
                    [_rootSavingContext performSave];
                }
                // If we're saving parent contexts, do so
                else if ([self parentContext])
                {
                    [[self parentContext] performSave];
                }
            }
            else
            {
                NSLog(@"Exeption During Saving!!!");
            }
        }
    };
    [self performBlockAndWait:saveBlock];
}

+ (void)closeContexts
{
    [[NSNotificationCenter defaultCenter]removeObserver:_mainContext];
    [[NSNotificationCenter defaultCenter]removeObserver:_rootSavingContext];
    
    _mainContext = nil;
    _rootSavingContext = nil;
}

@end

