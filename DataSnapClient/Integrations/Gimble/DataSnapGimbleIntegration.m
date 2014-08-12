#import "DataSnapGimbleIntegration.h"
#import "DataSnapClient.h"
#import "GlobalUtilities.h"
#import <FYX/FYXTransmitter.h>
#import <ContextLocation/QLPlaceEvent.h>
#import <ContextLocation/QLPlace.h>
#import <ContextLocation/QLGeoFence.h>
#import <ContextLocation/QLGeoFenceCircle.h>
#import <ContextLocation/QLGeoFencePolygon.h>
#import <ContextLocation/QLLocation.h>

@implementation DataSnapGimbleIntegration

+ (void)load {
    [DataSnapClient registerIntegration:[self new] withIdentifier:@"Gimbal"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Gimble";
    }
    
    return self;
}

+ (NSDictionary *)beaconEvent:(NSObject *)obj eventName:(NSString *)name{
    
    // Beacon Event
    if([obj isKindOfClass:[FYXVisit class]]) {
        
        NSMutableDictionary *eventData = [[NSMutableDictionary alloc] initWithDictionary:[self getUserAndDataSnapDictionary]];
        
        // Cast object to visit
        FYXVisit *visit = (FYXVisit *)obj;
        
        // Create dictionary from visit properties
        NSMutableDictionary *beacon= [[NSMutableDictionary alloc] initWithDictionary:[self dictionaryRepresentation:visit]];
        [beacon addEntriesFromDictionary:[self dictionaryRepresentation:visit.transmitter]];
        [beacon removeObjectForKey:@"transmitter"];
        beacon[@"hardware"] = @"Gimble";
        
        [self map:beacon withMap:@{@"identifier": @"id",
                                   @"battery": @"battery_level",
                                   @"dwellTime": @"dwell_time",
                                   @"lastUpdateTime": @"last_update_time",
                                   @"startTime": @"start_time"}];
        
        // handle NSDates
        [GlobalUtilities nsdateToNSString:beacon];
        
        [eventData addEntriesFromDictionary:@{@"event_type": name,
                                              @"beacon": beacon}];
        
        return eventData;
    }
    
    // Geofence Event
    else if ([obj isKindOfClass:[QLPlaceEvent class]]) {
        
        NSMutableDictionary *eventData = [[NSMutableDictionary alloc] initWithDictionary:[self getUserAndDataSnapDictionary]];
        
        // Cast object to QLPlaceEvent
        QLPlaceEvent *placeEvent = (QLPlaceEvent *)obj;
        NSMutableDictionary *place = [NSMutableDictionary new];
        
        // Circle geofence
        if ([[[placeEvent place] geoFence] isKindOfClass:[QLGeoFenceCircle class]]) {
            
            QLGeoFenceCircle *fence = (QLGeoFenceCircle *)[[placeEvent place] geoFence];
            
            place[@"geoFenceCircle"] = @{@"time": [[placeEvent time] description],
                                         @"id": [NSNumber numberWithLongLong:[[placeEvent place] id]],
                                         @"name": [[placeEvent place] name],
                                         @"radius": [NSNumber numberWithDouble:[fence radius]],
                                         @"location": @{@"latitude": [NSNumber numberWithDouble:[fence latitude]],
                                                        @"longitude": [NSNumber numberWithDouble:[fence longitude]]}};
        }
        // Polygon gerofence
        else if ([[[placeEvent place] geoFence] isKindOfClass:[QLGeofencePolygon class]]) {
            
            QLGeofencePolygon *fence = (QLGeofencePolygon *)[[placeEvent place] geoFence];

            NSMutableArray *locations = [NSMutableArray new];
            for(QLLocation *loc in [fence locations]) {
                [locations addObject:@{@"latitude": [loc latitude],
                                       @"longitude": [loc longitude]}];
            }
    
            place[@"geoFencePolygon"] = @{@"time": [[placeEvent time] description],
                                          @"id": [NSNumber numberWithLongLong:[[placeEvent place] id]],
                                          @"name": [[placeEvent place] name],
                                          @"locations": locations};
        }
        
        [eventData addEntriesFromDictionary:@{@"event_type": name,
                                              @"place": place}];
        
        return eventData;
    }
    
    return NULL;
}

@end
