//
//  AutoDbHandle.m
//  TestUpload
//
//  Created by 李响 on 15/6/15.
//  Copyright (c) 2015年 eqianzhuang. All rights reserved.
//

#import "AutoDbHandle.h"
#import "AutoDbObject.h"
#import <CommonCrypto/CommonCrypto.h>

#define DBName @"autodb.sqlite"
#define DBParentPrefix @"STDBParentID_"
#define DBChildPrefix  @"STDBChildID_"
#define kPId  @"__pid__"
#define kCId  @"__cid__"

#ifdef DEBUG
#ifdef AUTODBBUG
#define AUTODBLog(fmt, ...) NSLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define AUTODBLog(...)
#endif
#else
#define AUTODBLog(...)
#endif

objc_property_t * st_class_copyPropertyList(Class cls, unsigned int *count);

enum {
    DBObjAttrInt,
    DBObjAttrFloat,
    DBObjAttrString,
    DBObjAttrData,
    DBObjAttrDate,
    DBObjAttrArray,
    DBObjAttrDictionary,
};

#define DBText  @"text"
#define DBInt   @"integer"
#define DBFloat @"real"
#define DBData  @"blob"

@interface NSDate (AutoDbHandle)

+ (NSDate *)dateWithString:(NSString *)s;
+ (NSString *)stringWithDate:(NSDate *)date;

@end

@implementation NSDate (AutoDbHandle)

+ (NSDate *)dateWithString:(NSString *)s;
{
    if (!s || (NSNull *)s == [NSNull null] || [s isEqual:@""]) {
        return nil;
    }
    //    NSTimeInterval t = [s doubleValue];
    //    return [NSDate dateWithTimeIntervalSince1970:t];
    
    return [[self dateFormatter] dateFromString:s];
}

+ (NSString *)stringWithDate:(NSDate *)date;
{
    if (!date || (NSNull *)date == [NSNull null] || [date isEqual:@""]) {
        return nil;
    }
    //    NSTimeInterval t = [date timeIntervalSince1970];
    //    return [NSString stringWithFormat:@"%lf", t];
    return [[self dateFormatter] stringFromDate:date];
}

+ (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return dateFormatter;
}

@end

@interface NSString (AutoDbHandle)

- (NSData *)base64Data;
- (NSString *)encryptWithKey:(NSString *)key;
- (NSString *)decryptWithKey:(NSString *)key;

@end

@interface NSObject (AutoDbHandle)

+ (id)objectWithString:(NSString *)s;
+ (NSString *)stringWithObject:(NSObject *)obj;

@end

@implementation NSObject (AutoDbHandle)

