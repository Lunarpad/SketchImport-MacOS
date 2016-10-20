//
//  AppDelegate.swift
//  SketchImportExamples
//
//  Created by Paul Shapiro on 10/18/16.
//  Copyright © 2016 Lunarpad Corporation. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    @IBOutlet weak var window: NSWindow!
    //
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        demonstrate_sketchImport()
    }
}


////////////////////////////////////////////////////////////////////////////////
// Import demonstration

func demonstrate_sketchImport()
{
    LPSketchImport_attemptSketchImport(
    { layersByUID in
        NSLog("Importing \(layersByUID.count) elements…");
    },
    { (currentPageName) -> Bool in
        
        let messageText = NSLocalizedString("Import the page '\(currentPageName)' from Sketch?", comment: "")
        let informativeText = NSLocalizedString("Note: If your Sketch document has a lot of layers which are to be exported as images, this could take a few seconds.", comment: "")
        let buttonTitles =
        [
            NSLocalizedString("Import", comment: ""),
            NSLocalizedString("Cancel", comment: "")
        ]
        let response = LPAlerts_do_warningAlertModal(messageText, informativeText: informativeText, buttonTitles: buttonTitles)
        switch response {
            case NSAlertFirstButtonReturn:
                return true // proceed
            case NSAlertSecondButtonReturn: // cancelled
                return false
            default:
                return false
        }
    },
    { (warningAlert_title_localizedString_orNilForNoAlert, warningAlert_message_localizedString_orNilForBlankMessage) in
        if let title = warningAlert_title_localizedString_orNilForNoAlert {
            // show alert
            dispatch_async(dispatch_get_main_queue(),
            { // ^ as we're not sure what thread we're coming back on
                let _ = LPAlerts_do_warningAlertModal(
                    title,
                    informativeText: warningAlert_message_localizedString_orNilForBlankMessage,
                    buttonTitles: [ NSLocalizedString("OK", comment: "") ]
                )
            });
        } else {
            // no alert
        }
        })
    { sketchLayerDescriptionsByLayerID in
        let importedLayerIds = sketchLayerDescriptionsByLayerID.keys
        NSLog("import layer ids: \((sketchLayerDescriptionsByLayerID as NSDictionary).allKeys)")

        // Determine which image IDs exist and which need to be created
        for layerId_raw in importedLayerIds {
            let layerId = layerId_raw as! String
            guard let layerDescription = sketchLayerDescriptionsByLayerID[layerId] as? [String: AnyObject] else {
                NSLog("Layer description was not of expected type:\n\(sketchLayerDescriptionsByLayerID[layerId])")
                continue
            }
            let didFlatten_NSNumber = layerDescription["didFlatten"] as? NSNumber
            if didFlatten_NSNumber != nil {
                let didFlatten = didFlatten_NSNumber!.boolValue // there will be an image if it was flattened
                if didFlatten == true {
                    guard let layerExportDescription = layerDescription["layerExportDescription"] as? [String: AnyObject] else {
                        fatalError("layerExportDescription was nil")
                    }
                    for scale in 1...3 {
                        let fabricated_assetUID = __new_importedAssetVariationUIDFromSketchLayerId(layerId, scale: scale);
                        let imageName = layerDescription["name"] as? String ?? "Untitled"
                        //
                        // Now obtain the image-data-as-base64-string for this layerId and scale
                        let scaleKey = "\(scale)"
                        guard let assetsByScale = layerExportDescription["assetsByScale"] as? [String: AnyObject] else {
                            NSLog("Error: No assetsByScale in \(layerExportDescription)")
                            continue
                        }
                        guard let assetDescriptionForScale = assetsByScale[scaleKey] as? [String: AnyObject] else {
                            NSLog("Error: No asset for scale \(scaleKey) in \(layerExportDescription)")
                            continue
                        }
                        //                        NSString *image_absoluteFilepath = assetDescriptionForScale[@"image_absoluteFilepath"];
                        let imageData_asBase64String = assetDescriptionForScale["image_asBase64String"] as! String
                        guard let imageData = NSData(base64EncodedString: imageData_asBase64String, options: NSDataBase64DecodingOptions(rawValue: 0)) else {
                            NSLog("Error: Unable to base64-decode image data for image named \(imageName) with uid \(fabricated_assetUID)")
                            
                            continue
                        }
                        //
                        NSLog("Upsert asset named \"\(imageName)\" with UID \(fabricated_assetUID) with \(imageData.length) bytes of PNG data")
                    }
                }
            }
        }
        
        // Determine which views needed to be created anew
        for layerId_raw in importedLayerIds {
            let layerId = layerId_raw as! String
            guard let layerDescription = sketchLayerDescriptionsByLayerID[layerId] as? [String: AnyObject] else {
                NSLog("Layer description was not of expected type:\n\(sketchLayerDescriptionsByLayerID[layerId])")
                continue
            }
//            BOOL isTopLevel = [layerDescription["isTopLevel"] boolValue];
//            BOOL isASymbol = [layerDescription["isASymbol"] boolValue];
            let sketchLayerName = layerDescription["name"] as? String ?? "Untitled"
            let sourceLayerClassName = layerDescription["sourceLayerClassName"] as? String ?? "unknown"
            var didFlatten = false // finalize:
            let didFlatten_NSNumber = layerDescription["didFlatten"] as? NSNumber
            if didFlatten_NSNumber != nil {
                didFlatten = didFlatten_NSNumber!.boolValue // there will be an image if it was flattened
            }
            let viewType = __new_importedViewAMSubtypeString(
                sourceLayerClassName,
                sketchLayerName: sketchLayerName,
                didFlatten: didFlatten
            );
            
            // does a view already exist with the id (derived from) layerId?
            
            NSLog("Info: Upsert a view \(layerId) (\"\(sketchLayerName)\") with derived type \(viewType)\n\(stringifiedJSON(layerDescription, prettyPrinted: true))")
            
        }
        
        // Now that we know all the views' local representations have been created, let's revise the subview hierarchy
        // by accessing layerDescription["sublayerIds"]
//        for (NSString *aPotentialSuperview_layerId in sketchLayerDescriptionsByLayerID) {
//            NSDictionary *layerDescription = sketchLayerDescriptionsByLayerID[aPotentialSuperview_layerId];
//            NSArray *sublayerIds = layerDescription["sublayerIds"];
//            for (NSString *sublayerId in sublayerIds) {
    
        //
        // Now let's configure all remaining properties of the views.....
        for layerId_raw in importedLayerIds {
            let layerId = layerId_raw as! String
            guard let layerDescription = sketchLayerDescriptionsByLayerID[layerId] as? [String: AnyObject] else {
                NSLog("Layer description was not of expected type:\n\(sketchLayerDescriptionsByLayerID[layerId])")
                continue
            }
            //
            // Subviews: here, we're responsible for adding any missing subviews into this view model, and updating the subview models with their new superview UIDs
            //
            let sublayerIds = layerDescription["sublayerIds"] as? [String]
            //
            // Now update the AM (new or looked up) with the new properties
            let sketchLayerName = layerDescription["name"] as? String ?? "Untitled"
            let sourceLayerClassName = layerDescription["sourceLayerClassName"] as? String ?? "unknown"
            var didFlatten = false // finalize:
            let didFlatten_NSNumber = layerDescription["didFlatten"] as? NSNumber
            if didFlatten_NSNumber != nil {
                didFlatten = didFlatten_NSNumber!.boolValue // there will be an image if it was flattened
            }
            let viewType = __new_importedViewAMSubtypeString(
                sourceLayerClassName,
                sketchLayerName: sketchLayerName,
                didFlatten: didFlatten
            );

            // See if the view kind has changed…
            //
            if let layerExportDescription = layerDescription["layerExportDescription"] as? [String: AnyObject] {
                // Handle image property
                for scale in 1...3 {
                    let fabricated_assetUID = __new_importedAssetVariationUIDFromSketchLayerId(layerId, scale: scale);
                    // …
                }
            }
            //
            // Text properties
            let stringValue = layerDescription["stringValue"] as? String
            let fontSize_NSNumber = layerDescription["fontSize"] as? NSNumber
            let fontPostscriptName = layerDescription["fontPostscriptName"] as? String
            let textColor_hexValue = layerDescription["textColor_hexValue"] as? String
            let textAlignment_NSNumber = layerDescription["textAlignment"] as? NSNumber
            
            // textAlignment_NSNumber:
            // 0 -> left
            // 1 -> right // guessed on this one
            // 2 -> center 
            // 4 -> justified // guessed

        }
        
        //
        // Now that we are sure that all the superviews are in place, we can calculate the frames
        for layerId_raw in importedLayerIds {
            let layerId = layerId_raw as! String
            guard let layerDescription = sketchLayerDescriptionsByLayerID[layerId] as? [String: AnyObject] else {
                NSLog("Layer description was not of expected type:\n\(sketchLayerDescriptionsByLayerID[layerId])")
                continue
            }
            // Set size for all
            let absoluteRect_W_NSNumber = layerDescription["absoluteRect_W"] as! NSNumber
            let absoluteRect_W = absoluteRect_W_NSNumber.floatValue;
            let absoluteRect_H_NSNumber = layerDescription["absoluteRect_H"] as! NSNumber
            let absoluteRect_H = absoluteRect_H_NSNumber.floatValue;
            
            let isTopLevel_NSNumber = layerDescription["isTopLevel"] as? NSNumber
            let isTopLevel = isTopLevel_NSNumber != nil ? isTopLevel_NSNumber!.boolValue : false
            if (isTopLevel) {
                let absoluteRect_X_NSNumber = layerDescription["absoluteRect_X"] as! NSNumber
                let absoluteRect_X = CGFloat(absoluteRect_X_NSNumber.floatValue)
                let absoluteRect_Y_NSNumber = layerDescription["absoluteRect_Y"] as! NSNumber
                let absoluteRect_Y = CGFloat(absoluteRect_Y_NSNumber.floatValue)
                let parentViewAbsoluteOrigin = NSMakePoint(
                    absoluteRect_X,
                    absoluteRect_Y
                )
                if let layerDescription_sublayerIds = layerDescription["sublayerIds"] as? [String] {
                    for sublayerId in layerDescription_sublayerIds {
                        // don't modify the origin of this view if not found in imported layer descriptions
                        let subview_absoluteRect_X_NSNumber = layerDescription["absoluteRect_X"] as! NSNumber
                        let subview_absoluteRect_X = CGFloat(subview_absoluteRect_X_NSNumber.floatValue)
                        let subview_absoluteRect_Y_NSNumber = layerDescription["absoluteRect_Y"] as! NSNumber
                        let subview_absoluteRect_Y = CGFloat(subview_absoluteRect_Y_NSNumber.floatValue)
                        //
                        // Update the local subview module x,y by subtracting the parent absolute origin from the subview absolute origin
                        let subview_localRect_X = subview_absoluteRect_X - parentViewAbsoluteOrigin.x;
                        let subview_localRect_Y = subview_absoluteRect_Y - parentViewAbsoluteOrigin.y;
                    }
                }
            }
        }
        //
        // Now we should be all done and ready to save
    }
}



