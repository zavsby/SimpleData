//
//  NSManagedObject+SimpleData2.m
//  CheapTrip
//
//  Created by Sergey on 18.07.13.
//  Copyright (c) 2013 ITM House. All rights reserved.
//

#import "NSManagedObject+SimpleData.h"
#import "GlobalConstants.h"

@implementation NSManagedObject (SimpleData)

#pragma mark - Creating entities

+ (id)create
{
    id newObj = nil;
	Class class = [self class];
	newObj = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:[[SimpleDataModel sharedDataModel] contextForCurrentThread]];
    return newObj;
}

+ (id)findOrCreate:(id)objectId forKey:(NSString *)key
{
    NSManagedObject *object = [self first:objectId forParam:key];
    if (object == nil)
    {
        object = [self create];
        [object setValue:objectId forKey:key];
    }
    return object;
}

+ (NSArray *)findOrCreateMultiple:(NSArray *)newObjects byKey:(NSString *)key dbKey:(NSString *)dbKey process:(SimpleDataFindOrCreateProcessBlock)processBlock
{
    NSArray *sortedNewObjects = [newObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 valueForKey:key] compare:[obj2 valueForKey:key]];
    }];
    NSArray *newObjectsIds = [sortedNewObjects bk_map:^id(id obj) {
        return [obj valueForKey:key];
    }];
    
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = [NSPredicate predicateWithFormat:@"%@ IN %@", dbKey, newObjectsIds];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:dbKey ascending:YES]];
    
    NSArray *results = [[[SimpleDataModel sharedDataModel] contextForCurrentThread] executeFetchRequest:request error:nil];
    
    NSInteger resultsIndex = 0;
    for (NSInteger objectIndex = 0; objectIndex < sortedNewObjects.count; objectIndex++)
    {
        id objectNode = sortedNewObjects[objectIndex];
        if  (resultsIndex < results.count && [[objectNode valueForKey:key] compare:[results[resultsIndex] valueForKey:dbKey]] == NSOrderedSame)
        {
            if (processBlock)
            {
                processBlock(results[resultsIndex++], objectNode, objectIndex);
            }
        }
        else
        {
            NSManagedObject *object = [self create];
            [object setValue:[objectNode valueForKey:key] forKey:dbKey];
            if (processBlock)
            {
                processBlock(object, objectNode, objectIndex);
            }
        }
    }
    
    return results;
}

#pragma mark - Deleting entities

+ (void)deleteObject:(id)obj
{
	[[[SimpleDataModel sharedDataModel] contextForCurrentThread] deleteObject:obj];
}

+ (void)deleteObjects:(NSArray *)array
{
    for (NSManagedObject *object in array)
    {
        [[[SimpleDataModel sharedDataModel] contextForCurrentThread] deleteObject:object];
    }
}

+ (void)deleteObjectsSet:(NSSet *)set
{
    for (NSManagedObject *object in set)
    {
        [[[SimpleDataModel sharedDataModel] contextForCurrentThread] deleteObject:object];
    }
}

+ (void)deleteAllObjects
{
    [self deleteObjects:[self all]];
}

- (void)deleteObject
{
    [[[SimpleDataModel sharedDataModel] contextForCurrentThread] deleteObject:self];
}

#pragma mark - Saving

+ (void)save
{
	[[SimpleDataModel sharedDataModel] save];
}

- (void)save
{
	[[SimpleDataModel sharedDataModel] save];
}

#pragma mark - Getting entites

+ (id)first:(id)value forParam:(NSString *)param
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = [self predicateForValue:value key:param];
    request.fetchLimit = 1;
    
    return [[[SimpleDataModel sharedDataModel] contextForCurrentThread] executeFetchRequest:request error:nil].firstObject;
}

+ (NSArray *)all
{
    return [self allWithSort:nil limit:-1 offset:-1];
}

+ (NSArray *)allWithSort:(NSString *)sort
{
    return [self allWithSort:sort limit:-1 offset:-1];
}

+ (NSArray *)allWithSort:(NSString *)sort limit:(int)limit offset:(int)offset
{
	NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    if (offset != -1 || limit != -1)
    {
        request.fetchOffset = offset;
        request.fetchLimit = limit;
    }
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
	return [[[SimpleDataModel sharedDataModel] contextForCurrentThread] executeFetchRequest:request error:nil];
}

+ (NSArray *)find:(id)value byParam:(NSString *)param
{
    return [self find:value byParam:param sort:nil limit:-1 offset:-1];
}

+ (NSArray *)find:(id)value byParam:(NSString *)param sort:(NSString *)sort
{
    return [self find:value byParam:param sort:sort limit:-1 offset:-1];
}

