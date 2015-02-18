//
//  CoreDataHelper.m
//  CoreDataHelper
//
//  Created by Sergey on 01.08.12.
//  Copyright (c) 2012 ITM House. All rights reserved.
//

#import "SimpleDataModel.h"

@implementation SimpleDataModel

static SimpleDataModel* _instance;
static NSString const *simpleDataThreadKeyForContext = @"SimpleData_NSManagedObjectContextForThreadKey";

#pragma mark - Initializations

+ (SimpleDataModel*)sharedDataModel
{
    if (_instance == nil)
    {
        _instance = [[SimpleDataModel alloc] init];
    }
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _coreDataCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Setting Data Base

- (void)setDataModel:(NSString *)model withFile:(NSString *)filename
{
    if (_baseModelName != nil)
    {
        [self saveContext:[self contextForCurrentThread]];
        [NSManagedObjectContext closeContexts];
    }
    self.baseModelName = model;
    self.baseFileName = filename;
    [NSManagedObjectContext initializeContexts];
}

#pragma mark - Managing contexts

- (void)save
{
    [self saveContext:[self contextForCurrentThread]];
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [context performSave];
}

- (void)closeContext
{
    [NSManagedObjectContext closeContexts];
	self.managedModel = nil;
	self.storeCoordinator = nil;
}

#pragma mark - Properties setters

- (NSManagedObjectContext*)contextForCurrentThread
{
    return [NSManagedObjectContext contextForCurrentThread];
}

- (NSManagedObjectModel *)managedModel
{
    if (_managedModel != nil)
	{
        return _managedModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.baseModelName withExtension:@"momd"];
    return _managedModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSPersistentStoreCoordinator *)storeCoordinator
{
    if (_storeCoordinator != nil)
	{
        return _storeCoordinator;
    }
    
	NSURL * appDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL * storeURL = [appDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",self.baseFileName]];
    NSError * error = nil;
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @YES,
                              NSInferMappingModelAutomaticallyOption : @YES
                              };
    _storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedModel]];
    
    if (![_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
	{
        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
        _storeCoordinator = nil;
        error = nil;
        _storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedModel]];
        if (![_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _storeCoordinator;
}

#pragma mark - Clearing Data Base
- (void)clearDatabase
{
    NSError* error = nil;
	NSPersistentStore* store = [_storeCoordinator.persistentStores objectAtIndex:0];
	NSURL* storeUrl = store.URL;
	[_storeCoordinator removePersistentStore:store error:&error];
	[[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&error];
	if (![_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error])
	{
		NSLog(@"Error while creating new store after truncating!");
	}
}

- (void)clearDataModel
{
	[self saveContext:[NSManagedObjectContext contextForCurrentThread]];
	[NSManagedObjectContext closeContexts];
    [[SimpleDataModel sharedDataModel] setBaseModelName:nil];
}

#pragma mark - Cache

- (void)addCacheEntity:(NSArray *)entity forKey:(NSString *)key
{
    NSParameterAssert(key);
    NSParameterAssert(entity.count > 0);
    
    [self.coreDataCache setObject:entity forKey:key];
}

- (void)removeCacheEntityForKey:(NSString *)key
{
    NSParameterAssert(key);
    
    [self.coreDataCache removeObjectForKey:key];
}

- (NSArray *)cacheEntityForKey:(NSString *)key
{
    NSParameterAssert(key);
    
    return [self.coreDataCache objectForKey:key];
}

@end
