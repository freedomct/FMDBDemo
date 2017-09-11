//
//  ViewController.m
//  DatabaseDemo
//
//  Created by FengZi on 2017/9/4.
//  Copyright © 2017年 yang. All rights reserved.
//

#import "ViewController.h"
#import <FMDB.h>
@interface ViewController ()

@property FMDatabase *database;

@property FMDatabaseQueue *databaseQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
#pragma mark - - 创建数据库
- (IBAction)createSQL:(id)sender {
    
    //  创建 database
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *pathName = [paths lastObject];
    pathName = [pathName stringByAppendingString:@"/yang.sqlite"];
//    pathName = [pathName stringByAppendingString:@"/yang.db"];

    NSLog(@"pathName = %@",pathName);
    _database = [FMDatabase databaseWithPath:pathName];
    //  追踪执行  追踪执行的sql 语句
    _database.traceExecution = NO;
    //  是否签出  (这个没找到啥意思 大神知道的指导下 )
    _database.checkedOut = YES;
    //  当执行sql 语句出错时  crash 掉程序
    _database.crashOnErrors = NO;
    //  数据库执行出错时 log 说明
    _database.logsErrors = NO;
    
    //  当database 打开时
    if ([_database open]) {
        //  创建表
        BOOL createTableResult = [_database executeUpdate:@"CREATE  TABLE  IF NOT EXISTS PERSON(ID INTEGER PRIMARY KEY,NAME TEXT,AGE INTEGER,SEX INTEGER)"];
        if (!createTableResult) {
            NSLog(@"数据库创建失败");
            return;
        }
        NSLog(@"数据库创建成功");
    }
    
}

#pragma mark - - 插入数据
- (IBAction)insertDataToSQL:(id)sender {
    
    if ([_database open]) {
        
        NSString *insertSQL = @"INSERT INTO PERSON (ID,NAME,AGE,SEX) VALUES (?,?,?,?)";
        for (int i = 0; i < 10; i ++) {
            
            NSString *name = [NSString stringWithFormat:@"yang-%d",i];
            NSInteger sex = (i % 2 == 0) ? 0 : 1;
            BOOL insertResult = [_database executeUpdate:insertSQL,@(i),name,@(i),@(sex)];
            if (!insertResult) {
                
                NSLog(@"插入出错 -- %@",_database.lastErrorMessage);
                
            }
        }
    }
}

#pragma mark - - 查询数据
- (IBAction)selectDataFromSQL:(id)sender {
    
    if ([_database open]) {
        NSString *selectSQL = @"SELECT * FROM PERSON";
        //  查询的结果集
        FMResultSet *results = [_database executeQuery:selectSQL];
        NSLog(@"resultDictionary = %@",results.resultDictionary);
        
        while ([results next]) {
            
            NSString *name = [results stringForColumn:@"name"];
            int age = [results intForColumn:@"age"];
            int sex = [results intForColumn:@"sex"];
            NSLog(@"\nname = %@ age = %d sex = %d \n",name,age,sex);
        }

        
    }
    
}

#pragma mark - - 删除数据库
- (IBAction)deleteDataFromSQL:(id)sender {
    
    if ([_database open]) {
        
//        BOOL deleteResult = [_database executeUpdate:@"DELETE FROM PERSON WHERE NAME = ?",@"yang-4"];
        BOOL deleteFormateResutl =  [_database executeUpdateWithFormat:@"DELETE FROM PERSON WHERE NAME = %@",@"yang-5"];

        if (!deleteFormateResutl) {
            NSError *error = _database.lastError;
            
            NSLog(@"删除失败 userInfo = %@  code = %@",error.userInfo,error.userInfo);
            return;
        }
        NSLog(@"删除成功");
    }
}

#pragma mark - - 更新数据库
- (IBAction)updateDataWithSQL:(id)sender {
    
    if ([_database open]) {
        
        BOOL updateResult = [_database executeUpdate:@"UPDATE PERSON SET AGE = ? WHERE NAME = ?",@(100),@"yang-18"];
        if (!updateResult) {
            
            NSLog(@"更新操作失败");
            return;
        }
        NSLog(@"更新操作成功");

    }
}
/* 清空数据库 */
- (IBAction)clearData:(id)sender {
    
    if ([_database open]) {
        
        BOOL clearResult =  [_database executeUpdate:@"DELETE FROM PERSON"];
        if (!clearResult) {
            NSLog(@"清空失败");
            return;
        }
        NSLog(@"清空成功");
    }
}
/* 多线程 */
- (void)multipleThreadAction {
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *pathName = [paths lastObject];
        pathName = [pathName stringByAppendingString:@"/person.sqlite"];
        
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:pathName];
        //  事物操作
        [_databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            
            [db beginTransaction];
            /* codes */
            [db commit];
            
        }];
    }
    
    {
        [_databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            
            BOOL result = [db executeUpdate:@"sql"];
            if (!result) {
                *rollback = YES;
            }
        }];
  
    }
}

/* 销毁表 */
- (IBAction)dropTable:(id)sender {
    if ([_database open]) {
     
        BOOL dropResult = [_database executeUpdate:@"DROP TABLE IF EXISTS PERSON"];
        if (dropResult) {
            //  删除表 创建的sqlite 还在
            NSLog(@"销毁表成功");
            return;
        }
        NSLog(@"销毁表失败");
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