+ (id)objectWithString:(NSString *)s;
{
    if (!s || (NSNull *)s == [NSNull null] || [s isEqual:@""]) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:[s dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
}
+ (NSString *)stringWithObject:(NSObject *)obj;
{
    if (!obj || (NSNull *)obj == [NSNull null] || [obj isEqual:@""]) {
        return nil;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

@interface AutoDbHandle ()
@property (nonatomic) FMDatabase *dataBase;
@property (nonatomic, assign) BOOL isOpened;
@end
static AutoDbHandle* instance = nil;

@implementation AutoDbHandle

+ (instancetype)shareDb
{
    static AutoDbHandle *autodb;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        autodb = [[AutoDbHandle alloc]init];
    });
    return autodb;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (void)importDb:(NSString *)dbName
{
    @synchronized(self){
        NSString* dbPath = [AutoDbHandle dbPath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
            NSString* ext = [dbName pathExtension];
            NSString* extDbName = [dbName stringByDeletingPathExtension];
            NSString* extDbPath = [[NSBundle mainBundle] pathForResource:extDbName ofType:ext];
            if (extDbPath) {
                NSError *error;
                BOOL rc = [[NSFileManager defaultManager] copyItemAtPath:extDbPath toPath:dbPath error:&error];
                if (rc) {
                    NSArray *tables = [AutoDbHandle sqlite_tablename];
                    for (NSString *table in tables) {
                        NSMutableString *sql;
                        NSString *str = [NSString stringWithFormat:@"select sql from sqlite_master where type='table' and tbl_name='%@'", table];
                        AutoDbHandle *stdb = [AutoDbHandle shareDb];
                        [AutoDbHandle openDb];
                        
                        FMResultSet* resultSet = [stdb.dataBase executeQuery:str];
                        while ([resultSet next]) {
                            sql = [NSMutableString stringWithString:[resultSet stringForColumnIndex:0]];
                        }
                        
                        NSRange r = [sql rangeOfString:@"("];
                        
                        // 备份数据库
                        

                        
                        // 创建临时表
                        NSString *createTempDb = [NSString stringWithFormat:@"create temporary table t_backup%@", [sql substringFromIndex:r.location]];
                        
                        [stdb.dataBase executeStatements:createTempDb];
                            
                        
                        
                        //导入数据
                        NSString *importDb = [NSString stringWithFormat:@"insert into t_backup select * from %@", table];
                        [stdb.dataBase executeStatements:importDb];
                        
                        // 删除旧表
                        NSString *dropDb = [NSString stringWithFormat:@"drop table %@", table];
                        [stdb.dataBase executeStatements:dropDb];
                        
                        // 创建新表
                        NSMutableString *createNewTl = [NSMutableString stringWithString:sql];
                        if (r.location != NSNotFound) {
                            NSString *insertStr = [NSString stringWithFormat:@"\n\t%@ %@ primary key,", kDbId, DBInt];
                            [createNewTl insertString:insertStr atIndex:r.location + 1];
                        } else {
                            return;
                        }
                        NSString *createDb = [NSString stringWithFormat:@"%@", createNewTl];
                        [stdb.dataBase executeStatements:createDb];
                        
                        // 从临时表导入数据到新表
                        
                        NSString *cols = [[NSString alloc] init];
                        
                        NSString *t_str = [sql substringWithRange:NSMakeRange(r.location + 1, [sql length] - r.location - 2)];
                        t_str = [t_str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                        t_str = [t_str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                        t_str = [t_str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        
                        NSMutableArray *colsArr = [NSMutableArray arrayWithCapacity:0];
                        for (NSString *s in [t_str componentsSeparatedByString:@","]) {
                            NSString *s0 = [NSString stringWithString:s];
                            s0 = [s0 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            NSArray *a = [s0 componentsSeparatedByString:@" "];
                            NSString *s1 = a[0];
                            s1 = [s1 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                            [colsArr addObject:s1];
                        }
                        cols = [colsArr componentsJoinedByString:@", "];
                        
                        importDb = [NSString stringWithFormat:@"insert into %@ select (rowid-1) as %@, %@ from t_backup", table, kDbId, cols];
                        
                        [stdb.dataBase executeStatements:importDb];
                        
                        // 删除临时表
                        dropDb = [NSString stringWithFormat:@"drop table t_backup"];
                        [stdb.dataBase executeStatements:dropDb];
                    }
                }
                else
                {
                    NSLog(@"%@", error.localizedDescription);
                }
            }
            else
            {
                
            }
        }
    }
}


+ (BOOL)openDb
{
    @synchronized(self)
    {
        NSString* dbPath = [AutoDbHandle dbPath];
        AutoDbHandle *db = [AutoDbHandle shareDb];
        if (!db.dataBase) {
            db.dataBase = [[FMDatabase alloc]initWithPath:dbPath];
        }
        return [db.dataBase open];
    }
}

+ (BOOL)closeDb
{
    @synchronized(self)
    {
        //NSString* dbPath = [AutoDbHandle dbPath];
        AutoDbHandle *db = [AutoDbHandle shareDb];
        return [db.dataBase close];
    }
}

+ (NSString *)dbPath
{
    @synchronized(self){
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *path = [NSString stringWithFormat:@"%@/%@", document, DBName];
       
        return path;
    }
}

+ (void)dbTable:(Class)aClass addColumn:(NSString *)columnName
{
    @synchronized(self){
        [AutoDbHandle openDb];
        NSMutableString *sql = [NSMutableString stringWithCapacity:0];
        [sql appendString:@"alter table "];
        [sql appendString:NSStringFromClass(aClass)];
        if ([columnName isEqualToString:kDbId]) {
            NSString *colStr = [NSString stringWithFormat:@"%@ %@ primary key", kDbId, DBInt];
            [sql appendFormat:@" add column %@;", colStr];
        } else {
            [sql appendFormat:@" add column %@ %@;", columnName, DBText];
        }
        AutoDbHandle* db = [AutoDbHandle shareDb];
        [db.dataBase executeStatements:sql];
    }
}


+ (void)createDbTable:(Class)aClass
{
    @synchronized(self){
        [AutoDbHandle openDb];
        
        if ([AutoDbHandle sqlite_tableExist:aClass]) {
            AUTODBLog(@"数据库表%@已存在!", NSStringFromClass(aClass));
            return;
        }
        
        [AutoDbHandle openDb];
        
        NSMutableString *sql = [NSMutableString stringWithCapacity:0];
        [sql appendString:@"create table "];
        NSString *tableName = NSStringFromClass(aClass);
        NSArray* trueNameArray = [tableName componentsSeparatedByString:@"."];

        tableName = trueNameArray.lastObject;
        [sql appendString:tableName];
        [sql appendString:@"("];
        
        NSMutableArray *propertyArr = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *primaryKeys = [NSMutableArray arrayWithCapacity:0];
        
        [AutoDbHandle class:aClass getPropertyNameList:propertyArr primaryKeys:primaryKeys];
        
        NSString *propertyStr = [propertyArr componentsJoinedByString:@","];
        
        [sql appendString:propertyStr];
        
        NSMutableArray *primaryKeysArr = [NSMutableArray array];
        for (NSString *s in primaryKeys) {
            NSString *str = [NSString stringWithFormat:@"\"%@\"", s];
            [primaryKeysArr addObject:str];
        }
        
        NSString *priKeysStr = [primaryKeysArr componentsJoinedByString:@","];
        NSString *primaryKeysStr = [NSString stringWithFormat:@",primary key(%@)", priKeysStr];
        [sql appendString:primaryKeysStr];
        
        [sql appendString:@");"];
        
        AutoDbHandle* db = [AutoDbHandle shareDb];
        [db.dataBase executeStatements:sql];
    }
}

- (BOOL)insertDbObject:(AutoDbObject *)obj
{
    @synchronized(self){
        return [self insertDbObject:obj forced:YES];
    }
}

- (BOOL)replaceDbObject:(AutoDbObject *)obj
{
    @synchronized(self){
        return [self insertDbObject:obj forced:NO];
    }
}

- (BOOL)insertDbObject:(AutoDbObject *)obj forced:(BOOL)forced
{
    @synchronized(self){
        if (![AutoDbHandle openDb]) {
            return NO;
        }
        
        
        NSString *tableName = NSStringFromClass(obj.class);
        NSArray* trueNameArray = [tableName componentsSeparatedByString:@"."];
        tableName = trueNameArray.lastObject;
        
        if (![AutoDbHandle sqlite_tableExist:obj.class]) {
            [AutoDbHandle createDbTable:obj.class];
        }
        
        NSMutableArray *propertyArr = [NSMutableArray arrayWithCapacity:0];
        propertyArr = [NSMutableArray arrayWithArray:[AutoDbHandle sqlite_columns:obj.class]];
        
        NSUInteger argNum = [propertyArr count];
        
        NSString *insertSql = forced ? @"insert" : @"replace";
        NSMutableString *sql_NSString = [[NSMutableString alloc] initWithFormat:@"%@ into %@ values(?)", insertSql,tableName];
        NSRange range = [sql_NSString rangeOfString:@"?"];
        for (int i = 0; i < argNum - 1; i++) {
            [sql_NSString insertString:@",?" atIndex:range.location + 1];
        }
        
        AutoDbHandle* db = [AutoDbHandle shareDb];
        
        NSMutableArray* array = [NSMutableArray array];
        for (int i = 1; i <= argNum; i++) {
            NSString *key = propertyArr[i - 1][@"title"];
            
            id value;
            NSInteger rowId = [AutoDbHandle lastRowIdWithClass:obj.class];
            
            if ([key hasPrefix:DBParentPrefix]) {
                key = [key stringByReplacingOccurrencesOfString:DBParentPrefix withString:@""];
                
                value = [[NSString alloc] initWithFormat:@"%@", @(rowId+1)];
            } else {
                value = [obj valueForKey:key];
                NSObject *object = (NSObject *)value;
                if ([object isKindOfClass:[AutoDbObject class]]) {
                    NSInteger subDbRowId = [AutoDbHandle lastRowIdWithClass:object.class];
                    value = [[NSString alloc] initWithFormat:@"%@", @(subDbRowId+1)];
                    
                    AutoDbObject *dbObj = (AutoDbObject *)object;
                    [dbObj setValue:@(rowId+1) forKey:kPId];
                    [dbObj insertToDb];
                }
            }
            if(value == nil)
            {
                value = [NSNull null];
            }
            else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]])
            {
                
                objc_property_t property_t = class_getProperty(obj.class, [key UTF8String]);
                value = [AutoDbHandle valueForDbObjc_property_t:property_t dbValue:value _id:rowId];
            }
            
            [array addObject:value];
        }
        BOOL result = [db.dataBase executeUpdate:sql_NSString withArgumentsInArray:array];
        return result;
        
    }
}


- (NSMutableArray *)selectDbObjects:(Class)aClass condition:(NSString *)condition orderby:(NSString *)orderby
{
    //    @synchronized(self){
    [AutoDbHandle openDb];
    
    // 清除过期数据
//    [AutoDbHandle cleanExpireDbObject:aClass];
    
    NSMutableArray *array = nil;
    NSMutableString *selectstring = nil;
    NSString *tableName = NSStringFromClass(aClass);
    NSArray* trueNameArray = [tableName componentsSeparatedByString:@"."];
    tableName = trueNameArray.lastObject;
    selectstring = [[NSMutableString alloc] initWithFormat:@"select %@ from %@", @"*", tableName];
    if (condition != nil || [condition length] != 0) {
        if (![[condition lowercaseString] isEqualToString:@"all"]) {
            [selectstring appendFormat:@" where %@", condition];
        }
    }
    
    if (orderby != nil || [orderby length] != 0) {
        if (![[orderby lowercaseString] isEqualToString:@"no"]) {
            [selectstring appendFormat:@" order by %@", orderby];
        }
    }
    
    AutoDbHandle *db = [AutoDbHandle shareDb];

    FMResultSet* resultSet = [db.dataBase executeQuery:selectstring];
    while ([resultSet next]) {
        AutoDbObject* obj = [[NSClassFromString(NSStringFromClass(aClass)) alloc] init];
        for (int i = 0; i < resultSet.columnCount; i++) {
            NSString* key = [resultSet columnNameForIndex:i];
            id value = [resultSet objectForColumnIndex:i];
            if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNull class]])
            {
                objc_property_t property_t = class_getProperty(obj.class, [key UTF8String]);
                value = [AutoDbHandle valueForObjc_property_t:property_t dbValue:value];
            }
            [obj setValue:value forKey:key];
        }
        if (array == nil) {
            array = [[NSMutableArray alloc] initWithObjects:obj, nil];
        } else {
            [array addObject:obj];
        }
    }
    
    
    return array;
    //    }
}


- (BOOL)removeDbObjects:(Class)aClass condition:(NSString *)condition
{
    @synchronized(self){
        [AutoDbHandle openDb];
        
        NSString *tableName = NSStringFromClass(aClass);
        NSArray* trueNameArray = [tableName componentsSeparatedByString:@"."];
        tableName = trueNameArray.lastObject;
        
        // 删掉表
        if (!condition || [[condition lowercaseString] isEqualToString:@"all"]) {
            return [AutoDbHandle removeDbTable:aClass];
        }
        
        NSMutableString *createStr;
        
        if ([condition length] > 0) {
            createStr = [NSMutableString stringWithFormat:@"delete from %@ where %@", tableName, condition];
        } else {
            createStr = [NSMutableString stringWithFormat:@"delete from %@", tableName];
        }
        
        AutoDbHandle *db = [AutoDbHandle shareDb];
        return [db.dataBase executeUpdate:createStr];
    }
}


- (BOOL)updateDbObject:(AutoDbObject *)obj condition:(NSString *)condition
{
    @synchronized(self){
        [AutoDbHandle openDb];
//        NSMutableArray *propertyTypeArr = [NSMutableArray arrayWithArray:[AutoDbHandle sqlite_columns:obj.class]];
        NSString *tableName = NSStringFromClass(obj.class);
        NSArray* trueNameArray = [tableName componentsSeparatedByString:@"."];
        tableName = trueNameArray.lastObject;
        NSMutableArray *propertyArr = [NSMutableArray arrayWithCapacity:0];
        AutoDbHandle *db = [AutoDbHandle shareDb];
        
        unsigned int count;
        Class cls = [obj class];
        objc_property_t *properties = st_class_copyPropertyList(cls, &count);
        
        NSMutableArray *keys = [NSMutableArray arrayWithCapacity:0];
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            NSString * key = [[NSString alloc]initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            id objValue = [obj valueForKey:key];
            id value = [AutoDbHandle valueForDbObjc_property_t:property dbValue:objValue _id:-1];
            
            if (value && (NSNull *)value != [NSNull null]) {
                NSString *bindValue = [NSString stringWithFormat:@"%@=?", key];
                [propertyArr addObject:bindValue];
                [keys addObject:key];
            }
        }
        
        NSString *newValue = [propertyArr componentsJoinedByString:@","];
        
        NSMutableString *createStr = [NSMutableString stringWithFormat:@"update %@ set %@ where %@", tableName, newValue, condition];
        NSMutableArray* array = [NSMutableArray array];
        for (NSString *key in keys) {
            if ([key isEqualToString:kDbId]) {
                continue;
            }
            id value = [obj valueForKey:key];
            [array addObject:value];
        }
        free(properties);
        return [db.dataBase executeUpdate:createStr withArgumentsInArray:array];
    }
}


+ (BOOL)removeDbTable:(Class)aClass
{
    @synchronized(self){
        [AutoDbHandle openDb];
        NSMutableString *sql = [NSMutableString stringWithCapacity:0];
        [sql appendString:@"drop table if exists "];
        [sql appendString:NSStringFromClass(aClass)];
        
        AutoDbHandle* db = [AutoDbHandle shareDb];
        return [db.dataBase executeStatements:sql];
    }
}

+ (BOOL)cleanExpireDbObject:(Class)aClass
{
    NSString *dateStr = [NSDate stringWithDate:[NSDate date]];
    NSString *condition = [NSString stringWithFormat:@"expireDate<'%@'", dateStr];
    return [[AutoDbHandle shareDb] removeDbObjects:aClass condition:condition];
}


#pragma mark - other method

/*
 * 查看所有表名
 */
+ (NSArray *)sqlite_tablename {
    @synchronized(self){
        [AutoDbHandle openDb];
        
        NSMutableArray *tablenameArray = [[NSMutableArray alloc] init];
        NSString *str = [NSString stringWithFormat:@"select tbl_name from sqlite_master where type='table'"];
        AutoDbHandle* db = [AutoDbHandle shareDb];
        FMResultSet* resultSet = [db.dataBase executeQuery:str];
        while ([resultSet next]) {
            NSString* tableName = [resultSet stringForColumnIndex:0];
            if (tableName) {
                [tablenameArray addObject:tableName];
            }
            
        }
        return tablenameArray;
    }
}

/*
 * 判断一个表是否存在；
 */
+ (BOOL)sqlite_tableExist:(Class)aClass {
    @synchronized(self){
        NSArray *tableArray = [self sqlite_tablename];
        NSString *tableName = NSStringFromClass(aClass);
        NSArray* trueNameArray = [tableName componentsSeparatedByString:@"."];
        tableName = trueNameArray.lastObject;

        for (NSString *tablename in tableArray) {
            if ([tablename isEqualToString:tableName]) {
                return YES;
            }
        }
        return NO;
    }
}


+ (NSArray *)sqlite_columns:(Class)cls
{
    NSString *table = NSStringFromClass(cls);
    NSArray* trueNameArray = [table componentsSeparatedByString:@"."];
    table = trueNameArray.lastObject;
    NSMutableString *sql;
    NSString *str = [NSString stringWithFormat:@"select sql from sqlite_master where type='table' and tbl_name='%@'", table];
    AutoDbHandle *db = [AutoDbHandle shareDb];
    [AutoDbHandle openDb];
    
    FMResultSet* resultSet = [db.dataBase executeQuery:str];
    while ([resultSet next]) {
        sql = [NSMutableString stringWithString:[resultSet stringForColumnIndex:0]];
    }
    
    NSRange r = [sql rangeOfString:@"("];
    
    NSString *t_str = [sql substringWithRange:NSMakeRange(r.location + 1, [sql length] - r.location - 2)];
    t_str = [t_str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    t_str = [t_str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    t_str = [t_str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSRange primaryRangeR = [t_str rangeOfString:@",primary key\\(.*\\)" options:NSRegularExpressionSearch];
    //        NSLog(@"%@", NSStringFromRange(primaryRangeR));
    if (primaryRangeR.location != NSNotFound) {
        t_str = [t_str stringByReplacingCharactersInRange:primaryRangeR withString:@""];
    }
    
    NSMutableArray *colsArr = [NSMutableArray arrayWithCapacity:0];
    NSArray *strs = [t_str componentsSeparatedByString:@","];
    
    for (NSString *s in strs) {
        if ([s hasPrefix:@"primary key"] || s.length == 0) {
            continue;
        }
        NSString *s0 = [NSString stringWithString:s];
        s0 = [s0 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *a = [s0 componentsSeparatedByString:@" "];
        NSString *s1 = a[0];
        NSString *type = a.count >= 2 ? a[1] : @"blob";
        type = [type stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        type = [type stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        s1 = [s1 stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        [colsArr addObject:@{@"type": type, @"title": s1}];
    }
    return colsArr;
}

+ (NSString *)dbTypeConvertFromObjc_property_t:(objc_property_t)property
{
    @synchronized(self){
        char * type = property_copyAttributeValue(property, "T");
        
        switch(type[0]) {
            case 'f' : //float
            case 'd' : //double
            {
                free(type);
                return DBFloat;
            }
                break;
                
            case 'c':   // char
            case 's' : //short
            case 'i':   // int
            case 'l':   // long
            case 'q':   //long long
            case 'C':
            case 'S':
            case 'I':
            case 'L':
            case 'Q':
            {
                free(type);
                return DBInt;
            }
                break;
                
            case '*':   // char *
                break;
                
            case '@' : //ObjC object
                //Handle different clases in here
            {
                NSString *cls = [NSString stringWithUTF8String:type];
                cls = [cls stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                cls = [cls stringByReplacingOccurrencesOfString:@"@" withString:@""];
                cls = [cls stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSString class]]) {
                    free(type);
                    return DBText;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSNumber class]]) {
                    free(type);
                    return DBText;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSDictionary class]]) {
                    free(type);
                    return DBText;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSArray class]]) {
                    free(type);
                    return DBText;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSDate class]]) {
                    free(type);
                    return DBText;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSData class]]) {
                    free(type);
                    return DBData;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[AutoDbObject class]]) {
                    free(type);
                    return DBText;
                }
            }
                break;
        }
        free(type);
        return DBText;
    }
}

