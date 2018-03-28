//
//  CLFMDBManager.m
//  FMDB
//
//  Created by BmMac on 2017/5/3.
//  Copyright © 2017年 Seejoys. All rights reserved.
//

#import "CLFMDBManager.h"

#ifdef DEBUG
#   define CLLog(...)                       NSLog(__VA_ARGS__)
#else
#   define CLLog(...)
#endif

@interface CLFMDBManager ()
@property (nonatomic, strong) NSString *filePath;
@end

@implementation CLFMDBManager

#pragma mark - 初始化
+ (instancetype)manager {
    return [[self alloc] init];
}

static CLFMDBManager *instance = nil;
static dispatch_once_t onceToken;
- (instancetype)init
{
    dispatch_once(&onceToken, ^{
        instance = [super init];
        // 1.获得数据库文件的路径
        NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        self.filePath = [document stringByAppendingPathComponent:kFmdbName];
        CLLog(@"FMDB数据库文件的路径：%@", self.filePath);
    });
    return instance;
}


#pragma mark 创建数据表（私有方法，内部调用）
- (void)createTable:(NSString *)tableName
         primaryKey:(NSString *)primaryKey
{
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        // 4.当表不存在时创建新表（NOT EXISTS），只有一列（主键 列）
        NSString *createTable =  [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('%@' TEXT PRIMARY KEY)", tableName , primaryKey];
        // 5.提交更新
        BOOL result = [db executeUpdate:createTable];
        if (result) {
            CLLog(@"数据表%@创建成功", tableName);
        }else{
            CLLog(@"数据表%@创建失败", tableName);
        }
    }];
}

#pragma mark 创建表（必须调用，创建表）
- (void)createTableArray:(NSArray<NSString*> *)tableNames primaryKeyArray:(NSArray<NSString*> *)primaryKeys {
    if (tableNames.count != primaryKeys.count) {
        return;
    }
    for (int i = 0; i < tableNames.count; i++) {
        NSString *tableName = tableNames[i];
        NSString *primaryKey = primaryKeys[i];
        [self createTable:tableName primaryKey:primaryKey];
    }
}

#pragma mark -
#pragma mark 对指定数据表进行 数据插入
- (void)insertDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
                 dictionary:(NSDictionary *)dictionary
                  withBlock:(CLFMDBBoolBlock)block
{
    // 获取主键的值
    __block NSString *primaryValue = [NSString stringWithFormat:@"%@", dictionary[primaryKey]];
    if (!primaryValue || [primaryValue length] == 0) {
        block(nil, NO);
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        if ([weakSelf haveTable:tableName primaryKey:primaryKey primaryValue:primaryValue database:db]) {
            // MARK: 已存在该主键。执行更新数据方法
            [weakSelf updateTable:tableName primaryKey:primaryKey primaryValue:primaryValue dictionary:dictionary database:db withBlock:block];
        }else{
            // MARK: 不存在该主键。执行插入数据方法
            NSString *insertSql = [NSString stringWithFormat:
                                   @"INSERT INTO '%@' ('%@') VALUES (?)",
                                   tableName, primaryKey];
            
            [db executeUpdate:insertSql, primaryValue];
            [weakSelf updateTable:tableName primaryKey:primaryKey primaryValue:primaryValue dictionary:dictionary database:db withBlock:block];
        }
    }];
}

#pragma mark 对指定数据表进行 数据删除
- (void)deleteDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
               primaryValue:(NSString *)primaryValue
                  withBlock:(CLFMDBBoolBlock)block
{
    if ([primaryValue length] == 0) {
        block(nil, NO);
        return;
    }
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE %@ = '%@'", tableName, primaryKey, primaryValue];
        BOOL result = [db executeUpdate:deleteSql];
        if (block) {
            block(db, result);
        }
    }];
}

#pragma mark 对指定数据表进行 数据清空
- (void)deleteAllDataWithTable:(NSString *)tableName
                     withBlock:(CLFMDBBoolBlock)block
{
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM '%@'", tableName];
        BOOL result = [db executeUpdate:deleteSql];
        block(db, result);
    }];
}

#pragma mark 对指定数据表进行 表删除
- (void)deleteTable:(NSString *)tableName withBlock:(CLFMDBBoolBlock)block {
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        NSString *deleteSql = [NSString stringWithFormat:@"DROP TABLE  '%@'", tableName];
        BOOL result = [db executeUpdate:deleteSql];
        block(db, result);
    }];
}

