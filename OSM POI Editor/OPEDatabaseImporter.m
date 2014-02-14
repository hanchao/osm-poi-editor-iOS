 //
//  OPECoreDataImporter.m
//  OSM POI Editor
//
//  Created by David on 12/18/12.
//
//

#import "OPEDatabaseImporter.h"
#import "OPEConstants.h"
#import "OPEOsmTag.h"
#import "OPEUtility.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "OSMDatabaseManager.h"
#import "OPELog.h"

#define tagsFilePath [[NSBundle mainBundle] pathForResource:@"Tags" ofType:@"json"]
#define optionalPlistFilePath [[NSBundle mainBundle] pathForResource:@"Optional" ofType:@"json"]

@interface OPEDatabaseImporter ()

@property (nonatomic,strong) FMDatabaseQueue * databaseQueue;

@end


@implementation OPEDatabaseImporter

-(id)init
{
    if(self = [super init])
    {
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[OPEConstants databasePath]];
    }
    return self;
}

-(void)import
{
    [self setupDatabase];
    [self importSqliteOptionalTags];
    [self importSqlitePoiTags];
}


-(void)importSqliteOptionalSections
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"OptionalCategorySort" ofType:@"json"];
    NSError * error = nil;
    NSData * data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    NSDictionary * optionalDictionary = [NSJSONSerialization JSONObjectWithData:data options:nil error:&error];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        for (NSString * name in optionalDictionary)
        {
            int sortOrer = [optionalDictionary[name] intValue];
            [db executeUpdateWithFormat:@"insert or replace into optional_section(name,sortOrder) values(%@,%d)",name,sortOrer];
        }
    }];
}

-(void)importSqliteOptionalTags
{
    [self importSqliteOptionalSections];
    NSString * filePath = optionalPlistFilePath;
    NSError * error = nil;
    NSData * data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    NSDictionary * optionalDictionary = [NSJSONSerialization JSONObjectWithData:data options:nil error:&error];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        db.logsErrors = OPELogDatabaseErrors;
        
        
        for(NSString * key in optionalDictionary)
        {
            [db beginTransaction];
            
            OPEReferenceOptional * optional = [[OPEReferenceOptional alloc] initWithDictionary:optionalDictionary[key] withName:key];
            
            BOOL result = [db executeUpdate:[optional sqliteInsertString]];
            if (result) {
                optional.rowID = [db lastInsertRowId];
                NSString * tagsQuery = [optional sqliteOptionalTagsInsertString];
                if ([tagsQuery length]) {
                    result = [db executeUpdate:tagsQuery];
                }
                
            }
            [db commit];
        }
        
    }];
}
-(void)importSqlitePoiTags
{
    NSString * filePath = tagsFilePath;
    NSError * error = nil;
    NSData * data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:nil error:&error];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        db.logsErrors = OPELogDatabaseErrors;
        db.traceExecution = OPETraceDatabaseTraceExecution;
        
        for(NSString * category in dictionary)
        {
            [db beginTransaction];
            NSDictionary * categoryDictionary = [dictionary objectForKey:category];
            for(NSString * type in categoryDictionary)
            {
                
                NSDictionary * typeDictionary = [categoryDictionary objectForKey:type];
                OPEReferencePoi * poi = [[OPEReferencePoi alloc] initWithName:type withCategory:category andDictionary:typeDictionary];
                BOOL result = [db executeUpdate:[poi sqliteInsertString]];
                
                if (result) {
                    poi.rowID = [db lastInsertRowId];
                    result = [db executeUpdate:[poi sqliteTagsInsertString]];
                    NSString * optionalUpdate = [poi sqliteOptionalInsertString];
                    if (optionalUpdate) {
                        result = [db executeUpdate:optionalUpdate];
                    }
                }
                else
                {
                    DDLogError(@"Failed");
                }
            }
            [db commit];
            
        }
        
    }];
}

-(NSString *)lastImportHash
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * hash = [userDefaults stringForKey:kLastImportHashKey];
    return hash;
    
}
-(double)appVersionNumber
{
    NSString * currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [currentVersion doubleValue];
    
}
-(NSString *)currentFileHash;
{
    NSMutableData * data = [NSMutableData dataWithContentsOfFile:optionalPlistFilePath];
    [data appendData:[NSData dataWithContentsOfFile:tagsFilePath]];
    NSString * hash = [OPEUtility hasOfData:data];
    
    
    
    return hash;
    
}

-(NSDate *)lastImportDate
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = (NSDate *)[userDefaults stringForKey:kLastImportFileDate];
    return date;
}