+ (NSString *)dbNameConvertFromObjc_property_t:(objc_property_t)property
{
    @synchronized(self){
        NSString *key = [[NSString alloc]initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        char * type = property_copyAttributeValue(property, "T");
        
        switch(type[0]) {
            case '@' : //ObjC object
                //Handle different clases in here
            {
                NSString *cls = [NSString stringWithUTF8String:type];
                cls = [cls stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                cls = [cls stringByReplacingOccurrencesOfString:@"@" withString:@""];
                cls = [cls stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                
                if ([NSClassFromString(cls) isSubclassOfClass:[AutoDbObject class]]) {
                    NSString *retKey = key;
                    free(type);
                    return retKey;
                }
            }
                break;
        }
        free(type);
        return key;
    }
}

+ (id)valueForObjc_property_t:(objc_property_t)property dbValue:(id)dbValue
{
    @synchronized(self){
        char * type = property_copyAttributeValue(property, "T");
        //    NSString *key = [[NSString alloc]initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        
        switch(type[0]) {
            case 'f' : //float
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue floatValue]];
            }
                break;
            case 'd' : //double
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue doubleValue]];
            }
                break;
                
            case 'c':   // char
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue charValue]];
            }
                break;
            case 's' : //short
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue shortValue]];
            }
                break;
            case 'i':   // int
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue longValue]];
            }
                break;
            case 'l':   // long
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue longValue]];
            }
                break;
            case 'q':
            {
                free(type);
                return [NSNumber numberWithLongLong:[dbValue longLongValue]];
            }
            case 'C':   // char
            {
                free(type);
                return [NSNumber numberWithUnsignedChar:[dbValue charValue]];
            }
                break;
            case 'S' : //short
            {
                free(type);
                return [NSNumber numberWithUnsignedShort:[dbValue shortValue]];
            }
                break;
            case 'I':   // int
            {
                free(type);
                return [NSNumber numberWithUnsignedLong:[dbValue longValue]];
            }
                break;
            case 'L':   // long
            {
                free(type);
                return [NSNumber numberWithUnsignedLong:[dbValue longValue]];
            }
                break;
            case 'Q':
            {
                free(type);
                return [NSNumber numberWithUnsignedLongLong:[dbValue longLongValue]];
            }
                
            case '*':   // char *
                break;
                
            case '@' : //ObjC object
                //Handle different clases in here
            {
                NSString *cls = [NSString stringWithUTF8String:type];
                cls = [cls stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                cls = [cls stringByReplacingOccurrencesOfString:@"@" withString:@""];
                cls = [cls stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSString class]]) {
                    if ([dbValue isKindOfClass:[NSNull class]]) {
                        return @"";
                    }
                    NSString *retStr = [dbValue copy];
                    if ([[self shareDb] encryptEnable]) {
                        retStr = [retStr decryptWithKey:[self encryptKey]];
                    }
                    free(type);
                    return retStr;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSNumber class]]) {
                    free(type);
                    return [NSNumber numberWithDouble:[dbValue doubleValue]];
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSDictionary class]]) {
                    NSString *retStr = [dbValue copy];
                    if ([[self shareDb] encryptEnable]) {
                        retStr = [retStr decryptWithKey:[self encryptKey]];
                    }
                    NSDictionary *dict = [NSDictionary objectWithString:[NSString stringWithFormat:@"%@", retStr]];
                    NSMutableDictionary *results = [NSMutableDictionary dictionaryWithDictionary:dict];
                    
                    for (NSString *key in dict) {
                        NSObject *obj = dict[key];
                        if ([obj isKindOfClass:[NSString class]]) {
                            NSString *dbObj = [obj copy];
                            if ([dbObj hasPrefix:DBChildPrefix]) {
                                NSString *rowidStr = [dbObj stringByReplacingOccurrencesOfString:DBChildPrefix withString:@""];
                                NSArray *arr = [rowidStr componentsSeparatedByString:@","];
                                NSString *clsName = arr[0];
                                NSString *rowid = arr[1];
                                
                                NSString *where = [NSString stringWithFormat:@"%@='%@'", kDbId, rowid];
                                
                                AutoDbObject *child = (AutoDbObject *)[NSClassFromString(clsName) dbObjectsWhere:where orderby:nil][0];
                                [results setObject:child forKey:key];
                                
                                continue;
                            }
                        }
                        [results setObject:obj forKey:key];
                    }
                    free(type);
                    return results;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSArray class]]) {
                    
                    NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
                    
                    NSString *retStr = [dbValue copy];
                    if ([[self shareDb] encryptEnable]) {
                        retStr = [retStr decryptWithKey:[self encryptKey]];
                    }
                    NSArray *dbArr = [NSArray objectWithString:[NSString stringWithFormat:@"%@", retStr]];
                    
                    for (NSObject *obj in dbArr) {
                        
                        if ([obj isKindOfClass:[NSString class]]) {
                            NSString *dbObj = [obj copy];
                            if ([dbObj hasPrefix:DBChildPrefix]) {
                                NSString *rowidStr = [dbObj stringByReplacingOccurrencesOfString:DBChildPrefix withString:@""];
                                NSArray *arr = [rowidStr componentsSeparatedByString:@","];
                                NSString *clsName = arr[0];
                                NSString *rowid = arr[1];
                                
                                NSString *where = [NSString stringWithFormat:@"%@='%@'", kDbId, rowid];
                                
                                AutoDbObject *child = (AutoDbObject *)[NSClassFromString(clsName) dbObjectsWhere:where orderby:nil][0];
                                if(child)
                                    [results addObject:child];
                                
                                continue;
                            }
                        }
                        
                        [results addObject:obj];
                    }
                    free(type);
                    return results;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSDate class]]) {
                    NSString *retStr = [dbValue copy];
                    if ([[self shareDb] encryptEnable]) {
                        retStr = [retStr decryptWithKey:[self encryptKey]];
                    }
                    free(type);
                    return [NSDate dateWithString:[NSString stringWithFormat:@"%@", retStr]];
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSValue class]]) {
                    free(type);
                    return [NSData dataWithData:dbValue];
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[AutoDbObject class]]) {
                    
                    NSString *where = [[NSString alloc] initWithFormat:@"%@=%@", kDbId, dbValue];
                    
                    NSMutableArray *results = [NSClassFromString(cls) dbObjectsWhere:where orderby:nil];
                    free(type);
                    if (results.count > 0) {
                        AutoDbObject *obj = results[0];
                        return obj;
                    } else {
                        return nil;
                    }
                }
            }
                break;
        }
        
        NSString* typeString =[NSString stringWithFormat:@"%s",type];
        free(type);
        if ([typeString rangeOfString:@"NSRange"].length !=0) {
            return [NSValue valueWithRange:NSRangeFromString(dbValue)];
        }
        
        return dbValue;
    }
}