#pragma mark 对指定数据表进行 数据更新
- (void)updateDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
                 dictionary:(NSDictionary *)dictionary
                  withBlock:(CLFMDBBoolBlock)block
{
    // 获取主键的值
    __block NSString *primaryValue = [NSString stringWithFormat:@"%@", dictionary[primaryKey]];
    if (!primaryValue || [primaryValue length] == 0) {
        block(nil, NO);
        return;
    }
    __weak __typeof(self)weakSelf = self;
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        if ([weakSelf haveTable:tableName primaryKey:primaryKey primaryValue:primaryValue database:db]) {
            // MARK: 已存在该主键。执行更新数据方法
            [weakSelf updateTable:tableName primaryKey:primaryKey primaryValue:primaryValue dictionary:dictionary database:db withBlock:block];
        }else{
            // MARK: 不存在该主键。给失败回调
            block(db, NO);
        }
    }];
}

#pragma mark 对指定数据表进行 数据查询
- (void)selectDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
               primaryValue:(NSString *)primaryValue
                  withBlock:(CLFMDBResultBlock)block
{
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM '%@' WHERE %@ = '%@'", tableName, primaryKey, primaryValue];
        FMResultSet *result = [db executeQuery:selectSql];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
        do {
            if (result.resultDictionary) {
                [array addObject:result.resultDictionary];
            }
        } while ([result next]);
        // FIXME: executeQuery查询之后要关闭查询
        [result close];
        if (block) {
            block(array);
        }
    }];
}

#pragma mark 对指定数据表进行 精准数据查询
- (void)selectDataWithTable:(NSString *)tableName
                 conditions:(NSDictionary *)conditions
                  withBlock:(CLFMDBResultBlock)block
{
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        
        NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM '%@'", tableName];
        NSString *conditionString = @"";
        if (conditions.allKeys.count > 0) {
            for (NSString *key in conditions.allKeys) {
                conditionString = [NSString stringWithFormat:@"%@ %@ = '%@'", conditionString, key, conditions[key]];
                if (![key isEqual:conditions.allKeys.lastObject]) {
                    conditionString = [conditionString stringByAppendingString:@" AND "];
                }
            }
            selectSql = [selectSql stringByAppendingFormat:@" WHERE %@", conditionString];
        }
        
        FMResultSet *result = [db executeQuery:selectSql];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
        do {
            if (result.resultDictionary) {
                [array addObject:result.resultDictionary];
            }
        } while ([result next]);
        // FIXME: executeQuery查询之后要关闭查询
        [result close];
        if (block) {
            block(array);
        }
    }];
}

#pragma mark 对指定数据表进行 模糊数据查询
- (void)selectFuzzyDataWithTable:(NSString *)tableName
                      conditions:(NSDictionary *)conditions
                       withBlock:(CLFMDBResultBlock)block
{
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM '%@'", tableName];
        NSString *conditionString = @"";
        if (conditions.allKeys.count > 0) {
            for (NSString *key in conditions.allKeys) {
                conditionString = [NSString stringWithFormat:@"%@ %@ LIKE '%%%@%%'", conditionString, key, conditions[key]];
                if (![key isEqual:conditions.allKeys.lastObject]) {
                    conditionString = [conditionString stringByAppendingString:@" AND "];
                }
            }
            selectSql = [selectSql stringByAppendingFormat:@" WHERE %@", conditionString];
        }
        
        FMResultSet *result = [db executeQuery:selectSql];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
        do {
            if (result.resultDictionary) {
                [array addObject:result.resultDictionary];
            }
        } while ([result next]);
        // FIXME: executeQuery查询之后要关闭查询
        [result close];
        if (block) {
            block(array);
        }
    }];
}
/**
 对自定义进行Where 数据查询
 
 @param tableName 数据表名称
 @param block 查询结果回调
 */
-(void)selectDataWithTable:(NSString *)tableName
         customWhereSqlite:(NSString *)customSqlite
                 withBlock:(CLFMDBResultBlock)block
{
    // 2.得到数据库
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
    // 3.打开数据库
    [queue inDatabase:^(FMDatabase *db) {
        
        NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM '%@' %@", tableName,customSqlite];// WHERE, customSqlite
        FMResultSet *result = [db executeQuery:selectSql];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
        do {
            if (result.resultDictionary) {
                [array addObject:result.resultDictionary];
            }
        } while ([result next]);
        // FIXME: executeQuery查询之后要关闭查询
        [result close];
        if (block) {
            block(array);
        }
    }];
}


