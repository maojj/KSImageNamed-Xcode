//
//  IDEIndexCompletionStrategy+KSImageNamed.m
//  KSImageNamed
//
//  Created by Kent Sutherland on 1/19/13.
//
//

#import "IDEIndexCompletionStrategy+KSImageNamed.h"
#import "KSImageNamed.h"
#import "MethodSwizzle.h"

@implementation IDEIndexCompletionStrategy (KSImageNamed)

+ (void)load
{
    // Xcode 5 completion method
    MethodSwizzle(self,
                  @selector(completionItemsForDocumentLocation:context:areDefinitive:),
                  @selector(swizzle_completionItemsForDocumentLocation:context:areDefinitive:));
    
    // Xcode 6 completion method
    MethodSwizzle(self,
                  @selector(completionItemsForDocumentLocation:context:highlyLikelyCompletionItems:areDefinitive:),
                  @selector(swizzle_completionItemsForDocumentLocation:context:highlyLikelyCompletionItems:areDefinitive:));
}

/*
 arg1 = DVTTextDocumentLocation
 arg2 = NSDictionary
     DVTTextCompletionContextSourceCodeLanguage <DVTSourceCodeLanguage>
     DVTTextCompletionContextTextStorage <DVTTextStorage>
     DVTTextCompletionContextTextView <DVTSourceTextView>
     IDETextCompletionContextDocumentKey <IDESourceCodeDocument>
     IDETextCompletionContextEditorKey <IDESourceCodeEditor>
     IDETextCompletionContextPlatformFamilyNamesKey (macosx, iphoneos?)
     IDETextCompletionContextUnsavedDocumentStringsKey <NSDictionary>
     IDETextCompletionContextWorkspaceKey <IDEWorkspace>
 arg3 = unsure, not changing it
 returns = IDEIndexCompletionArray
 */
- (id)swizzle_completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 areDefinitive:(char *)arg3
{
    id items = [self swizzle_completionItemsForDocumentLocation:arg1 context:arg2 areDefinitive:arg3];
    id sourceTextView = [arg2 objectForKey:@"DVTTextCompletionContextTextView"];
    DVTCompletingTextView *textStorage = [arg2 objectForKey:@"DVTTextCompletionContextTextStorage"];
    
    [self ksimagenamed_checkForImageCompletionItems:items sourceTextView:sourceTextView textStorage:textStorage];
    
    return items;
}

- (id)swizzle_completionItemsForDocumentLocation:(id)arg1 context:(id)arg2 highlyLikelyCompletionItems:(id *)arg3 areDefinitive:(char *)arg4
{
    id items = [self swizzle_completionItemsForDocumentLocation:arg1 context:arg2 highlyLikelyCompletionItems:arg3 areDefinitive:arg4];
    id sourceTextView = [arg2 objectForKey:@"DVTTextCompletionContextTextView"];
    DVTCompletingTextView *textStorage = [arg2 objectForKey:@"DVTTextCompletionContextTextStorage"];
    
    [self ksimagenamed_checkForImageCompletionItems:items sourceTextView:sourceTextView textStorage:textStorage];
    
    return items;
}

// Returns void because this modifies items in place
- (void)ksimagenamed_checkForImageCompletionItems:(id)items sourceTextView:(id)sourceTextView textStorage:(id)textStorage
{
    void(^buildImageCompletions)() = ^{
        @try {
            BOOL atImageNamed = [[KSImageNamed sharedPlugin] atImageNamedForSourceTextView:sourceTextView
                                                                               textStorage:textStorage];

            if (atImageNamed) {
                //Find index
                id document = [[[sourceTextView window] windowController] document];
                id index = [[document performSelector:@selector(workspace)] performSelector:@selector(index)];
                NSArray *completions = [[KSImageNamed sharedPlugin] imageCompletionsForIndex:index];
                
                if ([completions count] > 0) {
                    [items removeAllObjects];
                    [items addObjectsFromArray:completions];
                }
            }
        } @catch (NSException *exception) {
            //Handle this or something
        }
    };
    
    //Ensure this runs on the main thread since we're using NSTextStorage
    if ([NSThread isMainThread]) {
        buildImageCompletions();
    } else {
        dispatch_sync(dispatch_get_main_queue(), buildImageCompletions);
    }
}

@end