+ (id)valueForDbObjc_property_t:(objc_property_t)property dbValue:(id)dbValue _id:(NSInteger)_id
{
    @synchronized(self){
        if (!dbValue) {
            return nil;
        }
        char * type = property_copyAttributeValue(property, "T");
        
        switch(type[0]) {
            case 'f' : //float
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue floatValue]];
            }
                break;
            case 'd' : //double
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue doubleValue]];
            }
                break;
                
            case 'c':   // char
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue charValue]];
            }
                break;
            case 's' : //short
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue shortValue]];
            }
                break;
            case 'i':   // int
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue longValue]];
            }
                break;
            case 'l':   // long
            {
                free(type);
                return [NSNumber numberWithDouble:[dbValue longValue]];
            }
                break;
                
            case '*':   // char *
                break;
                
            case '@' : //ObjC object
                //Handle different clases in here
            {
                NSString *cls = [NSString stringWithUTF8String:type];
                cls = [cls stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                cls = [cls stringByReplacingOccurrencesOfString:@"@" withString:@""];
                cls = [cls stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSString class]]) {
                    NSString *retStr = [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"%@", dbValue]];
                    if ([[self shareDb] encryptEnable]) {
                        retStr = [retStr encryptWithKey:[self encryptKey]];
                    }
                    free(type);
                    return retStr;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSNumber class]]) {
                    free(type);
                    return [NSNumber numberWithDouble:[dbValue doubleValue]];
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:0];
                    
                    for (NSString *key in dbValue) {
                        NSObject *obj = dbValue[key];
                        
                        if ([obj isKindOfClass:[AutoDbObject class]]) {
                            AutoDbObject *dbObject = (AutoDbObject *)obj;
                            
                            //[dbObject setValue:@(_id) forKey:kPId];
                            [dbObject replaceToDb];
                            
                            NSString *rowid = [dbObject __id__];
                            
                            [results setObject:[NSString stringWithFormat:@"%@%@,%@", DBChildPrefix, NSStringFromClass(obj.class),rowid]  forKey:key];
                        } else {
                            [results setObject:obj forKey:key];
                        }
                    }
                    
                    NSString *retStr = [NSString stringWithFormat:@"%@", [NSDictionary stringWithObject:results]];
                    if ([[self shareDb] encryptEnable]) {
                        retStr = [retStr encryptWithKey:[self encryptKey]];
                    }
                    free(type);
                    return retStr;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSArray class]]) {
                    
                    NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
                    for (NSObject *obj in (NSArray *)dbValue) {
                        if ([obj isKindOfClass:[AutoDbObject class]]) {
                            AutoDbObject *dbObject = (AutoDbObject *)obj;
                            
                            //[dbObject setValue:@(_id) forKey:kPId];
                            [dbObject replaceToDb];
                            
//                            NSInteger rowid = [dbObject.class lastRowId];
                            
                            [results addObject:[NSString stringWithFormat:@"%@%@,%@", DBChildPrefix, NSStringFromClass(obj.class),dbObject.__id__]];
                        } else {
                            [results addObject:obj];
                        }
                    }
                    NSString *retStr = [NSString stringWithFormat:@"%@", [NSArray stringWithObject:results]];
                    if ([[self shareDb] encryptEnable]) {
                        retStr = [retStr encryptWithKey:[self encryptKey]];
                    }
                    free(type);
                    return retStr;
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSDate class]]) {
                    if ([dbValue isKindOfClass:[NSDate class]]) {
                        NSString *retStr = [NSString stringWithFormat:@"%@", [NSDate stringWithDate:dbValue]];
                        if ([[self shareDb] encryptEnable]) {
                            retStr = [retStr encryptWithKey:[self encryptKey]];
                        }
                        free(type);
                        return retStr;
                    } else {
                        free(type);
                        return @"";
                    }
                    
                }
                
                
                if ([NSClassFromString(cls) isSubclassOfClass:[NSValue class]]) {
                    free(type);
                    return [NSData dataWithData:dbValue];
                }
                
                if ([NSClassFromString(cls) isSubclassOfClass:[AutoDbObject class]]) {
                    free(type);
                    return dbValue;
                }
            }
                break;
        }
        free(type);
        return dbValue;
    }
}

