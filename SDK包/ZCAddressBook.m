//
//  ZCAddressBook.m
//  通讯录Demo
//
//  Created by ZhangCheng on 14-4-19.
//  Copyright (c) 2014年 zhangcheng. All rights reserved.
//

#import "ZCAddressBook.h"
#import "pinyin.h"
static ZCAddressBook *instance;

@implementation ZCAddressBook

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
    if (kiOS9) {
        //添加的联系人
        CNMutableContact*contact=[[CNMutableContact alloc]init];
//        contact.familyName=@"iOS9姓氏";
        contact.givenName=name;
        contact.phoneNumbers=@[[CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberiPhone value:[CNPhoneNumber phoneNumberWithStringValue:label]]];
        
        //设置一个请求
        CNSaveRequest*request=[[CNSaveRequest alloc]init];
        //添加这个联系人
        [request addContact:contact toContainerWithIdentifier:nil];
        //联系人写入
        CNContactStore*store=[[CNContactStore alloc]init];
        //返回成功与否
        return [store executeSaveRequest:request error:nil];

    }else{
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
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
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
   
    
}
#pragma  mark 指定号码是否已经存在
- (ABHelperCheckExistResultType)existPhone:(NSString*)phoneNum{
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)                                                 {                                                     dispatch_semaphore_signal(sema);                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }else{
        addressBook = ABAddressBookCreate();
    }
    CFArrayRef records;
    if (addressBook) {
        
        // 获取通讯录中全部联系人
        records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    }else{
        
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
    
    if (kiOS9) {
        CNContactStore*store=[[CNContactStore alloc]init];
        //检索的数据
        CNContactFetchRequest*fetch=[[CNContactFetchRequest alloc]initWithKeysToFetch:@[CNContactFamilyNameKey,CNContactGivenNameKey,CNContactPhoneNumbersKey]];
        //检索条件，检索所有名字中有zhang的联系人
        //        NSPredicate * predicate = [CNContact predicateForContactsMatchingName:@"zhang"];
        //提取数据
        //        NSArray*contacts=[store unifiedContactsMatchingPredicate:nil keysToFetch:@[CNContactGivenNameKey] error:nil];

        
        [store enumerateContactsWithFetchRequest:fetch error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            //需要注意搜索条件里面需要带3个key才可以,读取电话号码时候用以下方法
            //[[[contact.phoneNumbers firstObject]value]stringValue]
            NSLog(@"%@~%@~%@",contact.familyName,contact.givenName,[[[contact.phoneNumbers firstObject]value]stringValue]);
            //组装数据
            NSMutableArray*xx=[NSMutableArray array];
            for (CNLabeledValue *label in contact.phoneNumbers) {
                [xx addObject:[[label value]stringValue]];
            }
            
            NSDictionary*dic=@{
                               @"first":contact.familyName,
                               @"last":contact.givenName,
                               @"telphone":xx
                               
                               };
            
            if ([contact.familyName isEqualToString:@" "] == NO || [contact.givenName isEqualToString:@" "]) {
                [self.dataArrayDic addObject:dic];
               
            }
            
            
        }];
        //排序
        //建立一个字典，字典保存key是A-Z  值是数组
        NSMutableDictionary*index=[NSMutableDictionary dictionaryWithCapacity:0];
        
        for (NSDictionary*dic in self.dataArrayDic) {
            
            NSString* str=[dic objectForKey:@"first"];
            //获得中文拼音首字母，如果是英文或数字则#
            if (str.length==0) {
                str=[dic objectForKey:@"last"];
            }
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
    }else{
    //取得本地通信录名柄
    ABAddressBookRef addressBook ;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)    {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)                                                 {                                                     dispatch_semaphore_signal(sema);                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
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
        NSString *first = (__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        if (first==nil) {
            first = @" ";
        }
        [dicInfoLocal setObject:first forKey:@"first"];
        
        NSString *last = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if (last == nil) {
            last = @" ";
        }
        [dicInfoLocal setObject:last forKey:@"last"];
        
        
        
        
        ABMultiValueRef tmlphone =  ABRecordCopyValue(person, kABPersonPhoneProperty);

        
       NSArray*telphoneArray= (__bridge NSArray*)ABMultiValueCopyArrayOfAllValues(tmlphone);
        NSMutableArray*array=[NSMutableArray array];
        for (NSString* telphone in telphoneArray) {
            if (telphone == nil) {
                
                [array addObject:@""];
                
                }else{
                [array addObject:telphone];
    
            }

        }
        
        [dicInfoLocal setObject:array forKey:@"telphone"];
        CFRelease((__bridge CFTypeRef)(telphoneArray));
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
        if (str.length==0) {
            str=[dic objectForKey:@"last"];
        }
        
//        NSLog(@"%@",dic);
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
}
#pragma  mark 字母转换大小写--6.0
-(NSString*)upperStr:(NSString*)str{
    
    // 全部转换为小写
    NSString *lowerStr = [str lowercaseStringWithLocale:[NSLocale currentLocale]];
    
    return lowerStr;
    
}
#pragma mark 排序
-(NSArray*)sortMethod
{
    return [self.dataArray sortedArrayUsingFunction:cmp context:NULL];
}
#pragma mark 构建数组排序方法SEL
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
-(void)showSystemMessageToListArray:(NSArray*)array Message:(NSString*)str ViewController:(id)target Block:(void(^)(int))a{
    self.target=target;
    self.MessageBlock=a;
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
-(void)showPhoneViewWithTarget:(id)target Block:(void(^)(BOOL,NSDictionary*))a
{
    self.target=target;
    self.PhoneBlock=a;
    
    if (kiOS9) {
        CNContactPickerViewController*vc=[[CNContactPickerViewController alloc]init];
        vc.delegate=self;
        [self.target presentViewController:vc animated:YES completion:nil];
    }else{
        
        ABPeoplePickerNavigationController * peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
        
        peoplePicker.peoplePickerDelegate = self;
        [self.target presentViewController:peoplePicker animated:YES completion:nil];
    }

}

#pragma mark iOS8点击详情进入的
-(void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{

}
#pragma mark iOS8点击联系人进入的
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person
{
    
    ABMutableMultiValueRef phoneMulti = ABRecordCopyValue(person, kABPersonPhoneProperty);
    
    NSString* firstName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    if (firstName==nil) {
        firstName = @" ";
    }
    NSString* lastName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    if (lastName==nil) {
        lastName = @" ";
    }
    NSMutableArray *phones = [NSMutableArray arrayWithCapacity:0];
    
    for (int i = 0; i < ABMultiValueGetCount(phoneMulti); i++) {
        
        NSString *aPhone = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneMulti, i) ;
        
        [phones addObject:aPhone];
        
    }
    NSDictionary*dic=@{@"firstName": firstName,@"lastName":lastName,@"phones":phones};
    
    self.PhoneBlock(YES,dic);
    
    [self.target dismissViewControllerAnimated:YES completion:nil];

}
#pragma mark iOS7方法
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
    
    NSString* firstName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    if (firstName==nil) {
        firstName = @" ";
    }
    NSString* lastName=(__bridge NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    if (lastName==nil) {
        lastName = @" ";
    }
    NSMutableArray *phones = [NSMutableArray arrayWithCapacity:0];
    
    for (int i = 0; i < ABMultiValueGetCount(phoneMulti); i++) {
        
        NSString *aPhone = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneMulti, i) ;
        
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
#pragma mark iOS9的方法
-(void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact
{
    NSLog(@"%@~~%@",contact.familyName,contact.givenName);
    
    NSMutableArray*xx=[NSMutableArray array];
    for (CNLabeledValue *label in contact.phoneNumbers) {
        [xx addObject:[[label value]stringValue]];
    }
    
    NSDictionary*dic=@{
                       @"first":contact.familyName,
                       @"last":contact.givenName,
                       @"telphone":xx
                       
                       };
    
    
    self.PhoneBlock(YES,dic);
    
    [self.target dismissViewControllerAnimated:YES completion:nil];
    
    
}
-(void)contactPickerDidCancel:(CNContactPickerViewController *)picker
{
    [self.target dismissViewControllerAnimated:YES completion:nil];
}
@end