+ (NSArray *)find:(id)value byParam:(NSString *)param sort:(NSString *)sort limit:(int)limit offset:(int)offset
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = [self predicateForValue:value key:param];
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
    if (offset != -1)
    {
        request.fetchOffset = offset;
    }
    if (limit != -1)
    {
        request.fetchLimit = limit;
    }
    
	return [[[SimpleDataModel sharedDataModel] contextForCurrentThread] executeFetchRequest:request error:nil];
}

+ (NSArray *)find:(NSDictionary *)params
{
    return [self find:params sort:nil limit:-1 offset:-1];
}

+ (NSArray *)find:(NSDictionary *)params sort:(NSString *)sort
{
    return [self find:params sort:sort limit:-1 offset:-1];
}

+ (NSArray *)find:(NSDictionary *)params sort:(NSString *)sort limit:(int)limit offset:(int)offset
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = [self predicateForDictionary:params];
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
    if (offset != -1)
    {
        request.fetchOffset = offset;
    }
    if (limit != -1)
    {
        request.fetchLimit = limit;
    }
    
	return [[[SimpleDataModel sharedDataModel] contextForCurrentThread] executeFetchRequest:request error:nil];
}

+ (NSArray *)findWithValues:(NSArray *)values byParam:(NSString *)param
{
    return [self findWithValues:values byParam:param sort:nil];
}

+ (NSArray *)findWithValues:(NSArray *)values byParam:(NSString *)param sort:(NSString *)sort
{
    if (values.count == 0 || param == nil)
    {
        return nil;
    }
    
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", param, values];
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
    
    return [[[SimpleDataModel sharedDataModel] contextForCurrentThread] executeFetchRequest:request error:nil];
}

#pragma mark - Getting entities by predicate

+ (NSArray *)findWithPredicate:(NSPredicate *)predicate
{
    return [self findWithPredicate:predicate sort:nil limit:-1 offset:-1];
}

+ (NSArray *)findWithPredicate:(NSPredicate *)predicate sort:(NSString *)sort
{
    return [self findWithPredicate:predicate sort:sort limit:-1 offset:-1];
}

+ (NSArray *)findWithPredicate:(NSPredicate *)predicate sort:(NSString *)sort limit:(int)limit offset:(int)offset
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = predicate;
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
    if (offset != -1)
    {
        request.fetchOffset = offset;
    }
    if (limit != -1)
    {
        request.fetchLimit = limit;
    }
    
	return [[[SimpleDataModel sharedDataModel] contextForCurrentThread] executeFetchRequest:request error:nil];
}

#pragma mark - Count

+ (NSInteger)count:(id)value byParam:(NSString *)param
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = [self predicateForValue:value key:param];
    [request setIncludesSubentities:NO];
    
    NSError *error = nil;
    NSUInteger count = [[NSManagedObjectContext contextForCurrentThread] countForFetchRequest:request error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error.localizedDescription);
    }
    
    return count;
}

+ (NSInteger)countWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = predicate;
    [request setIncludesSubentities:NO];
    
    NSError *error = nil;
    NSUInteger count = [[NSManagedObjectContext contextForCurrentThread] countForFetchRequest:request error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error.localizedDescription);
    }
    
    return count;
}

#pragma mark - Getting Fetch Request

+ (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate
{
    return [self fetchRequestWithPredicate:predicate sort:nil];
}

+ (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate sort:(NSString *)sort
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = predicate;
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
    return request;
}

+ (NSFetchRequest *)fetchRequestForFind:(id)value byParam:(NSString *)param
{
    return [self fetchRequestForFind:value byParam:param sort:nil];
}

+ (NSFetchRequest *)fetchRequestForFind:(id)value byParam:(NSString *)param sort:(NSString *)sort
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.predicate = [self predicateForValue:value key:param];
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
    return request;
}

+ (NSFetchRequest *)fetchRequestForAll
{
    return [self fetchRequestForAllWithSort:nil];
}

+ (NSFetchRequest *)fetchRequestForAllWithSort:(NSString *)sort
{
    NSFetchRequest *request = [self fetchRequestFromCurrentClass];
    request.sortDescriptors = [self sortDescriptorsFromString:sort];
    return request;
}

#pragma mark - Cache

+ (void)initCache
{
    [[SimpleDataModel sharedDataModel] addCacheEntity:[self all] forKey:NSStringFromClass(self)];
}

+ (void)clearCache
{
    [[SimpleDataModel sharedDataModel] removeCacheEntityForKey:NSStringFromClass(self)];
}

+ (instancetype)cachedObjectForKey:(NSString *)key withValue:(id)value
{
    if (value == nil)
    {
        return nil;
    }
    
    NSArray *objectsCache = [[SimpleDataModel sharedDataModel] cacheEntityForKey:NSStringFromClass(self)];
    for (id obj in objectsCache)
    {
        if ([[obj valueForKey:key] isEqual:value])
        {
            return obj;
        }
    }
    
    return nil;
}

#pragma mark - Merging