+ (BOOL)isOpened
{
    @synchronized(self){
        return [[self shareDb] isOpened];
    }
}

+ (void)class:(Class)aClass getPropertyNameList:(NSMutableArray *)proName primaryKeys:(NSMutableArray *)primaryKeys
{
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(aClass, &count);
    
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString * key = [AutoDbHandle dbNameConvertFromObjc_property_t:property];
        NSString *type = [AutoDbHandle dbTypeConvertFromObjc_property_t:property];
        NSString *proStr;
        if ([key isEqualToString:@"hash"]||[key isEqualToString:@"superclass"]||[key isEqualToString:@"description"]||[key isEqualToString:@"debugDescription"]) {
            continue;
        }
        if ([key isEqualToString:kDbId]) {
            [primaryKeys addObject:kDbId];
            proStr = [NSString stringWithFormat:@"%@ %@", kDbId, DBText];
        } else if ([key hasSuffix:kDbKeySuffix]) {
            [primaryKeys addObject:key];
            proStr = [NSString stringWithFormat:@"%@ %@", key, type];
        } else {
            proStr = [NSString stringWithFormat:@"%@ %@", key, type];
        }
        
        [proName addObject:proStr];
    }
    
    if (aClass == [AutoDbObject class]) {
        return;
    }
    [AutoDbHandle class:[aClass superclass] getPropertyNameList:proName primaryKeys:primaryKeys];
    
}