////////////////////////////////////////////////////////////////////////////////
// Shared

func LPAlerts_do_warningAlertModal(
    messageText: String?,
    informativeText: String?,
    buttonTitles: [String]
    ) -> NSModalResponse
{
    let alert = NSAlert()
    alert.alertStyle = .WarningAlertStyle
    if let messageText = messageText {
        alert.messageText = messageText
    }
    if let informativeText = informativeText {
        alert.informativeText = informativeText
    }
    buttonTitles.forEach
    { buttonTitle in
        alert.addButtonWithTitle(buttonTitle)
    }
    let response = alert.runModal()
    
    return response;
}


enum ViewType
{
    case View
    case ImageView
    case Label
}

    func __new_importedViewAMSubtypeString(
    sourceLayerClassName: String,
    sketchLayerName: String,
    didFlatten: Bool
) -> ViewType
{
    if didFlatten == true {
        return .ImageView;
    }
    switch sourceLayerClassName {
        case "MSLayerGroup",
             "MSArtboardGroup":
            return .View
        case "MSTextLayer":
            return .Label
        default:
            return .View;
    }
}

func __new_importedAssetVariationUIDFromSketchLayerId(
    sketchLayerId: String,
    scale: Int
) -> String
{
    let uid = "\(sketchLayerId)-\(scale)x"
    
    return uid
}


func stringifiedJSON(
    value: AnyObject,
    prettyPrinted: Bool = false
) -> String
{
    let options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions(rawValue: 0)
    if NSJSONSerialization.isValidJSONObject(value) {
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(value, options: options)
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string as String
            }
        } catch _ {
            
        }
    }
    return ""
}