#import "OPEManagedOsmElement.h"
#import "OPEManagedReferencePoi.h"
#import "OPEUtility.h"

#import "OPEManagedOsmTag.h"


@interface OPEManagedOsmElement ()

// Private interface goes here.

@end


@implementation OPEManagedOsmElement

-(CLLocationCoordinate2D)center
{
    return CLLocationCoordinate2DMake(0, 0);
}

-(NSString *)valueForOsmKey:(NSString *)osmKey
{
    NSPredicate * tagFilter = [NSPredicate predicateWithFormat:@"key == %@",osmKey];
    NSSet * filteredSet = [self.tags filteredSetUsingPredicate:tagFilter];
    if ([filteredSet count]) {
        OPEManagedOsmTag * tag = [filteredSet anyObject];
        return tag.value;
    }
    return @"";
}

-(NSString *)name
{
    NSString * possibleName = [self valueForOsmKey:@"name"];
    if ([possibleName length]) {
        return possibleName;
    }
    else if (self.type)
    {
        return self.type.name;
    }
    else
    {
        return @"";
    }
}
-(void)addKey:(NSString *)key value:(NSString *)value
{
    [self removeTagWithOsmKey:key];
    OPEManagedOsmTag * newTag = [OPEManagedOsmTag fetchOrCreateWithKey:key value:value];
    [self.tagsSet addObject:newTag];
}

-(void)setMetaData:(NSDictionary *)dictionary;
{
    self.versionValue = [[dictionary objectForKey:@"version"] longLongValue];
    self.userName = [dictionary objectForKey:@"user"];
    self.userIDValue = [[dictionary objectForKey:@"uid"]longLongValue];
    self.changesetIDValue = [[dictionary objectForKey:@"changeset"] longLongValue];
    NSString * timeString = [dictionary objectForKey:@"timestamp"];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZ"];
    self.timeStamp = [dateFormatter dateFromString:timeString];

}

-(NSString *)tagsXML
{
    NSMutableString * xml = [NSMutableString stringWithString:@""];
    for (OPEManagedOsmTag *tag in self.tags)
    {
        [xml appendFormat:@"<tag k=\"%@\" v=\"%@\"/>",tag.key,[OPEUtility addHTML:tag.value]];
    }
    return xml;
}

-(BOOL)findType
{
    if ([self.tags count]) {
        
        
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(tags, $tag, $tag IN %@).@count == tags.@count)",self.tags];
        NSArray * matches = [OPEManagedReferencePoi MR_findAllSortedBy:OPEManagedReferencePoiAttributes.isLegacy ascending:NO withPredicate:predicate];
        if ([matches count]) {
            
            self.type =[matches lastObject];
            if ([self.type.name isEqualToString:@"Bus Stop"]) {
                NSLog(@"mantches: %@",[self name]);
            }
            
            return YES;
        }
        
        /*
        for(OPEManagedOsmTag * tag in self.tags)
        {
            for(OPEManagedReferencePoi * poi in tag.referencePois)
            {
                if([poi.tags isSubsetOfSet:self.tags])
                {
                    if (poi.isLegacyValue)
                        [possibleLegacyMatches addObject:poi];
                    else
                        [possibleMatches addObject:poi];
                }
                
            }
        }
        
        if ([possibleMatches count]) {
            self.type = [possibleMatches anyObject];
            
            NSString * name = [self name];
            NSLog(@"Name: %@",name);
            return YES;
        }
        else if([possibleLegacyMatches count])
        {
            self.type = [possibleLegacyMatches anyObject];
            return YES;
        }
         */
    }
    
    return NO;
    
}

-(void)removeTagWithOsmKey:(NSString *)osmKey
{
    NSPredicate * keyFilter = [NSPredicate predicateWithFormat:@"%K == %@",OPEManagedOsmTagAttributes.key,osmKey];
    NSSet * removeSet = [self.tags filteredSetUsingPredicate:keyFilter];
    [self.tagsSet minusSet:removeSet];
}

-(void)newType:(OPEManagedReferencePoi *)newType
{
    if (self.type) {
        [self.tagsSet minusSet:self.type.tags];
    }
    [self.tagsSet unionSet:newType.tags];
    self.type = newType;
}

-(NSString *)tagsDescription
{
    NSMutableString * string = [NSMutableString stringWithString:@""];
    for (OPEManagedOsmTag * tag in self.tags)
    {
        [string appendFormat:@"\n%@ = %@",tag.key,tag.value];
    }
    return string;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@",[super description],[self tagsDescription]];
}

-(NSString *)osmType
{
    return OPEOsmElementNone;
}

+(NSInteger) minID
{
    NSFetchRequest * request = [OPEManagedOsmElement MR_requestAllSortedBy:OPEManagedOsmElementAttributes.osmID ascending:YES];
    request.fetchLimit = 1;
    
    NSArray * results = [OPEManagedOsmElement MR_executeFetchRequest:request];
    if ([results count]) {
        OPEManagedOsmElement * element = [results lastObject];
        if (element.osmIDValue < 0) {
            return  element.osmIDValue;
        }
    }
    return 0;
    
}

@end
