//
//  ZCAddressBook.h
//  通讯录Demo
//
//  Created by ZhangCheng on 14-4-19.
//  Copyright (c) 2014年 zhangcheng. All rights reserved.
//
//版本说明 iOS研究院 305044955
/*
 2016.2.25
 1.5版本 统一了初始化方式为单例方式,在iOS9下调用新库Contacts
 
 2015.7.19
 1.4版本 修改获取同一个联系人下获取多个电话，telphone字段变更为数组
 2015.3.13
 1.3版本 解决iOS8
 iOS8变更了代理方法，导致点击系统通讯录无法获取回调
 2014.4 18
 1.2版本 ZC封装的自定义通讯录界面
 1、解决了iOS7下无数据的问题，增加判断版本
 2、更正类名 由原来的CustomAddressBook修改为ZCAddressBook
 3、增加了发送短信功能
 2014.4.8
 1.1版本 获得的数据进行排序的函数
 解决了中文拼音的问题，处理英文拼写的问题
 2014.4.7
 1.0版本 ZC封装的自定义通讯录界面
 */
/*
 代码示例
 1、使用本类需要加入MessageUI~AddressBookUI~AddressBook3个系统库
 2、还需要有pingyin文件
 3、发送短信需要使用真机才可以
 
 //添加联系人 label是备注
 BOOL isSucceed=[[ZCAddressBook shareControl]addContactName:@"张三" phoneNum:@"34456789"withLabel:@"dfghjklvbn"];
 //获得Vcard
 NSMutableDictionary*dic= [[ZCAddressBook shareControl]getPersonInfo];
 //获得序列索引
 NSArray*array=[[ZCAddressBook shareControl]sortMethod];
 
 //发送短信,群发，可以有指定内容
 [[ZCAddressBook shareControl]showSystemMessageToListArray:@[@"13811928431"] Message:[NSString stringWithFormat:@"%@正在使用你的库文件",[[UIDevice currentDevice] systemName]] ViewController:self Block:^(int a) {
 NSLog(@"%d",a);
 }];
 //调用系统控件，选中后获得指定人信息
 [[ZCAddressBook shareControl]showPhoneViewWithTarget:self Block:^(BOOL isSuccess, NSDictionary *dic) {
 NSLog(@"从系统中获取通讯录~~~%@",dic);
 }];
 
 //跳出程序进行发送短信
 [ZCAddressBook sendMessage:@"13811928431"];
 */

/*
 方法说明
 多少段以及相应顺序 sortMethod 返回的数据
 构建界面，数据使用 getPersonInfo 返回的数据，key通过sortMethod获得
 //key是A-Z的标记   每个value是数组，每个数组成员是字典，每个字典记录每个联系人的具体内容
 //字典是无序的需要对allkeys进行排序
 -(NSMutableDictionary*)getPersonInfo;
 
 //获得排序后的序列
 -(NSArray*)sortMethod;
 
 // 查询指定号码是否已存在于通讯录
 // 返回值：
 //　　ABHelperCanNotConncetToAddressBook -> 连接通讯录失败（iOS6之后访问通讯录需要用户许可）
 //　　ABHelperExistSpecificContact　　　　-> 号码已存在
 //　　ABHelperNotExistSpecificContact　　-> 号码不存在
 // 添加联系人（联系人名称、号码、号码备注标签）
 
 */

#import <Foundation/Foundation.h>
//短信库
#import <MessageUI/MessageUI.h>

//通讯录UI库
#import <AddressBook/AddressBook.h>
//通讯录库
#import <AddressBookUI/AddressBookUI.h>

//iOS9通讯录库
#import <Contacts/Contacts.h>
//iOS9UI的库
#import <ContactsUI/ContactsUI.h>

#define kiOS9 [[UIDevice currentDevice].systemVersion floatValue]>=9.0
enum {
    ABHelperCanNotConncetToAddressBook,
    ABHelperExistSpecificContact,
    ABHelperNotExistSpecificContact
};typedef NSUInteger ABHelperCheckExistResultType;

@interface ZCAddressBook : NSObject<MFMessageComposeViewControllerDelegate,ABPeoplePickerNavigationControllerDelegate,CNContactPickerDelegate>

@property(nonatomic,assign) id target;
@property(nonatomic,copy)void(^MessageBlock)(int);
@property(nonatomic,copy)void(^PhoneBlock)(BOOL,NSDictionary*);
//保存排序好的数组index
@property(nonatomic,retain)NSMutableArray*dataArray;
//数组里面保存每个获取Vcard（名片）
@property(nonatomic,retain)NSMutableArray*dataArrayDic;
#pragma mark 获得单例
+ (ZCAddressBook*)shareControl;

#pragma  mark  添加联系人
- (BOOL)addContactName:(NSString*)name phoneNum:(NSString*)num withLabel:(NSString*)label;

#pragma mark 获取Vcard
-(NSMutableDictionary*)getPersonInfo;

#pragma mark Vcard序列

-(NSArray*)sortMethod;

#pragma mark 发送短信界面 调用系统控件 需要真机才能显示
-(void)showSystemMessageToListArray:(NSArray*)array Message:(NSString*)str ViewController:(id)target Block:(void(^)(int))a;

#pragma mark 使用系统方式进行发送短信，但是短信内容无法规定,会跳出程序 phoneNum传入数字
+(void)sendMessage:(NSString*)phoneNum;

#pragma mark 联系人界面 调用的系统控件
-(void)showPhoneViewWithTarget:(id)target Block:(void(^)(BOOL,NSDictionary*))a;

#pragma mark 查找通讯录中是否有这个联系人
- (ABHelperCheckExistResultType)existPhone:(NSString*)phoneNum;
@end
