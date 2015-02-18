//
//  NSManagedObject+SimpleData2.h
//  CheapTrip
//
//  Created by Sergey on 18.07.13.
//  Copyright (c) 2013 ITM House. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <BlocksKit.h>
#import "SimpleDataModel.h"

typedef NSManagedObject*(^SimpleDataMergeArrayBlock)(id node);
typedef NSManagedObject*(^SimpleDataDictionaryBlock)(id key, id value);
typedef void(^SimpleDataFindOrCreateProcessBlock)(id object, id objectNode, NSInteger objectIndex);

@interface NSManagedObject (SimpleData)

+ (id)create;
+ (id)findOrCreate:(id)objectId forKey:(NSString *)key;
+ (NSArray *)findOrCreateMultiple:(NSArray *)newObjects byKey:(NSString *)key dbKey:(NSString *)dbKey process:(SimpleDataFindOrCreateProcessBlock)processBlock;

+ (void)deleteObject:(id)obj;
+ (void)deleteObjects:(NSArray *)array;
+ (void)deleteObjectsSet:(NSSet *)set;
+ (void)deleteAllObjects;
- (void)deleteObject;

+ (NSArray *)all;
+ (NSArray *)allWithSort:(NSString *)sort;
+ (NSArray *)allWithSort:(NSString *)sort limit:(int)limit offset:(int)offset;

+ (id)first:(id)value forParam:(NSString *)param;

+ (NSArray *)find:(NSDictionary *)params;
+ (NSArray *)find:(NSDictionary *)params sort:(NSString *)sort;
+ (NSArray *)find:(NSDictionary *)params sort:(NSString *)sort limit:(int)limit offset:(int)offset;

+ (NSArray *)find:(id)value byParam:(NSString *)param;
+ (NSArray *)find:(id)value byParam:(NSString *)param sort:(NSString *)sort;
+ (NSArray *)find:(id)value byParam:(NSString *)param sort:(NSString *)sort limit:(int)limit offset:(int)offset;

+ (NSArray *)findWithPredicate:(NSPredicate *)predicate;
+ (NSArray *)findWithPredicate:(NSPredicate *)predicate sort:(NSString *)sort;
+ (NSArray *)findWithPredicate:(NSPredicate *)predicate sort:(NSString *)sort limit:(int)limit offset:(int)offset;

+ (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate;
+ (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate sort:(NSString *)sort;
+ (NSFetchRequest *)fetchRequestForFind:(id)value byParam:(NSString *)param;
+ (NSFetchRequest *)fetchRequestForFind:(id)value byParam:(NSString *)param sort:(NSString *)sort;
+ (NSFetchRequest *)fetchRequestForAll;
+ (NSFetchRequest *)fetchRequestForAllWithSort:(NSString *)sort;

+ (NSArray *)findWithValues:(NSArray *)values byParam:(NSString *)param;
+ (NSArray *)findWithValues:(NSArray *)values byParam:(NSString *)param sort:(NSString *)sort;

+ (NSInteger)count:(id)value byParam:(NSString *)param;
+ (NSInteger)countWithPredicate:(NSPredicate *)predicate;

+ (void)mergeDictionary:(NSDictionary *)jsonDict withSet:(NSMutableSet *)objectsSet mergingActions:(SimpleDataDictionaryBlock)block;
+ (void)mergeArray:(NSArray *)jsonArray withSet:(NSMutableSet *)objectsSet mergingActions:(SimpleDataMergeArrayBlock)block;

+ (void)save;
- (void)save;

// Cache

+ (void)initCache;
+ (void)clearCache;
+ (instancetype)cachedObjectForKey:(NSString *)key withValue:(id)value;

@end
