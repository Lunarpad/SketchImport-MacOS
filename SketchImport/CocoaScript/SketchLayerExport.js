// NOTE: To use this script, you must prepend the variable declarations supplying:
//  • the layerIdsToExport
// That variable 'layerIdsToExport' must be a list of the objectIDs of the layers you want to export.
// Like so:
// var layerIdsToExport = [ "……" ];
//
// Note: we don't check if the export directory exists, nor do we try to create it if it doesn't.
// We put responsibility to manage the directory on the application code which uses this code, since
// we don't manage the lifecycle (deletion) of the exported files with this script.

var numberOfLayerIdsToExport = layerIdsToExport.length;


////////////////////////////////////////////////////////////////////////////////
// Shared

function sketchVersionNumber()
{ // thanks to https://github.com/einancunlu/Flatten-Plugin-for-Sketch
    const version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
    var versionNumber = version.stringByReplacingOccurrencesOfString_withString(".", "") + ""
    while(versionNumber.length != 3) {
        versionNumber += "0"
    }
    //
    return parseInt(versionNumber)
}


////////////////////////////////////////////////////////////////////////////////

var state = {};
function sync_stateUpdatingOperation()
{
    var document = context.document; // we're assuming the doc has already been verified to exist by the time this is used
    var doc = document;
    var currentPage = [document currentPage];
    
    var artboards = [currentPage artboards];
    var hasArtboards = artboards.count() > 0;
    
    var sourceLayersList;
    if (hasArtboards == true) {
        sourceLayersList = artboards
    } else {
        sourceLayersList = [currentPage layers]
    }
    var numberOfTopLevelLayers = [sourceLayersList count];
    var sourceLayersToExport = [[NSMutableArray alloc] init]; // now to accumulate this...
    
    
//    var startDate_a = [NSDate date];
    
    var sourceLayersToSearchWithin = [[NSMutableArray alloc] init];
    //    log("numberOfTopLevelLayers " + numberOfTopLevelLayers);
    for (var i = 0 ; i < numberOfTopLevelLayers ; i++) { // first, to queue up the initial fodder for the following 'while' engine,
        var topLevelLayer = [sourceLayersList objectAtIndex:i];
        var layerId = topLevelLayer.objectID();
        [sourceLayersToSearchWithin addObject:topLevelLayer];
    }
//    log("typeof layerIdsToExport: '" + typeof(layerIdsToExport) + "'");
//    log("layerIdsToExport: '" + layerIdsToExport + "'");
//    log("numberOfLayerIdsToExport " + numberOfLayerIdsToExport);
//    log("num sourceLayersToSearchWithin " + [sourceLayersToSearchWithin count])
    
    
    
    while ([sourceLayersToSearchWithin count] > 0) {
        var sourceLayer = sourceLayersToSearchWithin[0];
        [sourceLayersToSearchWithin removeObjectAtIndex:0]; // walk the head pointer down..
        
        var layerId = sourceLayer.objectID();
        
        var foundLayerToExport = false;
//        console.log("layerId: " + layerId);
        for (var i = 0 ; i < numberOfLayerIdsToExport ; i++) { // i tried layerIdsToExport.indexOf(layerId) != -1
            var layerIdToExport = layerIdsToExport[i];
//            log("layerIdToExport " + layerIdToExport);
            if ([layerId isEqual:layerIdToExport]) {
//                log("equal!");
                foundLayerToExport = true;
                
                break;
            }
        }
        if (foundLayerToExport == true) {
//            log("~~~~~~~~~> found one.");
            // v Found one, so accumulate
            [sourceLayersToExport addObject:sourceLayer]; // nsarray, so -addObject: instead of .push(…)
            
        } else { // then it will not be flattened, and therefore, process its sublayers
//            log("go in");
            if (typeof(sourceLayer.layers) == "function") { // apparently sometimes this might be missing??
//                log("has layers fn");
                var sublayers = sourceLayer.layers();
                var numberOfSublayers = [sublayers count];
//                log("numberOfSublayers " + numberOfSublayers);
                for (var sublayerIdx = 0 ; sublayerIdx < numberOfSublayers ; sublayerIdx++) {
                    var sublayer = [sublayers objectAtIndex:sublayerIdx]
//                    console.log("search in sublayer "+ sublayer);
                    [sourceLayersToSearchWithin addObject:sublayer]; // adding to the end -- after all the top level views
                    // ^ note: we use '-addObject:' here because it's an NSMutableArray, not a JS Array
                }
            }
        }
    }
    
//    var endDate_a = [NSDate date];
//    var timeInterval_a = [endDate_a timeIntervalSinceDate:startDate_a];
//    log("done accumulating: " + timeInterval_a);
    
    
//    var startDate_w = [NSDate date];


    var layerExportDescriptionsByLayerId = {};
    var numberOfLayersFoundToExport = [sourceLayersToExport count];
    for (var layerIdx = 0 ; layerIdx < numberOfLayersFoundToExport ; layerIdx++) {
        var layerToExport = [sourceLayersToExport objectAtIndex:layerIdx];
        var layerId = layerToExport.objectID();
        var layerFrame = [layerToExport frame]; // MSRect
        var absoluteRect = [layerToExport absoluteRect]; // MSAbsoluteRect
        var absoluteInfluenceRect = [layerToExport absoluteInfluenceRect]; // CGRect
        
        var layerDescription = {};
        layerDescription.layerId = layerId;
        layerDescription.assetsByScale = {};
        for (var scale = 1.0 ; scale <= 3.0 ; scale += 1.0) {
//            var startDate_0 = [NSDate date];
            var exportRequest;
            if (sketchVersionNumber() >= 350) {
                exportRequest = [[MSExportRequest exportRequestsFromExportableLayer:layerToExport inRect:absoluteInfluenceRect useIDForName:false] firstObject];
            } else { // legacy support
                exportRequest = [[MSSliceMaker slicesFromExportableLayer:layerToExport inRect:absoluteInfluenceRect] firstObject]
            }
            
            
            
            
//            var exportRequestRect = [exportRequest rect]; // MSRect
            
            if (sketchVersionNumber() >= 350) {
                exportRequest.page = currentPage
            } else {
                exportRequest.page = currentPage.copyLightweight()
            }
        
            exportRequest.format = "png"
            exportRequest.scale = scale; // todo: do requests for 1,2, and 3

            
            
            
//            var endDate_0 = [NSDate date];
//            var timeInterval_0 = [endDate_0 timeIntervalSinceDate:startDate_0];
//            log("slice creation: " + timeInterval_0);

            
            

//            var startDate_1 = [NSDate date];
//            
            var imageData;
            if (sketchVersionNumber() >= 350) {
                var colorSpace = [NSColorSpace sRGBColorSpace];
                var exporter = [MSExporter exporterForRequest:exportRequest colorSpace:colorSpace]
                imageData = exporter.PNGData()
            } else {
                imageData = [MSSliceExporter dataForRequest:exportRequest] // NSData
            }

//
//            var endDate_1 = [NSDate date];
//            var timeInterval_1 = [endDate_1 timeIntervalSinceDate:startDate_1];
//            log("slice export: " + timeInterval_1);
            
            
            
//            var startDate_2 = [NSDate date];
            
            
            // Write to file
            var filename = layerId;
            filename += "@" + scale + "x"
            filename += ".png";
            
            var image_asBase64String = [imageData base64EncodedStringWithOptions:0]; // NSString
            
            layerDescription.assetsByScale[""+scale] =
            {
                "scale": 0+scale,
                "image_asBase64String": image_asBase64String
            };
            
            
//            var endDate_2 = [NSDate date];
//            var timeInterval_2 = [endDate_2 timeIntervalSinceDate:startDate_2];
//            log("file write: " + timeInterval_2);

            
            
//        log(layerId);
//        log(layerToExport);
//        log(layerFrame);
//        log(absoluteRect);
//        log(absoluteInfluenceRect);
//        log(exportRequest);
//        log(exportRequestRect);
//        log("imageData len " + imageData.length())
        }
        
        layerExportDescriptionsByLayerId[layerId] = layerDescription;
    }
    
    
//    var endDate_w = [NSDate date];
//    var timeInterval_w = [endDate_w timeIntervalSinceDate:startDate_w];
//    log("finished: " + timeInterval_w);
    
    

    state.layerExportDescriptionsByLayerId = layerExportDescriptionsByLayerId;
    
}
sync_stateUpdatingOperation();


////////////////////////////////////////////////////////////////////////////////

function yieldProgramState()
{
    //    log(state);
    var jsonData = [NSJSONSerialization dataWithJSONObject:state options:0 error:nil];
    if (jsonData) {
        var jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        log(jsonString);
    } else {
        log({"error" : "Nil JSON data from state."});
    }
}
yieldProgramState();