+ (void)class:(Class)aClass getPropertyKeyList:(NSMutableArray *)proName
{
    @synchronized(self){
        unsigned int count;
        objc_property_t *properties = class_copyPropertyList(aClass, &count);
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            NSString * key = [[NSString alloc]initWithCString:property_getName(property)  encoding:NSUTF8StringEncoding];
            [proName addObject:key];
        }
        free(properties);
        if (aClass == [AutoDbObject class]) {
            return;
        }
        [AutoDbHandle class:[aClass superclass] getPropertyKeyList:proName];
    }
}

+ (void)class:(Class)aClass getPropertyTypeList:(NSMutableArray *)proName
{
    @synchronized(self){
        unsigned int count;
        objc_property_t *properties = class_copyPropertyList(aClass, &count);
        
        for (int i = 0; i < count; i++) {
            objc_property_t property = properties[i];
            NSString *type = [AutoDbHandle dbTypeConvertFromObjc_property_t:property];
            [proName addObject:type];
        }
        free(properties);
        
        if (aClass == [AutoDbObject class]) {
            return;
        }
        [AutoDbHandle class:[aClass superclass] getPropertyTypeList:proName];
    }
}

+ (NSInteger)lastRowIdWithClass:(Class)aClass;
{
    @synchronized(self){
        NSInteger rowId = 0;
        [self openDb];
        

        
        NSMutableString *sql = [NSMutableString stringWithCapacity:0];
        [sql appendString:@"select max(rowid) as rowId from "];
        [sql appendString:NSStringFromClass(aClass)];
        [sql appendString:@";"];
        
        AutoDbHandle* db = [AutoDbHandle shareDb];
        FMResultSet* resultSet = [db.dataBase executeQuery:sql];
        
        while ([resultSet next]) {
            rowId = [resultSet intForColumnIndex:0];
        }

//        if (sqlite3_prepare_v2([[self shareDb] sqlite3DB], [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
//            sqlite3_step(stmt);
//            int value = sqlite3_column_int(stmt, 0);
//            rowId = value;
//        }
//        sqlite3_finalize(stmt);
//        stmt = NULL;
        
        return rowId;
    }
}

