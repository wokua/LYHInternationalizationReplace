//
//  ViewController.m
//  LYHInternationalizationReplace
//
//  Created by LRK on 21/3/10.
//  Copyright © 2021年 LRK. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()

@property (weak) IBOutlet NSTextField *stringsPath;
@property (weak) IBOutlet NSTextField *projectPath;
@property (weak) IBOutlet NSScrollView *txtShowChinese;
@property (weak) IBOutlet NSButton *checkStringsFile;
@property (weak) IBOutlet NSButton *replaceWithDefault;

@property (nonatomic, strong)  NSTextView *txtView;
@property(nonatomic,assign)int index;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.stringsPath.editable = NO;
    self.projectPath.editable = NO;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - action
- (IBAction)checkStringsFile:(NSButton *)sender {
    self.replaceWithDefault.state = 0;
}

- (IBAction)replaceWithDefault:(NSButton *)sender {
    self.checkStringsFile.state = 0;
}


- (IBAction)OpenFile:(NSButton *)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    if ([oPanel runModal] == NSModalResponseOK) {
        NSString *path = [[[[[oPanel URLs] objectAtIndex:0] absoluteString] componentsSeparatedByString:@":"] lastObject];
        path = [[path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByExpandingTildeInPath];
        if (sender.tag == 100) {
            self.stringsPath.placeholderString = path;
        } else {
            self.projectPath.placeholderString = path;
        }
    }
}

- (IBAction)exportAction:(id)sender {
    [self readFiles:self.stringsPath.placeholderString];
}

#pragma mark - Method
- (void)showTxt:(NSString *)txt {
    self.txtView.string = txt;
    self.txtShowChinese.documentView = _txtView;
}


- (void)readFiles:(NSString *)str {
    if (self.stringsPath.placeholderString.length == 0) {
        [self showTxt:@"亲，strings路径未选择"];
        return;
    }
    
    if (self.checkStringsFile.state == 0 && self.projectPath.placeholderString.length == 0) {
        [self showTxt:@"亲，项目路径未选择"];
        return;
    }
    
    NSError * error;
    NSString * stringsFile = [NSString stringWithFormat:@"%@/Localizable.strings",self.stringsPath.placeholderString];
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:stringsFile] error:&error];
  
    if (error) {
        [self showTxt:@"亲,.strings文件格式错误。请看项目最后一行日志，按输出对应行数检查"];
        return;
    }else if(self.checkStringsFile.state){
        [self showTxt:@".strings文件格式正常"];
        return;
    }
    [self showTxt:@"开始替换"];
    NSMutableDictionary * mdic = [NSMutableDictionary dictionary];
    
    for (NSString * key in dict.allKeys) {
        [mdic setValue:key forKey:dict[key]];
    }
    for (NSString * key in mdic.allKeys) {
        [self replaceText:key value:mdic[key]];
    }
}


-(void)replaceText:(NSString *)text value:(NSString *)value{
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.index*2*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    NSLog(@"ori:%@",text);
    NSArray * twoTranSpecial = @[@"\\"];  //前面加两个反斜杠
    for (NSString * str in twoTranSpecial) {
        if ([text containsString:str]) {
            NSString * result = [NSString stringWithFormat:@"\\\\%@",str];
            text = [text stringByReplacingOccurrencesOfString:str withString:result];
        }
        if([value containsString:str]){
            NSString * result = [NSString stringWithFormat:@"\\\\%@",str];
            value = [value stringByReplacingOccurrencesOfString:str withString:result];
        }
    }
    
    NSArray * threeTranSpecial = @[@"$",@"\""];//前面加三个反斜杠
    for (NSString * str in threeTranSpecial) {
        if ([text containsString:str]) {
            NSString * result = [NSString stringWithFormat:@"\\\\\\%@",str];
            text = [text stringByReplacingOccurrencesOfString:str withString:result];
        }
        if([value containsString:str]){
            NSString * result = [NSString stringWithFormat:@"\\\\\\%@",str];
            value = [value stringByReplacingOccurrencesOfString:str withString:result];
        }
    }
    
    NSArray * special = @[@"{",@"}",@"!",@"^",@"-",@"*",@"/",@"=",@"[",@"]",@"&",@"%",@"@"];//前面加一个反斜杠
    for (NSString * str in special) {
        if ([text containsString:str]) {
            NSString * result = [NSString stringWithFormat:@"\\%@",str];
            text = [text stringByReplacingOccurrencesOfString:str withString:result];
        }
        if([value containsString:str]){
            NSString * result = [NSString stringWithFormat:@"\\%@",str];
            value = [value stringByReplacingOccurrencesOfString:str withString:result];
        }
    }
    
    NSString * gsepText = text;
    //换行符特殊处理
    if ([text containsString:@"\n"]) {
        text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"\\\\n"];
        gsepText = [gsepText stringByReplacingOccurrencesOfString:@"\n" withString:@"'$'\n'$'"];
    }
    if ([value containsString:@"\n"]) {
        value = [value stringByReplacingOccurrencesOfString:@"\n" withString:@"\\\\n"];
    }
    
    text = [NSString stringWithFormat:@"@\\\"%@\\\"",text];
    value = [NSString stringWithFormat:@"@\\\"%@\\\"",value];
    NSLog(@"%@",text);
    NSString * sh2;
    if (self.replaceWithDefault.state) {
        sh2  = [NSString stringWithFormat:@"gsed -i 's/%@/NSLocalizedString(%@,%@)/g' `ggrep \'%@\' -rl --include=\"*.strings\" %@`",text,value,text,gsepText,self.projectPath.placeholderString];
    }else{
        sh2  = [NSString stringWithFormat:@"gsed -i 's/%@/NSLocalizedString(%@,@\"\")/g' `ggrep \'%@\' -rl --include=\"*.strings\" %@`",text,value,gsepText,self.projectPath.placeholderString];
    }
    [self cmd:sh2];
    NSLog(@"=========end");
}

#pragma mark - getter / setter
- (NSTextView *)txtView {
    if (_txtView) {
        return _txtView;
    }
    _txtView = [[NSTextView alloc]initWithFrame:CGRectMake(0, 0, 335, 190)];
    [_txtView setMinSize:NSMakeSize(0.0, 190)];
    [_txtView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [_txtView setVerticallyResizable:YES];
    [_txtView setHorizontallyResizable:NO];
    [_txtView setAutoresizingMask:NSViewWidthSizable];
    [[_txtView textContainer]setContainerSize:NSMakeSize(335,FLT_MAX)];
    [[_txtView textContainer]setWidthTracksTextView:YES];
    [_txtView setFont:[NSFont fontWithName:@"Helvetica" size:12.0]];
    [_txtView setEditable:NO];
    return _txtView;
}

///执行命令
- (void)cmd:(NSString *)cmd{  // 初始化并设置shell路径
    
    NSTask *task = [[NSTask alloc] init];

    //sed路径
    [task setLaunchPath: @"/bin/bash"];
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", cmd,nil];
    [task setArguments: arguments];
    //路径通过 which + sed/gsed 查看对应路径
    //gsed路径
    [task setEnvironment:@{@"path":@"/usr/local/bin"}];
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    // 开始task
    NSError * error;
    if (@available(macOS 10.13, *)) {
        [task launchAndReturnError:&error];
    } else {
        // Fallback on earlier versions
    }
    
    [task waitUntilExit];
}

@end
