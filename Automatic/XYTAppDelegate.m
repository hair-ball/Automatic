//
//  XYTAppDelegate.m
//  Automatic
//
//  Created by sagles on 14-9-3.
//  Copyright (c) 2014年 IKIS. All rights reserved.
//

static NSString *const kServerURLKey = @"ServerURLKey";
static NSString *const kRequestAPIKey = @"RequestAPIKey";
static NSString *const kKeyArrayKey = @"KeyArrayKey";
static NSString *const kValueArrayKey = @"ValueArrayKey";

#define TotalTextAllFormat @"成功：%d，失败：%d"
#define TotalTextSuccessFormat @"成功：%d"
#define TotalTextFailFormat @"失败：%d"

#import "XYTAppDelegate.h"
#import "HttpManager.h"

@interface XYTAppDelegate () <NSTableViewDataSource,NSTableViewDelegate,NSTextDelegate>

@property (weak) IBOutlet NSTextField *serverUrlTextField;

@property (weak) IBOutlet NSTextField *requestApiTextField;

@property (weak) IBOutlet NSTextField *repeatCountTextField;

@property (strong) IBOutlet NSTextView *textView;

@property (weak) IBOutlet NSTextField *totalLabel;

@property (weak) IBOutlet NSTableView *KeyValueTableView;

@property (weak) IBOutlet NSMatrix *matrix;

/**
 *  <#Description#>
 */
@property (nonatomic, assign) int totalSuccess;

/**
 *  <#Description#>
 */
@property (nonatomic, assign) int totalFail;

/**
 *  <#Description#>
 */
@property (nonatomic, assign) MethodType methodType;

/**
 *  key数据源
 */
@property (nonatomic, strong) NSMutableArray *keyArray;

/**
 *  value数据源
 */
@property (nonatomic, strong) NSMutableArray *valueArary;

@end

@implementation XYTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.serverUrlTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kServerURLKey];
    self.requestApiTextField.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:kRequestAPIKey];
    self.repeatCountTextField.stringValue = @"0";
    
    self.methodType = [self.matrix selectedRow];
    
    NSArray *keyArray = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyArrayKey];
    NSArray *valueArray = [[NSUserDefaults standardUserDefaults] objectForKey:kValueArrayKey];
    self.keyArray = keyArray ? [NSMutableArray arrayWithArray:keyArray] :[NSMutableArray array];
    self.valueArary = valueArray ? [NSMutableArray arrayWithArray:valueArray] : [NSMutableArray array];
    
    [self.KeyValueTableView reloadData];
}

#pragma mark - Button events

- (IBAction)beginPushing:(id)sender {
    
    if (self.serverUrlTextField.stringValue.length == 0) {
        [self alertWithContent:@"服务器url不能为空" delegate:nil];
        return;
    }
    
    if (self.requestApiTextField.stringValue.length == 0) {
        [self alertWithContent:@"Api不能为空" delegate:nil];
        return;
    }
    
    //save url and api
    [[NSUserDefaults standardUserDefaults] setObject:self.serverUrlTextField.stringValue forKey:kServerURLKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.requestApiTextField.stringValue forKey:kRequestAPIKey];
    
    //save key value
    [[NSUserDefaults standardUserDefaults] setObject:self.keyArray forKey:kKeyArrayKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.valueArary forKey:kValueArrayKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger count = self.repeatCountTextField.integerValue;
    
    [HttpManager defaultManager].baseUrl = [NSURL URLWithString:self.serverUrlTextField.stringValue];
    
    //reset default log ui
    [self.textView.textStorage.mutableString setString:@""];
    self.totalSuccess = 0;
    self.totalFail = 0;
    
    //setup key-value parameters
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (int i=0; i<self.keyArray.count; i++) {
        [parameters setObject:self.valueArary[i] forKey:self.keyArray[i]];
    }
    
    //star request
    __weak typeof(self) wSelf = self;
    for (int i=1; i<=count; i++) {
        [[HttpManager defaultManager] requestWithMethodType:self.methodType
                                                        api:self.requestApiTextField.stringValue
                                                 parameters:parameters
                                                   complete:^(RequestResultType type, int code) {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           NSString *text = [wSelf textWithType:type code:code index:i];
                                                           [[wSelf.textView.textStorage mutableString] appendString:text];
                                                           
                                                           [wSelf setTotalTextWithType:type];
                                                           
                                                       });
                                                   }];
    }
}
- (IBAction)requestTypeDidChange:(id)sender {
    
    if ([sender isKindOfClass:[NSMatrix class]]) {
        NSMatrix *ma = (NSMatrix *)sender;
        NSInteger selectedColum = [ma selectedColumn];
        
        self.methodType = selectedColum;
    }
}