+ (NSString *)encryptKey
{
    return @"stlwtr";
}

#pragma mark -


@end

@interface NSData (STDbHandle)

- (NSString *)base64String;
/** 加密 */
- (NSData *)aes256EncryptWithKey:(NSString *)key;
/** 解密 */
- (NSData *)aes256DecryptWithKey:(NSString *)key;

@end

@implementation NSData (STDbHandle)

- (NSString *)base64String
{
    NSData *data = [self copy];
    
    NSString *encoding = nil;
    unsigned char *encodingBytes = NULL;
    @try {
        static char encodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        static NSUInteger paddingTable[] = {0,2,1};
        //                 Table 1: The Base 64 Alphabet
        //
        //    Value Encoding  Value Encoding  Value Encoding  Value Encoding
        //        0 A            17 R            34 i            51 z
        //        1 B            18 S            35 j            52 0
        //        2 C            19 T            36 k            53 1
        //        3 D            20 U            37 l            54 2
        //        4 E            21 V            38 m            55 3
        //        5 F            22 W            39 n            56 4
        //        6 G            23 X            40 o            57 5
        //        7 H            24 Y            41 p            58 6
        //        8 I            25 Z            42 q            59 7
        //        9 J            26 a            43 r            60 8
        //       10 K            27 b            44 s            61 9
        //       11 L            28 c            45 t            62 +
        //       12 M            29 d            46 u            63 /
        //       13 N            30 e            47 v
        //       14 O            31 f            48 w         (pad) =
        //       15 P            32 g            49 x
        //       16 Q            33 h            50 y
        
        NSUInteger dataLength = [data length];
        NSUInteger encodedBlocks = (dataLength * 8) / 24;
        NSUInteger padding = paddingTable[dataLength % 3];
        if( padding > 0 ) encodedBlocks++;
        NSUInteger encodedLength = encodedBlocks * 4;
        
        encodingBytes = malloc(encodedLength);
        if( encodingBytes != NULL ) {
            NSUInteger rawBytesToProcess = dataLength;
            NSUInteger rawBaseIndex = 0;
            NSUInteger encodingBaseIndex = 0;
            unsigned char *rawBytes = (unsigned char *)[data bytes];
            unsigned char rawByte1, rawByte2, rawByte3;
            while( rawBytesToProcess >= 3 ) {
                rawByte1 = rawBytes[rawBaseIndex];
                rawByte2 = rawBytes[rawBaseIndex+1];
                rawByte3 = rawBytes[rawBaseIndex+2];
                encodingBytes[encodingBaseIndex] = encodingTable[((rawByte1 >> 2) & 0x3F)];
                encodingBytes[encodingBaseIndex+1] = encodingTable[((rawByte1 << 4) & 0x30) | ((rawByte2 >> 4) & 0x0F) ];
                encodingBytes[encodingBaseIndex+2] = encodingTable[((rawByte2 << 2) & 0x3C) | ((rawByte3 >> 6) & 0x03) ];
                encodingBytes[encodingBaseIndex+3] = encodingTable[(rawByte3 & 0x3F)];
                
                rawBaseIndex += 3;
                encodingBaseIndex += 4;
                rawBytesToProcess -= 3;
            }
            rawByte2 = 0;
            switch (dataLength-rawBaseIndex) {
                case 2:
                    rawByte2 = rawBytes[rawBaseIndex+1];
                case 1:
                    rawByte1 = rawBytes[rawBaseIndex];
                    encodingBytes[encodingBaseIndex] = encodingTable[((rawByte1 >> 2) & 0x3F)];
                    encodingBytes[encodingBaseIndex+1] = encodingTable[((rawByte1 << 4) & 0x30) | ((rawByte2 >> 4) & 0x0F) ];
                    encodingBytes[encodingBaseIndex+2] = encodingTable[((rawByte2 << 2) & 0x3C) ];
                    // we can skip rawByte3 since we have a partial block it would always be 0
                    break;
            }
            // compute location from where to begin inserting padding, it may overwrite some bytes from the partial block encoding
            // if their value was 0 (cases 1-2).
            encodingBaseIndex = encodedLength - padding;
            while( padding-- > 0 ) {
                encodingBytes[encodingBaseIndex++] = '=';
            }
            encoding = [[NSString alloc] initWithBytes:encodingBytes length:encodedLength encoding:NSASCIIStringEncoding];
        }
    }
    @catch (NSException *exception) {
        encoding = nil;
        NSLog(@"WARNING: error occured while tring to encode base 32 data: %@", exception);
    }
    @finally {
        if( encodingBytes != NULL ) {
            free( encodingBytes );
        }
    }
    return encoding;
}

