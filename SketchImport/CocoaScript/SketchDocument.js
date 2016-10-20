

////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////

var state = {};
function sync_stateUpdatingOperation()
{
    var doc = context.document;
    state.contextExists = context != null && context != undefined;
    if (state.contextExists) {
        state.documentExists = doc != null && doc != undefined;
        if (state.documentExists) {
            var currentPage = [doc currentPage];
            state.currentPageExists = currentPage != null && currentPage != undefined;
            if (state.currentPageExists) {
                state.currentPageName = [currentPage name];
                
                state.isSaved = ([doc fileURL] != null);
                state.numberOfArtboards = [[currentPage artboards] count];
                state.hasArtboards = state.numberOfArtboards > 0;
            }
        }
    }
}
sync_stateUpdatingOperation();


////////////////////////////////////////////////////////////////////////////////

function yieldProgramState()
{
    var jsonData = [NSJSONSerialization dataWithJSONObject:state options:0 error:nil];
    if (jsonData) {
        var jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]; 
        log(jsonString);
    }
}
yieldProgramState();