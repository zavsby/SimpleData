//
//  CoreDataHelper.h
//  CoreDataHelper
//
//  Created by Sergey on 01.08.12.
//  Copyright (c) 2012 ITM House. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObjectContext+SimpleData.h"


@interface SimpleDataModel : NSObject

@property (nonatomic, retain) NSString *baseModelName;
@property (nonatomic, retain) NSString *baseFileName;

@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic, retain) NSManagedObjectModel *managedModel;

// Objects Cache
@property (nonatomic, strong) NSMutableDictionary *coreDataCache;

+ (SimpleDataModel *)sharedDataModel;

- (void)setDataModel:(NSString *)model withFile:(NSString *)filename;
//- (void)closeMainContext;
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)save;
- (NSManagedObjectContext *)contextForCurrentThread;

- (void)clearDatabase;
- (void)clearDataModel;

//- (void)loadDataBaseWithFilename:(NSString *)_baseFileName;

// Cache

- (void)addCacheEntity:(NSArray *)entity forKey:(NSString *)key;
- (void)removeCacheEntityForKey:(NSString *)key;
- (NSArray *)cacheEntityForKey:(NSString *)key;

@end