+ (void)mergeArray:(NSArray *)jsonArray withSet:(NSMutableSet *)objectsSet mergingActions:(SimpleDataMergeArrayBlock)block
{
    for (id value in jsonArray)
    {
        if (block)
        {
            NSManagedObject *object = block(value);
            if ([objectsSet containsObject:object])
            {
                [objectsSet removeObject:object];
            }
        }
    }
    [self deleteObjectsSet:objectsSet];
    [self save];
}

+ (void)mergeDictionary:(NSDictionary *)jsonDict withSet:(NSMutableSet *)objectsSet mergingActions:(SimpleDataDictionaryBlock)block
{
    for (NSString *key in jsonDict.allKeys)
    {
        if (block)
        {
            NSManagedObject *object = block(key, jsonDict[key]);
            if ([objectsSet containsObject:object])
            {
                [objectsSet removeObject:object];
            }
        }
    }
    [self deleteObjectsSet:objectsSet];
    [self save];
}

#pragma mark - Helpers

+ (NSFetchRequest *)fetchRequestFromCurrentClass
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [[[[SimpleDataModel sharedDataModel] managedModel] entitiesByName] objectForKey:NSStringFromClass([self class])];
    [fetchRequest setEntity:entity];
    return fetchRequest;
}

+ (NSPredicate *)predicateForValue:(id)param key:(NSString*)fieldName
{
    NSString *stringForPredicate = nil;
    if ([param isKindOfClass:[NSString class]])
    {
        stringForPredicate = [NSString stringWithFormat:@"%@='%@'", fieldName, param];
    }
    else
    {
        stringForPredicate = [NSString stringWithFormat:@"%@=%@", fieldName, param];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:stringForPredicate];
    return predicate;
}

+ (NSPredicate *)predicateForDictionary:(NSDictionary *)dict
{
    NSMutableString *resultPredicate = [NSMutableString string];
    
    for (NSString *fieldName in dict.allKeys)
    {
        id value = dict[fieldName];
        
        NSString *stringForPredicate = nil;
        if ([value isKindOfClass:[NSString class]])
        {
            stringForPredicate = [NSString stringWithFormat:@"%@='%@'", fieldName, value];
        }
        else if ([value isKindOfClass:[NSNull class]])
        {
            stringForPredicate = [NSString stringWithFormat:@"%@=nil", fieldName];
        }
        else
        {
            stringForPredicate = [NSString stringWithFormat:@"%@=%@", fieldName, value];
        }
        
        if (resultPredicate.length == 0)
        {
            [resultPredicate appendString:stringForPredicate];
        }
        else
        {
            [resultPredicate appendFormat:@"&& %@", stringForPredicate];
        }
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:resultPredicate];
    return predicate;
}

+ (NSPredicate *)ORpredicateForValues:(NSArray *)values byParam:(NSString *)param
{
    if (values == nil || param == nil)
    {
        return nil;
    }
    
    NSMutableString *resultPredicate = [NSMutableString string];
    
    for (id value in values)
    {
        NSString *stringForPredicate = nil;
        if ([value isKindOfClass:[NSString class]])
        {
            stringForPredicate = [NSString stringWithFormat:@"%@='%@'", param, value];
        }
        else
        {
            stringForPredicate = [NSString stringWithFormat:@"%@=%@", param, value];
        }
        
        if (resultPredicate.length == 0)
        {
            [resultPredicate appendString:stringForPredicate];
        }
        else
        {
            [resultPredicate appendFormat:@"|| %@", stringForPredicate];
        }
    }
    
    return [NSPredicate predicateWithFormat:resultPredicate];
}

+ (NSArray *)sortDescriptorsFromString:(NSString *)str
{
    if (str == nil || [str isEqualToString:@""])
    {
        return nil;
    }
    
    NSMutableArray *sortDescriptors = [NSMutableArray array];
    NSArray *fields = [str componentsSeparatedByString:@", "];
    
    NSArray *lastFieldComponents = [((NSString *)fields.lastObject) componentsSeparatedByString:@" "];
    BOOL isAscending = lastFieldComponents.count > 1 ? [self isAscendingString:lastFieldComponents[1]] : YES;
    
    for (NSString *sortField in fields)
    {
        NSArray *components = [sortField componentsSeparatedByString:@" "];
        [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:components[0] ascending:components.count > 1 ? [self isAscendingString:components[1]] : isAscending]];
    }
    
//    NSLog(@"%@", fields);
    
    return sortDescriptors;
}

+ (BOOL)isAscendingString:(NSString *)str
{
    static NSString *ascString = @"asc";
    static NSString *descString = @"desc";
    
    if ([str isEqualToString:ascString])
    {
        return YES;
    }
    else if ([str isEqualToString:descString])
    {
        return NO;
    }
    @throw [[NSException alloc] initWithName:@"Argument Exception" reason:@"Unknown sort param." userInfo:nil];
}

@end