- (IBAction)addKeyValueButtonPressed:(id)sender {
    [self.keyArray addObject:@"key"];
    [self.valueArary addObject:@"value"];
    [self.KeyValueTableView reloadData];
}

- (IBAction)subtractKeyValueButtonPressed:(id)sender {
    
    NSInteger index = [self.KeyValueTableView selectedRow];
    
    if (index >= 0 && index < self.keyArray.count) {
        [self.keyArray removeObjectAtIndex:index];
        [self.valueArary removeObjectAtIndex:index];
        [self.KeyValueTableView reloadData];
    }
}


#pragma mark - Private methods

- (void)alertWithContent:(NSString *)content delegate:(id)delegate
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"提示"
                                     defaultButton:@"确定"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@",content];
    alert.alertStyle = NSWarningAlertStyle;
    alert.delegate = delegate;
    [alert runModal];
}

- (NSString *)textWithType:(RequestResultType)type code:(int)code index:(int)index
{
    switch (type) {
        case RequestResultTypeRequestFinished:
            return [NSString stringWithFormat:@"==No.%d==  请求成功\n",index];
            break;
        case RequestResultTypeRequestFailed:
            return [NSString stringWithFormat:@"==No.%d==  请求失败\n",index];
            break;
        case RequestResultTypeParseFinished:
            return [NSString stringWithFormat:@"==No.%d==  解析成功\n",index];
            break;
        case RequestResultTypeParserFailed:
            return [NSString stringWithFormat:@"==No.%d==  解析失败\n",index];
            break;
        case RequestResultTypeReturnError:
            return [NSString stringWithFormat:@"==No.%d==  服务器返回失败，code=%d\n",index,code];
            break;
        case RequestResultTypeReturnSuccess:
            return [NSString stringWithFormat:@"==No.%d==  服务器返回成功\n",index];
        default:
            return @"";
            break;
    }
}

- (void)setTotalTextWithType:(RequestResultType)type
{
    switch (type) {
        case RequestResultTypeReturnSuccess:
            self.totalSuccess++;
            break;
        case RequestResultTypeRequestFailed:
        case RequestResultTypeParserFailed:
        case RequestResultTypeReturnError:
            self.totalFail++;
            break;
        default:
            break;
    }
    
    NSString *text = @"";
    if (self.totalSuccess > 0 && self.totalFail > 0) {
        text = [NSString stringWithFormat:TotalTextAllFormat,self.totalSuccess,self.totalFail];
    }
    else if (self.totalSuccess > 0) {
        text = [NSString stringWithFormat:TotalTextSuccessFormat,self.totalSuccess];
    }
    else if (self.totalFail > 0) {
        text = [NSString stringWithFormat:TotalTextFailFormat,self.totalFail];
    }
    
    self.totalLabel.stringValue = text;
}

#pragma mark - NSTableViewDelegate / NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.keyArray.count;
}

#pragma mark Delegate

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"key"]) {
        return self.keyArray[row];
    }
    else {
        return self.valueArary[row];
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"key"]) {
        [self.keyArray replaceObjectAtIndex:row withObject:object];
    }
    else {
        [self.valueArary replaceObjectAtIndex:row withObject:object];
    }
}

@end