-(NSDate *)currentMostRecentFileDate
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSDictionary* tagsAttrs = [fm attributesOfItemAtPath:tagsFilePath error:nil];
    NSDictionary* optionalAttrs = [fm attributesOfItemAtPath:optionalPlistFilePath error:nil];
    
    if (tagsAttrs != nil || optionalAttrs != nil) {
        NSDate *tagsDate = (NSDate*)[tagsAttrs objectForKey: NSFileCreationDate];
        NSDate *optionalDate = (NSDate *)[optionalAttrs objectForKey:NSFileCreationDate];
        if ([tagsDate compare:optionalDate] == NSOrderedDescending) {
            return tagsDate;
        }
        else
        {
            return optionalDate;
        }
    }
    else {
        DDLogError(@"Not found");
    }
    return nil;
}

-(BOOL)shouldDoImport
{
    double numberOfOptionals = 1;//[[OPEReferenceOptional MR_numberOfEntities] doubleValue];
    double numberOfPOI = 1;//[[OPEReferencePoi MR_numberOfEntities] doubleValue];
    if ([[self lastImportDate] compare:[self currentMostRecentFileDate]] != NSOrderedSame) {
        return YES;
    }
    else if (numberOfOptionals == 0 && numberOfPOI == 0)
    {
        return YES;
    }
    return NO;
}

-(void)setImportVersionNumber
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[self currentMostRecentFileDate] forKey:kLastImportFileDate];
    [userDefaults synchronize];
}

-(void)setupDatabase
{
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = NO;
        OSMDatabaseManager * osmData = [[OSMDatabaseManager alloc] initWithFilePath:[OPEConstants databasePath] overrideIfExists:YES];
        [OSMDatabaseManager initialize];
        osmData = nil;
        [db beginTransaction];
        
        
        result = [db executeUpdate:@"DROP TABLE IF EXISTS poi"];
        result = [db executeUpdate:@"DROP TABLE IF EXISTS optional"];
        result = [db executeUpdate:@"DROP TABLE IF EXISTS optional_section"];
        result = [db executeUpdate:@"DROP TABLE IF EXISTS pois_tags"];
        result = [db executeUpdate:@"DROP TABLE IF EXISTS optionals_tags"];
        result = [db executeUpdate:@"DROP TABLE IF EXISTS pois_optionals"];
        
        //result = [db executeUpdate:@"DROP TABLE IF EXISTS poi_lastUsed"];
        
        result = [db executeUpdateWithFormat:@"create table poi(editOnly INTEGER DEFAULT 0,imageString TEXT,isLegacy INTEGER DEFAULT 0,displayName TEXT NOT NULL,category TEXT NOT NULL,UNIQUE(displayName,category))"];
        result = [db executeUpdateWithFormat:@"create table optional(name TEXT PRIMARY KEY NOT NULL, displayName TEXT NOT NULL, osmKey TEXT,sectionSortOrder INTEGER,type TEXT,section_id INTEGER)"];
        result = [db executeUpdate:@"create table pois_tags(poi_id INTEGER NOT NULL,key TEXT NOT NULL,value TEXT NOT NULL,UNIQUE(poi_id,key,value))"];
        result = [db executeUpdate:@"create table optionals_tags(optional_id INTEGER NOT NULL,name TEXT NOT NULL,key TEXT NOT NULL,value TEXT NOT NULL)"];
        result = [db executeUpdate:@"create table optional_section(name TEXT PRIMARY KEY NOT NULL,sortOrder INTEGER)"];
        result = [db executeUpdate:@"create table pois_optionals(poi_id INTEGER NOT NULL,optional_id INTEGER NOT NULL,UNIQUE(poi_id,optional_id))"];
        
        result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS poi_lastUsed(date TEXT,displayName TEXT PRIMARY KEY)"];
        
        result = [db executeUpdate:@"ALTER TABLE nodes ADD COLUMN poi_id INTEGER;"];
        result = [db executeUpdate:@"ALTER TABLE ways ADD COLUMN poi_id INTEGER;"];
        result = [db executeUpdate:@"ALTER TABLE relations ADD COLUMN poi_id INTEGER;"];
        
        result = [db executeUpdate:@"ALTER TABLE nodes ADD COLUMN isVisible INTEGER DEFAULT 1;"];
        result = [db executeUpdate:@"ALTER TABLE ways ADD COLUMN isVisible INTEGER DEFAULT 1;"];
        result = [db executeUpdate:@"ALTER TABLE relations ADD COLUMN isVisible INTEGER DEFAULT 1;"];
        
        [db commit];
        
    }];
    
}

@end