#pragma mark -
#pragma mark 对指定数据表进行 批量数据插入
- (void)insertMultipleDataWithTable:(NSString *)tableName
                         primaryKey:(NSString *)primaryKey
                      primaryValues:(NSArray *)valuesArray
{
    // 获取主键的值
    __block NSString *primaryValue = [NSString stringWithFormat:@"%@", valuesArray.firstObject[primaryKey]];
    if (!primaryValue || [primaryValue length] == 0) {
        return;
    }
    for (NSDictionary *dict in valuesArray) {
        [self insertDataWithTable:tableName primaryKey:primaryKey dictionary:dict withBlock:nil];
    }
}

#pragma mark 对指定数据表进行 批量数据删除
- (void)deleteMultipleDataWithTable:(NSString *)tableName
                         primaryKey:(NSString *)primaryKey
                      primaryValues:(NSArray *)valuesArray
{
    // 获取主键的值
    __block NSString *primaryValue = [NSString stringWithFormat:@"%@", valuesArray.firstObject[primaryKey]];
    if (!primaryValue || [primaryValue length] == 0) {
        return;
    }
    for (NSDictionary *dict in valuesArray) {
        NSString *primaryValue = [NSString stringWithFormat:@"%@", dict[primaryKey]];
        [self deleteDataWithTable:tableName primaryKey:primaryKey primaryValue:primaryValue withBlock:nil];
    }
}

#pragma mark -
#pragma mark 判断数据表是否已经存在该主键（私有方法，内部调用）
- (BOOL)haveTable:(NSString *)tableName
       primaryKey:(NSString *)primaryKey
     primaryValue:(NSString *)primaryValue
         database:(FMDatabase *)db
{
    NSString *selectSql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM '%@' WHERE %@ IN (%@)", tableName, primaryKey, primaryValue];
    
    NSUInteger count = [db intForQuery:selectSql];
    if (count > 0) {
        return YES;
    }else{
        return NO;
    }
}

#pragma mark 更新表数据（私有方法，内部调用）
- (void)updateTable:(NSString *)tableName
         primaryKey:(NSString *)primaryKey
       primaryValue:(NSString *)primaryValue
         dictionary:(NSDictionary *)dictionary
           database:(FMDatabase *)db
          withBlock:(CLFMDBBoolBlock)block
{
    __block NSString *sqlString = @"";
    for (id key in dictionary) {
        NSString *keyStr = [NSString stringWithFormat:@"%@", key];
        if ([keyStr isEqualToString:primaryKey])
            continue ;
        
        id value = [dictionary objectForKey:key];
        // 检测是否存在该列，若不存在则创建
        if (![db columnExists:keyStr inTableWithName:tableName]) {
            /*
             integer : 整型值
             real : 浮点值
             text : 文本字符串
             blob : 二进制数据（比如文件）
             */
            NSString *addSql;
            if ([value isKindOfClass:[NSNumber class]]) {
                addSql = [NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' integer;", tableName, keyStr];
            }else if ([value isKindOfClass:[NSData class]]) {
                addSql = [NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' blob;", tableName, keyStr];
            }else{
                addSql = [NSString stringWithFormat:@"ALTER TABLE '%@' ADD COLUMN '%@' text;", tableName, keyStr];
            }
            sqlString = [sqlString stringByAppendingString:addSql];
        }
        
        // 更新数据
        NSString *updateSql = [NSString stringWithFormat:
                               @"UPDATE '%@' SET '%@' = '%@' WHERE %@ = '%@';",
                               tableName,   keyStr,  value ,primaryKey,  primaryValue];
        sqlString = [sqlString stringByAppendingString:updateSql];
    }
    // MARK: 批处理数据，一个字符串包含多个方法
    BOOL result = [db executeStatements:sqlString];
    if (block) {
        block(db, result);
    }
}

@end

/*
 ALTER 语句修改数据表
 1.修改数据表名
 ALTER TABLE [方案名.]OLD_TABLE_NAME RENAME TO NEW_TABLE_NAME;
 2.修改列名
 ALTER TABLE [方案名.]TABLE_NAME RENAME COLUMN OLD_COLUMN_NAME TO NEW_COLUMN_NAME;
 3.修改列的数据类型
 ALTER TABLE [方案名.]TABLE_NAME MODIFY COLUMN_NAME NEW_DATATYPE;
 4.插入列
 ALTER TABLE [方案名.]TABLE_NAME ADD COLUMN_NAME DATATYPE;
 5.删除列
 ALTER TABLE [方案名.]TABLE_NAME DROP COLUMN COLUMN_NAME;
 */


