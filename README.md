# CLFMDBManager

### 没有页面，看数据库文件，看打印数据。
### 直接添加FMDB的库，然后拷贝CLFMDBManager的两个文件即可使用。

```

// sqlFile  数据库文件（一个即可）
static NSString *const kFmdbName = @"JYFMDB.sqlite";       //数据库的名称,可以定义成任何类型的文件


// table    要多少个表，就定义多少个
static NSString *const kFmdbTableName = @"cjqTable";        //xxx数据表

/**
 注意：
 
 主键：primaryKey，数据的对象Id主键
 需要根据这个key来插入、查询、更新、删除数据
 每个表都有自己的主键，主键需要根据接口返回id来定义字段
 */
static NSString *const kPrimaryKey = @"objectId";           // xxx表的主键

@interface CLFMDBManager : NSObject

@property (nonatomic, strong) FMDatabaseQueue *queue;

/**
 数据库操作：增（insert）、删（delete）、改（update）、查（select）。
 注意：insert会包含update操作，当插入数据主键已存在时，会替换数据以保证主键的唯一性。
 
 @return sql单例
 */
+ (instancetype)manager;

#pragma mark - 单数据处理    增删改查操作
/**
 对指定数据表进行 数据插入（1.表不存在则创建create；2.主键已存在则更新数据update）
 
 @param tableName 数据表名称
 @param primaryKey 插入数据主键
 @param dictionary 插入数据集合
 @param block 结果回调
 */
- (void)insertDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
                 dictionary:(NSDictionary *)dictionary
                  withBlock:(CLFMDBBoolBlock)block;

/**
 对指定数据表进行 数据删除
 
 @param tableName 数据表名称
 @param primaryKey 删除数据主键
 @param primaryValue 查询数据主键对应值
 @param block 结果回调
 */
- (void)deleteDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
               primaryValue:(NSString *)primaryValue
                  withBlock:(CLFMDBBoolBlock)block;

/**
 对指定数据表进行 数据更新
 
 @param tableName 数据表名称
 @param primaryKey 更新数据主键
 @param dictionary 更新数据集合
 @param block 结果回调
 */
- (void)updateDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
                 dictionary:(NSDictionary *)dictionary
                  withBlock:(CLFMDBBoolBlock)block;

/**
 对指定数据表进行 数据查询
 
 @param tableName 数据表名称
 @param primaryKey 查询数据主键
 @param primaryValue 查询数据主键对应值
 @param block 查询结果回调
 */
- (void)selectDataWithTable:(NSString *)tableName
                 primaryKey:(NSString *)primaryKey
               primaryValue:(NSString *)primaryValue
                  withBlock:(CLFMDBResultBlock)block;

/**
 对指定数据表进行 精准数据查询
 
 @param tableName 数据表名称
 @param conditions 查询条件集合，内容与条件都一致才匹配到，若为空则查询所有数据
 @param block 查询结果回调
 */
- (void)selectDataWithTable:(NSString *)tableName
                 conditions:(NSDictionary *)conditions
                  withBlock:(CLFMDBResultBlock)block;

/**
 对指定数据表进行 模糊数据查询
 
 @param tableName 数据表名称
 @param conditions 查询条件集合，内容带有条件多都可以匹配到，若为空则查询所有数据
 @param block 查询结果回调
 */
- (void)selectFuzzyDataWithTable:(NSString *)tableName
                      conditions:(NSDictionary *)conditions
                       withBlock:(CLFMDBResultBlock)block;

#pragma mark - 批量数据处理
/**
 对指定数据表进行 批量数据插入
 
 @param tableName 数据表名称
 @param primaryKey 数据主键
 @param valuesArray 数据数组（集合元素）
 */
- (void)insertMultipleDataWithTable:(NSString *)tableName
                         primaryKey:(NSString *)primaryKey
                      primaryValues:(NSArray<NSDictionary *> *)valuesArray;

/**
 对指定数据表进行 批量数据删除
 
 @param tableName 数据表名称
 @param primaryKey 数据主键
 @param valuesArray 数据数组（集合元素）
 */
- (void)deleteMultipleDataWithTable:(NSString *)tableName
                         primaryKey:(NSString *)primaryKey
                      primaryValues:(NSArray<NSDictionary *> *)valuesArray;

#pragma mark - 特殊处理
/**
 对指定数据表进行数据清空
 
 @param tableName 数据表名称
 @param block 结果回调
 */
- (void)deleteAllDataWithTable:(NSString *)tableName
                     withBlock:(CLFMDBBoolBlock)block;

/**
 对指定数据表进行表删除
 
 @param tableName 数据表名称
 @param block 结果回调
 */
- (void)deleteTable:(NSString *)tableName
          withBlock:(CLFMDBBoolBlock)block;

@end


```
