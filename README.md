# 💍&nbsp;&nbsp;SketchImport-MacOS

**Platforms:** MacOS, Sketch

**Languages:** Swift, Objective-C, CocoaScript

One of the awesome features we added to [Producer](http://www.getproducer.com) 2.0 which unfortunately never saw the light of public release was the ability to import your app designs from [Sketch](http://sketchapp.com) into Producer, which made it possible to convert app designs directly to fully configured, styled, and functional iOS views of the specific type that made the most sense. Text layers should be translated into Labels, flattened and exported graphic or image layers should be turned into Image Views, and so on.

Adding Sketch import was a no-brainer for us since plenty of people requested it, mobile designers were already using it to design their apps, and were already used to its awesome GUI. Being able to merge in our latest from our Sketch designs made building UIs a lot faster for our beta users – and also happened to make for a pretty impressive demo.

However, when we went to build out import from Sketch, we found that documentation on actually coding up an import was lacking – there weren't clear standards established – which means we had to continuously reference third-party dumps of the Sketch code headers. But in many cases this was complicated, so we had to rely upon examples. However, it was often difficult to find up-to-date or complete implementations of the import functionality we needed. Granted, our case was slightly special. We were specifically looking for an export of all layers which could be accompanied by persistent id tags so that we would be able to merge successive imports of the full layer hierarchy into a given Producer project. We were also looking to obtain as much appearance, styling, graphics, layout, and layer type information as possible from the layers, so we could construct their corresponding iOS app "Views" in Producer as completely as possible. Finally, we needed to be able to export graphics layers and slices as PNG images where applicable, we needed to obtain size variations for all the different screen pixel densities, and to top things off, we wanted to build a solution that didn't rely on CocoaScript being able to save to disk, as that could be very problematic for sandboxed applications.

To accomplish all of this, we built this library, `SketchImport`. It enables us to execute arbitrary CocoaScript code at runtime as a plugin on a running instance of the Sketch app, and provides techniques and plugins for grabbing detailed information on the layer hierarchy. To solve image exports, the provided Sketch plugins transmit the image data not through the filesystem but as base64-encoded strings of image data within the very JSON that is returned by the plugins to your code. This means you can handle the NSData of your exported images exactly how you want to, rather than having to read them from disk and manage tmp file deletions.

We aimed to design the code such that each layer of the library could be used independently of higher layers, which means that this library can also be used as a framework for general Sketch plugin code creation/execution. 

Using this library, we're able to take a Sketch file as complex as a full application or as isolated as a single view like the following:

![SketchImport-MacOS](https://github.com/Lunarpad/SketchImport-MacOS/raw/master/images/import%20example.png "SketchImport-MacOS")

*(see the included `./examples/import example.sketch`)*

and obtain the following information automatically:

	Info: Upsert asset named "Frame" with UID 2660D35D-8EAC-4A7D-B613-B80756E3580A-1x with 380 bytes of PNG data
	Info: Upsert asset named "Frame" with UID 2660D35D-8EAC-4A7D-B613-B80756E3580A-2x with 1245 bytes of PNG data
	Info: Upsert asset named "Frame" with UID 2660D35D-8EAC-4A7D-B613-B80756E3580A-3x with 2684 bytes of PNG data
	…
	Info: Upsert asset named "Float" with UID EF624A2D-D741-4DDE-93DA-AA3602BAE56F-1x with 503 bytes of PNG data
	Info: Upsert asset named "Float" with UID EF624A2D-D741-4DDE-93DA-AA3602BAE56F-2x with 972 bytes of PNG data
	Info: Upsert asset named "Float" with UID EF624A2D-D741-4DDE-93DA-AA3602BAE56F-3x with 1530 bytes of PNG data
	…
	Info: Upsert a view 65602CEA-4E77-413E-964C-06073EE3BB04 ("Prompt description.") with derived type Label
	{
	  "absoluteRect_H" : 16,
	  "isTopLevel" : false,
	  "didFlatten" : false,
	  "isLayerExportable" : false,
	  "sliceRect_Y" : 369,
	  "sliceRect_X" : 390,
	  "sourceLayerClassName" : "MSTextLayer",
	  "name" : "Prompt description.",
	  "textColor_hexValue" : "030303",
	  "isLayerKindOfImmutableShapePathLayer" : false,
	  "absoluteRect_rulerX" : 15,
	  "layerId" : "65602CEA-4E77-413E-964C-06073EE3BB04",
	  "absoluteRect_Y" : 369.5,
	  "stringValue" : "Prompt description.",
	  "absoluteInfluenceRect_H" : 16,
	  "fontSize" : 13,
	  "absoluteRect_X" : 390,
	  "absoluteRect_rulerY" : 48.5,
	  "absoluteInfluenceRect_Y" : 369.5,
	  "layerFrame_W" : 240,
	  "isLayerKindOfMSShapePathLayer" : false,
	  "sliceRect_W" : 240,
	  "textAlignment" : 2,
	  "absoluteInfluenceRect_X" : 390,
	  "sliceRect_H" : 17,
	  "absoluteInfluenceRect_W" : 240,
	  "absoluteRect_W" : 240,
	  "layerFrame_Y" : 48.5,
	  "isASymbol" : false,
	  "fontPostscriptName" : ".AppleSystemUIFont",
	  "layerFrame_X" : 15,
	  "layerFrame_H" : 16
	}
	…
	Info: Upsert a view 30066FCE-7EAC-42D3-BC85-240D84E061A6 ("Path") with derived type ImageView
	{
	  "absoluteRect_H" : 1,
	  "isTopLevel" : false,
	  "didFlatten" : true,
	  "isLayerExportable" : false,
	  "sliceRect_Y" : 442,
	  "sliceRect_X" : 374,
	  "sourceLayerClassName" : "MSShapeGroup",
	  "name" : "Path",
	  "isLayerKindOfImmutableShapePathLayer" : false,
	  "absoluteRect_rulerX" : -0.5,
	  "layerId" : "30066FCE-7EAC-42D3-BC85-240D84E061A6",
	  "absoluteRect_Y" : 442.5,
	  "sublayerIds" : [
			…
	  ],
	  "absoluteInfluenceRect_H" : 1,
	  "absoluteRect_X" : 374.5,
	  "absoluteRect_rulerY" : 121.5,
	  "absoluteInfluenceRect_Y" : 442.5,
	  "layerFrame_W" : 270,
	  "isLayerKindOfMSShapePathLayer" : false,
	  "layerExportDescription" : {
	    "layerId" : "30066FCE-7EAC-42D3-BC85-240D84E061A6",
	    "assetsByScale" : {
	      "1" : {
	        "scale" : 1,
	        "image_asBase64String" : "…"
	      },
	      "2" : {
	        "scale" : 2,
	        "image_asBase64String" : "…"
	      },
	      "3" : {
	        "scale" : 3,
	        "image_asBase64String" : "…"
	      }
	    }
	  },
	  "sliceRect_W" : 271,
	  "absoluteInfluenceRect_X" : 374.5,
	  "sliceRect_H" : 2,
	  "absoluteInfluenceRect_W" : 270,
	  "absoluteRect_W" : 270,
	  "layerFrame_Y" : 0.5,
	  "isASymbol" : true,
	  "layerFrame_X" : 52.5,
	  "layerFrame_H" : 1
	}
	…… 
	
*Full logs from example: [https://gist.github.com/paulshapiro/9954c5584d24b265af6995c6f8b9152b](https://gist.github.com/paulshapiro/9954c5584d24b265af6995c6f8b9152b)*

## Installation

To install, download the source or add this repo as a submodule, and drag `./SketchImport` into your Xcode project.

You'll need to ensure that the contents of `./bin` and `./CocoaScript` are copied to your application bundle so that they can be located at runtime by adding them to the Copy Bundle Resources build phase if necessary.

Finally, if you are using this library from Swift, you'll need to make sure your project has an Objective-C bridging header which `#import`s `LPSketchImport.h`.

See **Examples** below for detailed information.

**Note:** This library currently embeds a statically compiled version of `bin/coscript` for ease of usage. However, this is admittedly not an optimal practice, and this binary may be out of date at the time of reading this, so it would be a good idea to confirm the your targeted versions of Sketch and the compatible `coscript` builds.


## Usage

To do an import, there's only one Objective-C function to call, which is found in `LPSketchImport`:

	void LPSketchImport_attemptSketchImport(	    
	    void(^__nonnull willFlattenLayersByUID_block)(
	    	NSDictionary *__nonnull layersByUID
	    ),
	    
	    BOOL(^__nonnull willImport_returningTrueIfShouldProceed_block(
	    	NSString *__nonnull currentPageName
	    ),
	    
	    void(^__nonnull completeButDidntPerformImport_block)(
	    	NSString *_Nullable warningAlert_title_localizedString_orNilForNoAlert,
			NSString *_Nullable warningAlert_message_localizedString_orNilForBlankMessage
		),
	                                                         
	    void(^__nonnull receivedAnImport_block)(
	    	NSDictionary *_Nonnull importedLayersByUID
	    )
	)
	
… or, as translated to Swift:

	func LPSketchImport_attemptSketchImport(	    
	    willFlattenLayersByUID_block: ((
	    	layersByUID: [String: AnyObject]
	    ) -> Void),
	    
	    willImport_returningTrueIfShouldProceed_block: ((
	    	currentPageName: String
	    ) -> Bool),
	    
	    completeButDidntPerformImport_block:((
	    	warningAlert_title_localizedString_orNilForNoAlert: String?,
			warningAlert_message_localizedString_orNilForBlankMessage: String?
		) -> Void),
	                                                         
	    receivedAnImport_block: ((
	    	importedLayersByUID: [String: AnyObject]
	    ) -> Void)
	)

	

You only need to provide it with some callback blocks to handle the involved different tasks and cases.

* `willFlattenLayersByUID_block` is simply for notifying you that the import will begin so you can inform the user of the scale of the import, i.e. with a HUD;

* `willImport_returningTrueIfShouldProceed_block` can be used as a flow control method to proceed with or cancel the import, i.e. via an NSAlert or other;

* `completeButDidntPerformImport_block` is an error handling callback. The first argument, `warningAlert_title_localizedString_orNilForNoAlert`, will be nil if it was simply a cancellation and not an error. The arguments can be used directly as NSAlert title & informative text properties (See Example below); and

* `receivedAnImport_block` is the success handler and provides you with `importedLayersByUID` as an easy to parse dump from Sketch.

This system provides the building blocks for more sophisticated abstractions to be built on top, such as an internal object-oriented representation. It can be thought of very much like a server response to be parsed and modeled.

A full example is provided as a Mac app written in Swift. (See **Examples** below.)


## How it works

Internally, `LPSketchImport` will first attempt to fetch the Sketch document of the currently key Sketch window by calling `LPSketch`'s function `LPSketch_document`, to see, for example, if it's importable. 

Then, it will attempt to fetch the information about all the layers of the document with `LPSketch_views`, as well as a bitmap/slice export of all the images which can be exported from the layers.

`LPSketch` is able to obtain this information by way of a neat method that allows us to run CocoaScript at runtime from our code on Sketch, as a Sketch plugin. This enables us to do all sorts of useful things at runtime like calling Sketch Objective-C classes such as `MSExporter` on Sketch directly.

To make this integration, `LPSketch` calls a function in the included `LPCocoaScript` called `LPCocoaScript_runCoScript`. This function asks the embedded binary `SketchImport/bin/coscript` to execute the included `SketchImport/CocoaScript/RunSketchPluginScript.js`, which has the ability to load and run the various supporting CocoaScript plugins we have written to extract the info we're looking for. The plugins are located in `SketchImport/CocoaScript/`.

In order to actually get data results out of these CocoaScript plugins, we treat their standard output itself as a parsable JSON string. At the moment, even the base64-encoded exported images are provided embedded within this JSON which enables us to get around sandboxing and tmp dir complexities while providing a high degree of flexibility in data structure.

This library's plugins have been updated to work with the later, post-3.6 versions of Sketch and its newer layer export Objective-C API, but keeps legacy support for pre-3.5 for the moment. 


## Examples

A full, working example of performing a Sketch import and parsing the incoming data has been provided in Swift as a Mac app at is located at `examples/SketchImportExamples/SketchImportExamples.xcodeproj`. 

This example also aims to "sketch" out the basic steps in accomplishing a merge import with the parsed information. 



## Contributing

We ❤️ contributors! 

If you make improvements to this library which would be fit for public consumption we will be happy to review and approve pull requests. Contributers will be credited.

