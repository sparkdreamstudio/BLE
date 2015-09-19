//
//  AutoDbObject.m
//  TestUpload
//
//  Created by 李响 on 15/6/15.
//  Copyright (c) 2015年 eqianzhuang. All rights reserved.
//

#import "AutoDbObject.h"
#import "AutoDbHandle.h"

@interface AutoDbObject ()
//@property (strong, nonatomic, readwrite) NSString* __id__;
@end

@implementation AutoDbObject
- (id)init
{
    self = [super init];
    if (self) {
        self.expireDate = [NSDate distantFuture];
        self.__id__ = [NSString stringWithFormat:@"%f",[[NSDate date]timeIntervalSince1970]];
    }
    return self;
}

/**
 *	@brief	插入到数据库中
 */
- (BOOL)insertToDb
{
    @synchronized(self){
        return [[AutoDbHandle shareDb] insertDbObject:self];
    }
}

/**
 *	@brief	更新某些数据
 *
 *	@param 	where 	条件
 *          例：name='xue zhang' and sex='男'
 *
 */
- (BOOL)updateToDbsWhere:(NSString *)where NS_DEPRECATED(10_0, 10_4, 2_0, 2_0)
{
    @synchronized(self){
        return [[AutoDbHandle shareDb] updateDbObject:self condition:where];
    }
}

/**
 *	@brief	保证数据唯一
 */
- (BOOL)replaceToDb;
{
    @synchronized(self){
        return [[AutoDbHandle shareDb] replaceDbObject:self];
    }
}

/**
 *	@brief	更新数据到数据库中
 *
 *	@return	更新成功YES,否则NO
 */
- (BOOL)updatetoDb
{
    @synchronized(self){
        NSString *condition = [NSString stringWithFormat:@"%@=%@", kDbId, self.__id__];
        return [[AutoDbHandle shareDb] updateDbObject:self condition:condition];
    }
}

/**
 *	@brief	从数据库删除对象
 *
 *	@return	更新成功YES,否则NO
 */
- (BOOL)removeFromDb
{
    @synchronized(self){
        NSMutableArray *subDbObjects = [NSMutableArray arrayWithCapacity:0];
        [self subDbObjects:subDbObjects];
        
        for (AutoDbObject *dbObj in subDbObjects) {
            NSString *where = [NSString stringWithFormat:@"%@='%@'", kDbId,dbObj.__id__];
            [[AutoDbHandle shareDb] removeDbObjects:[dbObj class] condition:where];
        }
        return YES;
    }
}

- (void)subDbObjects:(NSMutableArray *)subObj
{
    @synchronized(self){
        if (!self || ![self isKindOfClass:[AutoDbObject class]]) {
            return;
        }
        
        [subObj addObject:self];
        
        unsigned int count;
        AutoDbObject *obj = self;
        Class cls = [obj class];
        objc_property_t *properties = st_class_copyPropertyList(cls, &count);
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            NSString * key = [[NSString alloc]initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            id value = [obj valueForKey:key];
            
            if (value && (NSNull *)value != [NSNull null] && [value isKindOfClass:[AutoDbObject class]]) {
                [subObj addObject:value];
            }
            
            if ([value isKindOfClass:[NSArray class]]) {
                for (AutoDbObject *obj in value) {
                    if (obj && (NSNull *)obj != [NSNull null] && [obj isKindOfClass:[AutoDbObject class]]) {
                        [subObj addObject:obj];
                    }
                }
            }
            
            if ([value isKindOfClass:[NSDictionary class]]) {
                for (NSString *key in value) {
                    AutoDbObject *obj = value[key];
                    if (obj && (NSNull *)obj != [NSNull null] && [obj isKindOfClass:[AutoDbObject class]]) {
                        [subObj addObject:obj];
                    }
                }
            }
        }
        free(properties);
    }
}

/**
 *	@brief	查看是否包含对象
 *
 *	@param 	where 	条件
 *          例：name='xue zhang' and sex='男'
 *
 *	@return	包含YES,否则NO
 */
+ (BOOL)existDbObjectsWhere:(NSString *)where
{
    @synchronized(self){
        NSArray *objs = [[AutoDbHandle shareDb] selectDbObjects:[self class] condition:where orderby:nil];
        if ([objs count] > 0) {
            return YES;
        }
        return NO;
    }
}

/**
 *	@brief	删除某些数据
 *
 *	@param 	where 	条件
 *          例：name='xue zhang' and sex='男'
 *          填入 all 为全部删除
 *
 *	@return 成功YES,否则NO
 */
+ (BOOL)removeDbObjectsWhere:(NSString *)where
{
    @synchronized(self){
        return [[AutoDbHandle shareDb] removeDbObjects:[self class] condition:where];
    }
}

/**
 *	@brief	根据条件取出某些数据
 *
 *	@param 	where 	条件
 *          例：name='xue zhang' and sex='男'
 *          填入 all 为全部
 *
 *	@param 	orderby 	排序
 *          例：name and age
 *
 *	@return	数据
 */
+ (NSArray *)dbObjectsWhere:(NSString *)where orderby:(NSString *)orderby
{
    @synchronized(self){
        return [[AutoDbHandle shareDb] selectDbObjects:[self class] condition:where orderby:orderby];
    }
}

/**
 *	@brief	取出所有数据
 *
 *	@return	数据
 */
+ (NSMutableArray *)allDbObjects
{
    @synchronized(self){
        return [[AutoDbHandle shareDb] selectDbObjects:[self class] condition:@"all" orderby:nil];
    }
}

/*
 * 查看最后插入数据的行号
 */
+ (NSInteger)lastRowId;
{
    @synchronized(self){
        return [AutoDbHandle lastRowIdWithClass:self];
    }
}

/**
 *	@brief	objc to dictionary
 */
- (NSDictionary *)objcDictionary;
{
    @synchronized(self){
        unsigned int count;
        AutoDbObject *obj = self;
        
        Class cls = [obj class];
        objc_property_t *properties = st_class_copyPropertyList(cls, &count);
        
        NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            NSString * key = [[NSString alloc]initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            if ([key isEqualToString:@"hash"]||[key isEqualToString:@"superclass"]||[key isEqualToString:@"description"]||[key isEqualToString:@"debugDescription"]) {
                continue;
            }
            id value = [obj valueForKey:key];
            if (value) {
                [retDict setObject:value forKey:key];
            }
        }
        
        return retDict;
    }
}

/**
 *	@brief	objc from dictionary
 */
- (AutoDbObject *)objcFromDictionary:(NSDictionary *)dict;
{
    @synchronized(self){
        AutoDbObject *obj = [[[self class] alloc] init];
        
        unsigned int count;
        
        Class cls = [obj class];
        objc_property_t *properties = st_class_copyPropertyList(cls, &count);
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            NSString * key = [[NSString alloc]initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            id value = [dict objectForKey:key];
            if (value) {
                [obj setValue:value forKey:key];
            }
        }
        return obj;
    }
}
@end
