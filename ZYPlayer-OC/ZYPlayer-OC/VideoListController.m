//
//  VideoListController.m
//  ZYPlayer-OC
//
//  Created by 嘴爷 on 2019/11/26.
//  Copyright © 2019 嘴爷. All rights reserved.
//

#import "VideoListController.h"

@interface VideoListController ()<UITableViewDelegate, UITableViewDataSource>

/** <#description#> */
@property (nonatomic, strong) NSArray<NSDictionary*>* dataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation VideoListController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString* url = [[NSBundle mainBundle] pathForResource:@"VideoList" ofType:@"plist"];
    self.dataSource = [NSArray arrayWithContentsOfFile:url];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataSource.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary* info = self.dataSource[indexPath.row];
    cell.textLabel.text = info[@"name"];
    cell.detailTextLabel.text = info[@"url"];
    
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary* info = self.dataSource[indexPath.row];
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoListController:selectInfo:)]) {
        [self.delegate videoListController:self selectInfo:info];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
