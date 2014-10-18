//
//  ZCAddressBook.m
//  通讯录Demo
//
//  Created by ZhangCheng on 14-4-19.
//  Copyright (c) 2014年 zhangcheng. All rights reserved.
//

#import "ZCAddressBook.h"
#import "pinyin.h"
#import <AddressBook/AddressBook.h>
static ZCAddressBook *instance;
@implementation ZCAddressBook
-(id)init
{
    if (self=[super init]) {
        
    }
    
    return self;
}
// 单列模式
+ (ZCAddressBook*)shareControl{
    @synchronized(self) {
        if(!instance) {
            instance = [[ZCAddressBook alloc] init];
        }
    }
    return instance;
}
#pragma  mark 添加联系人
// 添加联系人（联系人名称、号码、号码备注标签）
- (BOOL)addContactName:(NSString*)name phoneNum:(NSString*)num withLabel:(NSString*)label{
    // 创建一条空的联系人
    ABRecordRef record = ABPersonCreate();    CFErrorRef error;
    // 设置联系人的名字
    ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)name, &error);
    // 添加联系人电话号码以及该号码对应的标签名
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);    ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)num, (__bridge CFTypeRef)label, NULL);    ABRecordSetValue(record, kABPersonPhoneProperty, multi, &error);
    ABAddressBookRef addressBook = nil;
    // 如果为iOS6以上系统，需要等待用户确认是否允许访问通讯录。
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)    {        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)                                                 {                                                     dispatch_semaphore_signal(sema);                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);         dispatch_release(sema);
    }else{
        addressBook = ABAddressBookCreate();     }
    // 将新建联系人记录添加如通讯录中
    BOOL success = ABAddressBookAddRecord(addressBook, record, &error);
    if (!success) {
        return NO;
    }else{
        // 如果添加记录成功，保存更新到通讯录数据库中
        success = ABAddressBookSave(addressBook, &error);        return success ? YES : NO;
    }
}
#pragma  mark 指定号码是否已经存在
- (ABHelperCheckExistResultType)existPhone:(NSString*)phoneNum{
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)                                                 {                                                     dispatch_semaphore_signal(sema);                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);         dispatch_release(sema);
    }else{
        addressBook = ABAddressBookCreate();
    }
    CFArrayRef records;
    if (addressBook) {
        
        // 获取通讯录中全部联系人
        records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    }else{
        
#ifdef DEBUG        NSLog(@"can not connect to address book");
#endif
        return ABHelperCanNotConncetToAddressBook;
    }
    // 遍历全部联系人，检查是否存在指定号码
    for (int i=0; i<CFArrayGetCount(records); i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        CFTypeRef items = ABRecordCopyValue(record, kABPersonPhoneProperty);
        CFArrayRef phoneNums = ABMultiValueCopyArrayOfAllValues(items);
        if (phoneNums) {
            for (int j=0; j<CFArrayGetCount(phoneNums); j++) {                NSString *phone = (NSString*)CFArrayGetValueAtIndex(phoneNums, j);                if ([phone isEqualToString:phoneNum]) {                    return ABHelperExistSpecificContact;                }
            }
        }
    }    CFRelease(addressBook);
    return ABHelperNotExistSpecificContact;
}
#pragma mark 获取通讯录内容
-(NSMutableDictionary*)getPersonInfo{
    
    self.dataArray = [NSMutableArray arrayWithCapacity:0];
    self.dataArrayDic = [NSMutableArray arrayWithCapacity:0];
    //取得本地通信录名柄
    ABAddressBookRef addressBook ;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)                                                 {                                                     dispatch_semaphore_signal(sema);                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);         dispatch_release(sema);
    }else{
        addressBook = ABAddressBookCreate();
    }
    
    
    
    //取得本地所有联系人记录
    CFArrayRef results = ABAddressBookCopyArrayOfAllPeople(addressBook);
    //    NSLog(@"-----%d",(int)CFArrayGetCount(results));
    //    NSLog(@"in %s %d",__func__,__LINE__);
    for(int i = 0; i < CFArrayGetCount(results); i++)
    {
        NSMutableDictionary *dicInfoLocal = [NSMutableDictionary dictionaryWithCapacity:0];
        ABRecordRef person = CFArrayGetValueAtIndex(results, i);
        //读取firstname
        NSString *first = (NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        if (first==nil) {
            first = @" ";
        }
        [dicInfoLocal setObject:first forKey:@"first"];
        
        NSString *last = (NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if (last == nil) {
            last = @" ";
        }
        [dicInfoLocal setObject:last forKey:@"last"];
        
        
        
        
        ABMultiValueRef tmlphone =  ABRecordCopyValue(person, kABPersonPhoneProperty);
        NSString* telphone = (NSString*)ABMultiValueCopyValueAtIndex(tmlphone, 0);
        if (telphone == nil) {
            telphone = @" ";
        }
        [dicInfoLocal setObject:telphone forKey:@"telphone"];
        CFRelease(tmlphone);
        /*
         //获取的联系人单一属性:Email(s)
         
         ABMultiValueRef tmpEmails = ABRecordCopyValue(person, kABPersonEmailProperty);
         
         NSString *email = (NSString*)ABMultiValueCopyValueAtIndex(tmpEmails, 0);
         [dicInfoLocal setObject:email forKey:@"email"];
         
         CFRelease(tmpEmails);
         if (email) {
         email = @"";
         }
         [dicInfoLocal setObject:email forKey:@"email"];
         */
        //修改
        /*
         if (first&&![first isEqualToString:@""]) {
         //不全的 多信息 多信息
         [self.dataArraydic addObject:dicInfoLocal];
         } */
        
        if ([first isEqualToString:@" "] == NO || [last isEqualToString:@" "]) {
            [self.dataArrayDic addObject:dicInfoLocal];
            // [self.dataArray addObject: [NSString stringWithFormat:@"%@ %@",first,last]];
        }
        
    }
    CFRelease(results);//new
    CFRelease(addressBook);//new
    
    //排序
    //建立一个字典，字典保存key是A-Z  值是数组
    NSMutableDictionary*index=[NSMutableDictionary dictionaryWithCapacity:0];
    
    for (NSDictionary*dic in self.dataArrayDic) {
        
        NSString* str=[dic objectForKey:@"first"];
        //获得中文拼音首字母，如果是英文或数字则#
        
        NSLog(@"%@",dic);
        NSString *strFirLetter = [NSString stringWithFormat:@"%c",pinyinFirstLetter([str characterAtIndex:0])];
        
        if ([strFirLetter isEqualToString:@"#"]) {
            //转换为小写
            
            strFirLetter= [self upperStr:[str substringToIndex:1]];
        }
        if ([[index allKeys]containsObject:strFirLetter]) {
            //判断index字典中，是否有这个key如果有，取出值进行追加操作
            [[index objectForKey:strFirLetter] addObject:dic];
        }else{
            NSMutableArray*tempArray=[NSMutableArray arrayWithCapacity:0];
            [tempArray addObject:dic];
            [index setObject:tempArray forKey:strFirLetter];
        }
        
    }
    
    [self.dataArray addObjectsFromArray:[index allKeys]];
    
    return index;
}
#pragma  mark 字母转换大小写--6.0
-(NSString*)upperStr:(NSString*)str{
    
    //    //全部转换为大写
    //    NSString *upperStr = [str uppercaseStringWithLocale:[NSLocale currentLocale]];
    //    NSLog(@"upperStr: %@", upperStr);
    //首字母转换大写
    //    NSString *capStr = [str capitalizedStringWithLocale:[NSLocale currentLocale]];
    //    NSLog(@"capStr: %@", capStr);
    //    // 全部转换为小写
    NSString *lowerStr = [str lowercaseStringWithLocale:[NSLocale currentLocale]];
    //    NSLog(@"lowerStr: %@", lowerStr);
    return lowerStr;
    
}
#pragma mark 排序
-(NSArray*)sortMethod
{
    
    
    NSArray*array=  [self.dataArray sortedArrayUsingFunction:cmp context:NULL];
    return array;
    
}
//构建数组排序方法SEL
//NSInteger cmp(id, id, void *);
NSInteger cmp(NSString * a, NSString* b, void * p)
{
    if([a compare:b] == 1){
        return NSOrderedDescending;//(1)
    }else
        return  NSOrderedAscending;//(-1)
}

#pragma mark 使用系统方式进行发送短信，但是短信内容无法规定
+(void)sendMessage:(NSString*)phoneNum{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:  [NSString stringWithFormat:@"sms:%@",phoneNum]]];
    
}

