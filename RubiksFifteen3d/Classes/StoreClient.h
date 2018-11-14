//
//  StoreClient.m
//  RubiksFifteen3d
//
//  Created by Oliver Klemenz on 18.11.12.
//  Copyright 2013. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface StoreClient : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, UIAlertViewDelegate> {
    NSArray *storeProducts;
}

@property BOOL storeAvailable;

+ (StoreClient *)instance;

- (BOOL)isStoreAvailable;
- (void)requestProductData;
- (void)provideProduct:(NSString *)product;
- (void)purchaseProduct:(NSString *)product;

- (NSArray *)getStoreProducts;
- (void)purchaseProductAtIndex:(int)index;

- (void)showDonations;

@end