/** 加密 */
- (NSData *)aes256EncryptWithKey:(NSString *)key
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

/** 解密 */
- (NSData *)aes256DecryptWithKey:(NSString *)key
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

@end

@implementation NSString (STDbHandle)

- (NSData *)base64Data;
{
    NSString *encoding = [self copy];
    
    NSData *data = nil;
    unsigned char *decodedBytes = NULL;
    @try {
#define __ 255
        static char decodingTable[256] = {
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x00 - 0x0F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x10 - 0x1F
            __,__,__,__, __,__,__,__, __,__,__,62, __,__,__,63,  // 0x20 - 0x2F
            52,53,54,55, 56,57,58,59, 60,61,__,__, __, 0,__,__,  // 0x30 - 0x3F
            __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,  // 0x40 - 0x4F
            15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,  // 0x50 - 0x5F
            __,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,  // 0x60 - 0x6F
            41,42,43,44, 45,46,47,48, 49,50,51,__, __,__,__,__,  // 0x70 - 0x7F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x80 - 0x8F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x90 - 0x9F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xA0 - 0xAF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xB0 - 0xBF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xC0 - 0xCF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xD0 - 0xDF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xE0 - 0xEF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xF0 - 0xFF
        };
        encoding = [encoding stringByReplacingOccurrencesOfString:@"=" withString:@""];
        NSData *encodedData = [encoding dataUsingEncoding:NSASCIIStringEncoding];
        unsigned char *encodedBytes = (unsigned char *)[encodedData bytes];
        
        NSUInteger encodedLength = [encodedData length];
        NSUInteger encodedBlocks = (encodedLength+3) >> 2;
        NSUInteger expectedDataLength = encodedBlocks * 3;
        
        unsigned char decodingBlock[4];
        
        decodedBytes = malloc(expectedDataLength);
        if( decodedBytes != NULL ) {
            
            NSUInteger i = 0;
            NSUInteger j = 0;
            NSUInteger k = 0;
            unsigned char c;
            while( i < encodedLength ) {
                c = decodingTable[encodedBytes[i]];
                i++;
                if( c != __ ) {
                    decodingBlock[j] = c;
                    j++;
                    if( j == 4 ) {
                        decodedBytes[k] = (decodingBlock[0] << 2) | (decodingBlock[1] >> 4);
                        decodedBytes[k+1] = (decodingBlock[1] << 4) | (decodingBlock[2] >> 2);
                        decodedBytes[k+2] = (decodingBlock[2] << 6) | (decodingBlock[3]);
                        j = 0;
                        k += 3;
                    }
                }
            }
            
            // Process left over bytes, if any
            if( j == 3 ) {
                decodedBytes[k] = (decodingBlock[0] << 2) | (decodingBlock[1] >> 4);
                decodedBytes[k+1] = (decodingBlock[1] << 4) | (decodingBlock[2] >> 2);
                k += 2;
            } else if( j == 2 ) {
                decodedBytes[k] = (decodingBlock[0] << 2) | (decodingBlock[1] >> 4);
                k += 1;
            }
            data = [[NSData alloc] initWithBytes:decodedBytes length:k];
        }
    }
    @catch (NSException *exception) {
        data = nil;
        NSLog(@"WARNING: error occured while decoding base 32 string: %@", exception);
    }
    @finally {
        if( decodedBytes != NULL ) {
            free( decodedBytes );
        }
    }
    return data;
}

- (NSString *)encryptWithKey:(NSString *)key;
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSData *eData = [data aes256EncryptWithKey:key];
    NSString *base64String = [eData base64String];
    return base64String;
}

- (NSString *)decryptWithKey:(NSString *)key;
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSData *eData = [data aes256DecryptWithKey:key];
    NSString *base64String = [eData base64String];
    return base64String;
}

@end

objc_property_t * st_class_copyPropertyList(Class cls, unsigned int *count)
{
    if (![cls isSubclassOfClass:[AutoDbObject class]]) {
        return NULL;
    };
    objc_property_t *properties = class_copyPropertyList(cls, count);
    if (!properties) {
        while (1) {
            cls = [cls superclass];
            properties = class_copyPropertyList(cls, count);
            if (properties) {
                break;
            }
        }
    }
    return properties;
}