-(id)initWithTarget:(id)target MessageNameArray:(NSArray*)array Message:(NSString*)str Block:(void (^)(int))a
{
    if (self=[super init]) {
        self.target=target;
        self.MessageBlock=a;
        [self showViewMessageNameArray:array Message:str];
    }
    return self;
}
-(void)showViewMessageNameArray:(NSArray*)array Message:(NSString*)str{
    
    //判断当前设备是否可以发送信息
    if ([MFMessageComposeViewController canSendText]) {
        
        MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
        
        //委托到本类
        messageViewController.messageComposeDelegate = self;
        
        //设置收件人, 需要一个数组, 可以群发短信
        messageViewController.recipients = array;
        
        //短信的内容
        messageViewController.body =str;
        
        //打开短信视图控制器
        [self.target presentViewController:messageViewController animated:YES completion:nil];
        
        [messageViewController release];
    }
    
    
}
#pragma mark MFMessageComposeViewController 代理方法
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    //0 取消  1是成功 2是失败
    NSLog(@"~~~%d",result);
    self.MessageBlock(result);
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    
}
-(id)initWithTarget:(id)target PhoneView:(void (^)(BOOL, NSDictionary *))a
{
    if (self=[super init]) {
        self.target=target;
        self.PhoneBlock=a;
        ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
        peoplePicker.peoplePickerDelegate = self;
        [self.target presentViewController:peoplePicker animated:YES completion:nil];
        [peoplePicker release];
        
    }
    
    return self;
}
-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    
    ABMutableMultiValueRef phoneMulti = ABRecordCopyValue(person, kABPersonPhoneProperty);
    //获得选中Vcard相应信息
    /*
     ABMutableMultiValueRef address=ABRecordCopyValue(person, kABPersonAddressProperty);
     ABMutableMultiValueRef birthday=ABRecordCopyValue(person, kABPersonBirthdayProperty);
     ABMutableMultiValueRef creationDate=ABRecordCopyValue(person, kABPersonCreationDateProperty);
     ABMutableMultiValueRef date=ABRecordCopyValue(person, kABPersonDateProperty);
     ABMutableMultiValueRef department=ABRecordCopyValue(person, kABPersonDepartmentProperty);
     ABMutableMultiValueRef email=ABRecordCopyValue(person, kABPersonEmailProperty);
     ABMutableMultiValueRef firstNamePhonetic=ABRecordCopyValue(person, kABPersonFirstNamePhoneticProperty);
     
     ABMutableMultiValueRef instantMessage=ABRecordCopyValue(person, kABPersonInstantMessageProperty);
     ABMutableMultiValueRef jobTitle=ABRecordCopyValue(person, kABPersonJobTitleProperty);
     ABMutableMultiValueRef kind=ABRecordCopyValue(person, kABPersonKindProperty);
     ABMutableMultiValueRef lastNamePhonetic=ABRecordCopyValue(person, kABPersonLastNamePhoneticProperty);
     ABMutableMultiValueRef middleNamePhonetic=ABRecordCopyValue(person, kABPersonMiddleNamePhoneticProperty);
     ABMutableMultiValueRef middleName=ABRecordCopyValue(person, kABPersonMiddleNameProperty);
     ABMutableMultiValueRef modificationDate=ABRecordCopyValue(person, kABPersonModificationDateProperty);
     ABMutableMultiValueRef nickname=ABRecordCopyValue(person, kABPersonNicknameProperty);
     ABMutableMultiValueRef note=ABRecordCopyValue(person, kABPersonNoteProperty);
     ABMutableMultiValueRef organization=ABRecordCopyValue(person, kABPersonOrganizationProperty);
     ABMutableMultiValueRef phone=ABRecordCopyValue(person, kABPersonPhoneProperty);
     ABMutableMultiValueRef prefix=ABRecordCopyValue(person, kABPersonPrefixProperty);
     ABMutableMultiValueRef relatedNames=ABRecordCopyValue(person, kABPersonRelatedNamesProperty);
     ABMutableMultiValueRef socialProfile=ABRecordCopyValue(person, kABPersonSocialProfileProperty);
     ABMutableMultiValueRef personSuffix=ABRecordCopyValue(person, kABPersonSuffixProperty);
     ABMutableMultiValueRef _URL=ABRecordCopyValue(person, kABPersonURLProperty);
     */
    
    NSString* firstName=(NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    if (firstName==nil) {
        firstName = @" ";
    }
    NSString* lastName=(NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    if (lastName==nil) {
        lastName = @" ";
    }
    NSMutableArray *phones = [NSMutableArray arrayWithCapacity:0];
    
    for (int i = 0; i < ABMultiValueGetCount(phoneMulti); i++) {
        
        NSString *aPhone = [(NSString*)ABMultiValueCopyValueAtIndex(phoneMulti, i) autorelease];
        
        [phones addObject:aPhone];
        
    }
    NSDictionary*dic=@{@"firstName": firstName,@"lastName":lastName,@"phones":phones};
    
    self.PhoneBlock(YES,dic);
    
    [self.target dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}
-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    
    self.PhoneBlock(NO,nil);
    [self.target dismissViewControllerAnimated:YES completion:nil];
    
    
    
    return NO;
    
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    self.PhoneBlock(NO,nil);
    [self.target dismissViewControllerAnimated:YES completion:nil];
    
}

@end
